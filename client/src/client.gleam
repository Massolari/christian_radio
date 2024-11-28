import gleam/dynamic
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import icon
import lustre
import lustre/attribute.{class, src, style}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, img, li, nav, section, span, ul}
import lustre/event
import lustre_http as http
import lustre_websocket
import player
import plinth/browser/window
import plinth/javascript/global
import plinth/javascript/storage
import remote_data as rd
import shared/song.{type Song, Song}
import shared/station.{type Station}
import shared/websocket as shared_websocket
import util

// Model

type Model {
  Model(
    websocket: Option(lustre_websocket.WebSocket),
    station: Option(station.StationName),
    player: player.Model,
    tab: Tab,
    song: rd.RemoteData(Song, http.HttpError),
    history: List(Song),
    favorites: List(Song),
    is_mobile: Bool,
    is_online: Bool,
  )
}

type Tab {
  History
  Favorites
}

type Init {
  Init(favorites: List(Song), is_mobile: Bool)
}

fn init(init: Init) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      station: None,
      player: player.init(),
      tab: History,
      song: rd.NotAsked,
      websocket: None,
      history: [],
      favorites: init.favorites,
      is_mobile: init.is_mobile,
      is_online: True,
    ),
    effect.batch([
      lustre_websocket.init("/ws", WebSocketEvent),
      watch_resize(),
      watch_online_status(),
    ]),
  )
}

// Update

type Msg {
  WindowResized(Bool)
  WebSocketEvent(lustre_websocket.WebSocketEvent)
  SelectedStation(station.StationName)
  ClickedTab(tab: Tab)
  PlayerMsg(player.Msg)
  ClickedFavorite(song: Song)
  ReconnectWebSocket
  OnlineStatusChanged(Bool)
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    WindowResized(is_mobile) -> {
      io.debug(is_mobile)
      #(Model(..model, is_mobile:), effect.none())
    }

    WebSocketEvent(lustre_websocket.OnOpen(ws)) -> {
      let effect = case model.station {
        Some(station) -> lustre_websocket.send(ws, station.to_string(station))
        None -> effect.none()
      }
      #(Model(..model, websocket: Some(ws)), effect)
    }

    WebSocketEvent(lustre_websocket.OnTextMessage(text)) ->
      case shared_websocket.decode(text) {
        Ok(websocket_msg) -> handle_websocket_message(model, websocket_msg)

        Error(_) -> #(model, effect.none())
      }

    WebSocketEvent(lustre_websocket.OnBinaryMessage(_)) -> #(
      model,
      effect.none(),
    )
    WebSocketEvent(lustre_websocket.OnClose(_)) -> #(
      Model(..model, websocket: None),
      effect.from(fn(dispatch) {
        // Tenta reconectar após 3 segundos
        global.set_timeout(3000, fn() { dispatch(ReconnectWebSocket) })
        Nil
      }),
    )
    WebSocketEvent(lustre_websocket.InvalidUrl) -> #(model, effect.none())

    SelectedStation(station) -> {
      let #(player, player_effect, _) = player.play(model.player)

      case model.websocket {
        Some(ws) -> #(
          Model(..model, player:, station: Some(station), song: rd.Loading),
          effect.batch([
            lustre_websocket.send(ws, station.to_string(station)),
            player_effect |> effect.map(PlayerMsg),
          ]),
        )
        None -> #(model, effect.none())
      }
    }

    ClickedTab(tab) -> #(Model(..model, tab: tab), effect.none())

    PlayerMsg(player_msg) -> {
      let #(player, player_effect, out_msg) =
        player.update(model.player, player_msg)

      let new_favorites = case out_msg {
        Some(player.Favorite) ->
          model.song
          |> rd.to_option
          |> option.map(toggle_favorite(_, model.favorites))
          |> option.unwrap(model.favorites)

        None -> model.favorites
      }

      #(
        Model(..model, player: player, favorites: new_favorites),
        player_effect |> effect.map(PlayerMsg),
      )
    }

    ClickedFavorite(song) -> {
      let favorites = toggle_favorite(song, model.favorites)

      #(Model(..model, favorites: favorites), effect.none())
    }

    ReconnectWebSocket -> {
      let new_effect = case model.websocket {
        None -> lustre_websocket.init("/ws", WebSocketEvent)
        Some(_) -> effect.none()
      }
      #(model, new_effect)
    }

    OnlineStatusChanged(is_online) -> {
      #(Model(..model, is_online: is_online), effect.none())
    }
  }
}

fn handle_websocket_message(
  model: Model,
  msg: shared_websocket.WebSocketMessage,
) -> #(Model, effect.Effect(Msg)) {
  case msg {
    shared_websocket.Song(song) -> {
      let last_song =
        model.song
        |> rd.to_option
        |> option.map(fn(song) { [song] })
        |> option.unwrap([])

      let _ = set_title(song)

      #(
        Model(
          ..model,
          song: rd.Success(song),
          history: list.concat([last_song, model.history]),
        ),
        effect.none(),
      )
    }
    shared_websocket.History([]) -> #(model, effect.none())
    shared_websocket.History([song, ..history]) -> {
      let _ = set_title(song)

      #(Model(..model, song: rd.Success(song), history: history), effect.none())
    }
  }
}

// View

fn view(model: Model) -> Element(Msg) {
  html.main([class("bg-main-brand flex flex-col flex-grow h-[100dvh]")], [
    case model.is_mobile {
      True -> view_mobile(model)
      False -> view_desktop(model)
    },
    player.view(
      player: model.player,
      current_song: model.song,
      station: model.station,
      favorites: model.favorites,
      is_mobile: model.is_mobile,
      is_online: model.is_online,
    )
      |> element.map(PlayerMsg),
  ])
}

fn view_mobile(model: Model) -> Element(Msg) {
  div([class("flex flex-col gap-8 pt-6 overflow-hidden flex-grow")], [
    view_stations(
      model.station,
      model.is_online,
      player.is_playing(model.player),
    ),
    view_tabs(model),
  ])
}

fn view_desktop(model: Model) -> Element(Msg) {
  div(
    [
      class(
        "grid grid-cols-[1fr_2fr_1fr] gap-5 pt-3 pb-2 px-2 overflow-y-auto flex-grow",
      ),
    ],
    [
      view_desktop_history(model.history, model.favorites),
      view_stations(
        model.station,
        model.is_online,
        player.is_playing(model.player),
      ),
      view_desktop_favorites(model.favorites),
    ],
  )
}

fn view_desktop_section(title: String, content: Element(Msg)) -> Element(Msg) {
  div(
    [
      class(
        "flex flex-col bg-dark-accent rounded-lg text-light-shades overflow-y-auto",
      ),
    ],
    [span([class("text-xl text-center p-2")], [text(title)]), content],
  )
}

fn view_desktop_history(
  songs: List(Song),
  favorites: List(Song),
) -> Element(Msg) {
  view_desktop_section("Histórico", view_history(songs, favorites))
}

fn view_desktop_favorites(favorites: List(Song)) -> Element(Msg) {
  view_desktop_section("Favoritas", view_favorites(favorites))
}

fn view_stations(
  current_station: Option(station.StationName),
  is_online: Bool,
  is_playing: Bool,
) -> Element(Msg) {
  section([class("pl-3 flex flex-col gap-2 md:gap-3")], [
    span([class("text-light-shades text-3xl md:text-center")], [
      text("Estações"),
    ]),
    ul(
      [
        class("flex gap-3 overflow-scroll md:flex-wrap pr-3"),
        style([#("scrollbar-width", "none")]),
      ],
      list.map(station.list, view_station(
        current_station,
        _,
        is_online,
        is_playing,
      )),
    ),
  ])
}

fn view_station(
  current_station: Option(station.StationName),
  station: Station,
  is_online: Bool,
  is_playing: Bool,
) -> Element(Msg) {
  let is_selected = current_station == Some(station.name)

  let selected_classes = case is_selected {
    True -> "opacity-70 scale-95"
    False -> ""
  }

  let offline_classes = case is_online {
    True -> ""
    False -> "opacity-50 cursor-not-allowed"
  }

  li(
    [
      class(
        "active:scale-90 active:duration-100 hover:opacity-80 hover:duration-200 transition-all cursor-pointer",
      ),
      class("relative group"),
      class(selected_classes),
      class(offline_classes),
      case is_online {
        True -> event.on_click(SelectedStation(station.name))
        False -> attribute.none()
      },
    ],
    [
      case is_selected {
        False ->
          div(
            [
              class(
                "absolute top-0 left-0 w-full h-full text-light-shades flex items-center justify-center opacity-0 group-hover:opacity-70 transition-opacity",
              ),
            ],
            [icon.view([class("text-6xl")], icon.PlayArrow)],
          )
        True ->
          div(
            [
              class(
                "absolute top-0 left-0 w-full h-full text-light-shades flex items-center justify-center",
              ),
            ],
            [view_animated_equalizer(is_playing:)],
          )
      },
      div(
        [
          class(
            "bg-light-shades text-xl flex items-center text-center justify-center w-36 h-36 md:w-48 md:h-48 rounded-lg",
          ),
        ],
        case station.display {
          station.Label(value) -> [text(value)]
          station.Image(_ as image_src) -> [
            img([class("rounded-lg"), src(image_src)]),
          ]
        },
      ),
    ],
  )
}

fn view_animated_equalizer(is_playing is_playing: Bool) -> Element(Msg) {
  let equalizer_classes = case is_playing {
    True -> "equalizer"
    False -> "equalizer paused"
  }

  div([class(equalizer_classes)], [
    div([class("equalizer-bar")], []),
    div([class("equalizer-bar")], []),
    div([class("equalizer-bar")], []),
    div([class("equalizer-bar")], []),
  ])
}

fn view_tabs(model: Model) -> Element(Msg) {
  section([class("flex flex-col gap-3 h-full overflow-hidden")], [
    nav([class("flex gap-2 pl-3")], [
      view_tab(History, current: model.tab),
      view_tab(Favorites, current: model.tab),
    ]),
    div(
      [
        class(
          "bg-dark-accent rounded-tl-[40px] text-light-accent rounded-tr-[40px] flex-1 overflow-hidden",
        ),
      ],
      [
        case model.tab {
          History -> view_history(model.history, model.favorites)
          Favorites -> view_favorites(model.favorites)
        },
      ],
    ),
  ])
}

fn view_history(songs: List(Song), favorites: List(Song)) -> Element(Msg) {
  case songs {
    [] -> view_message(icon.MusicOff, "Nenhuma música tocada anteriormente")
    songs ->
      songs
      |> list.map(view_history_song(_, favorites))
      |> view_song_list_container
  }
}

fn view_song_list_container(content: List(Element(Msg))) -> Element(Msg) {
  ul(
    [
      class(
        "relative text-light-shades px-6 py-5 flex flex-col gap-3 overflow-y-auto h-full",
      ),
    ],
    list.map(content, view_song_list_item),
  )
}

fn view_song_list_item(content: Element(Msg)) -> Element(Msg) {
  li([], [content])
}

fn view_history_song(song: Song, favorites: List(Song)) -> Element(Msg) {
  let is_favorite = case list.find(favorites, fn(s) { s == song }) {
    Ok(_) -> True
    Error(_) -> False
  }

  view_song(song:, icon: None, is_favorite: Some(is_favorite))
}

fn view_message(icon: icon.Icon, message: String) -> Element(Msg) {
  div(
    [
      class(
        "w-full h-full flex flex-col text-center items-center justify-center gap-5 cursor-default",
      ),
    ],
    [icon.view([class("text-5xl")], icon), span([], [text(message)])],
  )
}

fn view_favorites(songs: List(Song)) -> Element(Msg) {
  case songs {
    [] -> view_message(icon.HeartBroken, "Nenhuma música favoritada ainda")
    songs -> view_song_list_container(list.map(songs, view_favorite_song))
  }
}

fn view_favorite_song(song: Song) -> Element(Msg) {
  view_song(song:, icon: None, is_favorite: Some(True))
}

type SongIcon {
  SongIcon(icon: icon.Icon, on_click: Msg)
}

fn view_song(
  song song: Song,
  icon icon: Option(SongIcon),
  is_favorite favorite: Option(Bool),
) -> Element(Msg) {
  div([class("flex justify-between items-center w-full")], [
    div([class("flex flex-col")], [
      span([class("text-lg")], [text(song.title)]),
      span([class("text-sm italic  text-light-accent")], [text(song.artist)]),
    ]),
    case icon {
      Some(SongIcon(icon, on_click)) ->
        icon.view([class("cursor-pointer"), event.on_click(on_click)], icon)
      None -> element.none()
    },
    case favorite {
      Some(is_favorite) ->
        button(
          [
            class("group"),
            util.hover_classes(),
            event.on_click(ClickedFavorite(song)),
          ],
          [
            icon.favorite(is_favorite, [
              class("text-3xl"),
              util.group_active_classes(),
            ]),
          ],
        )
      None -> element.none()
    },
  ])
}

fn view_tab(tab: Tab, current current: Tab) {
  let label = case tab {
    History -> "Histórico"
    Favorites -> "Favoritas"
  }

  button(
    [
      class("px-5 py-2 rounded-full"),
      get_tab_classes(for: tab, with: current),
      event.on_click(ClickedTab(tab)),
    ],
    [text(label)],
  )
}

// Helpers

fn get_tab_classes(
  for check: Tab,
  with current: Tab,
) -> attribute.Attribute(Msg) {
  case check == current {
    True -> class("text-dark-shades bg-light-shades")
    False -> class("text-light-shades bg-none")
  }
}

fn toggle_favorite(song: Song, favorites: List(Song)) -> List(Song) {
  let new_favorites = case list.find(favorites, fn(s) { s == song }) {
    Ok(_) -> list.filter(favorites, fn(s) { s != song })
    Error(_) -> list.append(favorites, [song])
  }

  let _ =
    storage.local()
    |> result.map(storage.set_item(
      _,
      "favorites",
      new_favorites |> json.array(of: song.encode) |> json.to_string,
    ))

  new_favorites
}

fn watch_resize() -> Effect(Msg) {
  use dispatch <- effect.from
  // When the window is resized, we need to update the layout
  window.add_event_listener("resize", fn(_) {
    window.self()
    |> window.inner_width
    |> is_mobile
    |> WindowResized
    |> dispatch
    Nil
  })
}

fn is_mobile(size: Int) -> Bool {
  size < 768
}

fn set_title(song: Song) {
  do_set_title(song.title <> " - " <> song.artist <> " | Christian Radio")
}

@external(javascript, "./ffi.mjs", "setTitle")
fn do_set_title(title: String) -> Nil

fn watch_online_status() -> Effect(Msg) {
  use dispatch <- effect.from

  window.add_event_listener("online", fn(_) {
    dispatch(OnlineStatusChanged(True))
    Nil
  })

  window.add_event_listener("offline", fn(_) {
    dispatch(OnlineStatusChanged(False))
    Nil
  })
}

// Main

pub fn main() {
  let this_window = window.self()
  let this_is_mobile =
    this_window
    |> window.inner_width
    |> is_mobile

  let local_storage = storage.local()
  let favorites =
    local_storage
    |> result.try(storage.get_item(_, "favorites"))
    |> result.try(fn(value) {
      value
      |> json.decode(dynamic.list(song.decode()))
      |> result.nil_error
    })
    |> result.unwrap([])

  let app = lustre.application(init, update, view)

  let assert Ok(_) =
    lustre.start(app, "#app", Init(favorites:, is_mobile: this_is_mobile))

  Nil
}
