import connection_status.{type ConnectionStatus}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import icon
import lustre/attribute.{attribute, class, max, min, src, step, type_, value}
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
import util

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
  ClickedPlay
  ClickedPause
  WasPlayed
  WasPaused
  ClickedFavorite
  VolumeChanged(String)
}

pub type OutMsg {
  Favorite
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg), Option(OutMsg)) {
  case msg {
    ClickedPlay -> play(model)
    ClickedPause -> pause(model)
    WasPlayed -> #(Model(..model, status: Playing), effect.none(), None)
    WasPaused -> #(Model(..model, status: Paused), effect.none(), None)
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

pub fn is_playing(model: Model) -> Bool {
  model.status == Playing
}

pub fn view(
  player model: Model,
  current_song song: rd.RemoteData(Song, http.HttpError),
  station station: Option(station.StationName),
  favorites favorites: List(Song),
  is_mobile is_mobile: Bool,
  connection_status connection_status: ConnectionStatus,
) -> Element(Msg) {
  let stream =
    station
    |> option.map(station.stream_url)
    |> option.unwrap("")

  div(
    [
      class(
        "bg-dark-accent dark:bg-dark-dark-accent md:bg-inherit w-full pb-2 md:mb-2 px-1 md:px-2 h-20",
      ),
    ],
    [
      audio(
        [
          class("hidden"),
          event.on("play", fn(_) { Ok(WasPlayed) }),
          event.on("pause", fn(_) { Ok(WasPaused) }),
          attribute("preload", "none"),
          src(stream),
        ],
        [],
      ),
      case connection_status {
        connection_status.Offline -> view_offline()
        status -> {
          let #(song, show_favorite_button) = case status {
            connection_status.ServerOffline -> #(
              rd.Success(Song(
                title: "Por favor, aguarde",
                artist: "Conectando ao servidor...",
              )),
              False,
            )
            _ -> #(song, True)
          }

          case is_mobile {
            True -> view_mobile(model, song, favorites, show_favorite_button)
            False -> view_desktop(model, song, favorites, show_favorite_button)
          }
        }
      },
    ],
  )
}

fn view_mobile(
  model: Model,
  song: rd.RemoteData(Song, http.HttpError),
  favorites: List(Song),
  show_favorite_button: Bool,
) -> Element(Msg) {
  div(
    [
      class(
        "relative shadow-outer w-full h-full bg-light-shades rounded-lg flex justify-between px-5 py-3 items-center",
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
        case show_favorite_button {
          True -> view_favorite_button(song, favorites)
          False -> element.none()
        },
        view_play_button(model),
      ]),
    ],
  )
}

fn view_desktop(
  model: Model,
  song: rd.RemoteData(Song, http.HttpError),
  favorites: List(Song),
  show_favorite_button: Bool,
) -> Element(Msg) {
  div(
    [
      class(
        "relative shadow-outer w-full h-full bg-light-shades rounded-lg grid grid-cols-[1fr_1fr_1fr] px-5 py-3 items-center",
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
        case show_favorite_button {
          True -> view_favorite_button(song, favorites)
          False -> element.none()
        },
      ]),
      view_play_button(model),
      view_volume(model),
    ],
  )
}

fn view_song(song: Song) -> Element(a) {
  div([class("flex flex-col gap-1")], [
    span([class("text-dark-dark-shades text-lg font-medium")], [
      text(song.title),
    ]),
    span([class("text-dark-dark-accent text-sm italic")], [text(song.artist)]),
  ])
}

fn view_favorite_button(
  song: rd.RemoteData(Song, http.HttpError),
  favorites: List(Song),
) -> Element(Msg) {
  case song {
    rd.Success(song) ->
      button(
        [class("group"), util.hover_classes(), event.on_click(ClickedFavorite)],
        [
          icon.favorite(list.contains(favorites, song), [
            class("text-3xl!"),
            util.group_active_classes(),
          ]),
        ],
      )
    _ -> element.none()
  }
}

fn view_play_button(model: Model) -> Element(Msg) {
  let #(click_msg, button_icon) = case model.status {
    Playing -> #(ClickedPause, icon.Pause)
    Paused -> #(ClickedPlay, icon.PlayArrow)
  }

  div([class("w-full")], [
    button(
      [
        class("group flex mx-auto md:justify-center items-center w-fit gap-2"),
        event.on_click(click_msg),
        util.hover_classes(),
      ],
      [
        icon.view(
          [class("text-4xl!"), util.group_active_classes()],
          button_icon,
        ),
      ],
    ),
  ])
}

fn view_volume(model: Model) -> Element(Msg) {
  let #(mute_volume, volume_icon) = case model.volume >. 0.0 {
    True -> #("0.0", icon.VolumeUp)
    False -> #("1.0", icon.VolumeOff)
  }

  div([class("flex items-center gap-3")], [
    button(
      [
        class("group"),
        util.hover_classes(),
        event.on_click(VolumeChanged(mute_volume)),
      ],
      [
        icon.view(
          [class("text-4xl! cursor-pointer"), util.group_active_classes()],
          volume_icon,
        ),
      ],
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

fn view_offline() -> Element(Msg) {
  view_not_connected(
    "Você está offline",
    "Verifique sua conexão com a internet",
  )
}

fn view_not_connected(title: String, message: String) -> Element(Msg) {
  div(
    [
      class(
        "relative shadow-outer w-full h-full bg-light-shades rounded-lg grid grid-cols-1 px-5 py-3 items-center",
      ),
    ],
    [
      div([class("flex flex-col gap-1 w-full text-center")], [
        span([class("text-lg font-medium")], [text(title)]),
        span([class("text-dark-dark-accent text-sm italic")], [text(message)]),
      ]),
    ],
  )
}
