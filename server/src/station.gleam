import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/result
import shared/song.{type Song}
import shared/station.{
  type StationName, ChristianHits, ChristianRock, GospelAdoracao, GospelMix,
  Melodia, Radio93,
}

pub fn get_song(station: StationName) -> Result(Song, String) {
  case station {
    ChristianHits -> get_christian_hits()
    ChristianRock -> get_christian_rock()
    GospelMix -> get_gospel_mix()
    Melodia -> get_melodia()
    Radio93 ->
      Ok(song.Song(title: "Sem dados da música", artist: "Rádio 93 FM"))
    GospelAdoracao -> get_gospel_adoracao()
  }
}

fn get_christian_hits() -> Result(Song, String) {
  get_christianrock_radio_song("https://www.christianrock.net/iphonechdn.php")
}

pub fn get_christian_rock() -> Result(Song, String) {
  get_christianrock_radio_song("https://www.christianrock.net/iphonecrdn.php")
}

fn get_christianrock_radio_song(radio: String) -> Result(Song, String) {
  let assert Ok(request) = request.to(radio)

  use response <- result.try(
    request
    |> httpc.send
    |> map_httpc_error,
  )

  response.body
  |> song.christianrock_decoder
  |> map_decoder_error
}

fn get_gospel_mix() -> Result(Song, String) {
  let assert Ok(request) =
    request.to(
      "https://d36nr0u3xmc4mm.cloudfront.net/index.php/api/streaming/status/7108/71903e44e2b47a851a09ec0fee6a984f/SV19BR",
    )

  // Send the HTTP request to the server
  use response <- result.try(
    request
    |> httpc.send
    |> map_httpc_error,
  )

  response.body
  |> song.gospel_mix_decoder
  |> map_decoder_error
}

fn get_melodia() -> Result(Song, String) {
  let assert Ok(request) =
    request.to(
      "https://np.tritondigital.com/public/nowplaying?mountName=MELODIAFMAAC&numberToFetch=1&eventType=track",
    )

  // Send the HTTP request to the server
  use response <- result.try(
    request
    |> httpc.send
    |> map_httpc_error,
  )

  response.body
  |> song.melodia_decoder
  |> map_decoder_error
}

fn get_gospel_adoracao() -> Result(Song, String) {
  let assert Ok(request) =
    request.to(
      "https://www.radiogospeladoracao.com/admin/includes/locutor/no-ar-player.php",
    )

  use response <- result.try(
    request
    |> httpc.send
    |> map_httpc_error,
  )

  response.body
  |> song.gospel_adoracao_decoder
  |> map_decoder_error
}

fn map_httpc_error(
  httpc_result: Result(a, httpc.HttpError),
) -> Result(a, String) {
  use error <- result.map_error(httpc_result)
  io.debug(error)

  "Não foi possível obter música"
}

fn map_decoder_error(decoded: Result(a, b)) -> Result(a, String) {
  use error <- result.map_error(decoded)
  io.debug(error)

  "Não foi possível decodificar música"
}
