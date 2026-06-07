import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, Calendar, ChevronRight, Dumbbell, Trash2 } from 'lucide-react'
import { exerciseLabel, getExercise } from '../data/exercises'
import { useStore } from '../store'
import type { CompletedProgram, PlannedExercise } from '../types'
import { accentVars } from '../lib/theme'
import { formatDateLong } from '../lib/utils'

/**
 * Program History — an archive of fully completed programs. Each entry keeps a
 * snapshot of the program plus every workout logged during the run, so the user
 * can look back at the weights and reps they did on any day of a past program.
 */
export function ProgramHistory() {
  const completedPrograms = useStore((s) => s.completedPrograms)
  const removeCompletedProgram = useStore((s) => s.removeCompletedProgram)
  const unit = useStore((s) => s.unit)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [confirmId, setConfirmId] = useState<string | null>(null)

  const sorted = useMemo(
    () =>
      [...completedPrograms].sort((a, b) => (a.completedAt < b.completedAt ? 1 : -1)),
    [completedPrograms],
  )
  const selected = sorted.find((c) => c.id === selectedId) ?? null

  if (selected) {
    return <CompletedDetail entry={selected} unit={unit} onBack={() => setSelectedId(null)} />
  }

  return (
    <div className="animate-fade-in space-y-5">
      <Link
        to="/programs"
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </Link>
      <div>
        <h1 className="heading text-3xl font-bold text-zinc-50">Program History</h1>
        <p className="mt-1 text-sm text-zinc-400">
          Completed programs are saved here.
        </p>
      </div>

      {sorted.length === 0 ? (
        <div className="card p-8 text-center">
          <Dumbbell className="mx-auto h-8 w-8 text-zinc-600" />
          <p className="mt-3 text-sm text-zinc-400">No completed programs yet.</p>
          <p className="mt-1 text-xs text-zinc-500">
            Finish every week of a program and it'll be archived here.
          </p>
        </div>
      ) : (
        <ul className="space-y-3">
          {sorted.map((c) => (
            <li key={c.id} className="relative">
              <button
                onClick={() => setSelectedId(c.id)}
                className="card flex w-full items-center gap-3 p-5 text-left"
                style={{
                  background: `linear-gradient(150deg, ${c.accent}1f, transparent 60%)`,
                }}
              >
                <div className="min-w-0 flex-1">
                  <span className="label-eyebrow" style={{ color: c.accent }}>
                    Completed
                  </span>
                  <h2 className="heading text-xl font-bold text-zinc-50">{c.name}</h2>
                  <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-zinc-400">
                    <span className="inline-flex items-center gap-1">
                      <Calendar className="h-3.5 w-3.5" /> {formatDateLong(c.completedAt)}
                    </span>
                    <span className="inline-flex items-center gap-1">
                      <Dumbbell className="h-3.5 w-3.5" /> {c.durationWeeks} weeks ·{' '}
                      {c.logs.length} workouts
                    </span>
                  </div>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-zinc-500" />
              </button>
              {confirmId === c.id ? (
                <div className="absolute right-2 top-2 flex items-center gap-1.5 rounded-lg border border-white/10 bg-ink-800 px-2 py-1.5 shadow-lg">
                  <button
                    onClick={() => setConfirmId(null)}
                    className="rounded-lg px-2 py-1 text-xs text-zinc-300 hover:text-zinc-100"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => {
                      removeCompletedProgram(c.id)
                      setConfirmId(null)
                    }}
                    className="rounded-lg bg-red-500/15 px-2 py-1 text-xs font-semibold text-red-300"
                  >
                    Delete
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setConfirmId(c.id)}
                  aria-label="Remove from history"
                  className="absolute right-2 top-2 grid h-8 w-8 place-items-center rounded-lg bg-ink-800/80 text-zinc-500 hover:text-red-400"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function CompletedDetail({
  entry,
  unit,
  onBack,
}: {
  entry: CompletedProgram
  unit: string
  onBack: () => void
}) {
  const daysLen = Math.max(1, entry.program.days.length)
  // Build a label lookup from the program's planned exercises (covers custom
  // names not in the library), falling back to the built-in library.
  const labels = useMemo(() => {
    const map = new Map<string, string>()
    const addDay = (exs: PlannedExercise[]) => {
      for (const pe of exs) if (!map.has(pe.exerciseId)) map.set(pe.exerciseId, exerciseLabel(pe))
    }
    entry.program.days.forEach((d) => addDay(d.exercises))
    Object.values(entry.program.weekOverrides ?? {}).forEach((list) =>
      list.forEach((o) => addDay(o.day.exercises)),
    )
    return map
  }, [entry])

  const labelFor = (exerciseId: string) =>
    labels.get(exerciseId) ?? getExercise(exerciseId)?.name ?? 'Exercise'

  return (
    <div className="animate-fade-in space-y-5" style={accentVars(entry.accent)}>
      <button
        onClick={onBack}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>
      <div>
        <span className="label-eyebrow" style={{ color: entry.accent }}>
          Completed · {formatDateLong(entry.completedAt)}
        </span>
        <h1 className="heading text-2xl font-bold text-zinc-50">{entry.name}</h1>
        <p className="mt-0.5 text-xs text-zinc-400">
          {entry.durationWeeks} weeks · {entry.logs.length} workouts logged
        </p>
      </div>

      {entry.logs.map((log, i) => {
        // Prefer the log's bound week; fall back to its position for legacy data.
        const dayLocalIdx = entry.program.days.findIndex((d) => d.id === log.dayId)
        const weekNum = log.week ?? Math.floor(i / daysLen) + 1
        const dayNum = (dayLocalIdx >= 0 ? dayLocalIdx : i % daysLen) + 1
        return (
          <div key={log.id} className="card p-5">
            <div className="flex items-baseline justify-between gap-2">
              <span className="label-eyebrow" style={{ color: entry.accent }}>
                Week {weekNum} · Day {dayNum}
              </span>
              <span className="text-[11px] text-zinc-500">{formatDateLong(log.date)}</span>
            </div>
            <h2 className="heading text-lg font-bold text-zinc-50">{log.dayName}</h2>
            <div className="mt-3 space-y-3">
              {log.exercises.length === 0 ? (
                <p className="text-sm text-zinc-500">No sets logged.</p>
              ) : (
                log.exercises.map((le, j) => (
                  <div key={`${le.exerciseId}-${j}`}>
                    <p className="text-sm font-semibold text-zinc-200">{labelFor(le.exerciseId)}</p>
                    <div className="mt-1 flex flex-wrap gap-1.5">
                      {le.sets.length === 0 ? (
                        <span className="text-xs text-zinc-500">—</span>
                      ) : (
                        le.sets.map((s, k) => (
                          <span
                            key={k}
                            className="rounded-md bg-ink-850 px-2 py-1 text-xs font-medium text-zinc-300"
                          >
                            {s.weight}
                            {unit} × {s.reps}
                          </span>
                        ))
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
