import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Check, Droplet, Minus, Plus, Target } from 'lucide-react'
import { useStore } from '../store'
import type { NutritionEntry, NutritionGoals } from '../types'
import { todayISO } from '../lib/utils'
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
  const entry = useMemo(
    () => nutritionLog.find((e) => e.date === date) ?? { date, ...EMPTY },
    [nutritionLog, date],
  )

  function update(patch: Partial<NutritionEntry>) {
    setNutritionEntry({ ...entry, ...patch, date })
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
          Log your daily calories, macros, and water against your targets.
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
      </div>

      {/* Calories */}
      <section className="card space-y-3 p-5">
        <Ring current={entry.calories} goal={goals.calories} />
        <NumberField
          label="Calories"
          unit="kcal"
          value={entry.calories}
          onChange={(v) => update({ calories: v })}
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
          onChange={(v) => update({ protein: v })}
        />
        <MacroRow
          label="Carbs"
          value={entry.carbs}
          goal={goals.carbs}
          color="#f97316"
          onChange={(v) => update({ carbs: v })}
        />
        <MacroRow
          label="Fat"
          value={entry.fat}
          goal={goals.fat}
          color="#a855f7"
          onChange={(v) => update({ fat: v })}
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
            <button
              key={i}
              onClick={() => update({ water: i + 1 === entry.water ? i : i + 1 })}
              aria-label={`Set water to ${i + 1}`}
              className={cn(
                'h-8 w-8 rounded-lg border transition',
                i < entry.water
                  ? 'border-sky-400/50 bg-sky-500/20 text-sky-300'
                  : 'border-white/10 bg-ink-900 text-zinc-600',
              )}
            >
              <Droplet className="mx-auto h-4 w-4" />
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => update({ water: Math.max(0, entry.water - 1) })}
            className="btn-ghost flex-1"
          >
            <Minus className="h-4 w-4" /> Glass
          </button>
          <button onClick={() => update({ water: entry.water + 1 })} className="btn-gold flex-1">
            <Plus className="h-4 w-4" /> Glass
          </button>
        </div>
      </section>

      <Goals />
    </div>
  )
}

function NumberField({
  label,
  unit,
  value,
  onChange,
}: {
  label: string
  unit: string
  value: number
  onChange: (v: number) => void
}) {
  const [text, setText] = useState<string | null>(null)
  return (
    <div>
      <label className="mb-1.5 block text-sm font-medium text-zinc-300">
        {label} <span className="text-zinc-500">({unit})</span>
      </label>
      <input
        type="number"
        inputMode="numeric"
        value={text ?? (value ? String(value) : '')}
        placeholder="0"
        onChange={(e) => setText(e.target.value)}
        onBlur={() => {
          onChange(Math.max(0, Math.round(parseFloat(text ?? '') || 0)))
          setText(null)
        }}
        className="input"
      />
    </div>
  )
}

function MacroRow({
  label,
  value,
  goal,
  color,
  onChange,
}: {
  label: string
  value: number
  goal: number
  color: string
  onChange: (v: number) => void
}) {
  const [text, setText] = useState<string | null>(null)
  const pct = goal > 0 ? Math.min(100, (value / goal) * 100) : 0
  return (
    <div>
      <div className="mb-1 flex items-center justify-between text-sm">
        <span className="font-medium text-zinc-200">{label}</span>
        <span className="text-zinc-400">
          {value} / {goal} g
        </span>
      </div>
      <div className="flex items-center gap-3">
        <div className="h-2 flex-1 overflow-hidden rounded-full bg-ink-900">
          <div className="h-full rounded-full" style={{ width: `${pct}%`, background: color }} />
        </div>
        <input
          type="number"
          inputMode="numeric"
          aria-label={`${label} grams`}
          value={text ?? (value ? String(value) : '')}
          placeholder="0"
          onChange={(e) => setText(e.target.value)}
          onBlur={() => {
            onChange(Math.max(0, Math.round(parseFloat(text ?? '') || 0)))
            setText(null)
          }}
          className="input w-20 shrink-0 text-center"
        />
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
