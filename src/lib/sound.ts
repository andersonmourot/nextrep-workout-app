/**
 * Sound helpers for the active workout. The rest-timer bell rings well after the
 * user's tap that started the rest (e.g. 90s later), so on iOS it must be
 * "unlocked" during a real user gesture first — `primeBell()` does that, then
 * `playBell()` can play it later even without an active gesture.
 */

/** Short synth beep via Web Audio, used as a fallback when the asset can't play. */
function beep(freq = 880) {
  try {
    const Ctx =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext
    const ctx = new Ctx()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.type = 'sine'
    osc.frequency.value = freq
    gain.gain.setValueAtTime(0.001, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.3, ctx.currentTime + 0.02)
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5)
    osc.start()
    osc.stop(ctx.currentTime + 0.52)
    osc.onended = () => ctx.close()
  } catch {
    // Audio not available — ignore.
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
