import { useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Dumbbell, Plus, Search } from 'lucide-react'
import { useStore } from '../store'
import type { MaxRecord } from '../types'
import { cn, todayISO, uid } from '../lib/utils'

export function MaxTracker() {
  const navigate = useNavigate()
  const maxTrackers = useStore((s) => s.maxTrackers)
  const addMaxRecord = useStore((s) => s.addMaxRecord)
  const unit = useStore((s) => s.unit)

  const [adding, setAdding] = useState(false)
  const [name, setName] = useState('')
  const [weight, setWeight] = useState('')
  const [reps, setReps] = useState('')
  const [errors, setErrors] = useState<{ name?: boolean; weight?: boolean; reps?: boolean }>({})
  const [query, setQuery] = useState('')

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return maxTrackers
    return maxTrackers.filter((t) => t.name.toLowerCase().includes(q))
  }, [maxTrackers, query])

  function reset() {
    setName('')
    setWeight('')
    setReps('')
    setErrors({})
    setAdding(false)
  }

  function save() {
    const w = parseFloat(weight)
    const r = parseInt(reps, 10)
    const next = {
      name: !name.trim(),
      weight: !(w > 0),
      reps: !(r > 0),
    }
    if (next.name || next.weight || next.reps) {
      setErrors(next)
      return
    }
    const record: MaxRecord = { id: uid(), date: todayISO(), weight: w, reps: r }
    addMaxRecord(name, record)
    reset()
  }

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div className="flex items-end justify-between gap-3">
        <div>
          <p className="label-eyebrow">Personal records</p>
          <h1 className="heading text-3xl font-bold text-zinc-50">Max Tracker</h1>
        </div>
        {!adding && (
          <button onClick={() => setAdding(true)} className="btn-gold shrink-0">
            <Plus className="h-4 w-4" /> New
          </button>
        )}
      </div>

      {adding && (
        <section className="card space-y-3 p-5">
          <h2 className="heading text-lg font-bold text-zinc-50">New entry</h2>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-zinc-300">Exercise</label>
            <input
              value={name}
              onChange={(e) => {
                setName(e.target.value)
                setErrors((x) => ({ ...x, name: false }))
              }}
              placeholder="e.g. Back Squat"
              className={cn('input', errors.name && 'border-red-500')}
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-300">
                Max weight ({unit})
              </label>
              <input
                type="number"
                inputMode="decimal"
                value={weight}
                onChange={(e) => {
                  setWeight(e.target.value)
                  setErrors((x) => ({ ...x, weight: false }))
                }}
                placeholder="0"
                className={cn('input', errors.weight && 'border-red-500')}
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-300">Reps</label>
              <input
                type="number"
                inputMode="numeric"
                value={reps}
                onChange={(e) => {
                  setReps(e.target.value)
                  setErrors((x) => ({ ...x, reps: false }))
                }}
                placeholder="0"
                className={cn('input', errors.reps && 'border-red-500')}
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={save} className="btn-gold flex-1">
              Save
            </button>
            <button onClick={reset} className="btn-ghost flex-1">
              Cancel
            </button>
          </div>
        </section>
      )}

      {maxTrackers.length === 0 && !adding ? (
        <div className="card p-8 text-center">
          <Dumbbell className="mx-auto h-8 w-8 text-zinc-600" />
          <p className="mt-3 text-sm text-zinc-400">
            No lifts tracked yet. Tap “New” to log your first max.
          </p>
        </div>
      ) : (
        <>
          {maxTrackers.length > 0 && (
            <div className="relative">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-500" />
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search"
                className="w-full rounded-xl border border-white/10 bg-ink-850 py-2.5 pl-9 pr-3 text-sm text-zinc-100 placeholder:text-zinc-500 focus:border-gold/60 focus:outline-none"
              />
            </div>
          )}
          {filtered.length === 0 ? (
            query.trim() ? (
              <div className="card p-6 text-center text-sm text-zinc-500">
                No max cards match “{query.trim()}”.
              </div>
            ) : null
          ) : (
            <div className="space-y-2">
              {filtered.map((t) => {
                const latest = [...t.records].sort((a, b) => (a.date < b.date ? 1 : -1))[0]
                return (
                  <Link
                    key={t.id}
                    to={`/max/${t.id}`}
                    className="card flex items-center justify-between gap-3 p-4 transition hover:border-white/20"
                  >
                    <span className="truncate font-semibold text-zinc-100">{t.name}</span>
                    {latest && (
                      <span className="shrink-0 font-semibold text-zinc-100">
                        {latest.weight} {unit} × {latest.reps}
                      </span>
                    )}
                  </Link>
                )
              })}
            </div>
          )}
        </>
      )}
    </div>
  )
}
