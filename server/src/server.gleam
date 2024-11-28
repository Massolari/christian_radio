import client_manager.{type ClientManager}
import gleam/bool
import gleam/bytes_builder
import gleam/erlang/os
import gleam/erlang/process
import gleam/function
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/json
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import history_manager.{type HistoryManager}
import mist.{type Connection, type ResponseData}
import shared/station as shared_station
import shared/websocket as shared_websocket
import simplifile

pub type Context {
  Context(priv_directory: String)
}

pub fn handle_request(
  client_manager: ClientManager,
  history_manager: HistoryManager,
  request: Request(Connection),
) -> Response(ResponseData) {
  case request.path_segments(request) {
    [] ->
      "./static/index.html"
      |> mist.send_file(offset: 0, limit: None)
      |> result.map(fn(file) {
        response.new(200)
        |> response.prepend_header("content-type", "text/html")
        |> response.set_body(file)
      })
      |> result.lazy_unwrap(response_not_found)
    ["ws"] -> handle_websocket(request, client_manager, history_manager)
    ["sw.js"] -> handle_service_worker()
    path -> {
      let file_path = "static/" <> string.join(path, "/")

      mist.send_file(file_path, offset: 0, limit: None)
      |> result.map(fn(file) {
        let content_type = guess_content_type(file_path)
        response.new(200)
        |> response.prepend_header("content-type", content_type)
        |> response.set_body(file)
      })
      |> result.lazy_unwrap(response_not_found)
    }
  }
}

fn response_not_found() -> Response(ResponseData) {
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_builder.new()))
}

fn guess_content_type(path: String) -> String {
  use <- bool.guard(when: string.ends_with(path, ".css"), return: "text/css")
  use <- bool.guard(
    when: string.ends_with(path, "js"),
    return: "application/javascript",
  )
  use <- bool.guard(when: string.ends_with(path, "html"), return: "text/html")
  use <- bool.guard(
    when: string.ends_with(path, "json"),
    return: "application/json",
  )

  "application/octet-stream"
}

fn handle_websocket(
  request: Request(Connection),
  client_manager: ClientManager,
  history_manager: HistoryManager,
) -> Response(ResponseData) {
  let selector = process.new_selector()

  mist.websocket(
    request:,
    on_init: fn(conn) {
      let subject = process.new_subject()

      let this_selector =
        process.selecting(selector, subject, function.identity)

      client_manager.add(client_manager, conn, subject)

      #(conn, Some(this_selector))
    },
    on_close: fn(state) { client_manager.remove(client_manager, state) },
    handler: fn(state, _conn, msg) {
      case msg {
        mist.Text(text) -> {
          case shared_station.from_string(text) {
            Ok(station) -> {
              client_manager.set_station(client_manager, state, station)

              // Get song history from the station
              // If the history is empty, get the last song from the station
              // and send it to the client
              io.println("Getting song history for " <> string.inspect(station))

              let _ =
                history_manager
                |> history_manager.get_history(station)
                |> result.nil_error
                |> result.try(fn(history) {
                  io.println("Got history")

                  case history {
                    [] -> {
                      io.println("No history, getting last song")

                      history_manager
                      |> history_manager.get_song(station)
                      |> result.nil_error
                      |> result.try(fn(song) {
                        io.println("Got last song: " <> song.title)

                        send_websocket_message(
                          shared_websocket.History([song]),
                          state,
                        )
                        |> result.nil_error
                      })
                    }

                    _ ->
                      send_websocket_message(
                        shared_websocket.History(history),
                        state,
                      )
                      |> result.nil_error
                  }
                })

              actor.continue(state)
            }
            Error(_) -> actor.continue(state)
          }
        }
        mist.Custom(client_manager.ClientSendSong(song)) -> {
          let _ = send_websocket_message(shared_websocket.Song(song), state)

          actor.continue(state)
        }
        mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
        _ -> actor.continue(state)
      }
    },
  )
}

fn handle_service_worker() -> Response(ResponseData) {
  // Lê o arquivo sw.js e substitui GIT_COMMIT_HASH
  simplifile.read("static/sw.js")
  |> result.map(fn(content) {
    let git_hash = os.get_env("GIT_COMMIT_HASH") |> result.unwrap("dev")
    let new_content =
      content
      |> string.replace("GIT_COMMIT_HASH", "'" <> git_hash <> "'")

    response.new(200)
    |> response.prepend_header("content-type", "application/javascript")
    |> response.set_body(
      new_content
      |> bytes_builder.from_string
      |> mist.Bytes,
    )
  })
  |> result.lazy_unwrap(response_not_found)
}

pub fn send_websocket_message(
  msg: shared_websocket.WebSocketMessage,
  conn: mist.WebsocketConnection,
) {
  let json_msg =
    msg
    |> shared_websocket.encode
    |> json.to_string

  mist.send_text_frame(conn, json_msg)
}

pub fn main() {
  // Inicializa o gerenciador de clientes websocket
  let assert Ok(client_manager) = client_manager.new()

  // Inicializa o gerenciador de histórico de músicas
  let assert Ok(history_manager) = history_manager.new(client_manager)

  // Inicializa o servidor HTTP
  let assert Ok(_) =
    handle_request(client_manager, history_manager, _)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
