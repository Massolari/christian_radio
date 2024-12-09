import gleam/dynamic
import gleam/int
import gleam/json
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

pub type Song {
  Song(artist: String, title: String)
}

pub fn encode(song: Song) -> json.Json {
  json.object([
    #("artist", json.string(song.artist)),
    #("title", json.string(song.title)),
  ])
}

pub fn decode() -> fn(dynamic.Dynamic) ->
  Result(Song, List(dynamic.DecodeError)) {
  dynamic.decode2(
    Song,
    dynamic.field("artist", of: dynamic.string),
    dynamic.field("title", of: dynamic.string),
  )
}

pub fn christianrock_decoder(json: String) -> Result(Song, json.DecodeError) {
  let decoder =
    dynamic.decode2(
      Song,
      dynamic.field("Artist", of: dynamic.string),
      dynamic.field("Title", of: dynamic.string),
    )

  json.decode(from: json, using: decoder)
}

pub fn christianhits_decoder(json: String) -> Result(Song, json.DecodeError) {
  christianrock_decoder(json)
}

pub fn gospel_mix_decoder(json: String) -> Result(Song, json.DecodeError) {
  let decoder =
    dynamic.decode1(
      fn(track: String) {
        let splitted =
          track
          |> string.split(" - ")
          |> list.filter_map(fn(part) {
            case int.parse(part) {
              Ok(_) -> Error(Nil)
              Error(_) ->
                case part {
                  "Ao Vivo" -> Error(Nil)
                  _ -> Ok(part)
                }
            }
          })

        case splitted {
          [artist, title] -> Song(artist, title)
          _ -> Song(artist: "", title: track)
        }
      },
      dynamic.field("currentTrack", of: dynamic.string),
    )

  json.decode(from: json, using: decoder)
}

pub fn melodia_decoder(xml: String) -> Result(Song, String) {
  use #(title, rest) <- result.try(get_melodia_xml_data("cue_title", xml))
  use #(artist, _) <- result.map(get_melodia_xml_data("track_artist_name", rest))

  Song(artist:, title:)
}

fn get_melodia_xml_data(
  name: String,
  xml: String,
) -> Result(#(String, String), String) {
  let error_mapper = fn(_) { "Could not get " <> name <> " from XML: " <> xml }

  xml
  |> string.split(name <> "\"><![CDATA[")
  |> list.last
  |> result.map_error(error_mapper)
  |> result.try(fn(from_title_chunk) {
    string.split_once(from_title_chunk, "]]")
    |> result.map_error(error_mapper)
  })
}

pub fn gospel_adoracao_decoder(html: String) -> Result(Song, String) {
  html
  |> string.split_once("<b>Tocando agora:</b>")
  |> result.map(pair.second)
  |> result.then(string.split_once(_, "|"))
  |> result.map(pair.first)
  |> result.then(string.split_once(_, "\r\n"))
  |> result.map(pair.first)
  |> result.map(string.trim)
  |> result.map(fn(song) {
    case string.split_once(song, " - ") {
      Ok(#(artist, title)) -> {
        // The part which is uppercase is the song title, probably
        case string.uppercase(artist) == artist {
          True -> Song(artist: title, title: artist)
          False -> Song(artist:, title:)
        }
      }
      Error(_) -> Song(artist: "", title: song)
    }
  })
  |> result.replace_error("Could not get song from HTML: " <> html)
}
