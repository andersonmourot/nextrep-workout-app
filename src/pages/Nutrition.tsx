import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Check, Droplet, History, Plus, Target } from 'lucide-react'
import { useStore } from '../store'
import type { NutritionEntry, NutritionGoals } from '../types'
import { formatDateLong, todayISO } from '../lib/utils'
import { cn } from '../lib/utils'

const EMPTY: Omit<NutritionEntry, 'date'> = {
  calories: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
  water: 0,
}

export function Nutrition() {
  const navigate = useNavigate()
  const nutritionLog = useStore((s) => s.nutritionLog)
  const goals = useStore((s) => s.nutritionGoals)
  const setNutritionEntry = useStore((s) => s.setNutritionEntry)

  const [date, setDate] = useState(todayISO())
  const [showHistory, setShowHistory] = useState(false)
  const entry = useMemo(
    () => nutritionLog.find((e) => e.date === date) ?? { date, ...EMPTY },
    [nutritionLog, date],
  )

  // Past days that have something logged, newest first.
  const history = useMemo(
    () => [...nutritionLog].sort((a, b) => (a.date < b.date ? 1 : -1)),
    [nutritionLog],
  )

  /** Add a delta to one field of the selected day's entry (clamped at 0). */
  function add(field: keyof typeof EMPTY, delta: number) {
    if (!delta) return
    setNutritionEntry({ ...entry, [field]: Math.max(0, entry[field] + delta), date })
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
        <p className="label-eyebrow">Daily fuel</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">Nutrition</h1>
        <p className="mt-1 text-sm text-zinc-400">
          Log your daily calories, macros, and hydration.
        </p>
      </div>

      <div className="flex items-center gap-2">
        <input
          type="date"
          value={date}
          max={todayISO()}
          onChange={(e) => setDate(e.target.value || todayISO())}
          className="input"
        />
        <button
          onClick={() => setShowHistory((v) => !v)}
          className={cn('btn-ghost shrink-0', showHistory && 'text-gold')}
        >
          <History className="h-4 w-4" /> History
        </button>
      </div>

      {showHistory && (
        <section className="card space-y-2 p-5">
          <h2 className="heading text-lg font-bold text-zinc-50">History</h2>
          {history.length === 0 ? (
            <p className="text-sm text-zinc-500">
              No saved days yet. Log something to start your history.
            </p>
          ) : (
            <ul className="space-y-1.5">
              {history.map((h) => (
                <li key={h.date}>
                  <button
                    onClick={() => {
                      setDate(h.date)
                      setShowHistory(false)
                    }}
                    className={cn(
                      'flex w-full items-center justify-between rounded-lg bg-ink-900 px-3 py-2 text-left text-sm transition hover:bg-ink-800',
                      h.date === date && 'ring-1 ring-gold/40',
                    )}
                  >
                    <span className="text-zinc-300">{formatDateLong(h.date)}</span>
                    <span className="text-xs text-zinc-500">
                      {h.calories} kcal · {h.protein}/{h.carbs}/{h.fat}g · {h.water} 💧
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </section>
      )}

      {/* Calories */}
      <section className="card space-y-3 p-5">
        <Ring current={entry.calories} goal={goals.calories} />
        <AddField
          label="Add calories"
          unit="kcal"
          onAdd={(v) => add('calories', v)}
        />
      </section>

      {/* Macros */}
      <section className="card space-y-4 p-5">
        <h2 className="heading text-lg font-bold text-zinc-50">Macros</h2>
        <MacroRow
          label="Protein"
          value={entry.protein}
          goal={goals.protein}
          color="#3b82f6"
          onAdd={(v) => add('protein', v)}
        />
        <MacroRow
          label="Carbs"
          value={entry.carbs}
          goal={goals.carbs}
          color="#f97316"
          onAdd={(v) => add('carbs', v)}
        />
        <MacroRow
          label="Fat"
          value={entry.fat}
          goal={goals.fat}
          color="#a855f7"
          onAdd={(v) => add('fat', v)}
        />
      </section>

      {/* Water */}
      <section className="card space-y-3 p-5">
        <div className="flex items-center justify-between">
          <h2 className="heading flex items-center gap-2 text-lg font-bold text-zinc-50">
            <Droplet className="h-5 w-5 text-sky-400" /> Water
          </h2>
          <span className="text-sm text-zinc-400">
            {entry.water} / {goals.water} glasses
          </span>
        </div>
        <div className="flex flex-wrap gap-2">
          {Array.from({ length: Math.max(goals.water, entry.water) }).map((_, i) => (
            <span
              key={i}
              aria-hidden
              className={cn(
                'grid h-8 w-8 place-items-center rounded-lg border',
                i < entry.water
                  ? 'border-sky-400/50 bg-sky-500/20 text-sky-300'
                  : 'border-white/10 bg-ink-900 text-zinc-600',
              )}
            >
              <Droplet className="h-4 w-4" />
            </span>
          ))}
        </div>
        <AddField label="Add glasses" unit="glasses" onAdd={(v) => add('water', v)} />
      </section>

      <Goals />
    </div>
  )
}

/** A number input that adds its value to a running total when submitted. */
function AddField({
  label,
  unit,
  onAdd,
}: {
  label: string
  unit: string
  onAdd: (v: number) => void
}) {
  const [text, setText] = useState('')
  function submit() {
    const v = Math.round(parseFloat(text) || 0)
    if (v) onAdd(v)
    setText('')
  }
  return (
    <div>
      <label className="mb-1.5 block text-sm font-medium text-zinc-300">
        {label} <span className="text-zinc-500">({unit})</span>
      </label>
      <div className="flex gap-2">
        <input
          type="number"
          inputMode="numeric"
          value={text}
          placeholder="0"
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && submit()}
          className="input"
        />
        <button onClick={submit} className="btn-gold shrink-0">
          <Plus className="h-4 w-4" /> Add
        </button>
      </div>
    </div>
  )
}

function MacroRow({
  label,
  value,
  goal,
  color,
  onAdd,
}: {
  label: string
  value: number
  goal: number
  color: string
  onAdd: (v: number) => void
}) {
  const [text, setText] = useState('')
  const pct = goal > 0 ? Math.min(100, (value / goal) * 100) : 0
  function submit() {
    const v = Math.round(parseFloat(text) || 0)
    if (v) onAdd(v)
    setText('')
  }
  return (
    <div>
      <div className="mb-1 flex items-center justify-between text-sm">
        <span className="font-medium text-zinc-200">{label}</span>
        <span className="text-zinc-400">
          {value} / {goal} g
        </span>
      </div>
      <div className="mb-2 h-2 overflow-hidden rounded-full bg-ink-900">
        <div className="h-full rounded-full" style={{ width: `${pct}%`, background: color }} />
      </div>
      <div className="flex gap-2">
        <input
          type="number"
          inputMode="numeric"
          aria-label={`Add ${label} grams`}
          value={text}
          placeholder="0"
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && submit()}
          className="input"
        />
        <button onClick={submit} className="btn-ghost shrink-0">
          <Plus className="h-4 w-4" /> Add
        </button>
      </div>
    </div>
  )
}

function Ring({ current, goal }: { current: number; goal: number }) {
  const pct = goal > 0 ? Math.min(1, current / goal) : 0
  const r = 52
  const c = 2 * Math.PI * r
  const remaining = Math.max(0, goal - current)
  return (
    <div className="flex items-center gap-5">
      <svg viewBox="0 0 120 120" className="h-28 w-28 shrink-0 -rotate-90">
        <circle cx="60" cy="60" r={r} fill="none" stroke="rgb(255 255 255 / 0.08)" strokeWidth="10" />
        <circle
          cx="60"
          cy="60"
          r={r}
          fill="none"
          stroke="rgb(var(--accent))"
          strokeWidth="10"
          strokeLinecap="round"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - pct)}
        />
      </svg>
      <div>
        <div className="heading text-3xl font-bold text-zinc-50">{current}</div>
        <div className="text-xs text-zinc-500">of {goal} kcal</div>
        <div className="mt-1 text-sm font-semibold text-zinc-300">{remaining} kcal left</div>
      </div>
    </div>
  )
}

function Goals() {
  const goals = useStore((s) => s.nutritionGoals)
  const setNutritionGoals = useStore((s) => s.setNutritionGoals)
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<Record<keyof NutritionGoals, string>>({
    calories: String(goals.calories),
    protein: String(goals.protein),
    carbs: String(goals.carbs),
    fat: String(goals.fat),
    water: String(goals.water),
  })
  const [saved, setSaved] = useState(false)

  function save() {
    setNutritionGoals({
      calories: Math.max(0, Math.round(parseFloat(draft.calories) || 0)),
      protein: Math.max(0, Math.round(parseFloat(draft.protein) || 0)),
      carbs: Math.max(0, Math.round(parseFloat(draft.carbs) || 0)),
      fat: Math.max(0, Math.round(parseFloat(draft.fat) || 0)),
      water: Math.max(0, Math.round(parseFloat(draft.water) || 0)),
    })
    setSaved(true)
    setTimeout(() => setSaved(false), 1500)
  }

  const fields: { key: keyof NutritionGoals; label: string; unit: string }[] = [
    { key: 'calories', label: 'Calories', unit: 'kcal' },
    { key: 'protein', label: 'Protein', unit: 'g' },
    { key: 'carbs', label: 'Carbs', unit: 'g' },
    { key: 'fat', label: 'Fat', unit: 'g' },
    { key: 'water', label: 'Water', unit: 'glasses' },
  ]

  return (
    <section className="card p-5">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between"
      >
        <h2 className="heading flex items-center gap-2 text-lg font-bold text-zinc-50">
          <Target className="h-5 w-5 text-gold" /> Daily Goals
        </h2>
        <span className="text-sm text-zinc-400">{open ? 'Close' : 'Edit'}</span>
      </button>

      {open && (
        <div className="mt-4 space-y-3">
          {fields.map((f) => (
            <div key={f.key}>
              <label className="mb-1.5 block text-sm font-medium text-zinc-300">
                {f.label} <span className="text-zinc-500">({f.unit})</span>
              </label>
              <input
                type="number"
                inputMode="numeric"
                value={draft[f.key]}
                placeholder="0"
                onChange={(e) => setDraft((d) => ({ ...d, [f.key]: e.target.value }))}
                className="input"
              />
            </div>
          ))}
          <button onClick={save} className="btn-gold w-full">
            {saved ? (
              <>
                <Check className="h-4 w-4" /> Saved
              </>
            ) : (
              'Save Goals'
            )}
          </button>
        </div>
      )}
    </section>
  )
}
