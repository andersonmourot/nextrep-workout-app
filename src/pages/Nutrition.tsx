import { useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Check,
  Droplet,
  History,
  Image as ImageIcon,
  ImagePlus,
  Plus,
  Target,
  X,
} from 'lucide-react'
import { useStore } from '../store'
import type { NutritionGoals } from '../types'
import { formatDateLong, todayISO } from '../lib/utils'
import { cn } from '../lib/utils'

/** The numeric, stepper-driven fields of a nutrition entry. */
type NumericField = 'calories' | 'protein' | 'carbs' | 'fat' | 'water'

const EMPTY: Record<NumericField, number> = {
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

  /** Set one field of the selected day's entry to an exact value (clamped at 0). */
  function setField(field: keyof typeof EMPTY, value: number) {
    setNutritionEntry({ ...entry, [field]: Math.max(0, value), date })
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
          {Array.from({ length: Math.max(goals.water, entry.water) }).map((_, i) => {
            const filled = i < entry.water
            return (
              <button
                key={i}
                type="button"
                aria-label={`Set water to ${i + 1} glasses`}
                onClick={() => setField('water', entry.water === i + 1 ? i : i + 1)}
                className={cn(
                  'grid h-8 w-8 place-items-center rounded-lg border transition hover:border-sky-400/60',
                  filled
                    ? 'border-sky-400/50 bg-sky-500/20 text-sky-300'
                    : 'border-white/10 bg-ink-900 text-zinc-600',
                )}
              >
                <Droplet className="h-4 w-4" />
              </button>
            )
          })}
        </div>
      </section>

      {/* Photos — up to 3 per day, at the bottom of the day's inputs. */}
      <DayPhotos
        photos={entry.photos ?? []}
        onChange={(photos) => setNutritionEntry({ ...entry, photos, date })}
      />

      <Goals />
    </div>
  )
}

/** Read an image file, scale it down, and return a compressed JPEG data URL so
   stored photos stay small enough to sync with the rest of the app data. */
async function compressImage(file: File, maxDim = 1080, quality = 0.6): Promise<string> {
  const dataUrl = await new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(new Error('read failed'))
    reader.readAsDataURL(file)
  })
  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const i = new Image()
    i.onload = () => resolve(i)
    i.onerror = () => reject(new Error('decode failed'))
    i.src = dataUrl
  })
  const scale = Math.min(1, maxDim / Math.max(img.width, img.height))
  const w = Math.round(img.width * scale)
  const h = Math.round(img.height * scale)
  const canvas = document.createElement('canvas')
  canvas.width = w
  canvas.height = h
  const ctx = canvas.getContext('2d')
  if (!ctx) return dataUrl
  ctx.drawImage(img, 0, 0, w, h)
  return canvas.toDataURL('image/jpeg', quality)
}

/** A grid of up to 3 day photos with add (file picker) and per-photo remove. */
function DayPhotos({
  photos,
  onChange,
}: {
  photos: string[]
  onChange: (photos: string[]) => void
}) {
  const inputRef = useRef<HTMLInputElement>(null)
  const [busy, setBusy] = useState(false)

  async function onFiles(files: FileList | null) {
    if (!files || files.length === 0) return
    setBusy(true)
    try {
      const room = 3 - photos.length
      const picked = Array.from(files).slice(0, Math.max(0, room))
      const next = [...photos]
      for (const f of picked) {
        try {
          next.push(await compressImage(f))
        } catch {
          // Skip files that can't be read/decoded.
        }
      }
      onChange(next.slice(0, 3))
    } finally {
      setBusy(false)
      if (inputRef.current) inputRef.current.value = ''
    }
  }

  return (
    <section className="card space-y-3 p-5">
      <div className="flex items-center justify-between">
        <h2 className="heading flex items-center gap-2 text-lg font-bold text-zinc-50">
          <ImageIcon className="h-5 w-5 text-gold" /> Photos
        </h2>
        <span className="text-sm text-zinc-400">{photos.length} / 3</span>
      </div>
      <p className="text-sm text-zinc-400">
        Add up to 3 photos for this day (meals, progress, etc.).
      </p>
      <div className="grid grid-cols-3 gap-2">
        {photos.map((src, i) => (
          <div
            key={i}
            className="relative aspect-square overflow-hidden rounded-xl border border-white/10 bg-ink-900"
          >
            <img src={src} alt={`Day photo ${i + 1}`} className="h-full w-full object-cover" />
            <button
              type="button"
              aria-label={`Remove photo ${i + 1}`}
              onClick={() => onChange(photos.filter((_, j) => j !== i))}
              className="absolute right-1 top-1 grid h-7 w-7 place-items-center rounded-full bg-black/60 text-white backdrop-blur transition hover:bg-black/80"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        ))}
        {photos.length < 3 && (
          <button
            type="button"
            onClick={() => inputRef.current?.click()}
            disabled={busy}
            className="grid aspect-square place-items-center rounded-xl border border-dashed border-white/15 bg-ink-900 text-zinc-500 transition hover:border-gold/50 hover:text-gold disabled:opacity-50"
          >
            <span className="flex flex-col items-center gap-1 text-xs">
              <ImagePlus className="h-6 w-6" />
              {busy ? 'Adding…' : 'Add photo'}
            </span>
          </button>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        multiple
        hidden
        onChange={(e) => onFiles(e.target.files)}
      />
    </section>
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
