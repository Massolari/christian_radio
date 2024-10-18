export const play = audio => audio.play()

export const pause = audio => audio.pause()

export const is_paused = audio => audio.paused

export const reload = audio => audio.load()

export const set_volume = (audio, volume) => audio.volume = volume