import gleam/option.{type Option, None, Some}

pub const list = [
  Station(
    name: GospelMix,
    display: Image(src: "/assets/station-gospel-mix.jpg"),
  ),
  Station(
    name: ChristianHits,
    display: Image(src: "/assets/station-christian-hits.jpg"),
  ),
  Station(
    name: ChristianRock,
    display: Image(src: "/assets/station-christian-rock.jpg"),
  ),
  Station(name: Melodia, display: Image(src: "/assets/station-melodia.png")),
  Station(name: Radio93, display: Image(src: "/assets/station-radio-93.png")),
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
  Radio93
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
    Melodia ->
      "https://playerservices.streamtheworld.com/api/livestream-redirect/MELODIAFMAAC_SC"
    Radio93 ->
      "https://playerservices.streamtheworld.com/api/livestream-redirect/FM93AAC_SC"
  }
}

pub fn endpoint(name: StationName) -> Option(String) {
  case name {
    ChristianHits -> Some(christian_hits_endpoint)
    ChristianRock -> Some(christian_rock_endpoint)
    GospelMix -> Some(gospel_mix_endpoint)
    Melodia -> Some(melodia_endpoint)
    Radio93 -> None
  }
}

pub fn to_string(name: StationName) -> String {
  case name {
    ChristianHits -> "ChristianHits"
    ChristianRock -> "ChristianRock"
    GospelMix -> "GospelMix"
    Melodia -> "Melodia"
    Radio93 -> "Radio93"
  }
}

pub fn from_string(name: String) -> Result(StationName, Nil) {
  case name {
    "ChristianHits" -> Ok(ChristianHits)
    "ChristianRock" -> Ok(ChristianRock)
    "GospelMix" -> Ok(GospelMix)
    "Melodia" -> Ok(Melodia)
    "Radio93" -> Ok(Radio93)
    _ -> Error(Nil)
  }
}
