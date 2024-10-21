import gleam/list
import gleam/pair
import gleam/result

pub const list = [
  Station(
    name: GospelMix,
    display: Image(src: "/assets/station-gospel-mix.jpg"),
  ), Station(name: ChristianHits, display: Label("Christian Hits .Net")),
  Station(name: ChristianRock, display: Label("Christian Rock .Net")),
  Station(name: Melodia, display: Label("Radio Melodia")),
]

const christian_hits_endpoint = "christianhits"

const christian_rock_endpoint = "christianrock"

const gospel_mix_endpoint = "gospelmix"

const melodia_endpoint = "melodia"

pub type Station {
  Station(name: StationName, display: StationDisplay)
}

pub type StationName {
  ChristianHits
  ChristianRock
  GospelMix
  Melodia
}

pub type StationDisplay {
  Label(String)
  Image(src: String)
}

pub fn stream_url(name: StationName) -> String {
  case name {
    ChristianHits -> "https://listen.christianrock.net/stream/12/"
    ChristianRock -> "https://listen.christianrock.net/stream/11/"
    GospelMix -> "https://servidor33-3.brlogic.com:8192/live"
    Melodia -> "https://14543.live.streamtheworld.com/MELODIAFMAAC.aac"
  }
}

pub fn endpoint(name: StationName) -> String {
  case name {
    ChristianHits -> christian_hits_endpoint
    ChristianRock -> christian_rock_endpoint
    GospelMix -> gospel_mix_endpoint
    Melodia -> melodia_endpoint
  }
}

pub fn to_string(name: StationName) -> String {
  case name {
    ChristianHits -> "ChristianHits"
    ChristianRock -> "ChristianRock"
    GospelMix -> "GospelMix"
    Melodia -> "Melodia"
  }
}

pub fn from_string(name: String) -> Result(StationName, Nil) {
  case name {
    "ChristianHits" -> Ok(ChristianHits)
    "ChristianRock" -> Ok(ChristianRock)
    "GospelMix" -> Ok(GospelMix)
    "Melodia" -> Ok(Melodia)
    _ -> Error(Nil)
  }
}

pub fn from_endpoint(endpoint: String) -> Result(StationName, Nil) {
  [
    #(christian_hits_endpoint, ChristianHits),
    #(christian_rock_endpoint, ChristianRock),
    #(gospel_mix_endpoint, GospelMix),
    #(melodia_endpoint, Melodia),
  ]
  |> list.find(fn(endpoint_name) { endpoint_name.0 == endpoint })
  |> result.map(pair.second)
}
