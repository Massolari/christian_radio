import client_manager.{type ClientManager}
import gleam/bool
import gleam/bytes_builder
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}
import shared/song
import shared/station.{type StationName} as shared_station
import shared/websocket as shared_websocket
import station

pub type SongHistory =
  Dict(StationName, List(song.Song))

pub type SongHistoryMessage {
  HistoryFetchSongs
  HistoryGetSong(Subject(song.Song), StationName)
  HistoryGetSongHistory(Subject(List(song.Song)), StationName)
}

pub type Context {
  Context(priv_directory: String)
}

pub fn handle_request(
  client_manager: ClientManager,
  song_history: Subject(SongHistoryMessage),
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
    ["ws"] -> handle_websocket(request, client_manager, song_history)
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
  song_history: Subject(SongHistoryMessage),
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
                song_history
                |> process.try_call(HistoryGetSongHistory(_, station), 15_000)
                |> result.replace_error(Nil)
                |> result.try(fn(history) {
                  io.println("Got history")

                  case history {
                    [] -> {
                      io.println("No history, getting last song")

                      song_history
                      |> process.try_call(HistoryGetSong(_, station), 15_000)
                      |> result.replace_error(Nil)
                      |> result.try(fn(song) {
                        io.println("Got last song: " <> song.title)

                        send_websocket_message(
                          shared_websocket.History([song]),
                          state,
                        )
                        |> result.replace_error(Nil)
                      })
                    }

                    _ ->
                      send_websocket_message(
                        shared_websocket.History(history),
                        state,
                      )
                      |> result.replace_error(Nil)
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

/// Inicializa o gerenciador de histórico de músicas
/// O gerenciador de histórico de músicas é responsável por buscar músicas das estações de clientes
/// e armazenar o histórico de músicas de cada estação
pub fn new_song_history_manager(
  client_manager: ClientManager,
) -> Result(Subject(SongHistoryMessage), actor.StartError) {
  actor.start(dict.new(), fn(msg, history) {
    case msg {
      HistoryFetchSongs ->
        client_manager
        |> client_manager.get_all
        |> result.map(fetch_songs_for_clients(_, history, client_manager))
        |> result.unwrap(history)
        |> actor.continue

      HistoryGetSongHistory(subject, station) -> {
        history
        |> dict.get(station)
        |> result.unwrap([])
        |> process.send(subject, _)

        actor.continue(history)
      }
      HistoryGetSong(subject, station) -> {
        let song =
          station
          |> station.get_song
          |> result.unwrap(song.Song(title: "Unknown", artist: "Unknown"))

        process.send(subject, song)

        let new_history =
          dict.upsert(history, station, fn(maybe_songs) {
            maybe_songs
            |> option.unwrap([])
            |> list.prepend(song)
          })

        actor.continue(new_history)
      }
    }
  })
}

pub fn fetch_songs_for_clients(
  client_states: List(client_manager.Client),
  history: Dict(StationName, List(song.Song)),
  client_manager: ClientManager,
) -> Dict(StationName, List(song.Song)) {
  io.println("Fetching songs for clients")
  // Group clients by station
  let clients_by_station =
    client_states
    |> list.filter_map(fn(client) {
      client.station
      |> option.map(fn(station) { #(client, station) })
      |> option.to_result(Nil)
    })
    |> list.group(fn(client_station) { client_station.1 })

  use acc, station, clients_with_station <- dict.fold(
    clients_by_station,
    dict.new(),
  )

  io.println("Getting song for " <> string.inspect(station))

  let old_history =
    history
    |> dict.get(station)
    |> result.unwrap([])

  let last_song = list.first(old_history)

  io.println("Last song: " <> string.inspect(last_song))

  // Check if the song is the same as the last song
  let song =
    station
    |> station.get_song
    |> result.try(fn(song) {
      io.println("Got new song: " <> song.title)

      case Ok(song) == last_song {
        True -> Error("Repeated")
        False -> Ok(song)
      }
    })

  let new_history = case song {
    Ok(song) -> {
      io.println("Sending new song to all clients of this station")

      // Send song to all clients of this station
      list.each(clients_with_station, fn(client_station) {
        client_manager.send_song(
          client_manager,
          { client_station.0 }.conn,
          song,
        )
      })

      // Update history for this station
      [song, ..old_history]
    }
    Error(_) -> old_history
  }

  dict.insert(acc, station, new_history)
}

fn fetch_song_periodically(song_history: Subject(SongHistoryMessage)) {
  process.sleep(30_000)
  process.send(song_history, HistoryFetchSongs)
  fetch_song_periodically(song_history)
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
  let assert Ok(song_history) = new_song_history_manager(client_manager)

  // Inicie a execução periódica em um novo processo
  process.start(fn() { fetch_song_periodically(song_history) }, True)

  // Inicializa o servidor HTTP
  let assert Ok(_) =
    handle_request(client_manager, song_history, _)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
