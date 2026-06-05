import { useEffect, useRef, useState } from 'react'
import { Pause, Play, RotateCcw } from 'lucide-react'
import { ProgressRing } from '../components/ProgressRing'
import { useStore } from '../store'
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

  useEffect(() => {
    if (!running) return
    const t = window.setInterval(() => {
      setRemaining((r) => {
        if (r <= 1) {
          window.clearInterval(t)
          setRunning(false)
          setDone(true)
          beep()
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
      </div>

      {savedTimers.length > 0 && (
        <div className="space-y-2">
          <h2 className="heading text-sm font-bold uppercase tracking-wider text-zinc-400">
            Recent timers
          </h2>
          <div className="space-y-2">
            {savedTimers.map((t) => (
              <button
                key={t.id}
                onClick={() => loadRecent(t.seconds)}
                className="card flex w-full items-center gap-2 p-3 text-left hover:border-white/10"
              >
                <Play className="h-4 w-4 text-gold" />
                <span className="font-semibold tabular-nums text-zinc-100">{t.label}</span>
              </button>
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
        <span className="text-zinc-400">.{hundredths.toString().padStart(2, '0')}</span>
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

const INTERVAL_FORMATS = ['EMOM', 'AMRAP', 'For Time', 'TABATA'] as const
type IntervalFormat = (typeof INTERVAL_FORMATS)[number]

function Interval() {
  const work = 30
  const rest = 15
  const rounds = 8

  const [format, setFormat] = useState<IntervalFormat | null>(null)
  const [running, setRunning] = useState(false)
  const [round, setRound] = useState(1)
  const [phase, setPhase] = useState<'work' | 'rest'>('work')
  const [remaining, setRemaining] = useState(30)
  const [finished, setFinished] = useState(false)

  // Runtime mirrors in refs so the single timer callback can run the whole
  // state machine (decrement + phase/round transitions) without stale closures
  // or extra effects.
  const cfgRef = useRef({ work, rest, rounds })
  const roundRef = useRef(1)
  const phaseRef = useRef<'work' | 'rest'>('work')
  const remainingRef = useRef(work)

  useEffect(() => {
    cfgRef.current = { work, rest, rounds }
  }, [work, rest, rounds])

  useEffect(() => {
    if (!running) return
    const t = window.setInterval(() => {
      if (remainingRef.current > 1) {
        remainingRef.current -= 1
        setRemaining(remainingRef.current)
        return
      }
      // Phase boundary.
      if (phaseRef.current === 'work') {
        phaseRef.current = 'rest'
        remainingRef.current = cfgRef.current.rest
        setPhase('rest')
        setRemaining(remainingRef.current)
        beep(880)
      } else if (roundRef.current >= cfgRef.current.rounds) {
        window.clearInterval(t)
        setRunning(false)
        setFinished(true)
        beep(660)
      } else {
        roundRef.current += 1
        phaseRef.current = 'work'
        remainingRef.current = cfgRef.current.work
        setRound(roundRef.current)
        setPhase('work')
        setRemaining(remainingRef.current)
        beep(660)
      }
    }, 1000)
    return () => window.clearInterval(t)
  }, [running])

  function start() {
    roundRef.current = 1
    phaseRef.current = 'work'
    remainingRef.current = work
    setRound(1)
    setPhase('work')
    setRemaining(work)
    setFinished(false)
    setRunning(true)
  }

  function reset() {
    roundRef.current = 1
    phaseRef.current = 'work'
    remainingRef.current = work
    setRunning(false)
    setFinished(false)
    setRound(1)
    setPhase('work')
    setRemaining(work)
  }

  const phaseTotal = phase === 'work' ? work : rest

  return (
    <div className="space-y-4">
      <div className="card flex flex-col items-center gap-4 p-6">
        <ProgressRing value={phaseTotal ? remaining / phaseTotal : 0} size={200} stroke={12}>
          <div className="flex flex-col items-center">
            <span
              className={cn(
                'text-xs font-bold uppercase tracking-widest',
                phase === 'work' ? 'text-gold' : 'text-zinc-400',
              )}
            >
              {finished ? 'Done' : phase}
            </span>
            <span className="heading text-5xl font-bold tabular-nums text-zinc-50">
              {fmt(remaining)}
            </span>
            <span className="text-xs text-zinc-500">
              Round {round}/{rounds}
            </span>
          </div>
        </ProgressRing>

        {finished && <p className="text-sm font-semibold text-gold">Workout complete!</p>}

        <div className="flex w-full gap-2">
          <button onClick={running ? () => setRunning(false) : start} className="btn-gold flex-1 py-3">
            {running ? (
              <span className="inline-flex items-center gap-2">
                <Pause className="h-4 w-4" /> Pause
              </span>
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

      <div className="card space-y-2 p-4">
        {INTERVAL_FORMATS.map((f) => (
          <button
            key={f}
            onClick={() => setFormat(f)}
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
