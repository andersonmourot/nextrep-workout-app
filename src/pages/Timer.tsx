import { useEffect, useRef, useState } from 'react'
import { Pause, Play, RotateCcw } from 'lucide-react'
import { ProgressRing } from '../components/ProgressRing'
import { cn } from '../lib/utils'

type Mode = 'countdown' | 'stopwatch'

const PRESETS = [30, 60, 90, 120, 180]

function fmt(totalSeconds: number): string {
  const s = Math.max(0, Math.round(totalSeconds))
  const m = Math.floor(s / 60)
  const sec = s % 60
  return `${m}:${sec.toString().padStart(2, '0')}`
}

/** Short beep using the Web Audio API (no asset needed). */
function beep() {
  try {
    const Ctx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext
    const ctx = new Ctx()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.type = 'sine'
    osc.frequency.value = 880
    gain.gain.setValueAtTime(0.001, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.3, ctx.currentTime + 0.02)
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.6)
    osc.start()
    osc.stop(ctx.currentTime + 0.62)
    osc.onended = () => ctx.close()
  } catch {
    // Audio not available — ignore.
  }
}

export function Timer() {
  const [mode, setMode] = useState<Mode>('countdown')

  // Countdown state.
  const [total, setTotal] = useState(60)
  const [remaining, setRemaining] = useState(60)
  const [running, setRunning] = useState(false)
  const [done, setDone] = useState(false)

  // Stopwatch state.
  const [elapsed, setElapsed] = useState(0)
  const [swRunning, setSwRunning] = useState(false)

  const tick = useRef<number | null>(null)

  // Countdown timer loop.
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
    tick.current = t
    return () => window.clearInterval(t)
  }, [running])

  // Stopwatch loop.
  useEffect(() => {
    if (!swRunning) return
    const t = window.setInterval(() => setElapsed((e) => e + 1), 1000)
    return () => window.clearInterval(t)
  }, [swRunning])

  function setDuration(seconds: number) {
    setRunning(false)
    setDone(false)
    setTotal(seconds)
    setRemaining(seconds)
  }

  function adjust(delta: number) {
    setDuration(Math.max(5, total + delta))
  }

  function toggleCountdown() {
    if (done || remaining === 0) {
      setRemaining(total)
      setDone(false)
      setRunning(true)
      return
    }
    setRunning((r) => !r)
  }

  function resetCountdown() {
    setRunning(false)
    setDone(false)
    setRemaining(total)
  }

  return (
    <div className="animate-fade-in space-y-5">
      <div>
        <h1 className="heading text-3xl font-bold text-zinc-50">Timer</h1>
      </div>

      <div className="grid grid-cols-2 gap-2">
        {(['countdown', 'stopwatch'] as Mode[]).map((m) => (
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
            {m === 'countdown' ? 'Rest timer' : 'Stopwatch'}
          </button>
        ))}
      </div>

      {mode === 'countdown' ? (
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

          {done && (
            <p className="text-sm font-semibold text-gold">Time's up!</p>
          )}

          <div className="flex items-center gap-2">
            <button onClick={() => adjust(-15)} className="btn-ghost px-3 py-2 text-sm font-semibold">
              −15s
            </button>
            <button onClick={() => adjust(15)} className="btn-ghost px-3 py-2 text-sm font-semibold">
              +15s
            </button>
          </div>

          <div className="grid w-full grid-cols-5 gap-2">
            {PRESETS.map((p) => (
              <button
                key={p}
                onClick={() => setDuration(p)}
                className={cn(
                  'rounded-lg border py-2 text-xs font-semibold transition',
                  total === p
                    ? 'border-gold bg-gold/15 text-gold'
                    : 'border-white/10 bg-ink-900 text-zinc-300 hover:border-white/30',
                )}
              >
                {fmt(p)}
              </button>
            ))}
          </div>

          <div className="flex w-full gap-2">
            <button onClick={toggleCountdown} className="btn-gold flex-1 py-3">
              {running ? (
                <span className="inline-flex items-center gap-2">
                  <Pause className="h-4 w-4" /> Pause
                </span>
              ) : (
                <span className="inline-flex items-center gap-2">
                  <Play className="h-4 w-4" /> {remaining === total && !done ? 'Start' : 'Resume'}
                </span>
              )}
            </button>
            <button onClick={resetCountdown} className="btn-ghost px-4 py-3" aria-label="Reset">
              <RotateCcw className="h-4 w-4" />
            </button>
          </div>
        </div>
      ) : (
        <div className="card flex flex-col items-center gap-6 p-6">
          <span className="heading text-6xl font-bold tabular-nums text-zinc-50">{fmt(elapsed)}</span>
          <div className="flex w-full gap-2">
            <button onClick={() => setSwRunning((r) => !r)} className="btn-gold flex-1 py-3">
              {swRunning ? (
                <span className="inline-flex items-center gap-2">
                  <Pause className="h-4 w-4" /> Pause
                </span>
              ) : (
                <span className="inline-flex items-center gap-2">
                  <Play className="h-4 w-4" /> {elapsed === 0 ? 'Start' : 'Resume'}
                </span>
              )}
            </button>
            <button
              onClick={() => {
                setSwRunning(false)
                setElapsed(0)
              }}
              className="btn-ghost px-4 py-3"
              aria-label="Reset"
            >
              <RotateCcw className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
