/**
 * Sound helpers for the workout + interval timers.
 *
 * iOS note: by default a web page's audio uses the "playback" session category,
 * which interrupts (pauses) whatever the user is listening to in another app
 * (Spotify, Apple Music, etc.). For short alert sounds we instead set the audio
 * session to "ambient" so our beeps/bell mix on top of background music without
 * stopping it. `enableMixedAudio()` does that and is a no-op where the
 * AudioSession API isn't available.
 *
 * The rest-timer bell also rings well after the tap that started the rest (e.g.
 * 90s later), so on iOS it must be "unlocked" during a real user gesture first —
 * `primeBell()` does that, then `playBell()` can play it later without a gesture.
 */

type NavWithAudioSession = Navigator & { audioSession?: { type: string } }

/**
 * Set the iOS audio session to "ambient" so our short sounds mix with the user's
 * background music instead of pausing it. No-op on browsers without the API.
 * Note: `<audio>` elements are silent under "transient", so we use "ambient".
 */
export function enableMixedAudio() {
  try {
    const nav = navigator as NavWithAudioSession
    if (nav.audioSession && nav.audioSession.type !== 'ambient') {
      nav.audioSession.type = 'ambient'
    }
  } catch {
    // AudioSession API not available — ignore.
  }
}

// Reuse a single AudioContext for all synth beeps. Creating a fresh context per
// beep is wasteful and can re-trigger audio-session negotiation on iOS (another
// way the user's music could get interrupted).
let audioCtx: AudioContext | null = null

function getCtx(): AudioContext | null {
  try {
    const Ctx =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext
    if (!Ctx) return null
    if (!audioCtx) audioCtx = new Ctx()
    if (audioCtx.state === 'suspended') void audioCtx.resume()
    return audioCtx
  } catch {
    return null
  }
}

/** Short synth beep via Web Audio (no asset needed). */
export function beep(freq = 880) {
  enableMixedAudio()
  const ctx = getCtx()
  if (!ctx) return
  try {
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.type = 'sine'
    osc.frequency.value = freq
    const t = ctx.currentTime
    gain.gain.setValueAtTime(0.001, t)
    gain.gain.exponentialRampToValueAtTime(0.3, t + 0.02)
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.5)
    osc.start()
    osc.stop(t + 0.52)
  } catch {
    // Audio not available — ignore.
  }
}

/** Play one of the bundled end sounds; falls back to a synth beep on error. */
export function playSound(id: string) {
  enableMixedAudio()
  try {
    const audio = new Audio(`${import.meta.env.BASE_URL}sounds/${id}.mp3`)
    void audio.play().catch(() => beep())
  } catch {
    beep()
  }
}

let bellEl: HTMLAudioElement | null = null

function getBell(): HTMLAudioElement | null {
  if (typeof Audio === 'undefined') return null
  if (!bellEl) {
    bellEl = new Audio(`${import.meta.env.BASE_URL}sounds/bell.mp3`)
    bellEl.preload = 'auto'
  }
  return bellEl
}

/**
 * Unlock the bell for later playback. Call this inside a user gesture (e.g. when
 * the user taps a set "done", which starts the rest that will ring). Plays the
 * element silently then resets it so a later `playBell()` is allowed on iOS.
 */
export function primeBell() {
  enableMixedAudio()
  const el = getBell()
  if (!el) return
  try {
    el.muted = true
    const p = el.play()
    const reset = () => {
      el.pause()
      el.currentTime = 0
      el.muted = false
    }
    if (p && typeof (p as Promise<void>).then === 'function') {
      ;(p as Promise<void>).then(reset).catch(() => {
        el.muted = false
      })
    } else {
      reset()
    }
  } catch {
    // ignore — playBell falls back to a synth beep
  }
}

/** Play the rest-timer bell. Used only when a rest timer ends naturally. */
export function playBell() {
  enableMixedAudio()
  const el = getBell()
  if (!el) {
    beep()
    return
  }
  try {
    el.muted = false
    el.currentTime = 0
    void el.play().catch(() => beep())
  } catch {
    beep()
  }
}
