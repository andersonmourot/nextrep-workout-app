import { useEffect, useRef, useState } from 'react'
import { Pause, Play, RotateCcw, Trash2 } from 'lucide-react'
import { ProgressRing } from '../components/ProgressRing'
import { useStore, DEFAULT_INTERVAL_SETTINGS, type IntervalSettings } from '../store'
import { cn, uid } from '../lib/utils'

type Mode = 'timer' | 'stopwatch' | 'interval'

function fmt(totalSeconds: number): string {
  const s = Math.max(0, Math.floor(totalSeconds))
  const m = Math.floor(s / 60)
  const sec = s % 60
  return `${m}:${sec.toString().padStart(2, '0')}`
}

/** Parse "mm:ss" or a bare seconds count into total seconds. */
function parseTime(input: string): number | null {
  const v = input.trim()
  if (!v) return null
  if (v.includes(':')) {
    const [mStr, sStr = '0'] = v.split(':')
    const m = parseInt(mStr, 10)
    const s = parseInt(sStr, 10)
    if (Number.isNaN(m) || Number.isNaN(s)) return null
    return m * 60 + s
  }
  const n = parseInt(v, 10)
  return Number.isNaN(n) ? null : n
}

/** Short beep using the Web Audio API (no asset needed). */
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

/** End-of-timer sound choices (free assets bundled under /public/sounds). */
const SOUND_OPTIONS = [
  { id: 'beep', label: 'Beep' },
  { id: 'bell', label: 'Bell' },
  { id: 'chime', label: 'Chime' },
  { id: 'alarm', label: 'Alarm' },
] as const

/** Play one of the bundled end sounds; falls back to a synth beep on error. */
function playSound(id: string) {
  try {
    const audio = new Audio(`${import.meta.env.BASE_URL}sounds/${id}.mp3`)
    void audio.play().catch(() => beep())
  } catch {
    beep()
  }
}

export function Timer() {
  const [mode, setMode] = useState<Mode>('timer')

  return (
    <div className="animate-fade-in space-y-5">
      <div>
        <h1 className="heading text-3xl font-bold text-zinc-50">Timer</h1>
      </div>

      <div className="grid grid-cols-3 gap-2">
        {(['timer', 'stopwatch', 'interval'] as Mode[]).map((m) => (
          <button
            key={m}
            onClick={() => setMode(m)}
            className={cn(
              'rounded-xl border py-2.5 text-sm font-semibold capitalize transition',
              mode === m
                ? 'border-gold bg-gold text-white'
                : 'border-white/10 bg-ink-900 text-zinc-300',
            )}
          >
            {m}
          </button>
        ))}
      </div>

      {mode === 'timer' && <Countdown />}
      {mode === 'stopwatch' && <Stopwatch />}
      {mode === 'interval' && <Interval />}
    </div>
  )
}

function Countdown() {
  const [total, setTotal] = useState(60)
  const [remaining, setRemaining] = useState(60)
  const [running, setRunning] = useState(false)
  const [done, setDone] = useState(false)
  const [input, setInput] = useState('')

  const savedTimers = useStore((s) => s.savedTimers)
  const addSavedTimer = useStore((s) => s.addSavedTimer)
  const removeSavedTimer = useStore((s) => s.removeSavedTimer)
  const timerSound = useStore((s) => s.timerSound)
  const setTimerSound = useStore((s) => s.setTimerSound)

  useEffect(() => {
    if (!running) return
    const t = window.setInterval(() => {
      setRemaining((r) => {
        if (r <= 1) {
          window.clearInterval(t)
          setRunning(false)
          setDone(true)
          playSound(useStore.getState().timerSound)
          return 0
        }
        return r - 1
      })
    }, 1000)
    return () => window.clearInterval(t)
  }, [running])

  function start() {
    const secs = parseTime(input) ?? total
    const v = Math.max(1, Math.round(secs || 0))
    if (!v) return
    setTotal(v)
    setRemaining(v)
    setDone(false)
    setRunning(true)
    addSavedTimer({ id: uid(), label: fmt(v), seconds: v })
  }

  function reset() {
    setRunning(false)
    setDone(false)
    setRemaining(total)
  }

  function loadRecent(seconds: number) {
    const v = Math.max(1, Math.round(seconds))
    setRunning(false)
    setDone(false)
    setTotal(v)
    setRemaining(v)
    setInput(fmt(v))
  }

  return (
    <div className="space-y-4">
      <div className="card flex flex-col items-center gap-5 p-6">
        <ProgressRing value={total ? remaining / total : 0} size={200} stroke={12}>
          <span
            className={cn(
              'heading text-5xl font-bold tabular-nums',
              done ? 'text-gold' : 'text-zinc-50',
            )}
          >
            {fmt(remaining)}
          </span>
        </ProgressRing>

        {done && <p className="text-sm font-semibold text-gold">Time's up!</p>}

        <div className="flex w-full items-center gap-2">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') start()
            }}
            placeholder="Set time (mm:ss or seconds)"
            inputMode="numeric"
            className="input"
          />
          <button
            onClick={running ? reset : start}
            className="btn-gold shrink-0 px-6 py-2.5 text-sm font-semibold"
          >
            {running ? 'Reset' : 'Start'}
          </button>
        </div>

        <div className="flex w-full items-center gap-2">
          <label htmlFor="timer-sound" className="text-xs font-medium text-zinc-400">
            Alert
          </label>
          <select
            id="timer-sound"
            value={timerSound}
            onChange={(e) => {
              setTimerSound(e.target.value)
              playSound(e.target.value)
            }}
            className="input flex-1 py-2 text-sm"
          >
            {SOUND_OPTIONS.map((o) => (
              <option key={o.id} value={o.id}>
                {o.label}
              </option>
            ))}
          </select>
          <button
            onClick={() => playSound(timerSound)}
            aria-label="Preview sound"
            className="btn-ghost shrink-0 px-3 py-2 text-sm"
          >
            <Play className="h-4 w-4" />
          </button>
        </div>
      </div>

      {savedTimers.length > 0 && (
        <div className="space-y-2">
          <h2 className="heading text-sm font-bold uppercase tracking-wider text-zinc-400">
            Recent timers
          </h2>
          <div className="space-y-2">
            {savedTimers.map((t) => (
              <div
                key={t.id}
                className="card flex w-full items-center gap-2 p-3 hover:border-white/10"
              >
                <button
                  onClick={() => loadRecent(t.seconds)}
                  className="flex flex-1 items-center gap-2 text-left"
                >
                  <Play className="h-4 w-4 text-gold" />
                  <span className="font-semibold tabular-nums text-zinc-100">{t.label}</span>
                </button>
                <button
                  onClick={() => removeSavedTimer(t.id)}
                  aria-label="Delete timer"
                  className="shrink-0 rounded-md p-1.5 text-zinc-500 hover:bg-white/5 hover:text-red-500"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function Stopwatch() {
  // Tracked in centiseconds (1/100s) so we can display milliseconds.
  const [cs, setCs] = useState(0)
  const [running, setRunning] = useState(false)

  useEffect(() => {
    if (!running) return
    const t = window.setInterval(() => setCs((c) => c + 1), 10)
    return () => window.clearInterval(t)
  }, [running])

  const totalSec = Math.floor(cs / 100)
  const m = Math.floor(totalSec / 60)
  const s = totalSec % 60
  const hundredths = cs % 100

  return (
    <div className="card flex flex-col items-center gap-6 p-6">
      <span className="heading text-6xl font-bold tabular-nums text-zinc-50">
        {m}:{s.toString().padStart(2, '0')}
        <span>.{hundredths.toString().padStart(2, '0')}</span>
      </span>
      <div className="flex w-full gap-2">
        <button onClick={() => setRunning((r) => !r)} className="btn-gold flex-1 py-3">
          {running ? (
            <span className="inline-flex items-center gap-2">
              <Pause className="h-4 w-4" /> Pause
            </span>
          ) : (
            <span className="inline-flex items-center gap-2">
              <Play className="h-4 w-4" /> {cs === 0 ? 'Start' : 'Resume'}
            </span>
          )}
        </button>
        <button
          onClick={() => {
            setRunning(false)
            setCs(0)
          }}
          className="btn-ghost px-4 py-3"
          aria-label="Reset"
        >
          <RotateCcw className="h-4 w-4" />
        </button>
      </div>
    </div>
  )
}

const INTERVAL_FORMATS = ['EMOM', 'AMRAP', 'TABATA'] as const
type IntervalFormat = (typeof INTERVAL_FORMATS)[number]

/** Short tick cue for the final 3 seconds of a phase. */
function tickCue(secLeft: number) {
  if (secLeft === 3 || secLeft === 2 || secLeft === 1) beep(1000)
}

function NumIn({
  label,
  value,
  onChange,
  disabled,
  min = 0,
  max,
}: {
  label: string
  value: number
  onChange: (v: number) => void
  disabled?: boolean
  min?: number
  max?: number
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-xs font-medium text-zinc-400">{label}</span>
      <input
        type="number"
        inputMode="numeric"
        value={value}
        min={min}
        max={max}
        disabled={disabled}
        onChange={(e) => {
          const n = parseInt(e.target.value, 10)
          let v = Number.isNaN(n) ? min : n
          if (v < min) v = min
          if (max !== undefined && v > max) v = max
          onChange(v)
        }}
        className="input no-spin py-2 text-sm disabled:opacity-50"
      />
    </label>
  )
}

function Interval() {
  const settings = useStore((s) => s.intervalSettings)
  const setIntervalSettings = useStore((s) => s.setIntervalSettings)

  const [format, setFormat] = useState<IntervalFormat | null>(null)
  const [running, setRunning] = useState(false)
  const [round, setRound] = useState(1)
  const [phase, setPhase] = useState<'work' | 'rest'>('work')
  const [remaining, setRemaining] = useState(DEFAULT_INTERVAL_SETTINGS.tabataWork)
  const [finished, setFinished] = useState(false)
  const [countdown, setCountdown] = useState<number | null>(null)
  const [amrapInput, setAmrapInput] = useState('')

  // Runtime mirrors in refs so the single timer callback can run the whole
  // state machine without stale closures.
  const cfgRef = useRef({ work: 20, rest: 10, rounds: 8 })
  const roundRef = useRef(1)
  const phaseRef = useRef<'work' | 'rest'>('work')
  const remainingRef = useRef(20)

  const cfg =
    format === 'EMOM'
      ? { work: settings.emomInterval, rest: 0, rounds: settings.emomRounds }
      : format === 'TABATA'
        ? { work: settings.tabataWork, rest: settings.tabataRest, rounds: settings.tabataRounds }
        : format === 'AMRAP'
          ? { work: Math.max(1, settings.amrapCap), rest: 0, rounds: 1 }
          : null

  // Reconfigure runtime refs + display for a given format/settings pair.
  function applyConfig(fmt: IntervalFormat | null, sett: IntervalSettings) {
    const c =
      fmt === 'EMOM'
        ? { work: sett.emomInterval, rest: 0, rounds: sett.emomRounds }
        : fmt === 'TABATA'
          ? { work: sett.tabataWork, rest: sett.tabataRest, rounds: sett.tabataRounds }
          : fmt === 'AMRAP'
            ? { work: Math.max(1, sett.amrapCap), rest: 0, rounds: 1 }
            : null
    if (c) cfgRef.current = c
    setRunning(false)
    setFinished(false)
    setCountdown(null)
    roundRef.current = 1
    phaseRef.current = 'work'
    if (c) {
      remainingRef.current = c.work
      setRound(1)
      setPhase('work')
      setRemaining(c.work)
    }
  }

  function selectFormat(f: IntervalFormat) {
    setFormat(f)
    applyConfig(f, settings)
  }

  // 5-4-3-2-1 intro countdown effect
  useEffect(() => {
    if (countdown === null) return
    const t = window.setTimeout(() => {
      if (countdown <= 1) {
        beep(1000)
        setCountdown(null)
        playSound(useStore.getState().timerSound)
        setRunning(true)
      } else {
        beep(1000)
        setCountdown(countdown - 1)
      }
    }, 1000)
    return () => window.clearTimeout(t)
  }, [countdown])

  useEffect(() => {
    if (!running) return
    const t = window.setInterval(() => {
      // Countdown rounds (EMOM / AMRAP / TABATA).
      if (remainingRef.current > 1) {
        remainingRef.current -= 1
        setRemaining(remainingRef.current)
        tickCue(remainingRef.current)
        return
      }
      const { work, rest, rounds } = cfgRef.current
      if (phaseRef.current === 'work' && rest > 0) {
        phaseRef.current = 'rest'
        remainingRef.current = rest
        setPhase('rest')
        setRemaining(rest)
        beep(880)
      } else if (roundRef.current >= rounds) {
        window.clearInterval(t)
        setRunning(false)
        setFinished(true)
        remainingRef.current = 0
        setRemaining(0)
        playSound(useStore.getState().timerSound)
      } else {
        roundRef.current += 1
        phaseRef.current = 'work'
        remainingRef.current = work
        setRound(roundRef.current)
        setPhase('work')
        setRemaining(work)
        beep(660)
      }
    }, 1000)
    return () => window.clearInterval(t)
  }, [running])

  function resetRuntime() {
    setFinished(false)
    setCountdown(null)
    const c = cfgRef.current
    roundRef.current = 1
    phaseRef.current = 'work'
    remainingRef.current = c.work
    setRound(1)
    setPhase('work')
    setRemaining(c.work)
  }

  function start() {
    if (!format) return
    if (finished) resetRuntime()
    setFinished(false)
    beep(660)
    setCountdown(5)
  }

  function reset() {
    setRunning(false)
    resetRuntime()
  }

  const phaseTotal = phase === 'work' ? cfg?.work ?? 1 : cfg?.rest ?? 1
  const ringValue = phaseTotal ? remaining / phaseTotal : 0
  const display = countdown !== null ? countdown : remaining

  const desc =
    format === 'EMOM'
      ? `${settings.emomInterval}s × ${settings.emomRounds} rounds`
      : format === 'AMRAP'
        ? `${fmt(settings.amrapCap)} time cap`
        : format === 'TABATA'
          ? `${settings.tabataWork}s work / ${settings.tabataRest}s rest × ${settings.tabataRounds}`
          : ''

  const subtitle = !format
    ? 'Select a format'
    : countdown !== null
      ? 'Get ready!'
      : format === 'AMRAP'
        ? 'Time cap'
        : `Round ${round}/${cfg?.rounds ?? 1}`

  const upd = (patch: Partial<IntervalSettings>) => {
    const next = { ...settings, ...patch }
    setIntervalSettings(next)
    if (!running) applyConfig(format, next)
  }

  return (
    <div className="space-y-4">
      <div className="card flex flex-col items-center gap-4 p-6">
        <ProgressRing value={ringValue} size={200} stroke={12}>
          <div className="flex flex-col items-center">
            <span
              className={cn(
                'text-xs font-bold uppercase tracking-widest',
                phase === 'work' ? 'text-gold' : 'text-zinc-400',
              )}
            >
              {finished ? 'Done' : !format ? 'Interval' : countdown !== null ? 'Ready' : phase}
            </span>
            <span className="heading text-5xl font-bold tabular-nums text-zinc-50">
              {fmt(display)}
            </span>
            <span className="text-xs text-zinc-500">{subtitle}</span>
          </div>
        </ProgressRing>

        {format && <p className="text-xs text-zinc-400">{desc}</p>}
        {finished && <p className="text-sm font-semibold text-gold">Workout complete!</p>}

        <div className="flex w-full gap-2">
          <button
            onClick={running ? () => setRunning(false) : countdown !== null ? reset : start}
            disabled={!format}
            className="btn-gold flex-1 py-3 disabled:cursor-not-allowed disabled:opacity-40"
          >
            {running ? (
              <span className="inline-flex items-center gap-2">
                <Pause className="h-4 w-4" /> Pause
              </span>
            ) : countdown !== null ? (
              <span>Cancel</span>
            ) : (
              <span className="inline-flex items-center gap-2">
                <Play className="h-4 w-4" /> Start
              </span>
            )}
          </button>
          <button onClick={reset} className="btn-ghost px-4 py-3" aria-label="Reset">
            <RotateCcw className="h-4 w-4" />
          </button>
        </div>
      </div>

      {format && (
        <div className="card space-y-3 p-4">
          <h2 className="heading text-sm font-bold uppercase tracking-wider text-zinc-400">
            {format} settings
          </h2>
          {format === 'EMOM' && (
            <div className="grid grid-cols-2 gap-3">
              <NumIn
                label="Interval (sec)"
                value={settings.emomInterval}
                min={5}
                disabled={running || countdown !== null}
                onChange={(v) => upd({ emomInterval: v })}
              />
              <NumIn
                label="Rounds"
                value={settings.emomRounds}
                min={1}
                disabled={running || countdown !== null}
                onChange={(v) => upd({ emomRounds: v })}
              />
            </div>
          )}
          {format === 'TABATA' && (
            <div className="grid grid-cols-3 gap-3">
              <NumIn
                label="Work (sec)"
                value={settings.tabataWork}
                min={1}
                disabled={running || countdown !== null}
                onChange={(v) => upd({ tabataWork: v })}
              />
              <NumIn
                label="Rest (sec)"
                value={settings.tabataRest}
                min={0}
                disabled={running || countdown !== null}
                onChange={(v) => upd({ tabataRest: v })}
              />
              <NumIn
                label="Rounds"
                value={settings.tabataRounds}
                min={1}
                disabled={running || countdown !== null}
                onChange={(v) => upd({ tabataRounds: v })}
              />
            </div>
          )}
          {format === 'AMRAP' && (
            <div>
              <label className="flex flex-col gap-1">
                <span className="text-xs font-medium text-zinc-400">Cap time (mm:ss)</span>
                <input
                  type="text"
                  inputMode="numeric"
                  placeholder={fmt(settings.amrapCap)}
                  value={amrapInput}
                  disabled={running || countdown !== null}
                  onChange={(e) => setAmrapInput(e.target.value)}
                  onBlur={() => {
                    const parsed = parseTime(amrapInput)
                    if (parsed !== null && parsed > 0) upd({ amrapCap: parsed })
                    setAmrapInput('')
                  }}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      const parsed = parseTime(amrapInput)
                      if (parsed !== null && parsed > 0) upd({ amrapCap: parsed })
                      setAmrapInput('')
                    }
                  }}
                  className="input no-spin py-2 text-sm disabled:opacity-50"
                />
              </label>
            </div>
          )}
        </div>
      )}

      <div className="card space-y-2 p-4">
        {INTERVAL_FORMATS.map((f) => (
          <button
            key={f}
            onClick={() => selectFormat(f)}
            className={cn(
              'w-full rounded-xl border py-3 text-sm font-semibold transition',
              format === f
                ? 'border-gold bg-gold text-white'
                : 'border-white/10 bg-ink-900 text-zinc-300 hover:border-white/20',
            )}
          >
            {f}
          </button>
        ))}
      </div>
    </div>
  )
}
