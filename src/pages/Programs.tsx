import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { CheckCircle2, Clock, Dumbbell } from 'lucide-react'
import { PROGRAMS } from '../data/programs'
import { useStore } from '../store'
import type { ProgramCategory } from '../types'
import { cn } from '../lib/utils'

const CATEGORIES: Array<ProgramCategory | 'All'> = [
  'All',
  'Bodybuilding',
  'Strength',
  'HIIT',
  'Powerlifting',
  'Functional',
  'Bodyweight',
]

export function Programs() {
  const [filter, setFilter] = useState<ProgramCategory | 'All'>('All')
  const activeProgramId = useStore((s) => s.activeProgramId)

  const list = useMemo(
    () => (filter === 'All' ? PROGRAMS : PROGRAMS.filter((p) => p.category === filter)),
    [filter],
  )

  return (
    <div className="animate-fade-in space-y-5">
      <div>
        <p className="label-eyebrow">Train with intent</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">Programs</h1>
      </div>

      <div className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1">
        {CATEGORIES.map((c) => (
          <button
            key={c}
            onClick={() => setFilter(c)}
            className={cn(
              'whitespace-nowrap rounded-full border px-3.5 py-1.5 text-xs font-semibold transition',
              filter === c
                ? 'border-gold bg-gold text-ink-950'
                : 'border-white/10 bg-ink-850 text-zinc-300 hover:border-white/20',
            )}
          >
            {c}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {list.map((p) => {
          const isActive = p.id === activeProgramId
          return (
            <Link
              key={p.id}
              to={`/programs/${p.id}`}
              className="card block overflow-hidden p-0"
            >
              <div
                className="p-5"
                style={{ background: `linear-gradient(150deg, ${p.accent}1f, transparent 60%)` }}
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <span className="label-eyebrow" style={{ color: p.accent }}>
                      {p.category} · {p.level}
                    </span>
                    <h2 className="heading mt-1 text-xl font-bold text-zinc-50">{p.name}</h2>
                  </div>
                  {isActive && (
                    <span className="inline-flex items-center gap-1 rounded-full bg-gold/15 px-2 py-1 text-[11px] font-semibold text-gold">
                      <CheckCircle2 className="h-3.5 w-3.5" /> Active
                    </span>
                  )}
                </div>
                <p className="mt-2 text-sm text-zinc-400">{p.summary}</p>
                <div className="mt-3 flex flex-wrap items-center gap-3 text-xs text-zinc-400">
                  <span className="inline-flex items-center gap-1">
                    <Clock className="h-3.5 w-3.5" /> {p.durationWeeks} weeks
                  </span>
                  <span className="inline-flex items-center gap-1">
                    <Dumbbell className="h-3.5 w-3.5" /> {p.daysPerWeek} days / week
                  </span>
                  <span className="text-zinc-500">· {p.goal}</span>
                </div>
              </div>
            </Link>
          )
        })}
      </div>
    </div>
  )
}
