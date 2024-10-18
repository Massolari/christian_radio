import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import icon
import lustre
import lustre/attribute.{class, src, style}
import lustre/effect
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, img, li, nav, section, span, ul}
import lustre/event
import lustre_http as http
import lustre_websocket
import player
import plinth/javascript/storage
import remote_data as rd
import shared/song.{type Song, Song}
import shared/station.{type Station}
import shared/websocket as shared_websocket

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
  )
}

type Tab {
  History
  Favorites
}

fn init(favorites: List(Song)) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      station: None,
      player: player.init(),
      tab: History,
      song: rd.NotAsked,
      websocket: None,
      history: [],
      favorites:,
    ),
    lustre_websocket.init("/ws", WebSocketEvent),
  )
}

// Update

type Msg {
  WebSocketEvent(lustre_websocket.WebSocketEvent)
  SelectedStation(station.StationName)
  ClickedTab(tab: Tab)
  PlayerMsg(player.Msg)
  ClickedFavorite(song: Song)
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    WebSocketEvent(lustre_websocket.OnOpen(ws)) -> #(
      Model(..model, websocket: Some(ws)),
      effect.none(),
    )

    WebSocketEvent(lustre_websocket.OnTextMessage(text)) ->
      case shared_websocket.decode(text) {
        Ok(websocket_msg) -> #(
          handle_websocket_message(model, websocket_msg),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }

    WebSocketEvent(lustre_websocket.OnBinaryMessage(_)) -> #(
      model,
      effect.none(),
    )
    WebSocketEvent(lustre_websocket.OnClose(_)) -> #(
      Model(..model, websocket: None),
      effect.none(),
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
  }
}

fn handle_websocket_message(
  model: Model,
  msg: shared_websocket.WebSocketMessage,
) -> Model {
  case msg {
    shared_websocket.Song(song) -> {
      let last_song =
        model.song
        |> rd.to_option
        |> option.map(fn(song) { [song] })
        |> option.unwrap([])

      Model(
        ..model,
        song: rd.Success(song),
        history: list.concat([last_song, model.history]),
      )
    }
    shared_websocket.History([]) -> model
    shared_websocket.History([song, ..history]) ->
      Model(..model, song: rd.Success(song), history: history)
  }
}

// View

fn view(model: Model) -> Element(Msg) {
  html.main([class("bg-main-brand flex flex-col h-screen")], [
    div([class("flex flex-col gap-8 pt-6 overflow-hidden flex-grow")], [
      view_stations(model.station),
      view_tabs(model),
    ]),
    player.view(
      player: model.player,
      current_song: model.song,
      station: model.station,
      favorites: model.favorites,
    )
      |> element.map(PlayerMsg),
  ])
}

fn view_stations(current_station: Option(station.StationName)) -> Element(Msg) {
  section([class("pl-3 flex flex-col gap-2")], [
    span([class("text-light-shades text-3xl")], [text("Estações")]),
    ul(
      [
        class("flex gap-3 overflow-scroll pr-3"),
        style([#("scrollbar-width", "none")]),
      ],
      list.map(station.list, view_station(current_station, _)),
    ),
  ])
}

fn view_station(
  current_station: Option(station.StationName),
  station: Station,
) -> Element(Msg) {
  let is_selected = current_station == Some(station.name)

  let selected_classes = case is_selected {
    True -> "opacity-60"
    False -> ""
  }

  let card_classes = class("w-36 h-36 rounded-lg " <> selected_classes)

  li([class("relative"), event.on_click(SelectedStation(station.name))], [
    case is_selected {
      True ->
        div(
          [
            class(
              "absolute top-0 left-0 w-full h-full text-light-shades flex items-center justify-center",
            ),
          ],
          [view_animated_equalizer()],
        )
      False -> text("")
    },
    case station.display {
      station.Label(value) ->
        div(
          [
            card_classes,
            class(
              "bg-light-shades text-xl flex items-center text-center justify-center",
            ),
          ],
          [text(value)],
        )
      station.Image(_ as image_src) ->
        div([card_classes], [img([class("rounded-lg"), src(image_src)])])
    },
  ])
}

fn view_animated_equalizer() -> Element(Msg) {
  div([class("equalizer")], [
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
  let song_icon = case list.find(favorites, fn(s) { s == song }) {
    Ok(_) -> icon.Favorite
    Error(_) -> icon.FavoriteBorder
  }

  view_song(
    title: song.title,
    artist: Some(song.artist),
    icon: SongIcon(icon: song_icon, on_click: ClickedFavorite(song)),
  )
}

fn view_message(icon: icon.Icon, message: String) -> Element(Msg) {
  div(
    [
      class(
        "w-full h-full flex flex-col text-center items-center justify-center gap-5",
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
  view_song(
    title: song.title,
    artist: Some(song.artist),
    icon: SongIcon(icon: icon.Favorite, on_click: ClickedFavorite(song)),
  )
}

type SongIcon {
  SongIcon(icon: icon.Icon, on_click: Msg)
}

fn view_song(
  title title: String,
  artist artist: Option(String),
  icon icon: SongIcon,
) -> Element(Msg) {
  let artist_element = case artist {
    Some(artist) -> [
      span([class("text-sm italic  text-light-accent")], [text(artist)]),
    ]
    None -> []
  }

  div([class("flex justify-between items-center w-full")], [
    div(
      [class("flex flex-col")],
      list.concat([[span([class("text-lg")], [text(title)])], artist_element]),
    ),
    icon.view(
      [class("cursor-pointer"), event.on_click(icon.on_click)],
      icon.icon,
    ),
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

// fn get_song(station: station.StationName) -> Effect(Msg) {
//   lustre_http.get(
//     location_origin() <> "/api/station/" <> station.endpoint(station),
//     lustre_http.expect_json(song.decode(), GotSong),
//   )
// }

// @external(javascript, "./ffi.mjs", "locationOrigin")
// fn location_origin() -> String

// Main

pub fn main() {
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

  let assert Ok(_) = lustre.start(app, "#app", favorites)
  Nil
}