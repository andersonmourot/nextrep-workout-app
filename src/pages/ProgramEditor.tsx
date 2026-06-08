import { useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
  ArrowLeft,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  Copy,
  Plus,
  Trash2,
} from 'lucide-react'
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
  // Start blank so the name box is empty until the user types an exercise.
  return { exerciseId: `custom-${uid()}`, name: '', sets: 3, reps: '10', restSec: 90 }
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
  const [overrides, setOverrides] = useState<
    Record<string, { fromWeek: number; day: ProgramDay }[]>
  >(existing?.weekOverrides ?? {})
  const [weekRaw, setWeek] = useState(1)
  const [collapsedDays, setCollapsedDays] = useState<Record<string, boolean>>({})
  const [applyConfirm, setApplyConfirm] = useState(false)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  const currentUserId = useAuth((s) => s.user?.id)
  const currentUserName = useAuth((s) => s.user?.name)
  // You're the owner of a brand-new program, or of one with no recorded owner
  // (legacy), or one you created. Only the owner may toggle collaboration.
  const isOwner = !existing?.ownerId || existing.ownerId === currentUserId

  const totalWeeks = Math.max(1, durationWeeks || 1)
  // Clamp to the current program length: shrinking the Weeks field shouldn't
  // leave you on a week that no longer exists.
  const week = Math.min(Math.max(1, weekRaw), totalWeeks)

  // The day plans shown for the selected week: Week 1 is the base plan; later
  // weeks apply any per-week-onward override for that day (falling back to base).
  const viewDays = useMemo(
    () =>
      days.map((base) => {
        const list = overrides[base.id]
        if (!list || list.length === 0) return base
        let chosen: ProgramDay | undefined
        let best = 0
        for (const o of list) {
          if (o.fromWeek <= week && o.fromWeek > best) {
            best = o.fromWeek
            chosen = o.day
          }
        }
        return chosen ?? base
      }),
    [days, overrides, week],
  )

  // Persist an edited day for the selected week. Week 1 rewrites the base plan;
  // later weeks store a per-week-onward override keyed by the base day id.
  function commitDay(dayIdx: number, day: ProgramDay) {
    if (week <= 1) {
      setDays((prev) => prev.map((d, i) => (i === dayIdx ? day : d)))
      return
    }
    const baseId = days[dayIdx].id
    const normalized: ProgramDay = { ...day, id: baseId }
    setOverrides((prev) => {
      const next = { ...prev }
      const list = (next[baseId] ?? []).filter((o) => o.fromWeek !== week)
      list.push({ fromWeek: week, day: normalized })
      list.sort((a, b) => a.fromWeek - b.fromWeek)
      next[baseId] = list
      return next
    })
  }

  function updateDay(dayIdx: number, patch: Partial<ProgramDay>) {
    commitDay(dayIdx, { ...viewDays[dayIdx], ...patch })
  }

  function setExerciseName(dayIdx: number, exIdx: number, typed: string, prev: PlannedExercise) {
    const match = findExerciseByName(typed)
    if (match) {
      // Built-ins resolve by id on every device, so leave name undefined (lets
      // overrides apply). For custom exercises, store the name so the program
      // stays self-contained when shared — followers who lack the creator's
      // custom library still see the real name, not the raw "custom-..." id.
      const keepName = match.id.startsWith('custom-') ? match.name : undefined
      updateExercise(dayIdx, exIdx, { exerciseId: match.id, name: keepName })
      return
    }
    const id = prev.exerciseId.startsWith('custom-') ? prev.exerciseId : `custom-${uid()}`
    updateExercise(dayIdx, exIdx, { exerciseId: id, name: typed })
  }

  function updateExercise(dayIdx: number, exIdx: number, patch: Partial<PlannedExercise>) {
    const d = viewDays[dayIdx]
    commitDay(dayIdx, {
      ...d,
      exercises: d.exercises.map((e, j) => (j === exIdx ? { ...e, ...patch } : e)),
    })
  }

  function addExercise(dayIdx: number) {
    const d = viewDays[dayIdx]
    commitDay(dayIdx, { ...d, exercises: [...d.exercises, blankExercise()] })
  }

  function removeExercise(dayIdx: number, exIdx: number) {
    const d = viewDays[dayIdx]
    commitDay(dayIdx, { ...d, exercises: d.exercises.filter((_, j) => j !== exIdx) })
  }

  // Structural changes (number of training days) only apply to the base plan
  // (Week 1) so every week keeps the same day slots.
  function addDay() {
    setDays((prev) => [...prev, blankDay(prev.length + 1)])
  }

  function removeDay(dayIdx: number) {
    const id = days[dayIdx].id
    setDays((prev) => prev.filter((_, i) => i !== dayIdx))
    setOverrides((prev) => {
      const next = { ...prev }
      delete next[id]
      return next
    })
  }

  // Copy the currently-viewed week's plan to every week: it becomes the new base
  // and all per-week overrides are cleared, so all weeks match.
  function applyToAllWeeks() {
    setDays(viewDays.map((d) => ({ ...d, exercises: d.exercises.map((e) => ({ ...e })) })))
    setOverrides({})
    setApplyConfirm(false)
    setWeek(1)
  }

  async function save() {
    if (!name.trim()) return setError('Give your program a name.')
    if (days.length === 0) return setError('Add at least one training day.')
    for (const d of days) {
      if (d.exercises.length === 0) return setError(`"${d.name}" needs at least one exercise.`)
      const blank = d.exercises.find((e) => !e.name?.trim() && !getExercise(e.exerciseId))
      if (blank) return setError(`Name every exercise in "${d.name}".`)
    }
    for (const list of Object.values(overrides)) {
      for (const o of list) {
        if (o.day.exercises.length === 0)
          return setError(`Week ${o.fromWeek}'s "${o.day.name}" needs at least one exercise.`)
        const blank = o.day.exercises.find((e) => !e.name?.trim() && !getExercise(e.exerciseId))
        if (blank) return setError(`Name every exercise in Week ${o.fromWeek}'s "${o.day.name}".`)
      }
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
      weekOverrides: Object.keys(overrides).length ? overrides : undefined,
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

    // After editing, go back to that program's detail page; after creating a
    // new program, go to the main list. Replace so Back doesn't re-open the editor.
    navigate(isEdit ? `/programs/${program.id}` : '/programs', { replace: true })
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

        {totalWeeks > 1 && (
          <div className="rounded-xl border border-white/5 bg-ink-900 p-3 text-center">
            {/* Stacked & centered: week stepper on top, info in the middle,
                full-width copy button beneath. */}
            <div className="flex items-center justify-center gap-2">
              <button
                type="button"
                onClick={() => setWeek((w) => Math.max(1, w - 1))}
                disabled={week <= 1}
                aria-label="Previous week"
                className="grid h-8 w-8 place-items-center rounded-lg bg-ink-850 text-zinc-300 disabled:opacity-40"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <span className="min-w-[6.5rem] text-center text-sm font-semibold text-zinc-200">
                Week {week} / {totalWeeks}
              </span>
              <button
                type="button"
                onClick={() => setWeek((w) => Math.min(totalWeeks, w + 1))}
                disabled={week >= totalWeeks}
                aria-label="Next week"
                className="grid h-8 w-8 place-items-center rounded-lg bg-ink-850 text-zinc-300 disabled:opacity-40"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>

            <p className="mt-3 text-xs text-zinc-400">
              {week === 1
                ? 'Editing Week 1 — the base plan. It applies to every week you haven’t edited individually.'
                : `Editing Week ${week}. Changes apply from Week ${week} onward; earlier weeks keep their plan.`}
            </p>

            {applyConfirm ? (
              <div className="mt-3 flex items-center justify-center gap-2">
                <button
                  type="button"
                  onClick={applyToAllWeeks}
                  className="btn-gold flex-1 justify-center px-3 py-2 text-xs"
                >
                  Confirm
                </button>
                <button
                  type="button"
                  onClick={() => setApplyConfirm(false)}
                  className="btn-ghost flex-1 justify-center px-3 py-2 text-xs"
                >
                  Cancel
                </button>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => setApplyConfirm(true)}
                className="btn-gold mt-3 inline-flex w-full items-center justify-center gap-1.5 px-3 py-2 text-xs"
              >
                <Copy className="h-3.5 w-3.5" /> Copy Week {week} to all weeks
              </button>
            )}
          </div>
        )}

        {viewDays.map((day, dayIdx) => {
          const collapsed = !!collapsedDays[day.id]
          return (
          <div key={day.id} className="card p-4">
            <div className="flex items-start gap-2">
              <button
                type="button"
                onClick={() =>
                  setCollapsedDays((c) => ({ ...c, [day.id]: !c[day.id] }))
                }
                className="mt-1 grid h-9 w-9 shrink-0 place-items-center rounded-lg text-zinc-400 hover:text-zinc-100"
                aria-label={collapsed ? 'Expand day' : 'Collapse day'}
              >
                {collapsed ? (
                  <ChevronDown className="h-4 w-4" />
                ) : (
                  <ChevronUp className="h-4 w-4" />
                )}
              </button>
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
                disabled={days.length === 1 || week > 1}
                className="mt-1 grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-500 hover:text-red-400 disabled:opacity-40"
                aria-label="Remove day"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>

            {!collapsed && (
            <div className="mt-3 space-y-2">
              {day.exercises.map((pe, exIdx) => {
                const ex = getExercise(pe.exerciseId)
                return (
                  <div key={exIdx} className="rounded-xl border border-white/5 bg-ink-900 p-3">
                    <div className="flex items-center gap-2">
                      <ExerciseNameInput
                        value={pe.name ?? ex?.name ?? ''}
                        onType={(typed) => setExerciseName(dayIdx, exIdx, typed, pe)}
                        placeholder="Type an exercise name"
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
                    <div className="mt-2 grid grid-cols-3 gap-2">
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
            )}
          </div>
          )
        })}

        {week === 1 ? (
          <button onClick={addDay} className="btn-outline w-full border-dashed">
            <Plus className="h-4 w-4" /> Add training day
          </button>
        ) : (
          <p className="text-center text-xs text-zinc-500">
            Switch to Week 1 to add or remove training days.
          </p>
        )}
      </section>

      {error && (
        <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{error}</p>
      )}

      <div className="sticky bottom-2 flex gap-2">
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
        // 16px (text-base): below this, iOS nudges the layout when a character
        // is typed (the box "jumping down" on input). 16px disables that.
        className="input px-2 py-2 text-center text-base"
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
        className="input px-2 py-2 text-center text-base"
      />
    </label>
  )
}

/**
 * Exercise-name field with a live autocomplete dropdown. Suggestions are drawn
 * from the built-in library plus the user's custom exercises (the same set
 * shown on the Exercises page), filtered as the user types and capped at five.
 */
function ExerciseNameInput({
  value,
  onType,
  placeholder,
}: {
  value: string
  onType: (typed: string) => void
  placeholder: string
}) {
  const customExercises = useStore((s) => s.customExercises)
  const [open, setOpen] = useState(false)

  const names = useMemo(() => {
    const seen = new Set<string>()
    const out: string[] = []
    for (const n of [...EXERCISES.map((e) => e.name), ...customExercises.map((e) => e.name)]) {
      const key = n.toLowerCase()
      if (!seen.has(key)) {
        seen.add(key)
        out.push(n)
      }
    }
    return out
  }, [customExercises])

  const suggestions = useMemo(() => {
    const q = value.trim().toLowerCase()
    if (!q) return []
    return names
      .filter((n) => n.toLowerCase().includes(q) && n.toLowerCase() !== q)
      .slice(0, 5)
  }, [names, value])

  return (
    <div className="relative flex-1">
      <input
        value={value}
        onChange={(e) => {
          onType(e.target.value)
          setOpen(true)
        }}
        onFocus={() => setOpen(true)}
        // Delay close so a click on a suggestion still registers.
        onBlur={() => setTimeout(() => setOpen(false), 150)}
        placeholder={placeholder}
        className="input w-full"
      />
      {open && suggestions.length > 0 && (
        <ul className="absolute z-30 mt-1 max-h-60 w-full overflow-auto rounded-xl border border-white/10 bg-ink-850 py-1 shadow-xl">
          {suggestions.map((n) => (
            <li key={n}>
              <button
                type="button"
                // mousedown fires before the input's blur, so the value sticks.
                onMouseDown={(e) => {
                  e.preventDefault()
                  onType(n)
                  setOpen(false)
                }}
                className="block w-full px-3 py-2 text-left text-sm text-zinc-200 hover:bg-white/5"
              >
                {n}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
