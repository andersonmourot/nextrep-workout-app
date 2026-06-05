import { useMemo, useState } from 'react'
import { createPortal } from 'react-dom'
import { Link } from 'react-router-dom'
import {
  ArrowLeft,
  Check,
  ChevronRight,
  ImagePlus,
  Pencil,
  Plus,
  RotateCcw,
  Search,
  Settings2,
  Trash2,
  X,
} from 'lucide-react'
import { EXERCISES } from '../data/exercises'
import { useStore } from '../store'
import { getToken, useAuth } from '../auth'
import { apiUpsertExercise } from '../api'
import type { Difficulty, Equipment, Exercise, Muscle } from '../types'
import { cn, uid } from '../lib/utils'

const MUSCLES: Array<Muscle | 'All'> = [
  'All',
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
  'Full Body',
]

const ALL_MUSCLES: Muscle[] = [
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

const DEFAULT_IDS = new Set(EXERCISES.map((e) => e.id))

/** Read an image file and return a downscaled JPEG data URL to keep payloads small. */
function downscaleImage(file: File, maxDim = 800, quality = 0.7): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('read failed'))
    reader.onload = () => {
      const img = new Image()
      img.onerror = () => reject(new Error('decode failed'))
      img.onload = () => {
        const scale = Math.min(1, maxDim / Math.max(img.width, img.height))
        const w = Math.max(1, Math.round(img.width * scale))
        const h = Math.max(1, Math.round(img.height * scale))
        const canvas = document.createElement('canvas')
        canvas.width = w
        canvas.height = h
        const ctx = canvas.getContext('2d')
        if (!ctx) return reject(new Error('no canvas context'))
        ctx.drawImage(img, 0, 0, w, h)
        resolve(canvas.toDataURL('image/jpeg', quality))
      }
      img.src = reader.result as string
    }
    reader.readAsDataURL(file)
  })
}

export function Exercises() {
  return <ExercisesPage />
}

export function ExercisesPage({ showBack = false }: { showBack?: boolean }) {
  const [q, setQ] = useState('')
  const [muscle, setMuscle] = useState<Muscle | 'All'>('All')
  const [creating, setCreating] = useState(false)
  const [editing, setEditing] = useState<Exercise | null>(null)
  const [managing, setManaging] = useState(false)
  const [showDeleted, setShowDeleted] = useState(false)
  const [confirmId, setConfirmId] = useState<string | null>(null)
  const customExercises = useStore((s) => s.customExercises)
  const overrides = useStore((s) => s.exerciseOverrides)
  const hiddenExerciseIds = useStore((s) => s.hiddenExerciseIds)
  const deleteExercise = useStore((s) => s.deleteExercise)
  const restoreExercise = useStore((s) => s.restoreExercise)

  // Custom exercises first, then the built-in library (with per-user edits
  // applied and hidden ones removed).
  const all = useMemo(
    () =>
      [...customExercises, ...EXERCISES.map((e) => overrides[e.id] ?? e)].filter(
        (e) => !hiddenExerciseIds.includes(e.id),
      ),
    [customExercises, overrides, hiddenExerciseIds],
  )

  const list = useMemo(() => {
    const query = q.trim().toLowerCase()
    return all
      .filter((e) => {
        const matchMuscle = muscle === 'All' || e.primaryMuscle === muscle
        const matchQuery =
          !query ||
          e.name.toLowerCase().includes(query) ||
          e.primaryMuscle.toLowerCase().includes(query) ||
          e.equipment.toLowerCase().includes(query)
        return matchMuscle && matchQuery
      })
      .sort((a, b) => a.name.localeCompare(b.name))
  }, [all, q, muscle])

  function toggleManaging() {
    setManaging((m) => !m)
    setConfirmId(null)
    setShowDeleted(false)
  }

  const customIds = useMemo(() => new Set(customExercises.map((e) => e.id)), [customExercises])

  // Default exercises the user has deleted (moved to the hidden "Deleted" list).
  const deletedList = useMemo(
    () =>
      EXERCISES.filter((e) => hiddenExerciseIds.includes(e.id))
        .map((e) => overrides[e.id] ?? e)
        .sort((a, b) => a.name.localeCompare(b.name)),
    [hiddenExerciseIds, overrides],
  )

  if (showDeleted) {
    return (
      <div className="animate-fade-in space-y-5">
        <button
          onClick={() => setShowDeleted(false)}
          className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
        >
          <ArrowLeft className="h-4 w-4" /> Back
        </button>
        <h1 className="heading text-3xl font-bold text-zinc-50">Deleted exercises</h1>
        <p className="text-xs text-zinc-500">
          {deletedList.length === 0
            ? 'No deleted exercises.'
            : 'Restore an exercise to return it to the main list.'}
        </p>
        <ul className="space-y-2">
          {deletedList.map((e) => (
            <li key={e.id} className="card flex items-center justify-between gap-3 p-4">
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-zinc-100">{e.name}</p>
                <div className="mt-1 flex flex-wrap gap-1.5">
                  <span className="chip" style={{ color: 'rgb(var(--accent-400))' }}>
                    {e.primaryMuscle}
                  </span>
                  <span className="chip">{e.equipment}</span>
                  <span className="chip">{e.difficulty}</span>
                </div>
              </div>
              <button
                onClick={() => restoreExercise(e.id)}
                className="btn-ghost inline-flex shrink-0 items-center gap-1.5 px-3 py-2 text-xs font-semibold text-gold"
              >
                <RotateCcw className="h-3.5 w-3.5" /> Restore
              </button>
            </li>
          ))}
        </ul>
      </div>
    )
  }

  return (
    <div className="animate-fade-in space-y-5">
      {showBack && (
        <Link
          to="/programs"
          className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
        >
          <ArrowLeft className="h-4 w-4" /> Back
        </Link>
      )}
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="heading text-3xl font-bold text-zinc-50">Exercises</h1>
        </div>
        <div className="flex shrink-0 gap-2">
          {managing && hiddenExerciseIds.length > 0 && (
            <button
              onClick={() => setShowDeleted(true)}
              className="btn-ghost px-3 py-2 text-sm"
            >
              Deleted ({hiddenExerciseIds.length})
            </button>
          )}
          <button
            onClick={toggleManaging}
            aria-label={managing ? 'Done managing' : 'Manage exercises'}
            className={cn('btn-ghost px-3 py-2 text-sm', managing && 'text-gold')}
          >
            {managing ? 'Done' : <Settings2 className="h-4 w-4" />}
          </button>
          <button
            onClick={() => setCreating(true)}
            className="btn-gold px-3 py-2 text-sm"
            aria-label="New exercise"
          >
            <Plus className="h-4 w-4" />
          </button>
        </div>
      </div>

      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-500" />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search exercises, muscles, equipment"
          className="input pl-9"
        />
      </div>

      <div className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1">
        {MUSCLES.map((m) => (
          <button
            key={m}
            onClick={() => setMuscle(m)}
            className={cn(
              'whitespace-nowrap rounded-full border px-3.5 py-1.5 text-xs font-semibold transition',
              muscle === m
                ? 'border-gold bg-gold text-white'
                : 'border-white/10 bg-ink-850 text-zinc-300 hover:border-white/20',
            )}
          >
            {m}
          </button>
        ))}
      </div>

      <p className="text-xs text-zinc-500">{list.length} exercises</p>

      <ul className="space-y-2">
        {list.map((e) => {
          const isCustom = customIds.has(e.id)
          return (
            <li key={e.id} className="relative">
              <Link
                to={`/exercises/${e.id}`}
                className={cn(
                  'card flex items-center justify-between p-4 hover:border-white/10',
                  managing ? 'pr-24' : 'pr-10',
                )}
              >
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-zinc-100">
                    {e.name}
                    {isCustom && (
                      <span className="ml-2 rounded-full bg-gold/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-gold">
                        Custom
                      </span>
                    )}
                  </p>
                  <div className="mt-1 flex flex-wrap gap-1.5">
                    <span className="chip" style={{ color: 'rgb(var(--accent-400))' }}>
                      {e.primaryMuscle}
                    </span>
                    <span className="chip">{e.equipment}</span>
                    <span className="chip">{e.difficulty}</span>
                  </div>
                </div>
                {!managing && <ChevronRight className="h-4 w-4 shrink-0 text-zinc-600" />}
              </Link>

              {managing &&
                (confirmId === e.id ? (
                  <div className="absolute right-2 top-1/2 z-10 flex -translate-y-1/2 items-center gap-1.5 rounded-lg border border-white/10 bg-ink-800 px-2 py-1.5 shadow-lg">
                    <button
                      onClick={() => setConfirmId(null)}
                      aria-label="Cancel"
                      className="grid h-7 w-7 place-items-center rounded-lg text-zinc-300 hover:text-zinc-100"
                    >
                      <X className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => {
                        deleteExercise(e.id)
                        setConfirmId(null)
                      }}
                      aria-label="Confirm delete"
                      className="grid h-7 w-7 place-items-center rounded-lg text-red-400 hover:text-red-300"
                    >
                      <Check className="h-4 w-4" />
                    </button>
                  </div>
                ) : (
                  <div className="absolute right-2 top-1/2 z-10 flex -translate-y-1/2 items-center gap-1.5">
                    <button
                      onClick={() => setEditing(e)}
                      aria-label={`Edit ${e.name}`}
                      className="grid h-8 w-8 place-items-center rounded-lg bg-ink-900/80 text-zinc-400 backdrop-blur hover:text-gold"
                    >
                      <Pencil className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => setConfirmId(e.id)}
                      aria-label={`Delete ${e.name}`}
                      className="grid h-8 w-8 place-items-center rounded-lg bg-ink-900/80 text-zinc-400 backdrop-blur hover:text-red-400"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
            </li>
          )
        })}
        {list.length === 0 && (
          <li className="card p-6 text-center text-sm text-zinc-400">No exercises match your search.</li>
        )}
      </ul>

      {(creating || editing) && (
        <ExerciseModal
          editing={editing}
          onClose={() => {
            setCreating(false)
            setEditing(null)
          }}
        />
      )}
    </div>
  )
}

export function ExerciseModal({ editing, onClose }: { editing: Exercise | null; onClose: () => void }) {
  const addCustomExercise = useStore((s) => s.addCustomExercise)
  const setExerciseOverride = useStore((s) => s.setExerciseOverride)
  const currentUserId = useAuth((s) => s.user?.id)
  const currentUserName = useAuth((s) => s.user?.name)
  const isEdit = !!editing
  const isDefault = !!editing && DEFAULT_IDS.has(editing.id)
  // Whether the current user owns this shared exercise (or it's brand new).
  const isOwner = !editing?.ownerId || editing.ownerId === currentUserId

  const [name, setName] = useState(editing?.name ?? '')
  const [primaryMuscle, setPrimaryMuscle] = useState<Muscle>(editing?.primaryMuscle ?? 'Chest')
  const [secondary, setSecondary] = useState<Muscle[]>(editing?.secondaryMuscles ?? [])
  const [equipment, setEquipment] = useState<Equipment>(editing?.equipment ?? 'Barbell')
  const [difficulty, setDifficulty] = useState<Difficulty>(editing?.difficulty ?? 'Beginner')
  const [tempo, setTempo] = useState(editing?.tempo ?? '2-0-1-0')
  const [instructions, setInstructions] = useState((editing?.instructions ?? []).join('\n'))
  const [tips, setTips] = useState((editing?.tips ?? []).join('\n'))
  const [photos, setPhotos] = useState<string[]>(editing?.photos ?? [])
  const [shared, setShared] = useState(editing?.shared ?? false)
  const [collaborative, setCollaborative] = useState(editing?.collaborative ?? false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  function toggleSecondary(m: Muscle) {
    setSecondary((prev) => (prev.includes(m) ? prev.filter((x) => x !== m) : [...prev, m]))
  }

  async function onPickPhoto(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return
    try {
      const dataUrl = await downscaleImage(file)
      setPhotos((p) => [...p, dataUrl].slice(0, 2))
    } catch {
      setError('Could not load that image.')
    }
  }

  async function save() {
    if (!name.trim()) return setError('Give the exercise a name.')
    const isShared = !isDefault && shared
    const exercise: Exercise = {
      id: editing?.id ?? `custom-ex-${uid()}`,
      name: name.trim(),
      primaryMuscle,
      secondaryMuscles: secondary.filter((m) => m !== primaryMuscle),
      equipment,
      difficulty,
      tempo: tempo.trim() || '2-0-1-0',
      instructions: instructions
        .split('\n')
        .map((s) => s.trim())
        .filter(Boolean),
      tips: tips
        .split('\n')
        .map((s) => s.trim())
        .filter(Boolean),
      photos: photos.length ? photos : undefined,
      shared: isShared ? true : undefined,
      ownerId: editing?.ownerId ?? (isShared ? currentUserId : undefined),
      ownerName: editing?.ownerName ?? (isShared ? currentUserName ?? 'You' : undefined),
      // Only the owner controls the edit policy; collaborators keep the setting.
      collaborative: isOwner ? collaborative : editing?.collaborative,
      version: Date.now(),
    }

    if (isDefault) setExerciseOverride(exercise)
    else addCustomExercise(exercise)

    // Propagate to the canonical shared store so edits reach everyone who added
    // it. Push when the exercise is shared (owner) or when editing a
    // collaborative exercise you're a member of; the backend enforces policy.
    const shouldPublish =
      !!exercise.ownerId && (isShared || (!!editing?.collaborative && !isOwner))
    if (shouldPublish) {
      const token = getToken()
      if (token) {
        setSaving(true)
        const res = await apiUpsertExercise<Exercise>(token, exercise)
        setSaving(false)
        if (res.ok && res.data) {
          // Preserve this account's own visibility; content/policy are canonical.
          addCustomExercise({ ...res.data.exercise, shared: exercise.shared })
        }
      }
    }
    onClose()
  }

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/60 p-0 py-6 sm:items-center sm:p-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-ink-900 p-5">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="heading text-xl font-bold text-zinc-50">
            {isEdit ? 'Edit Exercise' : 'New Exercise'}
          </h2>
          <button onClick={onClose} className="grid h-9 w-9 place-items-center rounded-lg bg-ink-800 text-zinc-400 hover:text-zinc-200">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="space-y-4">
          <Field label="Name">
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Incline Cable Fly" className="input" />
          </Field>

          <div className="grid grid-cols-2 gap-3">
            <Field label="Primary muscle">
              <select value={primaryMuscle} onChange={(e) => setPrimaryMuscle(e.target.value as Muscle)} className="input">
                {ALL_MUSCLES.map((m) => (
                  <option key={m} value={m}>
                    {m}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Equipment">
              <select value={equipment} onChange={(e) => setEquipment(e.target.value as Equipment)} className="input">
                {EQUIPMENT.map((eq) => (
                  <option key={eq} value={eq}>
                    {eq}
                  </option>
                ))}
              </select>
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Field label="Difficulty">
              <select value={difficulty} onChange={(e) => setDifficulty(e.target.value as Difficulty)} className="input">
                {DIFFICULTIES.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Tempo">
              <input value={tempo} onChange={(e) => setTempo(e.target.value)} placeholder="2-0-1-0" className="input" />
            </Field>
          </div>

          <Field label="Secondary muscles">
            <div className="flex flex-wrap gap-2">
              {ALL_MUSCLES.filter((m) => m !== primaryMuscle).map((m) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => toggleSecondary(m)}
                  className={cn(
                    'rounded-full border px-3 py-1.5 text-xs font-semibold transition',
                    secondary.includes(m)
                      ? 'border-gold bg-gold/15 text-gold'
                      : 'border-white/10 bg-ink-850 text-zinc-300 hover:border-white/30',
                  )}
                >
                  {m}
                </button>
              ))}
            </div>
          </Field>

          <Field label="Instructions (one per line)">
            <textarea
              value={instructions}
              onChange={(e) => setInstructions(e.target.value)}
              rows={4}
              placeholder={'Set up on the bench...\nLower under control...\nDrive back up...'}
              className="input resize-none"
            />
          </Field>

          <Field label="Tips (one per line)">
            <textarea
              value={tips}
              onChange={(e) => setTips(e.target.value)}
              rows={3}
              placeholder={'Keep your shoulders back...\nDon\u2019t flare your elbows...'}
              className="input resize-none"
            />
          </Field>

          <Field label="Photos (up to 2)">
            <div className="flex flex-wrap gap-3">
              {photos.map((src, i) => (
                <div key={i} className="relative h-24 w-24 overflow-hidden rounded-lg border border-white/10">
                  <img src={src} alt="" className="h-full w-full object-cover" />
                  <button
                    type="button"
                    onClick={() => setPhotos((p) => p.filter((_, j) => j !== i))}
                    aria-label="Remove photo"
                    className="absolute right-1 top-1 grid h-6 w-6 place-items-center rounded-full bg-black/60 text-white hover:bg-black/80"
                  >
                    <X className="h-3.5 w-3.5" />
                  </button>
                </div>
              ))}
              {photos.length < 2 && (
                <label className="grid h-24 w-24 cursor-pointer place-items-center rounded-lg border border-dashed border-white/20 text-zinc-400 hover:border-white/40 hover:text-zinc-200">
                  <ImagePlus className="h-6 w-6" />
                  <input type="file" accept="image/*" className="hidden" onChange={onPickPhoto} />
                </label>
              )}
            </div>
          </Field>

          {!isDefault && (
            <button
              type="button"
              onClick={() => setShared((v) => !v)}
              className="flex w-full items-center justify-between gap-3 rounded-xl border border-white/10 bg-ink-850 px-4 py-3 text-left"
            >
              <span>
                <span className="block text-sm font-medium text-zinc-200">Shareable</span>
                <span className="mt-0.5 block text-xs text-zinc-500">
                  Show this exercise on your profile so others can find and add it.
                </span>
              </span>
              <span
                className={cn(
                  'relative h-6 w-11 shrink-0 rounded-full transition',
                  shared ? 'bg-gold' : 'bg-ink-700',
                )}
              >
                <span
                  className={cn(
                    'absolute top-0.5 h-5 w-5 rounded-full bg-white transition',
                    shared ? 'left-[1.375rem]' : 'left-0.5',
                  )}
                />
              </span>
            </button>
          )}

          {/* Edit policy — only the creator chooses who may edit a shared exercise. */}
          {!isDefault && shared && isOwner && (
            <div className="rounded-xl border border-white/10 bg-ink-850 p-3">
              <span className="block text-sm font-medium text-zinc-200">Who can edit it?</span>
              <span className="mt-0.5 block text-xs text-zinc-500">
                Your edits always show for everyone who added it.
              </span>
              <div className="mt-3 grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setCollaborative(false)}
                  className={cn(
                    'rounded-lg border px-3 py-2 text-sm font-semibold transition',
                    !collaborative
                      ? 'border-gold bg-gold/15 text-gold'
                      : 'border-white/10 bg-ink-900 text-zinc-300 hover:border-white/20',
                  )}
                >
                  Only me
                </button>
                <button
                  type="button"
                  onClick={() => setCollaborative(true)}
                  className={cn(
                    'rounded-lg border px-3 py-2 text-sm font-semibold transition',
                    collaborative
                      ? 'border-gold bg-gold/15 text-gold'
                      : 'border-white/10 bg-ink-900 text-zinc-300 hover:border-white/20',
                  )}
                >
                  Anyone who added it
                </button>
              </div>
            </div>
          )}

          {error && <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{error}</p>}

          <div className="flex gap-2 pt-1">
            <button onClick={onClose} className="btn-ghost flex-1">
              Cancel
            </button>
            <button onClick={() => void save()} disabled={saving} className="btn-gold flex-1">
              {saving ? 'Saving…' : isEdit ? 'Save Changes' : 'Create Exercise'}
            </button>
          </div>
        </div>
      </div>
    </div>,
    document.body,
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
