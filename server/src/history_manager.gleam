import client_manager
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/string
import shared/song
import shared/station.{type StationName} as _
import station

pub opaque type HistoryManager {
  HistoryManager(Subject(Msg))
}

type Msg {
  FetchSongs
  GetSong(Subject(song.Song), StationName)
  GetSongHistory(Subject(List(song.Song)), StationName)
}

/// Inicializa o gerenciador de histórico de músicas
/// O gerenciador de histórico de músicas é responsável por buscar músicas das estações de clientes
/// e armazenar o histórico de músicas de cada estação
pub fn new(
  client_manager: client_manager.ClientManager,
) -> Result(HistoryManager, actor.StartError) {
  use subject <- result.map(
    actor.start(dict.new(), fn(msg, history) {
      case msg {
        FetchSongs ->
          client_manager
          |> client_manager.get_all
          |> result.map(fetch_songs_for_clients(_, history, client_manager))
          |> result.unwrap(history)
          |> actor.continue

        GetSongHistory(subject, station) -> {
          history
          |> dict.get(station)
          |> result.unwrap([])
          |> process.send(subject, _)

          actor.continue(history)
        }
        GetSong(subject, station) -> {
          let song =
            station
            |> station.get_song
            |> result.unwrap(song.unknown_song)

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
    }),
  )

  process.start(fn() { fetch_song_periodically(subject) }, True)

  HistoryManager(subject)
}

fn fetch_song_periodically(subject: Subject(Msg)) {
  process.sleep(30_000)

  process.send(subject, FetchSongs)

  fetch_song_periodically(subject)
}

fn fetch_songs_for_clients(
  client_states: List(client_manager.Client),
  history: Dict(StationName, List(song.Song)),
  client_manager: client_manager.ClientManager,
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
  station
  |> station.get_song
  |> result.try(fn(song) {
    io.println("Got new song: " <> song.title)

    case Ok(song) == last_song {
      True -> Error("Repeated")
      False -> Ok(song)
    }
  })
  |> result.map(fn(song) {
    io.println("Sending new song to all clients of this station")

    // Send song to all clients of this station
    list.each(clients_with_station, fn(client_station) {
      client_manager.send_song(client_manager, { client_station.0 }.conn, song)
    })

    // Update history for this station
    [song, ..old_history]
  })
  |> result.unwrap(old_history)
  |> dict.insert(acc, station, _)
}

pub fn get_history(
  history_manager: HistoryManager,
  station: StationName,
) -> Result(List(song.Song), process.CallError(List(song.Song))) {
  let HistoryManager(subject) = history_manager

  subject
  |> process.try_call(GetSongHistory(_, station), 15_000)
}

pub fn get_song(
  history_manager: HistoryManager,
  station: StationName,
) -> Result(song.Song, process.CallError(song.Song)) {
  let HistoryManager(subject) = history_manager

  subject |> process.try_call(GetSong(_, station), 15_000)
}
