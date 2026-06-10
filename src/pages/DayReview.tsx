import { useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Check, Info, Minus, Pencil, Plus, Trash2, X } from 'lucide-react'
import { exerciseLabel, findExerciseByName, getExercise } from '../data/exercises'
import { ExerciseNote, ExerciseNotesButton } from '../components/ExerciseNotesButton'
import { useIsCustomProgram, useProgram, useStore } from '../store'
import { getToken, useAuth } from '../auth'
import { apiUpsertProgram } from '../api'
import type { PlannedExercise, Program, ProgramDay, SetLog, WorkoutLog } from '../types'
import { cn, programLogSlots, resolveProgramDay, uid, withDayOverride } from '../lib/utils'

function buildSets(d: ProgramDay): SetLog[][] {
  return d.exercises.map((pe) =>
    Array.from({ length: pe.sets }, () => ({
      weight: 0,
      reps: parseReps(pe.reps),
      completed: false,
    })),
  )
}

/**
 * View / edit the logged data for a single program day. Reachable by tapping a
 * day card in ProgramDetail. The `dayIndex` URL param is the 0-based global
 * index across weeks (e.g. a 3-day program's Week 2 Day 1 = index 3).
 */
export function DayReview() {
  const { programId, dayIndex: dayIndexParam } = useParams()
  const navigate = useNavigate()
  const program = useProgram(programId)
  const isCustom = useIsCustomProgram(programId)
  const currentUserId = useAuth((s) => s.user?.id)
  const logs = useStore((s) => s.logs)
  const unit = useStore((s) => s.unit)
  const programAnchors = useStore((s) => s.programAnchors)
  const addLog = useStore((s) => s.addLog)
  const deleteLog = useStore((s) => s.deleteLog)
  const updateProgram = useStore((s) => s.updateProgram)

  const globalIdx = Number(dayIndexParam ?? 0)
  const daysLen = program ? Math.max(1, program.days.length) : 1
  const dayLocalIdx = globalIdx % daysLen
  const weekNum = Math.floor(globalIdx / daysLen) + 1
  // Show the plan resolved for the week being viewed (per-week edits apply).
  const day = program ? resolveProgramDay(program, dayLocalIdx, weekNum) : undefined

  const anchor = program ? programAnchors[program.id] : undefined
  // Resolve the log bound to this exact week+day slot (not by chronological
  // position), so viewing/editing a later week's day never reads or overwrites
  // an earlier week's logged data.
  const slots = useMemo(
    () => (program ? programLogSlots(program, logs, anchor) : []),
    [program, logs, anchor],
  )
  const existingLog: WorkoutLog | undefined = slots[globalIdx]

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

  // Day-plan editing (exercises/sets/reps/rest). Saving applies the change from
  // this week onward via a per-week override (Week 1 edits the base plan).
  const [editing, setEditing] = useState(false)
  const [draft, setDraft] = useState<ProgramDay | null>(null)
  const [savingEdit, setSavingEdit] = useState(false)
  const [editError, setEditError] = useState('')

  const isOwner = !program?.ownerId || program.ownerId === currentUserId
  const canEdit = isCustom && (isOwner || !!program?.collaborative)

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
      week: weekNum,
      durationSec: existingLog?.durationSec ?? 0,
      exercises: loggedExercises,
      totalVolume,
    }
    if (existingLog) deleteLog(existingLog.id)
    addLog(log)
    setSaved(true)
  }

  function startEdit() {
    if (!day) return
    // Deep-copy the resolved day so edits don't mutate the live plan until save.
    setDraft({
      ...day,
      exercises: day.exercises.map((e) => ({ ...e })),
    })
    setEditError('')
    setEditing(true)
  }

  function updateDraftExercise(idx: number, patch: Partial<PlannedExercise>) {
    setDraft((prev) =>
      prev
        ? { ...prev, exercises: prev.exercises.map((e, i) => (i === idx ? { ...e, ...patch } : e)) }
        : prev,
    )
  }

  function setDraftExerciseName(idx: number, typed: string, prev: PlannedExercise) {
    const match = findExerciseByName(typed)
    // Only snap to a matched library exercise when there's no trailing space,
    // so typing a space after a complete name doesn't strip the space (which
    // made the spacebar appear broken while renaming).
    if (match && typed === typed.trimEnd()) {
      const keepName = match.id.startsWith('custom-') ? match.name : undefined
      updateDraftExercise(idx, { exerciseId: match.id, name: keepName })
      return
    }
    const id = prev.exerciseId.startsWith('custom-') ? prev.exerciseId : `custom-${uid()}`
    updateDraftExercise(idx, { exerciseId: id, name: typed })
  }

  function addDraftExercise() {
    setDraft((prev) =>
      prev
        ? {
            ...prev,
            exercises: [
              ...prev.exercises,
              { exerciseId: `custom-${uid()}`, name: '', sets: 3, reps: '10', restSec: 90 },
            ],
          }
        : prev,
    )
  }

  function removeDraftExercise(idx: number) {
    setDraft((prev) =>
      prev ? { ...prev, exercises: prev.exercises.filter((_, i) => i !== idx) } : prev,
    )
  }

  async function saveEdit() {
    if (!program || !day || !draft) return
    if (draft.exercises.length === 0) {
      setEditError('Add at least one exercise.')
      return
    }
    const blank = draft.exercises.find((e) => !e.name?.trim() && !getExercise(e.exerciseId))
    if (blank) {
      setEditError('Name every exercise.')
      return
    }
    setSavingEdit(true)
    const updated: Program = withDayOverride(program, day.id, weekNum, draft)
    updateProgram(updated)
    const token = getToken()
    if (token) await apiUpsertProgram<Program>(token, updated)
    // Refresh the logging template to match the new plan.
    setSets(buildSets(draft))
    setSaved(false)
    setSavingEdit(false)
    setEditing(false)
    setDraft(null)
  }

  const hasCompleted = sets.flat().some((s) => s.completed)

  return (
    <div className="animate-fade-in space-y-5">
      {/* Back arrow — icon only. Pop the history entry we came from (the program
          detail) instead of pushing a fresh one, otherwise tapping Back on the
          detail page would land back here and create a loop. Fall back to the
          program detail when there's no in-app history (e.g. a deep link). */}
      <button
        onClick={() => {
          const idx = (window.history.state as { idx?: number } | null)?.idx ?? 0
          if (idx > 0) navigate(-1)
          else navigate(`/programs/${program.id}`)
        }}
        className="grid h-9 w-9 place-items-center rounded-lg bg-ink-850 text-zinc-400 hover:text-zinc-100"
        aria-label="Back to program"
      >
        <ArrowLeft className="h-5 w-5" />
      </button>

      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <span className="label-eyebrow" style={{ color: program.accent }}>
            Week {weekNum} · Day {dayLocalIdx + 1}
          </span>
          <h1 className="heading text-2xl font-bold text-zinc-50">{day.name}</h1>
          {day.focus && <p className="mt-0.5 text-xs text-zinc-400">{day.focus}</p>}
        </div>
        {canEdit && !editing && (
          <button
            onClick={startEdit}
            className="inline-flex shrink-0 items-center gap-1.5 rounded-lg bg-ink-850 px-3 py-2 text-xs font-medium text-zinc-300 hover:text-zinc-100"
            style={{ color: program.accent }}
            aria-label="Edit this day"
          >
            <Pencil className="h-3.5 w-3.5" /> Edit this day
          </button>
        )}
      </div>

      {editing && draft && (
        <div className="card space-y-3 p-5">
          <div>
            <h2 className="heading text-lg font-bold text-zinc-50">Edit this day</h2>
            <p className="mt-0.5 text-xs text-zinc-400">
              {weekNum <= 1
                ? 'Changes apply to the whole program.'
                : `Changes apply from Week ${weekNum} onward. Earlier weeks keep the current plan.`}
            </p>
          </div>
          {draft.exercises.map((pe, exIdx) => {
            const ex = getExercise(pe.exerciseId)
            return (
              <div key={exIdx} className="rounded-xl border border-white/5 bg-ink-900 p-3">
                <div className="flex items-center gap-2">
                  <input
                    value={pe.name ?? ex?.name ?? ''}
                    onChange={(e) => setDraftExerciseName(exIdx, e.target.value, pe)}
                    placeholder="Type an exercise name"
                    className="input flex-1"
                  />
                  <button
                    onClick={() => removeDraftExercise(exIdx)}
                    disabled={draft.exercises.length === 1}
                    className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-500 hover:text-red-400 disabled:opacity-40"
                    aria-label="Remove exercise"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
                <p className="mt-1 px-1 text-[11px] text-zinc-500">
                  {ex ? `${ex.primaryMuscle} · ${ex.equipment}` : 'Custom exercise'}
                </p>
                <div className="mt-2 grid grid-cols-3 gap-2">
                  <EditNumField
                    label="Sets"
                    value={pe.sets}
                    onChange={(v) => updateDraftExercise(exIdx, { sets: v })}
                  />
                  <EditTextField
                    label="Reps"
                    value={pe.reps}
                    onChange={(v) => updateDraftExercise(exIdx, { reps: v })}
                  />
                  <EditNumField
                    label="Rest s"
                    value={pe.restSec}
                    onChange={(v) => updateDraftExercise(exIdx, { restSec: v })}
                  />
                </div>
              </div>
            )
          })}
          <button
            onClick={addDraftExercise}
            className="btn-outline w-full border-dashed py-2 text-xs"
          >
            <Plus className="h-3.5 w-3.5" /> Add exercise
          </button>
          {editError && (
            <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{editError}</p>
          )}
          <div className="flex gap-2">
            <button
              onClick={() => {
                setEditing(false)
                setDraft(null)
                setEditError('')
              }}
              className="btn-ghost flex-1"
            >
              <X className="h-4 w-4" /> Cancel
            </button>
            <button
              onClick={() => void saveEdit()}
              disabled={savingEdit}
              className="btn-gold flex-1 disabled:opacity-60"
            >
              {savingEdit ? 'Saving…' : 'Save day'}
            </button>
          </div>
        </div>
      )}

      {!editing && day.exercises.map((pe, exIdx) => {
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
              <div className="flex shrink-0 items-center gap-2">
                <ExerciseNotesButton exerciseId={pe.exerciseId} label={exerciseLabel(pe)} />
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
            </div>

            <ExerciseNote exerciseId={pe.exerciseId} />

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

      {!editing && hasCompleted && (
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

function EditNumField({
  label,
  value,
  onChange,
}: {
  label: string
  value: number
  onChange: (v: number) => void
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-[10px] font-semibold uppercase tracking-wider text-zinc-500">
        {label}
      </span>
      <input
        type="text"
        inputMode="numeric"
        value={value}
        onChange={(e) => {
          const raw = e.target.value.replace(/[^0-9]/g, '')
          onChange(raw === '' ? 0 : Math.max(0, Number(raw)))
        }}
        className="input px-2 py-2 text-center text-base"
      />
    </label>
  )
}

function EditTextField({
  label,
  value,
  onChange,
}: {
  label: string
  value: string
  onChange: (v: string) => void
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-[10px] font-semibold uppercase tracking-wider text-zinc-500">
        {label}
      </span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="input px-2 py-2 text-center text-base"
      />
    </label>
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
