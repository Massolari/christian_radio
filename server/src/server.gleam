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
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData}
import shared/song
import shared/station.{type StationName} as shared_station
import shared/websocket as shared_websocket
import station

pub type WebSocketClients =
  Subject(WebSocketManagerMessage)

pub type ClientState {
  ClientState(
    station: Option(StationName),
    conn: mist.WebsocketConnection,
    subject: Subject(WebSocketProcessMessage),
  )
}

pub type WebSocketManagerMessage {
  Connect(mist.WebsocketConnection, Subject(WebSocketProcessMessage))
  Disconnect(mist.WebsocketConnection)
  SetStation(mist.WebsocketConnection, StationName)
  GetClients(Subject(List(ClientState)))
  SendSong(mist.WebsocketConnection, song.Song)
}

pub type SongHistory =
  Dict(StationName, List(song.Song))

pub type SongHistoryMessage {
  HistoryFetchSongs
  HistoryGetSong(Subject(song.Song), StationName)
  HistoryGetSongHistory(Subject(List(song.Song)), StationName)
}

pub type WebSocketProcessMessage {
  SendSongMessage(song.Song)
}

pub type Context {
  Context(priv_directory: String)
}

pub fn handle_request(
  clients: WebSocketClients,
  song_history: Subject(SongHistoryMessage),
  request: Request(Connection),
) -> Response(ResponseData) {
  case request.path_segments(request) {
    [] ->
      "./static/index.html"
      |> mist.send_file(offset: 0, limit: None)
      |> io.debug
      |> result.map(fn(file) {
        response.new(200)
        |> response.prepend_header("content-type", "text/html")
        |> response.set_body(file)
      })
      |> result.lazy_unwrap(response_not_found)
    ["ws"] -> handle_websocket(request, clients, song_history)
    ["api", ..path] -> handle_api_request(request, path)
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

fn handle_api_request(
  _request: Request(Connection),
  path: List(String),
) -> Response(ResponseData) {
  case path {
    ["station", station] -> station.handle_request(station)
    _ -> response_not_found()
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

  "application/octet-stream"
}

fn handle_websocket(
  request: Request(Connection),
  websocket_manager: WebSocketClients,
  song_history: Subject(SongHistoryMessage),
) -> Response(ResponseData) {
  let selector = process.new_selector()

  mist.websocket(
    request:,
    on_init: fn(conn) {
      let subject = process.new_subject()

      let this_selector =
        process.selecting(selector, subject, function.identity)

      process.send(websocket_manager, Connect(conn, subject))
      #(conn, Some(this_selector))
    },
    on_close: fn(state) { process.send(websocket_manager, Disconnect(state)) },
    handler: fn(state, _conn, msg) {
      case msg {
        mist.Text(text) -> {
          case shared_station.from_string(text) {
            Ok(station) -> {
              process.send(websocket_manager, SetStation(state, station))

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
        mist.Custom(SendSongMessage(song)) -> {
          let _ = send_websocket_message(shared_websocket.Song(song), state)

          actor.continue(state)
        }
        mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
        _ -> actor.continue(state)
      }
    },
  )
}

/// Inicializa o gerenciador de clientes websocket
/// O gerenciador de clientes websocket é responsável por gerenciar os clientes conectados
pub fn new_websocket_manager() -> Result(
  Subject(WebSocketManagerMessage),
  actor.StartError,
) {
  actor.start(dict.new(), fn(msg, clients) {
    case msg {
      Connect(conn, subject) -> {
        actor.continue(dict.insert(
          clients,
          conn,
          ClientState(conn:, subject:, station: None),
        ))
      }
      Disconnect(conn) -> actor.continue(dict.delete(clients, conn))
      SetStation(conn, station) ->
        clients
        |> dict.get(conn)
        |> result.map(fn(client) {
          ClientState(..client, station: Some(station))
        })
        |> result.map(dict.insert(clients, conn, _))
        |> result.unwrap(clients)
        |> actor.continue

      GetClients(subject) -> {
        clients
        |> dict.values
        |> list.filter(fn(client) { option.is_some(client.station) })
        |> process.send(subject, _)

        actor.continue(clients)
      }
      SendSong(conn, song) -> {
        let _ =
          clients
          |> dict.get(conn)
          |> result.map(fn(client) {
            process.send(client.subject, SendSongMessage(song))
          })

        actor.continue(clients)
      }
    }
  })
}

/// Inicializa o gerenciador de histórico de músicas
/// O gerenciador de histórico de músicas é responsável por buscar músicas das estações de clientes
/// e armazenar o histórico de músicas de cada estação
pub fn new_song_history_manager(
  websocket_manager: Subject(WebSocketManagerMessage),
) -> Result(Subject(SongHistoryMessage), actor.StartError) {
  actor.start(dict.new(), fn(msg, history) {
    case msg {
      HistoryFetchSongs ->
        websocket_manager
        |> process.try_call(GetClients, 5000)
        |> result.map(fetch_songs_for_clients(_, history, websocket_manager))
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
        case station.get_song(station) {
          Ok(song) -> {
            process.send(subject, song)

            let new_history =
              dict.upsert(history, station, fn(maybe_songs) {
                maybe_songs
                |> option.unwrap([])
                |> list.prepend(song)
              })

            actor.continue(new_history)
          }
          Error(_) -> actor.continue(history)
        }
      }
    }
  })
}

pub fn fetch_songs_for_clients(
  client_states: List(ClientState),
  history: Dict(StationName, List(song.Song)),
  websocket_manager: Subject(WebSocketManagerMessage),
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
        process.send(
          websocket_manager,
          SendSong({ client_station.0 }.conn, song),
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
  let assert Ok(clients) = new_websocket_manager()

  // Inicializa o gerenciador de histórico de músicas
  let assert Ok(song_history) = new_song_history_manager(clients)

  // Inicie a execução periódica em um novo processo
  process.start(fn() { fetch_song_periodically(song_history) }, True)

  // Inicializa o servidor HTTP
  let assert Ok(_) =
    handle_request(clients, song_history, _)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
