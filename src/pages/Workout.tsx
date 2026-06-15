import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Check, Info, SkipForward, Timer, X } from 'lucide-react'
import { exerciseLabel, resolvePlannedExercise } from '../data/exercises'
import { useProgram, useStore } from '../store'
import type { SetLog, WorkoutLog } from '../types'
import {
  cn,
  formatClock,
  lastInGroupIndices,
  resolveProgramDay,
  supersetGroups,
  uid,
  type SupersetGroup,
} from '../lib/utils'
import { playBell, primeBell } from '../lib/sound'
import { ExerciseNotesButton } from '../components/ExerciseNotesButton'
import { ExerciseSubheader, ExerciseCueButton } from '../components/ExerciseSubheader'

export function Workout() {
  const navigate = useNavigate()
  const activeWorkout = useStore((s) => s.activeWorkout)
  const program = useProgram(activeWorkout?.programId)
  // Resolve the day for the week being trained so per-week edits apply.
  const dayLocalIdx = program
    ? program.days.findIndex((d) => d.id === activeWorkout?.dayId)
    : -1
  const day =
    program && dayLocalIdx >= 0
      ? resolveProgramDay(program, dayLocalIdx, activeWorkout?.week ?? 1)
      : undefined
  const unit = useStore((s) => s.unit)
  const activeProgramId = useStore((s) => s.activeProgramId)
  const addLog = useStore((s) => s.addLog)
  const startProgram = useStore((s) => s.startProgram)
  const setActiveWorkoutSets = useStore((s) => s.setActiveWorkoutSets)
  const setActiveWorkoutRest = useStore((s) => s.setActiveWorkoutRest)
  const startRest = useStore((s) => s.startRest)
  const reconcileActiveWorkout = useStore((s) => s.reconcileActiveWorkout)
  const endWorkout = useStore((s) => s.endWorkout)
  // Group consecutive exercises that share a groupId into supersets/trisets/
  // giant sets, rendered round-by-round. Standalone exercises are their own
  // singleton group, so this is a no-op for days without any grouping.
  const groups = useMemo<SupersetGroup[]>(() => supersetGroups(day?.exercises ?? []), [day])
  // Indices that end a round (the last member of each group) — only these fire
  // the rest timer/bell. For singletons that's the exercise itself.
  const lastInGroup = useMemo(() => lastInGroupIndices(day?.exercises ?? []), [day])

  // Keep the live session in sync with the program plan: if the day is edited
  // (exercises added/removed/reordered, set counts changed) while the workout is
  // active, merge those changes in — preserving entered weights/reps and done
  // sets. The signature changes whenever the plan's shape changes.
  const planSignature = day
    ? day.exercises.map((pe) => `${pe.exerciseId}:${pe.sets}`).join('|')
    : ''
  useEffect(() => {
    if (activeWorkout && day) reconcileActiveWorkout()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [planSignature])

  const [finished, setFinished] = useState<WorkoutLog | null>(null)
  // A clock tick stored in state (set from effects) so the render stays pure;
  // it advances every second to update the derived elapsed/rest clocks.
  const [now, setNow] = useState(() => Date.now())

  // Derive the session values from the store so they survive tab switches.
  const sets = useMemo(() => activeWorkout?.sets ?? [], [activeWorkout])
  const startedAt = activeWorkout?.startedAt ?? 0
  const elapsed = activeWorkout && now ? Math.max(0, Math.floor((now - startedAt) / 1000)) : 0
  const restRemaining =
    activeWorkout?.restEndsAt && now
      ? Math.max(0, Math.ceil((activeWorkout.restEndsAt - now) / 1000))
      : 0
  const restActive = restRemaining > 0

  // Single ticking interval: advances the clock for the displays and auto-clears
  // rest once it has elapsed. Uses getState() to avoid stale closures.
  useEffect(() => {
    if (finished || !activeWorkout) return
    const t = window.setInterval(() => {
      const t2 = Date.now()
      setNow(t2)
      const aw = useStore.getState().activeWorkout
      if (aw?.restEndsAt && t2 >= aw.restEndsAt) {
        // Rest finished on its own — ring the bell. (Skipping clears restEndsAt
        // directly without hitting this path, so a skipped timer stays silent.)
        playBell()
        useStore.getState().setActiveWorkoutRest(null, 0)
      }
    }, 1000)
    return () => window.clearInterval(t)
  }, [finished, activeWorkout])

  const completedCount = useMemo(
    () => sets.flat().filter((s) => s.completed).length,
    [sets],
  )
  const totalSets = useMemo(() => sets.flat().length, [sets])

  if (finished) {
    return (
      <Summary
        log={finished}
        unit={unit}
        onClose={() => {
          endWorkout()
          navigate('/')
        }}
      />
    )
  }

  if (!activeWorkout || !program || !day) {
    return (
      <div className="container-app py-10 text-center">
        <p className="text-zinc-400">No active workout.</p>
        <button onClick={() => navigate('/programs')} className="btn-outline mt-4">
          Back to Programs
        </button>
      </div>
    )
  }

  function updateSet(exIdx: number, setIdx: number, patch: Partial<SetLog>) {
    const next = sets.map((arr, i) =>
      i === exIdx ? arr.map((s, j) => (j === setIdx ? { ...s, ...patch } : s)) : arr,
    )
    setActiveWorkoutSets(next)
  }

  function toggleComplete(exIdx: number, setIdx: number) {
    const current = sets[exIdx]?.[setIdx]
    if (!current || !day) return
    const willComplete = !current.completed
    const restSec = day.exercises[exIdx].restSec
    updateSet(exIdx, setIdx, { completed: willComplete })
    // In a superset, only the last exercise of the round rests — the others are
    // performed back-to-back with no rest between (no bell either).
    if (willComplete && restSec > 0 && lastInGroup.has(exIdx)) {
      // Unlock audio within this tap so the bell can ring when rest ends (iOS).
      primeBell()
      startRest(restSec)
    }
  }

  function finish() {
    if (!program || !day) return
    const loggedExercises = day.exercises.map((p, i) => ({
      exerciseId: p.exerciseId,
      // Save sets the user marked done, plus any where they entered a weight
      // but forgot to tap "done" — record those as done too so nothing is lost.
      sets: (sets[i] ?? [])
        .filter((s) => s.completed || s.weight > 0)
        .map((s) => ({ ...s, completed: true })),
    }))
    const totalVolume = loggedExercises.reduce(
      (sum, le) => sum + le.sets.reduce((a, s) => a + s.weight * s.reps, 0),
      0,
    )
    const log: WorkoutLog = {
      id: uid(),
      date: new Date().toISOString(),
      programId: program.id,
      programName: program.name,
      dayId: day.id,
      dayName: day.name,
      week: activeWorkout?.week,
      durationSec: elapsed,
      exercises: loggedExercises,
      totalVolume,
    }
    if (activeProgramId !== program.id) startProgram(program.id)
    addLog(log)
    setFinished(log)
  }

  return (
    <div className="min-h-full pb-40">
      {/* Top bar */}
      <header className="sticky top-0 z-20 border-b border-white/5 bg-ink-950/85 backdrop-blur">
        <div className="container-app flex h-14 items-center justify-between">
          <button
            onClick={() => {
              // Leave the session running so entered weights/reps/done sets are
              // kept — the user can go edit the day and come back to Resume.
              // (Finishing the workout is the explicit "complete & log" path.)
              // Go to the program's detail page so the day can be edited; the
              // session stays live and a "Resume workout" banner brings it back.
              navigate(`/programs/${program.id}`)
            }}
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
        {groups.map((group) => {
          // ---- Standalone exercise (the usual one-exercise card) ----
          if (!group.isSuperset) {
            const exIdx = group.indices[0]
            const pe = day.exercises[exIdx]
            const ex = resolvePlannedExercise(pe)
            const exerciseSets = sets[exIdx] ?? []
            return (
              <div key={`${pe.exerciseId}-${exIdx}`} className="card p-5">
                <div className="flex items-start justify-between">
                  <div>
                    <span className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
                      Exercise {exIdx + 1} of {day.exercises.length}
                    </span>
                    <h1 className="heading text-2xl font-bold text-zinc-50">{exerciseLabel(pe)}</h1>
                    <p className="mt-0.5 text-sm text-zinc-400">
                      {pe.sets} sets × {pe.reps} reps
                    </p>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    <ExerciseCueButton exerciseId={ex?.id ?? pe.exerciseId} />
                    <ExerciseNotesButton exerciseId={ex?.id ?? pe.exerciseId} label={exerciseLabel(pe)} />
                    {ex && (
                      <Link
                        to={`/exercises/${ex.id}`}
                        className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-400 hover:text-gold"
                        aria-label="Exercise info"
                      >
                        <Info className="h-5 w-5" />
                      </Link>
                    )}
                  </div>
                </div>

                {pe.notes && (
                  <p className="mt-3 rounded-lg bg-gold/10 px-3 py-2 text-xs text-gold">{pe.notes}</p>
                )}
                <ExerciseSubheader exerciseId={ex?.id ?? pe.exerciseId} />

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
                      <SetRow
                        key={j}
                        lead={`${j + 1}`}
                        set={s}
                        onWeight={(v) => updateSet(exIdx, j, { weight: v })}
                        onReps={(v) => updateSet(exIdx, j, { reps: v })}
                        onToggle={() => toggleComplete(exIdx, j)}
                      />
                    ))}
                  </div>
                </div>
              </div>
            )
          }

          // ---- Superset / triset / giant set (round-by-round) ----
          const members = group.indices
          const rounds = Math.max(1, ...members.map((i) => (sets[i] ?? []).length))
          return (
            <div
              key={`ss-${group.groupId}`}
              className="rounded-2xl border border-gold/45 bg-gradient-to-b from-gold/[0.07] to-transparent p-4"
            >
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-bold uppercase tracking-wider text-gold">
                  Superset {group.label} · no rest between
                </span>
                <span className="text-[11px] text-zinc-500">{rounds} rounds</span>
              </div>

              {/* Legend: each exercise once, with its info + notes controls */}
              <div className="mt-3 space-y-2">
                {members.map((exIdx, pos) => {
                  const pe = day.exercises[exIdx]
                  const ex = resolvePlannedExercise(pe)
                  return (
                    <div key={`leg-${exIdx}`}>
                      <div className="flex items-center gap-2">
                        <span className="grid h-7 w-8 shrink-0 place-items-center rounded-md bg-gold/15 text-xs font-bold text-gold">
                          {group.label}
                          {pos + 1}
                        </span>
                        <div className="min-w-0 flex-1">
                          <p className="truncate font-semibold text-zinc-100">{exerciseLabel(pe)}</p>
                          <p className="text-[11px] text-zinc-500">{pe.reps} reps target</p>
                        </div>
                        <ExerciseCueButton exerciseId={ex?.id ?? pe.exerciseId} />
                        <ExerciseNotesButton exerciseId={ex?.id ?? pe.exerciseId} label={exerciseLabel(pe)} />
                        {ex && (
                          <Link
                            to={`/exercises/${ex.id}`}
                            className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-400 hover:text-gold"
                            aria-label="Exercise info"
                          >
                            <Info className="h-5 w-5" />
                          </Link>
                        )}
                      </div>
                      {pe.notes && (
                        <p className="mt-1 rounded-lg bg-gold/10 px-3 py-1.5 text-xs text-gold">{pe.notes}</p>
                      )}
                      <ExerciseSubheader exerciseId={ex?.id ?? pe.exerciseId} className="mt-2" />
                    </div>
                  )
                })}
              </div>

              {/* Rounds: log A1 then A2 …, the round's rest fires after the last */}
              <div className="mt-4">
                <div className="grid grid-cols-[2.5rem_1fr_1fr_3rem] items-center gap-2 px-1 pb-1 text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
                  <span></span>
                  <span>Weight ({unit})</span>
                  <span>Reps</span>
                  <span className="text-right">Done</span>
                </div>
                <div className="space-y-3">
                  {Array.from({ length: rounds }, (_, r) => (
                    <div key={`round-${r}`}>
                      <p className="mb-1.5 flex items-center gap-2 text-[11px] font-bold uppercase tracking-wider text-zinc-400">
                        Round {r + 1}
                        <span className="h-px flex-1 bg-white/10" />
                      </p>
                      <div className="space-y-2">
                        {members.map((exIdx, pos) => {
                          const s = sets[exIdx]?.[r]
                          if (!s) return null
                          return (
                            <SetRow
                              key={`r${r}-${exIdx}`}
                              lead={`${group.label}${pos + 1}`}
                              set={s}
                              onWeight={(v) => updateSet(exIdx, r, { weight: v })}
                              onReps={(v) => updateSet(exIdx, r, { reps: v })}
                              onToggle={() => toggleComplete(exIdx, r)}
                            />
                          )
                        })}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )
        })}

        <button onClick={finish} className="btn-gold w-full">
          <Check className="h-4 w-4" /> Finish Workout
        </button>
      </main>

      {/* Rest timer — sits just above the bottom nav so both stay visible. */}
      {restActive && (
        <div className="fixed inset-x-0 bottom-[4.25rem] z-30 animate-fade-in border-y border-gold/20 bg-ink-900/95 backdrop-blur">
          <div className="container-app py-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="label-eyebrow">Rest</p>
                <p className="heading text-3xl font-bold tabular-nums text-gold">
                  {formatClock(restRemaining)}
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() =>
                    setActiveWorkoutRest(
                      (activeWorkout.restEndsAt ?? Date.now()) + 15000,
                      activeWorkout.restTotal + 15,
                    )
                  }
                  className="btn-ghost"
                >
                  +15s
                </button>
                <button onClick={() => setActiveWorkoutRest(null, 0)} className="btn-gold">
                  <SkipForward className="h-4 w-4" /> Skip
                </button>
              </div>
            </div>
            <div className="mt-3 h-1.5 w-full overflow-hidden rounded-full bg-ink-800">
              <div
                className="h-full bg-gold transition-all duration-1000 ease-linear"
                style={{
                  width: `${activeWorkout.restTotal ? (restRemaining / activeWorkout.restTotal) * 100 : 0}%`,
                }}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

/**
 * One weight/reps/done row, shared by standalone exercises and superset rounds.
 * `lead` is the small badge at the start (a set number like "1" for a normal
 * exercise, or a member tag like "A2" inside a superset round).
 */
function SetRow({
  lead,
  set,
  onWeight,
  onReps,
  onToggle,
}: {
  lead: string
  set: SetLog
  onWeight: (v: number) => void
  onReps: (v: number) => void
  onToggle: () => void
}) {
  const wide = lead.length > 1
  return (
    <div
      className={cn(
        'grid items-center gap-2 rounded-xl border p-2 transition',
        wide ? 'grid-cols-[2.5rem_1fr_1fr_3rem]' : 'grid-cols-[2rem_1fr_1fr_3rem]',
        set.completed ? 'border-gold/40 bg-gold/[0.07]' : 'border-white/5 bg-ink-900',
      )}
    >
      <span
        className={cn(
          'grid h-7 place-items-center rounded-md text-sm font-bold',
          wide ? 'w-10 bg-gold/15 text-xs text-gold' : 'w-7 bg-ink-800 text-zinc-300',
        )}
      >
        {lead}
      </span>
      <NumberField value={set.weight} decimal onChange={onWeight} />
      <NumberField value={set.reps} onChange={onReps} />
      <div className="flex justify-end">
        <button
          onClick={onToggle}
          className={cn(
            'grid h-9 w-9 place-items-center rounded-lg border transition active:scale-95',
            set.completed
              ? 'border-gold bg-gold text-white'
              : 'border-white/15 bg-ink-800 text-zinc-500 hover:border-gold/50',
          )}
          aria-label={set.completed ? 'Mark set incomplete' : 'Mark set complete'}
        >
          <Check className="h-5 w-5" />
        </button>
      </div>
    </div>
  )
}

/**
 * Numeric entry for weight/reps in an active workout. Backed by local text so the
 * box can be cleared to blank (a stored 0 shows as an empty box with a "0"
 * placeholder rather than a literal 0 the user can't erase). No spinner arrows.
 */
function NumberField({
  value,
  onChange,
  decimal = false,
}: {
  value: number
  onChange: (v: number) => void
  decimal?: boolean
}) {
  const [text, setText] = useState(value ? String(value) : '')
  const focused = useRef(false)
  // Sync from the store when the value changes externally and we're not editing.
  useEffect(() => {
    if (!focused.current) setText(value ? String(value) : '')
  }, [value])

  return (
    <input
      type="text"
      inputMode={decimal ? 'decimal' : 'numeric'}
      value={text}
      placeholder="0"
      onFocus={() => {
        focused.current = true
      }}
      onBlur={() => {
        focused.current = false
        setText(value ? String(value) : '')
      }}
      onChange={(e) => {
        const raw = e.target.value
        const pattern = decimal ? /^\d*\.?\d*$/ : /^\d*$/
        if (!pattern.test(raw)) return
        setText(raw)
        onChange(raw === '' || raw === '.' ? 0 : Math.max(0, Number(raw)))
      }}
      className="w-full min-w-0 rounded-lg border border-white/10 bg-ink-850 px-2 py-2 text-center text-sm font-semibold text-zinc-100 outline-none placeholder:text-zinc-600 focus:border-gold/50"
    />
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
      <div className="grid h-20 w-20 place-items-center rounded-full bg-gold text-white shadow-glow animate-fade-in">
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
