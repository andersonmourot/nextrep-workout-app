import { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'
import { Navigate, useNavigate } from 'react-router-dom'
import { ArrowLeft, Dumbbell, ListChecks, Pencil, Plus, ShieldCheck, Trash2 } from 'lucide-react'
import { getToken, useAuth } from '../auth'
import { apiAdminPutCatalog, apiGetCatalog } from '../api'
import { setBuiltInExercises } from '../data/exercises'
import { setBuiltInPrograms } from '../data/programs'
import type { Difficulty, Equipment, Exercise, Muscle, Program } from '../types'
import { uid } from '../lib/utils'

const MUSCLES: Muscle[] = [
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Quads',
  'Hamstrings',
  'Glutes',
  'Calves',
  'Core',
  'Forearms',
  'Full Body',
]
const EQUIPMENT: Equipment[] = [
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Bodyweight',
  'Kettlebell',
  'Bands',
]
const DIFFICULTIES: Difficulty[] = ['Beginner', 'Intermediate', 'Advanced']

function slugifyId(name: string): string {
  const base = name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
  return base || `custom-${uid()}`
}

function blankExercise(): Exercise {
  return {
    id: '',
    name: '',
    primaryMuscle: 'Chest',
    secondaryMuscles: [],
    equipment: 'Barbell',
    difficulty: 'Beginner',
    instructions: [],
    tips: [],
  }
}

function linesToList(text: string): string[] {
  return text
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean)
}

function ExerciseForm({
  initial,
  isNew,
  onCancel,
  onSave,
  busy,
}: {
  initial: Exercise
  isNew: boolean
  onCancel: () => void
  onSave: (ex: Exercise) => void
  busy: boolean
}) {
  const [name, setName] = useState(initial.name)
  const [primaryMuscle, setPrimaryMuscle] = useState<Muscle>(initial.primaryMuscle)
  const [secondary, setSecondary] = useState(initial.secondaryMuscles.join(', '))
  const [equipment, setEquipment] = useState<Equipment>(initial.equipment)
  const [difficulty, setDifficulty] = useState<Difficulty>(initial.difficulty)
  const [instructions, setInstructions] = useState(initial.instructions.join('\n'))
  const [tips, setTips] = useState(initial.tips.join('\n'))
  const [err, setErr] = useState('')

  function submit() {
    if (!name.trim()) return setErr('Give the exercise a name.')
    const secondaryMuscles = secondary
      .split(',')
      .map((s) => s.trim())
      .filter((s): s is Muscle => (MUSCLES as string[]).includes(s))
    onSave({
      ...initial,
      id: initial.id || slugifyId(name),
      name: name.trim(),
      primaryMuscle,
      secondaryMuscles,
      equipment,
      difficulty,
      instructions: linesToList(instructions),
      tips: linesToList(tips),
    })
  }

  return (
    <div className="card space-y-3 p-4">
      <h3 className="heading text-base font-bold text-zinc-50">
        {isNew ? 'New exercise' : 'Edit exercise'}
      </h3>
      {err && <p className="rounded-lg bg-red-500/10 px-3 py-2 text-xs text-red-300">{err}</p>}

      <div>
        <label className="mb-1 block text-xs font-medium text-zinc-400">Name</label>
        <input value={name} onChange={(e) => setName(e.target.value)} className="input" placeholder="Barbell Bench Press" />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="mb-1 block text-xs font-medium text-zinc-400">Primary muscle</label>
          <select value={primaryMuscle} onChange={(e) => setPrimaryMuscle(e.target.value as Muscle)} className="input">
            {MUSCLES.map((m) => (
              <option key={m} value={m}>
                {m}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-zinc-400">Equipment</label>
          <select value={equipment} onChange={(e) => setEquipment(e.target.value as Equipment)} className="input">
            {EQUIPMENT.map((m) => (
              <option key={m} value={m}>
                {m}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="mb-1 block text-xs font-medium text-zinc-400">Difficulty</label>
          <select value={difficulty} onChange={(e) => setDifficulty(e.target.value as Difficulty)} className="input">
            {DIFFICULTIES.map((m) => (
              <option key={m} value={m}>
                {m}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-zinc-400">Secondary muscles</label>
          <input
            value={secondary}
            onChange={(e) => setSecondary(e.target.value)}
            className="input"
            placeholder="Triceps, Shoulders"
          />
        </div>
      </div>

      <div>
        <label className="mb-1 block text-xs font-medium text-zinc-400">Instructions (one per line)</label>
        <textarea
          value={instructions}
          onChange={(e) => setInstructions(e.target.value)}
          rows={4}
          className="input resize-y"
        />
      </div>

      <div>
        <label className="mb-1 block text-xs font-medium text-zinc-400">Tips (one per line)</label>
        <textarea value={tips} onChange={(e) => setTips(e.target.value)} rows={3} className="input resize-y" />
      </div>

      <div className="flex gap-2">
        <button onClick={submit} disabled={busy} className="btn-gold flex-1">
          {busy ? 'Saving…' : 'Save exercise'}
        </button>
        <button onClick={onCancel} disabled={busy} className="btn-ghost">
          Cancel
        </button>
      </div>
    </div>
  )
}

export function AdminCatalog() {
  const navigate = useNavigate()
  const account = useAuth((s) => s.user)
  const ready = useAuth((s) => s.ready)

  const [programs, setPrograms] = useState<Program[]>([])
  const [exercises, setExercises] = useState<Exercise[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [editingExercise, setEditingExercise] = useState<{ ex: Exercise; isNew: boolean } | null>(null)
  const [confirmRemove, setConfirmRemove] = useState<{ kind: 'program' | 'exercise'; id: string } | null>(null)

  useEffect(() => {
    let active = true
    void apiGetCatalog<Program, Exercise>().then((res) => {
      if (!active) return
      if (res.ok && res.data) {
        setPrograms(res.data.programs)
        setExercises(res.data.exercises)
      } else {
        setError(res.error ?? 'Could not load the catalog.')
      }
      setLoading(false)
    })
    return () => {
      active = false
    }
  }, [])

  // Non-admins should never reach this page.
  if (ready && account && !account.is_admin) return <Navigate to="/" replace />

  async function persist(nextPrograms: Program[], nextExercises: Exercise[]) {
    const token = getToken()
    if (!token) {
      setError('You must be signed in.')
      return false
    }
    setBusy(true)
    const res = await apiAdminPutCatalog<Program, Exercise>(token, {
      programs: nextPrograms,
      exercises: nextExercises,
    })
    setBusy(false)
    if (!res.ok || !res.data) {
      setError(res.error ?? 'Could not save the catalog.')
      return false
    }
    setPrograms(res.data.programs)
    setExercises(res.data.exercises)
    // Refresh the live in-memory catalog so changes show across the app at once.
    setBuiltInPrograms(res.data.programs)
    setBuiltInExercises(res.data.exercises)
    setError(null)
    return true
  }

  async function saveExercise(ex: Exercise) {
    const idx = exercises.findIndex((e) => e.id === ex.id)
    const next = idx >= 0 ? exercises.map((e) => (e.id === ex.id ? ex : e)) : [ex, ...exercises]
    const ok = await persist(programs, next)
    if (ok) setEditingExercise(null)
  }

  async function removeItem() {
    if (!confirmRemove) return
    if (confirmRemove.kind === 'program') {
      await persist(
        programs.filter((p) => p.id !== confirmRemove.id),
        exercises,
      )
    } else {
      await persist(
        programs,
        exercises.filter((e) => e.id !== confirmRemove.id),
      )
    }
    setConfirmRemove(null)
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
        <p className="label-eyebrow flex items-center gap-1.5">
          <ShieldCheck className="h-3.5 w-3.5 text-gold" /> Admin
        </p>
        <h1 className="heading text-3xl font-bold text-zinc-50">Catalog</h1>
        <p className="mt-1 text-sm text-zinc-400">
          Edit the built-in programs and exercises everyone sees. Changes go live immediately.
        </p>
      </div>

      {error && <p className="card p-4 text-sm text-red-300">{error}</p>}
      {loading && <p className="text-sm text-zinc-400">Loading…</p>}

      {!loading && (
        <>
          {/* Programs */}
          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="heading flex items-center gap-2 text-sm font-semibold tracking-wider text-zinc-300">
                <ListChecks className="h-4 w-4" /> Programs · {programs.length}
              </h2>
              <button
                onClick={() => navigate('/admin/catalog/programs/new')}
                className="inline-flex items-center gap-1 text-sm font-medium text-gold hover:opacity-80"
              >
                <Plus className="h-4 w-4" /> New
              </button>
            </div>
            <div className="space-y-2">
              {programs.map((p) => (
                <div key={p.id} className="card flex items-center justify-between gap-3 p-4">
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-zinc-100">{p.name}</p>
                    <p className="truncate text-xs text-zinc-500">
                      {p.category} · {p.level} · {p.daysPerWeek} days/week
                    </p>
                  </div>
                  <div className="flex shrink-0 gap-1">
                    <button
                      onClick={() => navigate('/admin/catalog/programs/edit', { state: { program: p } })}
                      aria-label={`Edit ${p.name}`}
                      className="grid h-9 w-9 place-items-center rounded-lg bg-ink-800 text-zinc-400 transition hover:text-gold"
                    >
                      <Pencil className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => setConfirmRemove({ kind: 'program', id: p.id })}
                      aria-label={`Remove ${p.name}`}
                      className="grid h-9 w-9 place-items-center rounded-lg bg-ink-800 text-zinc-400 transition hover:text-red-400"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* Exercises */}
          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="heading flex items-center gap-2 text-sm font-semibold tracking-wider text-zinc-300">
                <Dumbbell className="h-4 w-4" /> Exercises · {exercises.length}
              </h2>
              <button
                onClick={() => setEditingExercise({ ex: blankExercise(), isNew: true })}
                className="inline-flex items-center gap-1 text-sm font-medium text-gold hover:opacity-80"
              >
                <Plus className="h-4 w-4" /> New
              </button>
            </div>

            {editingExercise && (
              <ExerciseForm
                initial={editingExercise.ex}
                isNew={editingExercise.isNew}
                busy={busy}
                onCancel={() => setEditingExercise(null)}
                onSave={saveExercise}
              />
            )}

            <div className="space-y-2">
              {exercises.map((e) => (
                <div key={e.id} className="card flex items-center justify-between gap-3 p-4">
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-zinc-100">{e.name}</p>
                    <p className="truncate text-xs text-zinc-500">
                      {e.primaryMuscle} · {e.equipment}
                    </p>
                  </div>
                  <div className="flex shrink-0 gap-1">
                    <button
                      onClick={() => setEditingExercise({ ex: e, isNew: false })}
                      aria-label={`Edit ${e.name}`}
                      className="grid h-9 w-9 place-items-center rounded-lg bg-ink-800 text-zinc-400 transition hover:text-gold"
                    >
                      <Pencil className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => setConfirmRemove({ kind: 'exercise', id: e.id })}
                      aria-label={`Remove ${e.name}`}
                      className="grid h-9 w-9 place-items-center rounded-lg bg-ink-800 text-zinc-400 transition hover:text-red-400"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </>
      )}

      {confirmRemove &&
        createPortal(
          <div className="fixed inset-0 z-50 grid place-items-center bg-black/60 p-4">
            <div className="card w-full max-w-sm space-y-4 p-5">
              <p className="text-sm text-zinc-200">
                Remove this {confirmRemove.kind} from the catalog for everyone?
              </p>
              <div className="flex gap-2">
                <button onClick={removeItem} disabled={busy} className="btn flex-1 bg-red-500/90 text-white hover:bg-red-500">
                  {busy ? 'Removing…' : 'Remove'}
                </button>
                <button onClick={() => setConfirmRemove(null)} disabled={busy} className="btn-ghost flex-1">
                  Cancel
                </button>
              </div>
            </div>
          </div>,
          document.body,
        )}
    </div>
  )
}
