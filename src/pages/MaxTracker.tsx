import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, ChevronRight, Dumbbell, Plus } from 'lucide-react'
import { useStore } from '../store'
import type { MaxRecord } from '../types'
import { cn, formatDateLong, todayISO, uid } from '../lib/utils'

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
        <div className="space-y-2">
          {maxTrackers.map((t) => {
            const latest = [...t.records].sort((a, b) => (a.date < b.date ? 1 : -1))[0]
            return (
              <Link
                key={t.id}
                to={`/max/${t.id}`}
                className="card flex items-center justify-between p-4 transition hover:border-white/20"
              >
                <div className="min-w-0">
                  <p className="truncate font-semibold text-zinc-100">{t.name}</p>
                  {latest && (
                    <p className="truncate text-xs text-zinc-500">
                      {latest.weight} {unit} × {latest.reps} · {formatDateLong(latest.date)}
                    </p>
                  )}
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-zinc-500" />
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}
