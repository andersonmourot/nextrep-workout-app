import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Check,
  CheckCircle2,
  Clock,
  Dumbbell,
  Plus,
  RotateCcw,
  Settings2,
  Trash2,
  X,
} from 'lucide-react'
import { useAllPrograms, useStore } from '../store'
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
  const [managing, setManaging] = useState(false)
  const [confirmId, setConfirmId] = useState<string | null>(null)
  const activeProgramId = useStore((s) => s.activeProgramId)
  const customPrograms = useStore((s) => s.customPrograms)
  const hiddenCount = useStore((s) => s.hiddenProgramIds.length)
  const deleteProgram = useStore((s) => s.deleteProgram)
  const restorePrograms = useStore((s) => s.restorePrograms)
  const customIds = useMemo(() => new Set(customPrograms.map((p) => p.id)), [customPrograms])
  const allPrograms = useAllPrograms()

  const list = useMemo(
    () => (filter === 'All' ? allPrograms : allPrograms.filter((p) => p.category === filter)),
    [filter, allPrograms],
  )

  function toggleManaging() {
    setManaging((m) => !m)
    setConfirmId(null)
  }

  return (
    <div className="animate-fade-in space-y-5">
      <div className="flex items-end justify-between gap-3">
        <div>
          <h1 className="heading text-3xl font-bold text-zinc-50">Programs</h1>
        </div>
        <div className="flex shrink-0 gap-2">
          <Link to="/programs/exercises" aria-label="Exercises" className="btn-ghost px-3 py-2 text-sm">
            <Dumbbell className="h-4 w-4" />
          </Link>
          <button
            onClick={toggleManaging}
            aria-label={managing ? 'Done managing' : 'Manage programs'}
            className={cn('btn-ghost px-3 py-2 text-sm', managing && 'text-gold')}
          >
            {managing ? 'Done' : <Settings2 className="h-4 w-4" />}
          </button>
          <Link
            to="/programs/new"
            aria-label="Create program"
            className="btn-gold px-3 py-2 text-sm"
          >
            <Plus className="h-4 w-4" />
          </Link>
        </div>
      </div>

      <div className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1">
        {CATEGORIES.map((c) => (
          <button
            key={c}
            onClick={() => setFilter(c)}
            className={cn(
              'whitespace-nowrap rounded-full border px-3.5 py-1.5 text-xs font-semibold transition',
              filter === c
                ? 'border-gold bg-gold text-white'
                : 'border-white/10 bg-ink-850 text-zinc-300 hover:border-white/20',
            )}
          >
            {c}
          </button>
        ))}
      </div>

      {managing && hiddenCount > 0 && (
        <button
          onClick={restorePrograms}
          className="inline-flex items-center gap-1.5 text-xs font-semibold text-gold hover:text-gold-400"
        >
          <RotateCcw className="h-3.5 w-3.5" /> Restore {hiddenCount} default program
          {hiddenCount > 1 ? 's' : ''}
        </button>
      )}

      <div className="space-y-3">
        {list.map((p) => {
          const isActive = p.id === activeProgramId
          const isCustom = customIds.has(p.id)
          return (
            <div key={p.id} className="relative">
              <Link to={`/programs/${p.id}`} className="card block overflow-hidden p-0">
                <div
                  className="p-5"
                  style={{ background: `linear-gradient(150deg, ${p.accent}1f, transparent 60%)` }}
                >
                  <div className="flex flex-wrap items-center gap-2 pr-9">
                    <span className="label-eyebrow" style={{ color: p.accent }}>
                      {p.category} · {p.level}
                    </span>
                    {isCustom && (
                      <span className="rounded-full bg-gold/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-gold">
                        Custom
                      </span>
                    )}
                    {isActive && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-gold/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-gold">
                        <CheckCircle2 className="h-3 w-3" /> Active
                      </span>
                    )}
                  </div>
                  <h2 className="heading mt-1 text-xl font-bold text-zinc-50">{p.name}</h2>
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

              {managing &&
                (confirmId === p.id ? (
                  <div className="absolute right-2 top-2 z-10 flex items-center gap-1.5 rounded-lg border border-white/10 bg-ink-800 px-2 py-1.5 shadow-lg">
                    <button
                      onClick={() => setConfirmId(null)}
                      aria-label="Cancel"
                      className="grid h-7 w-7 place-items-center rounded-lg text-zinc-300 hover:text-zinc-100"
                    >
                      <X className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => {
                        deleteProgram(p.id)
                        setConfirmId(null)
                      }}
                      aria-label="Confirm delete"
                      className="grid h-7 w-7 place-items-center rounded-lg text-red-400 hover:text-red-300"
                    >
                      <Check className="h-4 w-4" />
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => setConfirmId(p.id)}
                    aria-label={`Delete ${p.name}`}
                    className="absolute right-2 top-2 z-10 grid h-8 w-8 place-items-center rounded-lg bg-ink-900/80 text-zinc-400 backdrop-blur hover:text-red-400"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                ))}
            </div>
          )
        })}

        {list.length === 0 && (
          <div className="card p-8 text-center">
            <p className="text-sm text-zinc-400">
              {filter === 'All'
                ? 'No programs yet.'
                : `No ${filter} programs.`}
            </p>
            <div className="mt-4 flex justify-center gap-2">
              {hiddenCount > 0 && (
                <button onClick={restorePrograms} className="btn-outline">
                  <RotateCcw className="h-4 w-4" /> Restore defaults
                </button>
              )}
              <Link to="/programs/new" className="btn-gold">
                <Plus className="h-4 w-4" /> Create one
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
