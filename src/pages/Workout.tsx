import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
  Check,
  ChevronLeft,
  ChevronRight,
  Info,
  Minus,
  Plus,
  SkipForward,
  Timer,
  X,
} from 'lucide-react'
import { getExercise } from '../data/exercises'
import { useProgram, useStore } from '../store'
import type { SetLog, WorkoutLog } from '../types'
import { cn, formatClock, uid } from '../lib/utils'

function parseReps(reps: string): number {
  const m = reps.match(/\d+/)
  return m ? parseInt(m[0], 10) : 10
}

export function Workout() {
  const { programId, dayId } = useParams()
  const navigate = useNavigate()
  const program = useProgram(programId)
  const day = program?.days.find((d) => d.id === dayId)
  const { unit, addLog, startProgram, activeProgramId } = useStore()

  const [index, setIndex] = useState(0)
  const [elapsed, setElapsed] = useState(0)
  const [rest, setRest] = useState<{ remaining: number; total: number } | null>(null)
  const [finished, setFinished] = useState<WorkoutLog | null>(null)

  // Per-exercise set logs.
  const [sets, setSets] = useState<SetLog[][]>(
    () =>
      day?.exercises.map((pe) =>
        Array.from({ length: pe.sets }, () => ({
          weight: 0,
          reps: parseReps(pe.reps),
          completed: false,
        })),
      ) ?? [],
  )

  // Elapsed timer.
  useEffect(() => {
    if (finished) return
    const t = setInterval(() => setElapsed((e) => e + 1), 1000)
    return () => clearInterval(t)
  }, [finished])

  // Rest countdown. Runs a single interval while a rest period is active;
  // the functional updater always reads the latest remaining value.
  const restActive = rest !== null
  useEffect(() => {
    if (!restActive) return
    const t = window.setInterval(() => {
      setRest((r) => {
        if (!r) return r
        if (r.remaining <= 1) return null
        return { ...r, remaining: r.remaining - 1 }
      })
    }, 1000)
    return () => window.clearInterval(t)
  }, [restActive])

  const completedCount = useMemo(
    () => sets.flat().filter((s) => s.completed).length,
    [sets],
  )
  const totalSets = useMemo(() => sets.flat().length, [sets])

  if (!program || !day) {
    return (
      <div className="container-app py-10 text-center">
        <p className="text-zinc-400">Workout not found.</p>
        <Link to="/" className="btn-outline mt-4">
          Go Home
        </Link>
      </div>
    )
  }

  const pe = day.exercises[index]
  const ex = getExercise(pe.exerciseId)
  const exerciseSets = sets[index] ?? []

  function updateSet(exIdx: number, setIdx: number, patch: Partial<SetLog>) {
    setSets((prev) =>
      prev.map((arr, i) =>
        i === exIdx ? arr.map((s, j) => (j === setIdx ? { ...s, ...patch } : s)) : arr,
      ),
    )
  }

  function toggleComplete(setIdx: number) {
    const current = exerciseSets[setIdx]
    const willComplete = !current.completed
    updateSet(index, setIdx, { completed: willComplete })
    if (willComplete && pe.restSec > 0) {
      setRest({ remaining: pe.restSec, total: pe.restSec })
    }
  }

  function finish() {
    const loggedExercises = day!.exercises.map((p, i) => ({
      exerciseId: p.exerciseId,
      sets: sets[i].filter((s) => s.completed),
    }))
    const totalVolume = loggedExercises.reduce(
      (sum, le) => sum + le.sets.reduce((a, s) => a + s.weight * s.reps, 0),
      0,
    )
    const log: WorkoutLog = {
      id: uid(),
      date: new Date().toISOString(),
      programId: program!.id,
      programName: program!.name,
      dayId: day!.id,
      dayName: day!.name,
      durationSec: elapsed,
      exercises: loggedExercises,
      totalVolume,
    }
    if (activeProgramId !== program!.id) startProgram(program!.id)
    addLog(log)
    setFinished(log)
  }

  if (finished) {
    return <Summary log={finished} unit={unit} onClose={() => navigate('/')} />
  }

  const isLast = index === day.exercises.length - 1

  return (
    <div className="min-h-full pb-40">
      {/* Top bar */}
      <header className="sticky top-0 z-20 border-b border-white/5 bg-ink-950/85 backdrop-blur">
        <div className="container-app flex h-14 items-center justify-between">
          <button
            onClick={() => navigate(-1)}
            className="grid h-9 w-9 place-items-center rounded-lg bg-ink-850 text-zinc-400 hover:text-zinc-100"
            aria-label="Exit workout"
          >
            <X className="h-5 w-5" />
          </button>
          <div className="text-center">
            <p className="heading text-sm font-bold text-zinc-100">{day.name}</p>
            <p className="text-[11px] text-zinc-500">{program.name}</p>
          </div>
          <div className="flex items-center gap-1 rounded-lg bg-ink-850 px-2.5 py-1.5 text-sm font-semibold text-gold">
            <Timer className="h-4 w-4" />
            {formatClock(elapsed)}
          </div>
        </div>
        <div className="h-1 w-full bg-ink-800">
          <div
            className="h-full bg-gold transition-all"
            style={{ width: `${totalSets ? (completedCount / totalSets) * 100 : 0}%` }}
          />
        </div>
      </header>

      <main className="container-app space-y-5 py-5">
        {/* Exercise switcher */}
        <div className="-mx-4 flex gap-2 overflow-x-auto px-4">
          {day.exercises.map((p, i) => {
            const e = getExercise(p.exerciseId)
            const done = sets[i].every((s) => s.completed)
            return (
              <button
                key={p.exerciseId}
                onClick={() => setIndex(i)}
                className={cn(
                  'whitespace-nowrap rounded-full border px-3 py-1.5 text-xs font-medium transition',
                  i === index
                    ? 'border-gold bg-gold text-ink-950'
                    : done
                      ? 'border-gold/30 bg-gold/10 text-gold'
                      : 'border-white/10 bg-ink-850 text-zinc-400',
                )}
              >
                {done && <Check className="mr-1 inline h-3 w-3" />}
                {e?.name.split(' ').slice(-1)[0] ?? `#${i + 1}`}
              </button>
            )
          })}
        </div>

        {/* Current exercise */}
        <div className="card p-5">
          <div className="flex items-start justify-between">
            <div>
              <span className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
                Exercise {index + 1} of {day.exercises.length}
              </span>
              <h1 className="heading text-2xl font-bold text-zinc-50">{ex?.name}</h1>
              <p className="mt-0.5 text-sm text-zinc-400">
                {pe.sets} sets × {pe.reps} reps · tempo {pe.tempo}
              </p>
            </div>
            <Link
              to={`/exercises/${pe.exerciseId}`}
              className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-400 hover:text-gold"
              aria-label="Exercise info"
            >
              <Info className="h-5 w-5" />
            </Link>
          </div>

          {pe.notes && (
            <p className="mt-3 rounded-lg bg-gold/10 px-3 py-2 text-xs text-gold">{pe.notes}</p>
          )}

          {/* Sets table */}
          <div className="mt-4">
            <div className="grid grid-cols-[2rem_1fr_1fr_3rem] items-center gap-2 px-1 pb-2 text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
              <span>Set</span>
              <span>Weight ({unit})</span>
              <span>Reps</span>
              <span className="text-right">Done</span>
            </div>
            <div className="space-y-2">
              {exerciseSets.map((s, j) => (
                <div
                  key={j}
                  className={cn(
                    'grid grid-cols-[2rem_1fr_1fr_3rem] items-center gap-2 rounded-xl border p-2 transition',
                    s.completed
                      ? 'border-gold/40 bg-gold/[0.07]'
                      : 'border-white/5 bg-ink-900',
                  )}
                >
                  <span className="grid h-7 w-7 place-items-center rounded-md bg-ink-800 text-sm font-bold text-zinc-300">
                    {j + 1}
                  </span>
                  <Stepper
                    value={s.weight}
                    step={5}
                    onChange={(v) => updateSet(index, j, { weight: v })}
                  />
                  <Stepper
                    value={s.reps}
                    step={1}
                    onChange={(v) => updateSet(index, j, { reps: v })}
                  />
                  <div className="flex justify-end">
                    <button
                      onClick={() => toggleComplete(j)}
                      className={cn(
                        'grid h-9 w-9 place-items-center rounded-lg border transition active:scale-95',
                        s.completed
                          ? 'border-gold bg-gold text-ink-950'
                          : 'border-white/15 bg-ink-800 text-zinc-500 hover:border-gold/50',
                      )}
                      aria-label={s.completed ? 'Mark set incomplete' : 'Mark set complete'}
                    >
                      <Check className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Prev / Next */}
          <div className="mt-5 flex gap-2">
            <button
              onClick={() => setIndex((i) => Math.max(0, i - 1))}
              disabled={index === 0}
              className="btn-ghost"
            >
              <ChevronLeft className="h-4 w-4" /> Prev
            </button>
            {isLast ? (
              <button onClick={finish} className="btn-gold flex-1">
                <Check className="h-4 w-4" /> Finish Workout
              </button>
            ) : (
              <button onClick={() => setIndex((i) => i + 1)} className="btn-gold flex-1">
                Next Exercise <ChevronRight className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>

        <button onClick={finish} className="w-full text-center text-xs font-medium text-zinc-500 hover:text-zinc-300">
          End & save workout now
        </button>
      </main>

      {/* Rest timer */}
      {rest && (
        <div className="fixed inset-x-0 bottom-0 z-30 animate-fade-in border-t border-gold/20 bg-ink-900/95 backdrop-blur">
          <div className="container-app py-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="label-eyebrow">Rest</p>
                <p className="heading text-3xl font-bold tabular-nums text-gold">
                  {formatClock(rest.remaining)}
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setRest((r) => (r ? { ...r, remaining: r.remaining + 15, total: r.total + 15 } : r))}
                  className="btn-ghost"
                >
                  +15s
                </button>
                <button onClick={() => setRest(null)} className="btn-gold">
                  <SkipForward className="h-4 w-4" /> Skip
                </button>
              </div>
            </div>
            <div className="mt-3 h-1.5 w-full overflow-hidden rounded-full bg-ink-800">
              <div
                className="h-full bg-gold transition-all duration-1000 ease-linear"
                style={{ width: `${(rest.remaining / rest.total) * 100}%` }}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function Stepper({
  value,
  step,
  onChange,
}: {
  value: number
  step: number
  onChange: (v: number) => void
}) {
  return (
    <div className="flex items-center overflow-hidden rounded-lg border border-white/10 bg-ink-850">
      <button
        onClick={() => onChange(Math.max(0, +(value - step).toFixed(2)))}
        className="grid h-9 w-8 place-items-center text-zinc-400 hover:bg-ink-700 hover:text-zinc-100"
        aria-label="decrease"
      >
        <Minus className="h-4 w-4" />
      </button>
      <input
        type="number"
        inputMode="decimal"
        value={value}
        onChange={(e) => onChange(e.target.value === '' ? 0 : Math.max(0, Number(e.target.value)))}
        className="w-full min-w-0 bg-transparent text-center text-sm font-semibold text-zinc-100 outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
      />
      <button
        onClick={() => onChange(+(value + step).toFixed(2))}
        className="grid h-9 w-8 place-items-center text-zinc-400 hover:bg-ink-700 hover:text-zinc-100"
        aria-label="increase"
      >
        <Plus className="h-4 w-4" />
      </button>
    </div>
  )
}

function Summary({
  log,
  unit,
  onClose,
}: {
  log: WorkoutLog
  unit: string
  onClose: () => void
}) {
  const completedSets = log.exercises.reduce((a, e) => a + e.sets.length, 0)
  return (
    <div className="container-app flex min-h-full flex-col items-center justify-center gap-6 py-12 text-center">
      <div className="grid h-20 w-20 place-items-center rounded-full bg-gold text-ink-950 shadow-glow animate-fade-in">
        <Check className="h-10 w-10" strokeWidth={3} />
      </div>
      <div className="animate-fade-in">
        <p className="label-eyebrow">Workout Complete</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">{log.dayName}</h1>
        <p className="text-sm text-zinc-400">{log.programName}</p>
      </div>
      <div className="grid w-full grid-cols-3 gap-3">
        <SummaryStat value={formatClock(log.durationSec)} label="Time" />
        <SummaryStat value={`${completedSets}`} label="Sets" />
        <SummaryStat value={`${Math.round(log.totalVolume).toLocaleString()}`} label={`Vol (${unit})`} />
      </div>
      <button onClick={onClose} className="btn-gold w-full">
        Done
      </button>
    </div>
  )
}

function SummaryStat({ value, label }: { value: string; label: string }) {
  return (
    <div className="card p-4">
      <div className="heading text-xl font-bold text-zinc-50">{value}</div>
      <div className="mt-1 text-[11px] text-zinc-500">{label}</div>
    </div>
  )
}
