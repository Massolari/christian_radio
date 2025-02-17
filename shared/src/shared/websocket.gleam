import gleam/dynamic/decode
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
  let type_ = json.parse(json, decode.at(["type"], decode.string))

  case type_ {
    Ok("song") ->
      json
      |> json.parse(decode.at(["song"], song.decoder()))
      |> result.replace_error(json)
      |> result.map(Song)
    Ok("history") ->
      json
      |> json.parse(decode.at(["history"], decode.list(song.decoder())))
      |> result.replace_error(json)
      |> result.map(History)
    _ -> Error(json)
  }
}
