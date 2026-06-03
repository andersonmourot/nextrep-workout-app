import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ChevronRight, Plus, Search, X } from 'lucide-react'
import { EXERCISES } from '../data/exercises'
import { useStore } from '../store'
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

export function Exercises() {
  const [q, setQ] = useState('')
  const [muscle, setMuscle] = useState<Muscle | 'All'>('All')
  const [creating, setCreating] = useState(false)
  const customExercises = useStore((s) => s.customExercises)

  // Custom exercises first, then the built-in library.
  const all = useMemo(() => [...customExercises, ...EXERCISES], [customExercises])

  const list = useMemo(() => {
    const query = q.trim().toLowerCase()
    return all.filter((e) => {
      const matchMuscle = muscle === 'All' || e.primaryMuscle === muscle
      const matchQuery =
        !query ||
        e.name.toLowerCase().includes(query) ||
        e.primaryMuscle.toLowerCase().includes(query) ||
        e.equipment.toLowerCase().includes(query)
      return matchMuscle && matchQuery
    })
  }, [all, q, muscle])

  const customIds = useMemo(() => new Set(customExercises.map((e) => e.id)), [customExercises])

  return (
    <div className="animate-fade-in space-y-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="label-eyebrow">Perfect your form</p>
          <h1 className="heading text-3xl font-bold text-zinc-50">Exercises</h1>
        </div>
        <button onClick={() => setCreating(true)} className="btn-gold shrink-0 px-3 py-2 text-sm">
          <Plus className="h-4 w-4" /> New
        </button>
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
        {list.map((e) => (
          <li key={e.id}>
            <Link
              to={`/exercises/${e.id}`}
              className="card flex items-center justify-between p-4 hover:border-white/10"
            >
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-zinc-100">
                  {e.name}
                  {customIds.has(e.id) && (
                    <span className="ml-2 rounded-full bg-gold/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-gold">
                      Custom
                    </span>
                  )}
                </p>
                <div className="mt-1 flex flex-wrap gap-1.5">
                  <span className="chip" style={{ color: '#4c8a55' }}>
                    {e.primaryMuscle}
                  </span>
                  <span className="chip">{e.equipment}</span>
                  <span className="chip">{e.difficulty}</span>
                </div>
              </div>
              <ChevronRight className="h-4 w-4 shrink-0 text-zinc-600" />
            </Link>
          </li>
        ))}
        {list.length === 0 && (
          <li className="card p-6 text-center text-sm text-zinc-400">No exercises match your search.</li>
        )}
      </ul>

      {creating && <NewExerciseModal onClose={() => setCreating(false)} />}
    </div>
  )
}

function NewExerciseModal({ onClose }: { onClose: () => void }) {
  const addCustomExercise = useStore((s) => s.addCustomExercise)
  const [name, setName] = useState('')
  const [primaryMuscle, setPrimaryMuscle] = useState<Muscle>('Chest')
  const [secondary, setSecondary] = useState<Muscle[]>([])
  const [equipment, setEquipment] = useState<Equipment>('Barbell')
  const [difficulty, setDifficulty] = useState<Difficulty>('Beginner')
  const [tempo, setTempo] = useState('2-0-1-0')
  const [instructions, setInstructions] = useState('')
  const [tips, setTips] = useState('')
  const [error, setError] = useState('')

  function toggleSecondary(m: Muscle) {
    setSecondary((prev) => (prev.includes(m) ? prev.filter((x) => x !== m) : [...prev, m]))
  }

  function save() {
    if (!name.trim()) return setError('Give the exercise a name.')
    const exercise: Exercise = {
      id: `custom-ex-${uid()}`,
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
    }
    addCustomExercise(exercise)
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 p-0 sm:items-center sm:p-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl bg-ink-900 p-5 sm:rounded-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="heading text-xl font-bold text-zinc-50">New Exercise</h2>
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

          {error && <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{error}</p>}

          <div className="flex gap-2 pt-1">
            <button onClick={onClose} className="btn-ghost flex-1">
              Cancel
            </button>
            <button onClick={save} className="btn-gold flex-1">
              Create Exercise
            </button>
          </div>
        </div>
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
