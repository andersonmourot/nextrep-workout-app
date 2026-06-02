import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ChevronRight, Search } from 'lucide-react'
import { EXERCISES } from '../data/exercises'
import type { Muscle } from '../types'
import { cn } from '../lib/utils'

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

export function Exercises() {
  const [q, setQ] = useState('')
  const [muscle, setMuscle] = useState<Muscle | 'All'>('All')

  const list = useMemo(() => {
    const query = q.trim().toLowerCase()
    return EXERCISES.filter((e) => {
      const matchMuscle = muscle === 'All' || e.primaryMuscle === muscle
      const matchQuery =
        !query ||
        e.name.toLowerCase().includes(query) ||
        e.primaryMuscle.toLowerCase().includes(query) ||
        e.equipment.toLowerCase().includes(query)
      return matchMuscle && matchQuery
    })
  }, [q, muscle])

  return (
    <div className="animate-fade-in space-y-5">
      <div>
        <p className="label-eyebrow">Perfect your form</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">Exercises</h1>
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
                <p className="truncate text-sm font-semibold text-zinc-100">{e.name}</p>
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
    </div>
  )
}
