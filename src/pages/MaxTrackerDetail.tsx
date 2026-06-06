import { useState } from 'react'
import { Navigate, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Check, Plus, Trash2, X } from 'lucide-react'
import { useStore } from '../store'
import type { MaxRecord } from '../types'
import { TrendChart } from '../components/TrendChart'
import { cn, formatDateLong, todayISO, uid } from '../lib/utils'

export function MaxTrackerDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const tracker = useStore((s) => s.maxTrackers.find((t) => t.id === id))
  const addMaxRecordToTracker = useStore((s) => s.addMaxRecordToTracker)
  const deleteMaxRecord = useStore((s) => s.deleteMaxRecord)
  const deleteMaxTracker = useStore((s) => s.deleteMaxTracker)
  const unit = useStore((s) => s.unit)
  const themeColor = useStore((s) => s.themeColor)

  const [weight, setWeight] = useState('')
  const [reps, setReps] = useState('')
  const [errors, setErrors] = useState<{ weight?: boolean; reps?: boolean }>({})
  const [confirmId, setConfirmId] = useState<string | null>(null)
  const [confirmDelete, setConfirmDelete] = useState(false)

  if (!tracker) return <Navigate to="/max" replace />

  const sorted = [...tracker.records].sort((a, b) => (a.date < b.date ? -1 : 1))
  const best = tracker.records.reduce(
    (m, r) => (r.weight > m ? r.weight : m),
    0,
  )

  function add() {
    const w = parseFloat(weight)
    const r = parseInt(reps, 10)
    const next = { weight: !(w > 0), reps: !(r > 0) }
    if (next.weight || next.reps) {
      setErrors(next)
      return
    }
    const record: MaxRecord = { id: uid(), date: todayISO(), weight: w, reps: r }
    addMaxRecordToTracker(tracker!.id, record)
    setWeight('')
    setReps('')
    setErrors({})
  }

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate('/max')}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div>
        <p className="label-eyebrow">Max tracker</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">{tracker.name}</h1>
        {best > 0 && (
          <p className="mt-1 text-sm text-zinc-400">
            Best: <span className="font-semibold text-zinc-200">{best} {unit}</span>
          </p>
        )}
      </div>

      {/* Trend */}
      <section className="card p-5">
        <h2 className="heading mb-3 text-lg font-bold text-zinc-50">Trend</h2>
        <TrendChart
          points={sorted.map((r) => ({ value: r.weight }))}
          accent={themeColor}
          unit={unit}
          emptyLabel="Log a max to start a trend line."
          oneMoreLabel="Log one more max to see your trend."
        />
      </section>

      {/* Add entry */}
      <section className="card space-y-3 p-5">
        <h2 className="heading text-lg font-bold text-zinc-50">Log a max</h2>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-zinc-300">
              Weight ({unit})
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
        <button onClick={add} className="btn-gold w-full">
          <Plus className="h-4 w-4" /> Add entry
        </button>
      </section>

      {/* History */}
      <section className="card p-5">
        <h2 className="heading mb-3 text-lg font-bold text-zinc-50">History</h2>
        {tracker.records.length === 0 ? (
          <p className="text-sm text-zinc-500">No entries yet.</p>
        ) : (
          <ul className="space-y-1.5">
            {[...sorted].reverse().map((r) => (
              <li
                key={r.id}
                className="flex items-center justify-between rounded-lg bg-ink-900 px-3 py-2 text-sm"
              >
                <span className="text-zinc-400">{formatDateLong(r.date)}</span>
                <span className="flex items-center gap-3">
                  <span className="font-semibold text-zinc-100">
                    {r.weight} {unit} × {r.reps}
                  </span>
                  {confirmId === r.id ? (
                    <span className="flex items-center gap-1">
                      <button
                        onClick={() => {
                          deleteMaxRecord(tracker.id, r.id)
                          setConfirmId(null)
                        }}
                        aria-label="Confirm delete"
                        className="rounded-md p-1 text-emerald-400 hover:bg-white/5"
                      >
                        <Check className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => setConfirmId(null)}
                        aria-label="Cancel delete"
                        className="rounded-md p-1 text-zinc-400 hover:bg-white/5"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </span>
                  ) : (
                    <button
                      onClick={() => setConfirmId(r.id)}
                      aria-label="Delete entry"
                      className="rounded-md p-1 text-zinc-500 hover:text-red-400"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  )}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* Delete tracker */}
      <section className="card border-red-500/20 p-5">
        {confirmDelete ? (
          <div className="flex items-center justify-between gap-3">
            <p className="text-sm text-zinc-300">Delete “{tracker.name}” and its history?</p>
            <span className="flex shrink-0 items-center gap-1">
              <button
                onClick={() => {
                  deleteMaxTracker(tracker.id)
                  navigate('/max')
                }}
                aria-label="Confirm delete tracker"
                className="rounded-md p-1.5 text-emerald-400 hover:bg-white/5"
              >
                <Check className="h-5 w-5" />
              </button>
              <button
                onClick={() => setConfirmDelete(false)}
                aria-label="Cancel delete tracker"
                className="rounded-md p-1.5 text-zinc-400 hover:bg-white/5"
              >
                <X className="h-5 w-5" />
              </button>
            </span>
          </div>
        ) : (
          <button
            onClick={() => setConfirmDelete(true)}
            className="btn w-full border border-red-500/40 text-red-300 hover:bg-red-500/10"
          >
            <Trash2 className="h-4 w-4" /> Delete tracker
          </button>
        )}
      </section>
    </div>
  )
}
