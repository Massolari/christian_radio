import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import icon
import lustre/attribute.{
  attribute, class, disabled, max, min, src, step, style, type_, value,
}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{audio, button, div, input, span}
import lustre/event
import lustre_http as http
import plinth/browser/document
import plinth/browser/element as browser_element
import plinth/browser/window
import remote_data as rd
import shared/song.{type Song, Song}
import shared/station

pub opaque type Model {
  Model(status: Status, volume: Float)
}

pub opaque type Status {
  Playing
  Paused
}

pub fn init() -> Model {
  Model(status: Paused, volume: 1.0)
}

pub opaque type Msg {
  Play
  Pause
  ClickedFavorite
  VolumeChanged(String)
}

pub type OutMsg {
  Favorite
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg), Option(OutMsg)) {
  case msg {
    Play -> play(model)
    Pause -> pause(model)
    ClickedFavorite -> #(model, effect.none(), Some(Favorite))
    VolumeChanged(volume) -> {
      let audio = document.query_selector("audio")
      case audio {
        Ok(audio) -> {
          let new_volume =
            volume
            |> float.parse
            |> result.try_recover(fn(_) {
              volume
              |> int.parse
              |> result.map(int.to_float)
            })
            |> result.unwrap(model.volume)

          #(
            Model(..model, volume: new_volume),
            effect.from(fn(_) { audio_set_volume(audio, new_volume) }),
            None,
          )
        }
        Error(_) -> #(model, effect.none(), None)
      }
    }
  }
}

@external(javascript, "./player_ffi.mjs", "play")
fn audio_play(audio: browser_element.Element) -> Nil

@external(javascript, "./player_ffi.mjs", "pause")
fn audio_pause(audio: browser_element.Element) -> Nil

@external(javascript, "./player_ffi.mjs", "reload")
fn audio_reload(audio: browser_element.Element) -> Nil

@external(javascript, "./player_ffi.mjs", "set_volume")
fn audio_set_volume(audio: browser_element.Element, volume: Float) -> Nil

fn play_pause(play: Bool) -> Effect(a) {
  use _ <- effect.from

  window.request_animation_frame(fn(_) {
    let _ =
      document.query_selector("audio")
      |> result.map(fn(element) {
        case play {
          True -> {
            audio_reload(element)
            audio_play(element)
          }
          False -> audio_pause(element)
        }
      })

    Nil
  })

  Nil
}

pub fn play(model: Model) -> #(Model, Effect(Msg), Option(OutMsg)) {
  #(Model(..model, status: Playing), play_pause(True), None)
}

pub fn pause(model: Model) -> #(Model, Effect(Msg), Option(OutMsg)) {
  #(Model(..model, status: Paused), play_pause(False), None)
}

pub fn view(
  player model: Model,
  current_song song: rd.RemoteData(Song, http.HttpError),
  station station: Option(station.StationName),
  favorites favorites: List(Song),
  is_mobile is_mobile: Bool,
) -> Element(Msg) {
  let stream =
    station
    |> option.map(station.stream_url)
    |> option.unwrap("")

  div([class("w-full mb-2 md:mb-5 px-1 h-20")], [
    audio([class("hidden"), attribute("preload", "none"), src(stream)], []),
    case is_mobile {
      True ->
        div(
          [
            class("absolute bottom-0 left-0 right-0 h-32 pointer-events-none"),
            style([
              #(
                "background",
                "linear-gradient(to bottom, rgba(0,0,0,0) 0%, rgba(0,0,0,1) 100%)",
              ),
            ]),
          ],
          [],
        )
      False -> element.none()
    },
    case is_mobile {
      True -> view_mobile(model, song, favorites)
      False -> view_desktop(model, song, favorites)
    },
  ])
}

fn view_mobile(
  model: Model,
  song: rd.RemoteData(Song, http.HttpError),
  favorites: List(Song),
) -> Element(Msg) {
  div(
    [
      class(
        "relative w-full h-full bg-light-shades rounded-lg flex justify-between px-5 py-3 items-center",
      ),
    ],
    [
      case song {
        rd.NotAsked -> div([], [text("Nenhuma estação selecionada")])
        rd.Loading -> div([], [text("Carregando...")])
        rd.Success(song) -> view_song(song)
        rd.Failure(error) ->
          view_song(Song(
            title: "Erro ao carregar música",
            artist: string.inspect(error),
          ))
      },
      div([class("flex")], [
        view_favorite_button(song, favorites),
        view_play_button(model, song),
      ]),
    ],
  )
}

fn view_desktop(
  model: Model,
  song: rd.RemoteData(Song, http.HttpError),
  favorites: List(Song),
) -> Element(Msg) {
  div(
    [
      class(
        "relative w-full h-full bg-light-shades rounded-lg grid grid-cols-[1fr_1fr_1fr] px-5 py-3 items-center",
      ),
    ],
    [
      div([class("flex gap-5")], [
        case song {
          rd.NotAsked -> div([], [text("Nenhuma estação selecionada")])
          rd.Loading -> div([], [text("Carregando...")])
          rd.Success(song) -> view_song(song)
          rd.Failure(error) ->
            view_song(Song(
              title: "Erro ao carregar música",
              artist: string.inspect(error),
            ))
        },
        view_favorite_button(song, favorites),
      ]),
      view_play_button(model, song),
      view_volume(model),
    ],
  )
}

fn view_song(song: Song) -> Element(a) {
  div([class("flex flex-col gap-1")], [
    span([class("text-dark-shades text-lg font-medium")], [text(song.title)]),
    span([class("text-dark-accent text-sm italic")], [text(song.artist)]),
  ])
}

fn view_favorite_button(
  song: rd.RemoteData(Song, http.HttpError),
  favorites: List(Song),
) -> Element(Msg) {
  case song {
    rd.Success(song) ->
      button([], [
        icon.view([class("text-3xl"), event.on_click(ClickedFavorite)], case
          list.contains(favorites, song)
        {
          True -> icon.Favorite
          False -> icon.FavoriteBorder
        }),
      ])
    _ -> element.none()
  }
}

fn view_play_button(
  model: Model,
  song: rd.RemoteData(Song, http.HttpError),
) -> Element(Msg) {
  let #(click_msg, button_icon) = case model.status {
    Playing -> #(Pause, icon.Pause)
    Paused -> #(Play, icon.PlayArrow)
  }

  button(
    list.concat([
      song
        |> rd.map(fn(_) { [] })
        |> rd.unwrap([class("opacity-50"), disabled(True)]),
      [
        class("flex md:justify-center items-center gap-2"),
        event.on_click(click_msg),
      ],
    ]),
    [icon.view([class("text-4xl")], button_icon)],
  )
}

fn view_volume(model: Model) -> Element(Msg) {
  let mute_volume = case model.volume >. 0.0 {
    True -> "0.0"
    False -> "1.0"
  }

  let volume_icon = case model.volume >. 0.0 {
    True -> icon.VolumeUp
    False -> icon.VolumeOff
  }

  div([class("flex items-center gap-3")], [
    icon.view(
      [
        class("text-4xl cursor-pointer"),
        event.on_click(VolumeChanged(mute_volume)),
      ],
      volume_icon,
    ),
    input([
      type_("range"),
      min("0"),
      max("1"),
      step("any"),
      value(float.to_string(model.volume)),
      event.on_input(VolumeChanged),
      class("w-full accent-black h-1"),
    ]),
  ])
}
