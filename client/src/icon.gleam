import gleam/list
import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, span}
import util

pub type Icon {
  DataSaverOff
  ErrorIcon
  Favorite
  FavoriteBorder
  GraphicEq
  HeartBroken
  MusicOff
  Pause
  PlayArrow
  VolumeOff
  VolumeUp
  SyncProblem
}

pub fn view(
  attributes attributes: List(attribute.Attribute(msg)),
  icon icon: Icon,
) {
  let icon_str = to_string(icon)

  span([class("material-icons"), ..attributes], [text(icon_str)])
}

fn to_string(icon: Icon) -> String {
  case icon {
    DataSaverOff -> "data_saver_off"
    ErrorIcon -> "error"
    Favorite -> "favorite"
    FavoriteBorder -> "favorite_border"
    GraphicEq -> "graphic_eq"
    HeartBroken -> "heart_broken"
    MusicOff -> "music_off"
    Pause -> "pause"
    PlayArrow -> "play_arrow"
    VolumeOff -> "volume_off"
    VolumeUp -> "volume_up"
    SyncProblem -> "sync_problem"
  }
}

pub fn favorite(
  is_favorite: Bool,
  attributes: List(attribute.Attribute(msg)),
) -> Element(msg) {
  case is_favorite {
    True -> view(attributes: attributes, icon: Favorite)
    False -> view(attributes: attributes, icon: FavoriteBorder)
  }
}
