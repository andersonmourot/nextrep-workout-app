import { useState } from 'react'
import { Plus, Trash2, TrendingUp } from 'lucide-react'
import { useStore } from '../store'
import {
  computeStreak,
  formatDate,
  formatDateLong,
  formatDuration,
  todayISO,
  totalVolume,
  uid,
} from '../lib/utils'
import type { BodyWeightEntry } from '../types'

export function Progress() {
  const { logs, bodyWeight, unit, addBodyWeight, deleteBodyWeight, deleteLog } = useStore()
  const [weight, setWeight] = useState('')

  const streak = computeStreak(logs)
  const vol = totalVolume(logs)

  function logWeight() {
    const w = parseFloat(weight)
    if (!w || w <= 0) return
    const entry: BodyWeightEntry = { id: uid(), date: todayISO(), weight: w }
    addBodyWeight(entry)
    setWeight('')
  }

  return (
    <div className="animate-fade-in space-y-6">
      <div>
        <p className="label-eyebrow">Track your transformation</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">Progress</h1>
      </div>

      <section className="grid grid-cols-3 gap-3 text-center">
        <Stat value={`${logs.length}`} label="Workouts" />
        <Stat value={`${streak}`} label="Day streak" />
        <Stat value={`${(vol / 1000).toFixed(1)}k`} label={`Volume (${unit})`} />
      </section>

      {/* Body weight */}
      <section className="card p-5">
        <div className="flex items-center justify-between">
          <h2 className="heading text-lg font-bold text-zinc-50">Body Weight</h2>
          <span className="text-xs text-zinc-500">{unit}</span>
        </div>

        <WeightChart entries={bodyWeight} />

        <div className="mt-4 flex gap-2">
          <input
            type="number"
            inputMode="decimal"
            value={weight}
            onChange={(e) => setWeight(e.target.value)}
            placeholder={`Today's weight (${unit})`}
            className="input"
            onKeyDown={(e) => e.key === 'Enter' && logWeight()}
          />
          <button onClick={logWeight} className="btn-gold shrink-0">
            <Plus className="h-4 w-4" /> Log
          </button>
        </div>

        {bodyWeight.length > 0 && (
          <ul className="mt-4 space-y-1.5">
            {[...bodyWeight]
              .reverse()
              .slice(0, 5)
              .map((e) => (
                <li
                  key={e.id}
                  className="flex items-center justify-between rounded-lg bg-ink-900 px-3 py-2 text-sm"
                >
                  <span className="text-zinc-400">{formatDateLong(e.date)}</span>
                  <span className="flex items-center gap-3">
                    <span className="font-semibold text-zinc-100">
                      {e.weight} {unit}
                    </span>
                    <button
                      onClick={() => deleteBodyWeight(e.id)}
                      className="text-zinc-600 hover:text-red-400"
                      aria-label="Delete entry"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </span>
                </li>
              ))}
          </ul>
        )}
      </section>

      {/* History */}
      <section>
        <h2 className="heading mb-2 text-sm font-semibold tracking-wider text-zinc-300">
          Workout History
        </h2>
        {logs.length === 0 ? (
          <div className="card p-6 text-center text-sm text-zinc-400">
            No workouts logged yet. Finish a session to see it here.
          </div>
        ) : (
          <ul className="space-y-2">
            {logs.map((log) => {
              const setCount = log.exercises.reduce((a, e) => a + e.sets.length, 0)
              return (
                <li key={log.id} className="card p-4">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="text-sm font-semibold text-zinc-100">{log.dayName}</p>
                      <p className="text-xs text-zinc-500">
                        {log.programName} · {formatDate(log.date)}
                      </p>
                    </div>
                    <button
                      onClick={() => deleteLog(log.id)}
                      className="text-zinc-600 hover:text-red-400"
                      aria-label="Delete workout"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                  <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-zinc-400">
                    <span>{formatDuration(log.durationSec)}</span>
                    <span>{setCount} sets</span>
                    <span className="inline-flex items-center gap-1 text-gold">
                      <TrendingUp className="h-3.5 w-3.5" />
                      {Math.round(log.totalVolume).toLocaleString()} {unit}
                    </span>
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </section>
    </div>
  )
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div className="card p-4">
      <div className="heading text-2xl font-bold text-zinc-50">{value}</div>
      <div className="mt-1 text-[11px] text-zinc-500">{label}</div>
    </div>
  )
}

function WeightChart({ entries }: { entries: BodyWeightEntry[] }) {
  if (entries.length < 2) {
    return (
      <div className="mt-3 grid h-32 place-items-center rounded-xl border border-dashed border-white/10 bg-ink-900/50 text-center text-xs text-zinc-500">
        {entries.length === 0
          ? 'Log your weight to start a trend line.'
          : 'Log one more entry to see your trend.'}
      </div>
    )
  }

  const w = 320
  const h = 120
  const pad = 12
  const weights = entries.map((e) => e.weight)
  const min = Math.min(...weights)
  const max = Math.max(...weights)
  const range = max - min || 1
  const n = entries.length

  const points = entries.map((e, i) => {
    const x = pad + (i / (n - 1)) * (w - pad * 2)
    const y = pad + (1 - (e.weight - min) / range) * (h - pad * 2)
    return [x, y] as const
  })

  const path = points.map(([x, y], i) => `${i === 0 ? 'M' : 'L'} ${x.toFixed(1)} ${y.toFixed(1)}`).join(' ')
  const area = `${path} L ${points[n - 1][0].toFixed(1)} ${h - pad} L ${points[0][0].toFixed(1)} ${h - pad} Z`
  const first = entries[0].weight
  const last = entries[n - 1].weight
  const diff = +(last - first).toFixed(1)

  return (
    <div className="mt-3">
      <div className="mb-1 flex items-end justify-between">
        <span className="heading text-2xl font-bold text-zinc-50">{last}</span>
        <span
          className={`text-xs font-semibold ${diff < 0 ? 'text-emerald-400' : diff > 0 ? 'text-gold' : 'text-zinc-500'}`}
        >
          {diff > 0 ? '+' : ''}
          {diff} since start
        </span>
      </div>
      <svg viewBox={`0 0 ${w} ${h}`} className="w-full" preserveAspectRatio="none">
        <defs>
          <linearGradient id="wg" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor="#e9b949" stopOpacity="0.35" />
            <stop offset="100%" stopColor="#e9b949" stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={area} fill="url(#wg)" />
        <path d={path} fill="none" stroke="#e9b949" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round" />
        {points.map(([x, y], i) => (
          <circle key={i} cx={x} cy={y} r={2.5} fill="#e9b949" />
        ))}
      </svg>
    </div>
  )
}
