import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/result
import gleam/string
import shared/song.{type Song}
import shared/station.{
  type StationName, ChristianHits, ChristianRock, GospelMix, Melodia,
}

@external(erlang, "hackney_ssl_ffi", "send_with_ssl_options")
fn send_with_ssl_options(
  method: http.Method,
  url: String,
  headers: List(http.Header),
) -> Result(#(Int, List(http.Header), BitArray), Dynamic)

pub fn get_song(station: StationName) -> Result(Song, String) {
  case station {
    ChristianHits -> get_christian_hits()
    ChristianRock -> get_christian_rock()
    GospelMix -> get_gospel_mix()
    Melodia -> get_melodia()
  }
}

fn get_christian_hits() -> Result(Song, String) {
  get_christianrock_radio_song("https://www.christianrock.net/iphonechdn.php")
}

pub fn get_christian_rock() -> Result(Song, String) {
  get_christianrock_radio_song("https://www.christianrock.net/iphonecrdn.php")
}

fn get_christianrock_radio_song(radio: String) -> Result(Song, String) {
  use response <- result.try(
    send_with_ssl_options(http.Get, radio, [
      #("Host", "www.christianrock.net"),
      #("Connection", "close"),
    ])
    |> result.map_error(fn(err) {
      io.debug("Erro na requisição HTTP: " <> string.inspect(err))
      "Falha na conexão SSL"
    }),
  )

  let #(_, _, body_bit_array) = response

  use body <- result.try(
    body_bit_array
    |> bit_array.to_string
    |> result.map_error(fn(_) {
      "Falha ao converter corpo da resposta para string"
    }),
  )

  body
  |> song.christianrock_decoder
  |> map_decoder_error
}

fn get_gospel_mix() -> Result(Song, String) {
  let assert Ok(request) =
    request.to(
      "https://d36nr0u3xmc4mm.cloudfront.net/index.php/api/streaming/status/8192/2e1cbe43529055ddda74868d2db9ae98/SV4BR",
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

fn map_httpc_error(httpc_result: Result(a, Dynamic)) -> Result(a, String) {
  use error <- result.map_error(httpc_result)
  io.debug(error)

  "Não foi possível obter música"
}

fn map_decoder_error(decoded: Result(a, b)) -> Result(a, String) {
  use error <- result.map_error(decoded)
  io.debug(error)

  "Não foi possível decodificar música"
}
