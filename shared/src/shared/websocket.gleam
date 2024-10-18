import gleam/dynamic
import gleam/json
import gleam/result
import shared/song

pub type WebSocketMessage {
  Song(song.Song)
  History(List(song.Song))
}

pub fn encode(msg: WebSocketMessage) -> json.Json {
  case msg {
    Song(song) ->
      json.object([#("type", json.string("song")), #("song", song.encode(song))])
    History(history) ->
      json.object([
        #("type", json.string("history")),
        #("history", json.array(history, of: song.encode)),
      ])
  }
}

pub fn decode(json: String) -> Result(WebSocketMessage, String) {
  let type_ = json.decode(json, dynamic.field("type", of: dynamic.string))

  case type_ {
    Ok("song") ->
      json
      |> json.decode(dynamic.field("song", of: song.decode()))
      |> result.replace_error(json)
      |> result.map(Song)
    Ok("history") ->
      json
      |> json.decode(dynamic.field(
        "history",
        of: dynamic.list(of: song.decode()),
      ))
      |> result.replace_error(json)
      |> result.map(History)
    _ -> Error(json)
  }
}
