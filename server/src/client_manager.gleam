import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import mist
import shared/song
import shared/station.{type StationName}

pub opaque type ClientManager {
  ClientManager(Subject(Msg))
}

pub type Client {
  Client(
    station: Option(StationName),
    conn: mist.WebsocketConnection,
    subject: Subject(ClientMsg),
  )
}

pub type ClientMsg {
  ClientSendSong(song.Song)
}

type Msg {
  Connect(mist.WebsocketConnection, Subject(ClientMsg))
  Disconnect(mist.WebsocketConnection)
  SetStation(mist.WebsocketConnection, StationName)
  GetClients(Subject(List(Client)))
  SendSong(mist.WebsocketConnection, song.Song)
}

/// Inicializa o gerenciador de clientes websocket
/// O gerenciador de clientes websocket é responsável por gerenciar os clientes conectados
pub fn new() -> Result(ClientManager, actor.StartError) {
  actor.start(dict.new(), fn(msg, clients) {
    case msg {
      Connect(conn, subject) -> {
        actor.continue(dict.insert(
          clients,
          conn,
          Client(conn:, subject:, station: None),
        ))
      }
      Disconnect(conn) -> actor.continue(dict.delete(clients, conn))
      SetStation(conn, station) ->
        clients
        |> dict.get(conn)
        |> result.map(fn(client) { Client(..client, station: Some(station)) })
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
            process.send(client.subject, ClientSendSong(song))
          })

        actor.continue(clients)
      }
    }
  })
  |> result.map(ClientManager)
}

pub fn add(
  client_manager: ClientManager,
  conn: mist.WebsocketConnection,
  client_subject: Subject(ClientMsg),
) {
  let ClientManager(subject) = client_manager

  process.send(subject, Connect(conn, client_subject))
}

pub fn remove(client_manager: ClientManager, conn: mist.WebsocketConnection) {
  let ClientManager(subject) = client_manager

  process.send(subject, Disconnect(conn))
}

pub fn set_station(
  client_manager: ClientManager,
  conn: mist.WebsocketConnection,
  station: StationName,
) {
  let ClientManager(subject) = client_manager
  process.send(subject, SetStation(conn, station))
}

pub fn get_all(
  client_manager: ClientManager,
) -> Result(List(Client), process.CallError(List(Client))) {
  let ClientManager(subject) = client_manager

  process.try_call(subject, GetClients, 5000)
}

pub fn send_song(
  client_manager: ClientManager,
  conn: mist.WebsocketConnection,
  song: song.Song,
) {
  let ClientManager(subject) = client_manager
  process.send(subject, SendSong(conn, song))
}
