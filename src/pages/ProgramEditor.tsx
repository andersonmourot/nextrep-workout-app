import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, GripVertical, Plus, Trash2 } from 'lucide-react'
import { EXERCISES, findExerciseByName, getExercise } from '../data/exercises'
import { useProgram, useStore } from '../store'
import { apiUpsertProgram } from '../api'
import { getToken, useAuth } from '../auth'
import type {
  Difficulty,
  PlannedExercise,
  Program,
  ProgramCategory,
  ProgramDay,
} from '../types'
import { cn, uid } from '../lib/utils'

const CATEGORIES: ProgramCategory[] = [
  'Bodybuilding',
  'Strength',
  'HIIT',
  'Powerlifting',
  'Functional',
  'Bodyweight',
]
const LEVELS: Difficulty[] = ['Beginner', 'Intermediate', 'Advanced']
const ACCENTS = ['#e9b949', '#b91c1c', '#3b82f6', '#22c55e', '#a855f7', '#f97316', '#14b8a6', '#ec4899']

function blankExercise(): PlannedExercise {
  const ex = EXERCISES[0]
  return { exerciseId: ex.id, sets: 3, reps: '8-12', tempo: ex.tempo, restSec: 90 }
}

function blankDay(n: number): ProgramDay {
  return { id: uid(), name: `Day ${n}`, focus: '', exercises: [blankExercise()] }
}

export function ProgramEditor() {
  const navigate = useNavigate()
  const { programId } = useParams()
  const existing = useProgram(programId)
  const isEdit = !!programId
  const { addProgram, updateProgram } = useStore()

  const [name, setName] = useState(existing?.name ?? '')
  const [category, setCategory] = useState<ProgramCategory>(existing?.category ?? 'Bodybuilding')
  const [level, setLevel] = useState<Difficulty>(existing?.level ?? 'Beginner')
  const [goal, setGoal] = useState(existing?.goal ?? '')
  const [coach, setCoach] = useState(existing?.coach ?? 'You')
  const [durationWeeks, setDurationWeeks] = useState(existing?.durationWeeks ?? 4)
  const [daysPerWeek, setDaysPerWeek] = useState(existing?.daysPerWeek ?? 4)
  const [accent, setAccent] = useState(existing?.accent ?? ACCENTS[0])
  const [summary, setSummary] = useState(existing?.summary ?? '')
  const [description, setDescription] = useState(existing?.description ?? '')
  const [tags, setTags] = useState((existing?.tags ?? []).join(', '))
  const [collaborative, setCollaborative] = useState(existing?.collaborative ?? false)
  const [days, setDays] = useState<ProgramDay[]>(existing?.days ?? [blankDay(1)])
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  const currentUserId = useAuth((s) => s.user?.id)
  const currentUserName = useAuth((s) => s.user?.name)
  // You're the owner of a brand-new program, or of one with no recorded owner
  // (legacy), or one you created. Only the owner may toggle collaboration.
  const isOwner = !existing?.ownerId || existing.ownerId === currentUserId

  function updateDay(dayIdx: number, patch: Partial<ProgramDay>) {
    setDays((prev) => prev.map((d, i) => (i === dayIdx ? { ...d, ...patch } : d)))
  }

  function setExerciseName(dayIdx: number, exIdx: number, typed: string, prev: PlannedExercise) {
    const match = findExerciseByName(typed)
    if (match) {
      updateExercise(dayIdx, exIdx, { exerciseId: match.id, name: undefined, tempo: match.tempo })
      return
    }
    const id = prev.exerciseId.startsWith('custom-') ? prev.exerciseId : `custom-${uid()}`
    updateExercise(dayIdx, exIdx, { exerciseId: id, name: typed })
  }

  function updateExercise(dayIdx: number, exIdx: number, patch: Partial<PlannedExercise>) {
    setDays((prev) =>
      prev.map((d, i) =>
        i === dayIdx
          ? { ...d, exercises: d.exercises.map((e, j) => (j === exIdx ? { ...e, ...patch } : e)) }
          : d,
      ),
    )
  }

  function addExercise(dayIdx: number) {
    setDays((prev) =>
      prev.map((d, i) => (i === dayIdx ? { ...d, exercises: [...d.exercises, blankExercise()] } : d)),
    )
  }

  function removeExercise(dayIdx: number, exIdx: number) {
    setDays((prev) =>
      prev.map((d, i) =>
        i === dayIdx ? { ...d, exercises: d.exercises.filter((_, j) => j !== exIdx) } : d,
      ),
    )
  }

  function addDay() {
    setDays((prev) => [...prev, blankDay(prev.length + 1)])
  }

  function removeDay(dayIdx: number) {
    setDays((prev) => prev.filter((_, i) => i !== dayIdx))
  }

  async function save() {
    if (!name.trim()) return setError('Give your program a name.')
    if (days.length === 0) return setError('Add at least one training day.')
    for (const d of days) {
      if (d.exercises.length === 0) return setError(`"${d.name}" needs at least one exercise.`)
    }

    const program: Program = {
      id: existing?.id ?? `custom-${uid()}`,
      name: name.trim(),
      category,
      level,
      goal: goal.trim() || 'Custom training',
      coach: coach.trim() || 'You',
      durationWeeks: Math.max(1, durationWeeks),
      daysPerWeek: Math.max(1, daysPerWeek),
      accent,
      summary: summary.trim() || `${category} program · ${days.length} days`,
      description:
        description.trim() ||
        `A custom ${level.toLowerCase()} ${category.toLowerCase()} program with ${days.length} training days.`,
      tags: tags
        .split(',')
        .map((t) => t.trim())
        .filter(Boolean),
      days: days.map((d) => ({ ...d, name: d.name.trim() || 'Day', focus: d.focus.trim() })),
      ownerId: existing?.ownerId ?? currentUserId,
      ownerName: existing?.ownerName ?? currentUserName ?? coach.trim() ?? 'You',
      // Owner controls the flag; collaborators keep the existing setting.
      collaborative: isOwner ? collaborative : existing?.collaborative,
      version: Date.now(),
    }

    // Persist locally first so the UI is responsive even if the network is slow.
    if (isEdit && existing) updateProgram(program)
    else addProgram(program)

    // Publish to the shared store so edits propagate to every account that has
    // this program. Use the canonical copy the server returns (authoritative
    // owner/version) when available.
    setSaving(true)
    const token = getToken()
    if (token) {
      const res = await apiUpsertProgram<Program>(token, program)
      if (res.ok && res.data) updateProgram(res.data.program)
    }
    setSaving(false)

    // After creating or editing, go to the full Programs list (replace so Back
    // returns to the list, not the editor).
    navigate('/programs', { replace: true })
  }

  if (isEdit && !existing) {
    return (
      <div className="animate-fade-in py-10 text-center">
        <p className="text-zinc-400">Program not found.</p>
        <Link to="/programs" className="btn-outline mt-4">
          Back to Programs
        </Link>
      </div>
    )
  }

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div>
        <p className="label-eyebrow">{isEdit ? 'Edit program' : 'Build your own'}</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">
          {isEdit ? 'Edit Program' : 'Create Program'}
        </h1>
      </div>

      {/* Basics */}
      <section className="card space-y-4 p-5">
        <Field label="Program name">
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. My Push/Pull/Legs"
            className="input"
          />
        </Field>

        <div className="grid grid-cols-2 gap-3">
          <Field label="Category">
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value as ProgramCategory)}
              className="input"
            >
              {CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Level">
            <select
              value={level}
              onChange={(e) => setLevel(e.target.value as Difficulty)}
              className="input"
            >
              {LEVELS.map((l) => (
                <option key={l} value={l}>
                  {l}
                </option>
              ))}
            </select>
          </Field>
        </div>

        <Field label="Goal">
          <input
            value={goal}
            onChange={(e) => setGoal(e.target.value)}
            placeholder="e.g. Build muscle"
            className="input"
          />
        </Field>

        <div className="grid grid-cols-3 gap-3">
          <Field label="Weeks">
            <input
              type="text"
              inputMode="numeric"
              value={durationWeeks}
              onChange={(e) => {
                const raw = e.target.value.replace(/[^0-9]/g, '')
                setDurationWeeks(raw === '' ? 0 : Number(raw))
              }}
              className="input"
            />
          </Field>
          <Field label="Days / week">
            <input
              type="text"
              inputMode="numeric"
              value={daysPerWeek}
              onChange={(e) => {
                const raw = e.target.value.replace(/[^0-9]/g, '')
                setDaysPerWeek(raw === '' ? 0 : Number(raw))
              }}
              className="input"
            />
          </Field>
          <Field label="Coach">
            <input value={coach} onChange={(e) => setCoach(e.target.value)} className="input" />
          </Field>
        </div>

        <Field label="Accent color">
          <div className="flex flex-wrap gap-2">
            {ACCENTS.map((c) => (
              <button
                key={c}
                type="button"
                onClick={() => setAccent(c)}
                className={cn(
                  'h-8 w-8 rounded-full border-2 transition',
                  accent === c ? 'border-white' : 'border-transparent',
                )}
                style={{ background: c }}
                aria-label={`Accent ${c}`}
              />
            ))}
          </div>
        </Field>

        <Field label="Summary (short)">
          <input
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            placeholder="One-line description"
            className="input"
          />
        </Field>

        <Field label="Description">
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="What is this program about?"
            rows={3}
            className="input resize-none"
          />
        </Field>

        <Field label="Tags (comma separated)">
          <input
            value={tags}
            onChange={(e) => setTags(e.target.value)}
            placeholder="Hypertrophy, Split, Gym"
            className="input"
          />
        </Field>

        <Field label="Collaborative">
          <div className="flex gap-2">
            <button
              type="button"
              disabled={!isOwner}
              onClick={() => setCollaborative(true)}
              className={cn(
                'flex-1 rounded-lg border px-3 py-2 text-sm font-semibold transition disabled:opacity-50',
                collaborative
                  ? 'border-gold bg-gold/15 text-gold'
                  : 'border-white/10 bg-ink-850 text-zinc-300 hover:border-white/30',
              )}
            >
              Yes
            </button>
            <button
              type="button"
              disabled={!isOwner}
              onClick={() => setCollaborative(false)}
              className={cn(
                'flex-1 rounded-lg border px-3 py-2 text-sm font-semibold transition disabled:opacity-50',
                !collaborative
                  ? 'border-gold bg-gold/15 text-gold'
                  : 'border-white/10 bg-ink-850 text-zinc-300 hover:border-white/30',
              )}
            >
              No
            </button>
          </div>
          <p className="mt-1.5 text-xs text-zinc-500">
            {collaborative
              ? 'Anyone who adds this program can edit it. Edits apply to everyone who has it.'
              : 'Only you can edit this program. Your edits apply to everyone who has it.'}
            {!isOwner && ' Only the original creator can change this setting.'}
          </p>
        </Field>
      </section>

      {/* Days */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="heading text-sm font-semibold tracking-wider text-zinc-300">
            Training Days · {days.length}
          </h2>
        </div>

        {days.map((day, dayIdx) => (
          <div key={day.id} className="card p-4">
            <div className="flex items-start gap-2">
              <GripVertical className="mt-2 h-4 w-4 shrink-0 text-zinc-600" />
              <div className="grid flex-1 grid-cols-2 gap-2">
                <input
                  value={day.name}
                  onChange={(e) => updateDay(dayIdx, { name: e.target.value })}
                  placeholder="Day name"
                  className="input"
                />
                <input
                  value={day.focus}
                  onChange={(e) => updateDay(dayIdx, { focus: e.target.value })}
                  placeholder="Focus (e.g. Chest · Triceps)"
                  className="input"
                />
              </div>
              <button
                onClick={() => removeDay(dayIdx)}
                disabled={days.length === 1}
                className="mt-1 grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-500 hover:text-red-400 disabled:opacity-40"
                aria-label="Remove day"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>

            <div className="mt-3 space-y-2">
              {day.exercises.map((pe, exIdx) => {
                const ex = getExercise(pe.exerciseId)
                return (
                  <div key={exIdx} className="rounded-xl border border-white/5 bg-ink-900 p-3">
                    <div className="flex items-center gap-2">
                      <input
                        value={pe.name ?? ex?.name ?? ''}
                        onChange={(e) => setExerciseName(dayIdx, exIdx, e.target.value, pe)}
                        placeholder="Type an exercise name"
                        className="input flex-1"
                      />
                      <button
                        onClick={() => removeExercise(dayIdx, exIdx)}
                        disabled={day.exercises.length === 1}
                        className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-500 hover:text-red-400 disabled:opacity-40"
                        aria-label="Remove exercise"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                    <p className="mt-1 px-1 text-[11px] text-zinc-500">
                      {ex ? `${ex.primaryMuscle} · ${ex.equipment}` : 'Custom exercise'}
                    </p>
                    <div className="mt-2 grid grid-cols-4 gap-2">
                      <NumField
                        label="Sets"
                        value={pe.sets}
                        onChange={(v) => updateExercise(dayIdx, exIdx, { sets: v })}
                      />
                      <TextField
                        label="Reps"
                        value={pe.reps}
                        onChange={(v) => updateExercise(dayIdx, exIdx, { reps: v })}
                      />
                      <TextField
                        label="Tempo"
                        value={pe.tempo}
                        onChange={(v) => updateExercise(dayIdx, exIdx, { tempo: v })}
                      />
                      <NumField
                        label="Rest s"
                        value={pe.restSec}
                        onChange={(v) => updateExercise(dayIdx, exIdx, { restSec: v })}
                      />
                    </div>
                  </div>
                )
              })}
              <button
                onClick={() => addExercise(dayIdx)}
                className="btn-outline w-full border-dashed py-2 text-xs"
              >
                <Plus className="h-3.5 w-3.5" /> Add exercise
              </button>
            </div>
          </div>
        ))}

        <button onClick={addDay} className="btn-outline w-full border-dashed">
          <Plus className="h-4 w-4" /> Add training day
        </button>
      </section>

      {error && (
        <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{error}</p>
      )}

      <div className="sticky bottom-20 flex gap-2">
        <button onClick={() => navigate(-1)} className="btn-ghost flex-1">
          Cancel
        </button>
        <button onClick={() => void save()} disabled={saving} className="btn-gold flex-1 disabled:opacity-60">
          {saving ? 'Saving…' : isEdit ? 'Save Changes' : 'Create Program'}
        </button>
      </div>
    </div>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-sm font-medium text-zinc-300">{label}</span>
      {children}
    </label>
  )
}

function NumField({
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
        // text + numeric inputmode keeps the numeric keypad but drops the
        // up/down spinner arrows that `type="number"` adds.
        type="text"
        inputMode="numeric"
        value={value}
        onChange={(e) => {
          const raw = e.target.value.replace(/[^0-9]/g, '')
          onChange(raw === '' ? 0 : Math.max(0, Number(raw)))
        }}
        className="input px-2 py-2 text-center text-sm"
      />
    </label>
  )
}

function TextField({
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
        className="input px-2 py-2 text-center text-sm"
      />
    </label>
  )
}
