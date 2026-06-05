import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  ArrowLeft,
  Check,
  CheckCircle2,
  Clock,
  Dumbbell,
  EyeOff,
  Plus,
  RotateCcw,
  Search,
  Settings2,
  Star,
  Trash2,
  X,
} from 'lucide-react'
import { useAllPrograms, useStore, TRASH_TTL_MS } from '../store'
import { PROGRAMS } from '../data/programs'
import type { ProgramCategory } from '../types'
import { cn, trashTimeLeft } from '../lib/utils'

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
  const [query, setQuery] = useState('')
  const [managing, setManaging] = useState(false)
  const [showHidden, setShowHidden] = useState(false)
  const [showTrash, setShowTrash] = useState(false)
  const [confirmId, setConfirmId] = useState<string | null>(null)
  const activeProgramId = useStore((s) => s.activeProgramId)
  const favoriteProgramIds = useStore((s) => s.favoriteProgramIds)
  const customPrograms = useStore((s) => s.customPrograms)
  const hiddenProgramIds = useStore((s) => s.hiddenProgramIds)
  const hiddenCount = hiddenProgramIds.length
  const trashedPrograms = useStore((s) => s.trashedPrograms)
  const deleteProgram = useStore((s) => s.deleteProgram)
  const restoreProgram = useStore((s) => s.restoreProgram)
  const restorePrograms = useStore((s) => s.restorePrograms)
  const restoreTrashedProgram = useStore((s) => s.restoreTrashedProgram)
  const purgeTrashedProgram = useStore((s) => s.purgeTrashedProgram)
  const customIds = useMemo(() => new Set(customPrograms.map((p) => p.id)), [customPrograms])
  const allPrograms = useAllPrograms()

  // Default programs the user has hidden (moved to the "Hidden" list).
  const hiddenList = useMemo(
    () => PROGRAMS.filter((p) => hiddenProgramIds.includes(p.id)),
    [hiddenProgramIds],
  )

  const list = useMemo(() => {
    const byCat =
      filter === 'All' ? allPrograms : allPrograms.filter((p) => p.category === filter)
    const q = query.trim().toLowerCase()
    if (!q) return byCat
    return byCat.filter((p) =>
      [p.name, p.summary, p.goal, p.coach, p.category, p.level, ...(p.tags ?? [])]
        .filter(Boolean)
        .some((s) => s.toLowerCase().includes(q)),
    )
  }, [filter, allPrograms, query])

  // Pin the active program first, then favorites (in the order they were
  // favorited), then everything else (original order preserved by stable sort).
  const orderedList = useMemo(() => {
    const rank = (id: string) => {
      if (id === activeProgramId) return 0
      const fi = favoriteProgramIds.indexOf(id)
      return fi === -1 ? 100 : 1 + fi
    }
    return [...list].sort((a, b) => rank(a.id) - rank(b.id))
  }, [list, activeProgramId, favoriteProgramIds])

  function toggleManaging() {
    setManaging((m) => !m)
    setConfirmId(null)
    setShowHidden(false)
    setShowTrash(false)
  }

  if (showHidden) {
    return (
      <div className="animate-fade-in space-y-5">
        <button
          onClick={() => setShowHidden(false)}
          className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
        >
          <ArrowLeft className="h-4 w-4" /> Back
        </button>
        <h1 className="heading text-3xl font-bold text-zinc-50">Hidden programs</h1>
        <p className="text-xs text-zinc-500">
          {hiddenList.length === 0
            ? 'No hidden programs.'
            : 'Restore a program to return it to the main list.'}
        </p>
        <ul className="space-y-2">
          {hiddenList.map((p) => (
            <li key={p.id} className="card flex items-center justify-between gap-3 p-4">
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-zinc-100">{p.name}</p>
                <div className="mt-1 flex flex-wrap gap-1.5">
                  <span className="chip" style={{ color: p.accent }}>
                    {p.category}
                  </span>
                  <span className="chip">{p.level}</span>
                  <span className="chip">{p.durationWeeks} weeks</span>
                </div>
              </div>
              <button
                onClick={() => restoreProgram(p.id)}
                className="btn-ghost inline-flex shrink-0 items-center gap-1.5 px-3 py-2 text-xs font-semibold text-gold"
              >
                <RotateCcw className="h-3.5 w-3.5" /> Restore
              </button>
            </li>
          ))}
        </ul>
      </div>
    )
  }

  if (showTrash) {
    return (
      <div className="animate-fade-in space-y-5">
        <button
          onClick={() => setShowTrash(false)}
          className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
        >
          <ArrowLeft className="h-4 w-4" /> Back
        </button>
        <h1 className="heading text-3xl font-bold text-zinc-50">Trash</h1>
        <p className="text-xs text-zinc-500">
          {trashedPrograms.length === 0
            ? 'No deleted custom programs.'
            : 'Deleted custom programs are kept for 7 days, then removed for good.'}
        </p>
        <ul className="space-y-2">
          {trashedPrograms.map((t) => (
            <li key={t.program.id} className="card flex items-center justify-between gap-3 p-4">
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold text-zinc-100">{t.program.name}</p>
                <div className="mt-1 flex flex-wrap items-center gap-1.5">
                  <span className="chip" style={{ color: t.program.accent }}>
                    {t.program.category}
                  </span>
                  <span className="chip">{t.program.level}</span>
                  <span className="text-[11px] font-medium text-zinc-500">
                    {trashTimeLeft(t.deletedAt, TRASH_TTL_MS)}
                  </span>
                </div>
              </div>
              <div className="flex shrink-0 items-center gap-1">
                <button
                  onClick={() => restoreTrashedProgram(t.program.id)}
                  className="btn-ghost inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold text-gold"
                >
                  <RotateCcw className="h-3.5 w-3.5" /> Restore
                </button>
                <button
                  onClick={() => purgeTrashedProgram(t.program.id)}
                  aria-label={`Delete ${t.program.name} permanently`}
                  className="grid h-8 w-8 place-items-center rounded-lg text-zinc-400 hover:text-red-400"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </li>
          ))}
        </ul>
      </div>
    )
  }

  return (
    <div className="animate-fade-in space-y-5">
      <div className="flex items-end justify-between gap-3">
        <div>
          <h1 className="heading text-3xl font-bold text-zinc-50">Programs</h1>
        </div>
        <div className="flex shrink-0 gap-2">
          {managing && hiddenCount > 0 && (
            <button onClick={() => setShowHidden(true)} className="btn-ghost px-3 py-2 text-sm">
              Hidden ({hiddenCount})
            </button>
          )}
          {managing && trashedPrograms.length > 0 && (
            <button
              onClick={() => setShowTrash(true)}
              aria-label={`Trash (${trashedPrograms.length})`}
              className="btn-ghost inline-flex items-center gap-1.5 px-3 py-2 text-sm"
            >
              <Trash2 className="h-4 w-4" /> {trashedPrograms.length}
            </button>
          )}
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

      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-500" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search programs"
          className="w-full rounded-xl border border-white/10 bg-ink-850 py-2.5 pl-9 pr-3 text-sm text-zinc-100 placeholder:text-zinc-500 focus:border-gold/60 focus:outline-none"
        />
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

      <div className="space-y-3">
        {orderedList.map((p) => {
          const isActive = p.id === activeProgramId
          const isCustom = customIds.has(p.id)
          const isFavorite = favoriteProgramIds.includes(p.id)
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
                    {isFavorite && !isActive && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-gold/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-gold">
                        <Star className="h-3 w-3 fill-current" /> Favorite
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
                      aria-label={isCustom ? 'Confirm delete' : 'Confirm hide'}
                      className={cn(
                        'grid h-7 w-7 place-items-center rounded-lg',
                        isCustom ? 'text-red-400 hover:text-red-300' : 'text-gold hover:text-gold-400',
                      )}
                    >
                      <Check className="h-4 w-4" />
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => setConfirmId(p.id)}
                    aria-label={isCustom ? `Delete ${p.name}` : `Hide ${p.name}`}
                    className={cn(
                      'absolute right-2 top-2 z-10 grid h-8 w-8 place-items-center rounded-lg bg-ink-900/80 text-zinc-400 backdrop-blur',
                      isCustom ? 'hover:text-red-400' : 'hover:text-gold',
                    )}
                  >
                    {isCustom ? <Trash2 className="h-4 w-4" /> : <EyeOff className="h-4 w-4" />}
                  </button>
                ))}
            </div>
          )
        })}

        {list.length === 0 && (
          <div className="card p-8 text-center">
            <p className="text-sm text-zinc-400">
              {query.trim()
                ? `No programs match “${query.trim()}”.`
                : filter === 'All'
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
