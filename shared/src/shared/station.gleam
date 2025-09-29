import gleam/option.{type Option, None, Some}

pub const list = [
  Station(
    name: GospelHits,
    display: Image(src: "/assets/station-gospel-hits.jpg"),
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
  Station(
    name: GospelAdoracao,
    display: Image(src: "/assets/station-gospel-adoracao.png"),
  ),
]

const christian_hits_endpoint = "christianhits"

const christian_rock_endpoint = "christianrock"

const melodia_endpoint = "melodia"

const gospel_adoracao_endpoint = "gospeladoracao"

pub type Station {
  Station(name: StationName, display: StationDisplay)
}

pub type StationName {
  ChristianHits
  ChristianRock
  GospelHits
  Melodia
  Radio93
  GospelAdoracao
}

pub type StationDisplay {
  Label(String)
  Image(src: String)
}

pub fn stream_url(name: StationName) -> String {
  case name {
    ChristianHits -> "https://listen.christianrock.net/stream/12/"
    ChristianRock -> "https://listen.christianrock.net/stream/11/"
    GospelHits -> "http://servidor37-2.brlogic.com:7068/live"
    Melodia ->
      "https://playerservices.streamtheworld.com/api/livestream-redirect/MELODIAFMAAC_SC"
    Radio93 ->
      "https://playerservices.streamtheworld.com/api/livestream-redirect/FM93AAC_SC"
    GospelAdoracao -> "https://stm12.voxhd.com.br:9752/stream"
  }
}

pub fn endpoint(name: StationName) -> Option(String) {
  case name {
    ChristianHits -> Some(christian_hits_endpoint)
    ChristianRock -> Some(christian_rock_endpoint)
    GospelHits -> None
    Melodia -> Some(melodia_endpoint)
    Radio93 -> None
    GospelAdoracao -> Some(gospel_adoracao_endpoint)
  }
}

pub fn to_string(name: StationName) -> String {
  case name {
    ChristianHits -> "ChristianHits"
    ChristianRock -> "ChristianRock"
    GospelHits -> "GospelHits"
    Melodia -> "Melodia"
    Radio93 -> "Radio93"
    GospelAdoracao -> "GospelAdoracao"
  }
}

pub fn from_string(name: String) -> Result(StationName, Nil) {
  case name {
    "ChristianHits" -> Ok(ChristianHits)
    "ChristianRock" -> Ok(ChristianRock)
    "GospelHits" -> Ok(GospelHits)
    "Melodia" -> Ok(Melodia)
    "Radio93" -> Ok(Radio93)
    "GospelAdoracao" -> Ok(GospelAdoracao)
    _ -> Error(Nil)
  }
}
