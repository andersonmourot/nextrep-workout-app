import { useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Check, Info, Minus, Plus } from 'lucide-react'
import { exerciseLabel, getExercise } from '../data/exercises'
import { useProgram, useStore } from '../store'
import type { SetLog, WorkoutLog } from '../types'
import { cn, programLogsChrono, uid } from '../lib/utils'

/**
 * View / edit the logged data for a single program day. Reachable by tapping a
 * day card in ProgramDetail. The `dayIndex` URL param is the 0-based global
 * index across weeks (e.g. a 3-day program's Week 2 Day 1 = index 3).
 */
export function DayReview() {
  const { programId, dayIndex: dayIndexParam } = useParams()
  const navigate = useNavigate()
  const program = useProgram(programId)
  const logs = useStore((s) => s.logs)
  const unit = useStore((s) => s.unit)
  const programAnchors = useStore((s) => s.programAnchors)
  const addLog = useStore((s) => s.addLog)
  const deleteLog = useStore((s) => s.deleteLog)

  const globalIdx = Number(dayIndexParam ?? 0)
  const daysLen = program ? Math.max(1, program.days.length) : 1
  const dayLocalIdx = globalIdx % daysLen
  const weekNum = Math.floor(globalIdx / daysLen) + 1
  const day = program?.days[dayLocalIdx]

  const anchor = program ? programAnchors[program.id] : undefined
  const chrono = useMemo(
    () => (program ? programLogsChrono(program, logs, anchor) : []),
    [program, logs, anchor],
  )
  const existingLog: WorkoutLog | undefined = chrono[globalIdx]

  // Local set state — pre-filled from an existing log or from the day template.
  const [sets, setSets] = useState<SetLog[][]>(() => {
    if (!day) return []
    if (existingLog) {
      return day.exercises.map((pe, i) => {
        const logged = existingLog.exercises[i]
        if (logged && logged.sets.length > 0) {
          return logged.sets.map((s) => ({ ...s }))
        }
        return Array.from({ length: pe.sets }, () => ({
          weight: 0,
          reps: parseReps(pe.reps),
          completed: false,
        }))
      })
    }
    return day.exercises.map((pe) =>
      Array.from({ length: pe.sets }, () => ({
        weight: 0,
        reps: parseReps(pe.reps),
        completed: false,
      })),
    )
  })

  const [saved, setSaved] = useState(false)

  if (!program || !day) {
    return (
      <div className="animate-fade-in py-10 text-center">
        <p className="text-zinc-400">Day not found.</p>
        <Link to="/programs" className="btn-outline mt-4">
          Back to Programs
        </Link>
      </div>
    )
  }

  function updateSet(exIdx: number, setIdx: number, patch: Partial<SetLog>) {
    setSets((prev) =>
      prev.map((arr, i) =>
        i === exIdx ? arr.map((s, j) => (j === setIdx ? { ...s, ...patch } : s)) : arr,
      ),
    )
    setSaved(false)
  }

  function toggleComplete(exIdx: number, setIdx: number) {
    const current = sets[exIdx]?.[setIdx]
    if (!current) return
    updateSet(exIdx, setIdx, { completed: !current.completed })
  }

  function save() {
    if (!program || !day) return
    const loggedExercises = day.exercises.map((p, i) => ({
      exerciseId: p.exerciseId,
      sets: (sets[i] ?? []).filter((s) => s.completed),
    }))
    const totalVolume = loggedExercises.reduce(
      (sum, le) => sum + le.sets.reduce((a, s) => a + s.weight * s.reps, 0),
      0,
    )
    const log: WorkoutLog = {
      id: existingLog?.id ?? uid(),
      date: existingLog?.date ?? new Date().toISOString(),
      programId: program.id,
      programName: program.name,
      dayId: day.id,
      dayName: day.name,
      durationSec: existingLog?.durationSec ?? 0,
      exercises: loggedExercises,
      totalVolume,
    }
    if (existingLog) deleteLog(existingLog.id)
    addLog(log)
    setSaved(true)
  }

  const hasCompleted = sets.flat().some((s) => s.completed)

  return (
    <div className="animate-fade-in space-y-5">
      {/* Back arrow — icon only */}
      <button
        onClick={() => navigate(`/programs/${program.id}`)}
        className="grid h-9 w-9 place-items-center rounded-lg bg-ink-850 text-zinc-400 hover:text-zinc-100"
        aria-label="Back to program"
      >
        <ArrowLeft className="h-5 w-5" />
      </button>

      <div>
        <span className="label-eyebrow" style={{ color: program.accent }}>
          Week {weekNum} · Day {dayLocalIdx + 1}
        </span>
        <h1 className="heading text-2xl font-bold text-zinc-50">{day.name}</h1>
        {day.focus && <p className="mt-0.5 text-xs text-zinc-400">{day.focus}</p>}
      </div>

      {day.exercises.map((pe, exIdx) => {
        const ex = getExercise(pe.exerciseId)
        const exerciseSets = sets[exIdx] ?? []
        return (
          <div key={`${pe.exerciseId}-${exIdx}`} className="card p-5">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
                  Exercise {exIdx + 1} of {day.exercises.length}
                </span>
                <h2 className="heading text-xl font-bold text-zinc-50">{exerciseLabel(pe)}</h2>
                <p className="mt-0.5 text-sm text-zinc-400">
                  {pe.sets} sets × {pe.reps} reps
                </p>
              </div>
              {ex && (
                <Link
                  to={`/exercises/${pe.exerciseId}`}
                  className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-400 hover:text-gold"
                  aria-label="Exercise info"
                >
                  <Info className="h-5 w-5" />
                </Link>
              )}
            </div>

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
                      onChange={(v) => updateSet(exIdx, j, { weight: v })}
                    />
                    <Stepper
                      value={s.reps}
                      step={1}
                      onChange={(v) => updateSet(exIdx, j, { reps: v })}
                    />
                    <div className="flex justify-end">
                      <button
                        onClick={() => toggleComplete(exIdx, j)}
                        className={cn(
                          'grid h-9 w-9 place-items-center rounded-lg border transition active:scale-95',
                          s.completed
                            ? 'border-gold bg-gold text-white'
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
          </div>
        )
      })}

      {hasCompleted && (
        <button onClick={save} disabled={saved} className="btn-gold w-full disabled:opacity-60">
          {saved ? 'Saved' : existingLog ? 'Update Workout' : 'Save Workout'}
        </button>
      )}
    </div>
  )
}

function parseReps(reps: string): number {
  const n = parseInt(reps, 10)
  return Number.isNaN(n) ? 0 : n
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
