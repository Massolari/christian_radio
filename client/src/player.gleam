import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import icon
import lustre/attribute.{attribute, class, disabled, src, style}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{audio, button, div, span}
import lustre/event
import lustre_http as http
import plinth/browser/document
import plinth/browser/element as browser_element
import plinth/browser/window
import remote_data as rd
import shared/song.{type Song, Song}
import shared/station

pub opaque type Model {
  Model(status: Status)
}

pub opaque type Status {
  Playing
  Paused
}

pub fn init() -> Model {
  Model(status: Paused)
}

pub opaque type Msg {
  Play
  Pause
  ClickedFavorite
}

pub type OutMsg {
  Favorite
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg), Option(OutMsg)) {
  case msg {
    Play -> play(model)
    Pause -> pause(model)
    ClickedFavorite -> #(model, effect.none(), Some(Favorite))
  }
}

@external(javascript, "./player_ffi.mjs", "play")
fn audio_play(audio: browser_element.Element) -> Effect(a)

@external(javascript, "./player_ffi.mjs", "pause")
fn audio_pause(audio: browser_element.Element) -> Effect(a)

@external(javascript, "./player_ffi.mjs", "reload")
fn audio_reload(audio: browser_element.Element) -> Effect(a)

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

pub fn play(_model: Model) -> #(Model, Effect(Msg), Option(OutMsg)) {
  #(Model(status: Playing), play_pause(True), None)
}

pub fn pause(_model: Model) -> #(Model, Effect(Msg), Option(OutMsg)) {
  #(Model(status: Paused), play_pause(False), None)
}

pub fn view(
  player model: Model,
  current_song song: rd.RemoteData(Song, http.HttpError),
  station station: Option(station.StationName),
  favorites favorites: List(Song),
) -> Element(Msg) {
  let stream =
    station
    |> option.map(station.stream_url)
    |> option.unwrap("")

  div([class("w-full mb-2 px-1 h-20")], [
    audio([class("hidden"), attribute("preload", "none"), src(stream)], []),
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
    ),
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
    ),
  ])
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
    _ -> text("")
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
      [class("flex items-center gap-2"), event.on_click(click_msg)],
    ]),
    [icon.view([class("text-4xl")], button_icon)],
  )
}
