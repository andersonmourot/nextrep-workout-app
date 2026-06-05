import { useCallback, useEffect, useRef, useState } from 'react'
import {
  Check,
  ChevronDown,
  Dumbbell,
  Plus,
  Search,
  Star,
  UserMinus,
  UserPlus,
  Users,
} from 'lucide-react'
import {
  apiAddExercise,
  apiAddProgram,
  apiFollow,
  apiFollowing,
  apiSearchUsers,
  apiUnfollow,
  apiUserExercises,
  apiUserPrograms,
  type DiscoverUser,
  type FollowUser,
} from '../api'
import { getToken, useAuth } from '../auth'
import { MAX_FAVORITES, useStore } from '../store'
import type { Exercise, Program } from '../types'
import { cn } from '../lib/utils'

export function People() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<DiscoverUser[]>([])
  const [searching, setSearching] = useState(false)
  const [searched, setSearched] = useState(false)
  const [following, setFollowing] = useState<FollowUser[]>([])
  const [busyId, setBusyId] = useState<string | null>(null)
  const debounce = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)
  const favoriteUserIds = useStore((s) => s.favoriteUserIds)
  const toggleFavoriteUser = useStore((s) => s.toggleFavoriteUser)

  const loadFollowing = useCallback(async () => {
    const token = getToken()
    if (!token) return
    const res = await apiFollowing(token)
    if (res.ok && res.data) setFollowing(res.data)
  }, [])

  useEffect(() => {
    let active = true
    const token = getToken()
    if (!token) return
    void apiFollowing(token).then((res) => {
      if (active && res.ok && res.data) setFollowing(res.data)
    })
    return () => {
      active = false
    }
  }, [])

  const runSearch = useCallback(async (q: string) => {
    const token = getToken()
    if (!token || !q.trim()) {
      setResults([])
      setSearched(false)
      return
    }
    setSearching(true)
    const res = await apiSearchUsers(token, q.trim())
    setSearching(false)
    setSearched(true)
    if (res.ok && res.data) setResults(res.data)
  }, [])

  function onQueryChange(v: string) {
    setQuery(v)
    if (debounce.current) clearTimeout(debounce.current)
    debounce.current = setTimeout(() => void runSearch(v), 350)
  }

  async function toggleFollow(u: DiscoverUser) {
    const token = getToken()
    if (!token) return
    setBusyId(u.id)
    const res = u.following ? await apiUnfollow(token, u.id) : await apiFollow(token, u.id)
    setBusyId(null)
    if (res.ok) {
      setResults((prev) =>
        prev.map((r) => (r.id === u.id ? { ...r, following: !u.following } : r)),
      )
      void loadFollowing()
    }
  }

  async function unfollow(userId: string) {
    const token = getToken()
    if (!token) return
    setBusyId(userId)
    const res = await apiUnfollow(token, userId)
    setBusyId(null)
    if (res.ok) {
      setFollowing((prev) => prev.filter((f) => f.id !== userId))
      setResults((prev) => prev.map((r) => (r.id === userId ? { ...r, following: false } : r)))
    }
  }

  // Pin favorited accounts to the top; keep server order within each group.
  const sortedFollowing = [...following].sort((a, b) => {
    const fa = favoriteUserIds.includes(a.id) ? 0 : 1
    const fb = favoriteUserIds.includes(b.id) ? 0 : 1
    return fa - fb
  })
  const canFavorite = favoriteUserIds.length < MAX_FAVORITES

  return (
    <div className="animate-fade-in space-y-6">
      <div>
        <p className="label-eyebrow">Train together</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">People</h1>
        <p className="mt-1 text-sm text-zinc-400">
          Find other athletes by name, follow them, and add their programs.
        </p>
      </div>

      {/* Search */}
      <div>
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-500" />
          <input
            value={query}
            onChange={(e) => onQueryChange(e.target.value)}
            placeholder="Search by name"
            className="w-full rounded-xl border border-white/10 bg-ink-850 py-2.5 pl-9 pr-3 text-sm text-zinc-100 placeholder:text-zinc-500 focus:border-gold/60 focus:outline-none"
          />
        </div>

        {searching && <p className="mt-3 text-sm text-zinc-500">Searching…</p>}

        {!searching && searched && results.length === 0 && (
          <p className="mt-3 text-sm text-zinc-500">No users found for “{query}”.</p>
        )}

        {results.length > 0 && (
          <div className="mt-3 space-y-2">
            {results.map((u) => (
              <SearchResultCard
                key={u.id}
                user={u}
                busy={busyId === u.id}
                onToggleFollow={() => void toggleFollow(u)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Following */}
      <div>
        <div className="mb-3 flex items-center gap-2">
          <Users className="h-4 w-4 text-gold" />
          <h2 className="heading text-lg font-bold text-zinc-100">
            Following {following.length > 0 && `(${following.length})`}
          </h2>
        </div>

        {following.length === 0 ? (
          <div className="card p-6 text-center text-sm text-zinc-500">
            You’re not following anyone yet. Search above to find athletes and follow them.
          </div>
        ) : (
          <div className="space-y-3">
            {sortedFollowing.map((f) => {
              const favorited = favoriteUserIds.includes(f.id)
              return (
                <FollowingCard
                  key={f.id}
                  user={f}
                  onUnfollow={() => void unfollow(f.id)}
                  busy={busyId === f.id}
                  favorited={favorited}
                  canFavorite={canFavorite}
                  onToggleFavorite={() => toggleFavoriteUser(f.id)}
                />
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}

/** Expandable list of a user's shared programs and exercises (with Add buttons). */
function SharedContent({
  userId,
  ownerName,
  programCount,
  exerciseCount,
}: {
  userId: string
  ownerName: string
  programCount: number
  exerciseCount: number
}) {
  const [loading, setLoading] = useState(() => getToken() != null)
  const [programs, setPrograms] = useState<Program[]>([])
  const [exercises, setExercises] = useState<Exercise[]>([])
  const [addedPrograms, setAddedPrograms] = useState<Set<string>>(new Set())
  const [addedExercises, setAddedExercises] = useState<Set<string>>(new Set())
  const customPrograms = useStore((s) => s.customPrograms)
  const addProgram = useStore((s) => s.addProgram)
  const customExercises = useStore((s) => s.customExercises)
  const addCustomExercise = useStore((s) => s.addCustomExercise)
  const currentUserId = useAuth((s) => s.user?.id)

  useEffect(() => {
    let active = true
    const token = getToken()
    if (!token) return
    const tasks: Promise<void>[] = []
    if (programCount > 0) {
      tasks.push(
        apiUserPrograms<Program>(token, userId).then((res) => {
          if (active && res.ok && res.data) setPrograms(res.data.programs ?? [])
        }),
      )
    }
    if (exerciseCount > 0) {
      tasks.push(
        apiUserExercises<Exercise>(token, userId).then((res) => {
          if (active && res.ok && res.data) setExercises(res.data.exercises ?? [])
        }),
      )
    }
    void Promise.all(tasks).finally(() => {
      if (active) setLoading(false)
    })
    return () => {
      active = false
    }
  }, [userId, programCount, exerciseCount])

  async function addProgramToMine(p: Program) {
    const token = getToken()
    if (!token) return
    const res = await apiAddProgram<Program>(token, p.id)
    const program = res.ok && res.data ? res.data.program : { ...p, coach: p.coach || ownerName }
    addProgram({ ...program, coach: program.coach || ownerName })
    setAddedPrograms((prev) => new Set(prev).add(p.id))
  }

  async function addExerciseToMine(e: Exercise) {
    const token = getToken()
    // Register membership so the creator's edits propagate to this account.
    const res = token ? await apiAddExercise<Exercise>(token, e.id) : null
    const canon = res && res.ok && res.data ? res.data.exercise : e
    // Copy into the current user's library; don't auto-reshare from their
    // profile (shared:false), but keep ownerId/version so updates propagate.
    addCustomExercise({ ...canon, shared: false, ownerName: canon.ownerName || ownerName })
    setAddedExercises((prev) => new Set(prev).add(e.id))
  }

  return (
    <div className="space-y-4 border-t border-white/5 p-4">
      {loading && <p className="text-sm text-zinc-500">Loading…</p>}

      {programs.length > 0 && (
        <div>
          <h3 className="mb-2 flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-zinc-400">
            <Plus className="h-3.5 w-3.5" /> Programs
          </h3>
          <div className="space-y-2">
            {programs.map((p) => {
              const isOwner = !!currentUserId && p.ownerId === currentUserId
              const isAdded = addedPrograms.has(p.id) || customPrograms.some((c) => c.id === p.id)
              return (
                <div
                  key={p.id}
                  className="flex items-center justify-between gap-3 rounded-xl border border-white/5 bg-ink-900 p-3"
                >
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-zinc-100">{p.name}</p>
                    <p className="truncate text-xs text-zinc-500">
                      {p.category} · {p.level} · {p.days?.length ?? 0} day
                      {(p.days?.length ?? 0) === 1 ? '' : 's'}
                    </p>
                  </div>
                  {isOwner ? (
                    <span className="inline-flex shrink-0 items-center gap-1 rounded-lg border border-white/10 bg-ink-800 px-3 py-2 text-sm font-semibold text-zinc-400">
                      <Check className="h-4 w-4" /> Yours
                    </span>
                  ) : (
                    <button
                      onClick={() => void addProgramToMine(p)}
                      disabled={isAdded}
                      className={cn(
                        'shrink-0 rounded-lg px-3 py-2 text-sm font-semibold transition disabled:opacity-60',
                        isAdded ? 'border border-white/10 bg-ink-800 text-zinc-400' : 'btn-gold',
                      )}
                    >
                      {isAdded ? (
                        <>
                          <Check className="h-4 w-4" /> Added
                        </>
                      ) : (
                        <>
                          <Plus className="h-4 w-4" /> Add
                        </>
                      )}
                    </button>
                  )}
                </div>
              )
            })}
          </div>
        </div>
      )}

      {exercises.length > 0 && (
        <div>
          <h3 className="mb-2 flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-zinc-400">
            <Dumbbell className="h-3.5 w-3.5" /> Exercises
          </h3>
          <div className="space-y-2">
            {exercises.map((e) => {
              const isAdded = addedExercises.has(e.id) || customExercises.some((c) => c.id === e.id)
              return (
                <div
                  key={e.id}
                  className="flex items-center justify-between gap-3 rounded-xl border border-white/5 bg-ink-900 p-3"
                >
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-zinc-100">{e.name}</p>
                    <p className="truncate text-xs text-zinc-500">
                      {e.primaryMuscle} · {e.equipment} · {e.difficulty}
                    </p>
                  </div>
                  <button
                    onClick={() => void addExerciseToMine(e)}
                    disabled={isAdded}
                    className={cn(
                      'shrink-0 rounded-lg px-3 py-2 text-sm font-semibold transition disabled:opacity-60',
                      isAdded ? 'border border-white/10 bg-ink-800 text-zinc-400' : 'btn-gold',
                    )}
                  >
                    {isAdded ? (
                      <>
                        <Check className="h-4 w-4" /> Added
                      </>
                    ) : (
                      <>
                        <Plus className="h-4 w-4" /> Add
                      </>
                    )}
                  </button>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {!loading && programs.length === 0 && exercises.length === 0 && (
        <p className="text-sm text-zinc-500">This athlete hasn’t shared anything yet.</p>
      )}
    </div>
  )
}

function SearchResultCard({
  user,
  busy,
  onToggleFollow,
}: {
  user: DiscoverUser
  busy: boolean
  onToggleFollow: () => void
}) {
  const [open, setOpen] = useState(false)
  const hasShared = user.program_count > 0 || user.exercise_count > 0

  const subtitleParts: string[] = []
  if (user.program_count > 0)
    subtitleParts.push(`${user.program_count} program${user.program_count === 1 ? '' : 's'}`)
  if (user.exercise_count > 0)
    subtitleParts.push(`${user.exercise_count} exercise${user.exercise_count === 1 ? '' : 's'}`)

  return (
    <div className="card overflow-hidden border-l-4 p-0" style={{ borderLeftColor: user.color }}>
      <div className="flex items-center justify-between gap-3 p-4">
        <button
          onClick={() => setOpen((v) => !v)}
          disabled={!hasShared}
          className="flex min-w-0 flex-1 items-center gap-3 text-left disabled:cursor-default"
        >
          {hasShared && (
            <ChevronDown
              className={cn('h-4 w-4 shrink-0 text-zinc-500 transition', open && 'rotate-180')}
            />
          )}
          <span
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold uppercase text-white"
            style={{ background: user.color }}
            aria-hidden
          >
            {user.name.trim().charAt(0) || '?'}
          </span>
          <span className="min-w-0">
            <span className="block truncate font-semibold text-zinc-100">{user.name}</span>
            {subtitleParts.length > 0 && (
              <span className="mt-0.5 block truncate text-xs text-zinc-500">
                {subtitleParts.join(' · ')}
              </span>
            )}
          </span>
        </button>
        <button
          onClick={onToggleFollow}
          disabled={busy}
          className={cn(
            'shrink-0 rounded-lg px-3 py-2 text-sm font-semibold transition disabled:opacity-50',
            user.following
              ? 'border border-white/15 bg-ink-800 text-zinc-300 hover:border-white/30'
              : 'btn-gold',
          )}
        >
          {user.following ? (
            <>
              <UserMinus className="h-4 w-4" /> Following
            </>
          ) : (
            <>
              <UserPlus className="h-4 w-4" /> Follow
            </>
          )}
        </button>
      </div>

      {open && hasShared && (
        <SharedContent
          userId={user.id}
          ownerName={user.name}
          programCount={user.program_count}
          exerciseCount={user.exercise_count}
        />
      )}
    </div>
  )
}

function FollowingCard({
  user,
  onUnfollow,
  busy,
  favorited,
  canFavorite,
  onToggleFavorite,
}: {
  user: FollowUser
  onUnfollow: () => void
  busy: boolean
  favorited: boolean
  canFavorite: boolean
  onToggleFavorite: () => void
}) {
  const [open, setOpen] = useState(false)
  const hasShared = user.program_count > 0 || user.exercise_count > 0

  const subtitleParts: string[] = []
  if (user.program_count > 0)
    subtitleParts.push(`${user.program_count} program${user.program_count === 1 ? '' : 's'}`)
  if (user.exercise_count > 0)
    subtitleParts.push(`${user.exercise_count} exercise${user.exercise_count === 1 ? '' : 's'}`)

  return (
    <div className="card overflow-hidden border-l-4 p-0" style={{ borderLeftColor: user.color }}>
      <div className="flex items-center justify-between gap-3 p-4">
        <button
          onClick={() => setOpen((v) => !v)}
          disabled={!hasShared}
          className="flex min-w-0 flex-1 items-center gap-3 text-left disabled:cursor-default"
        >
          {hasShared && (
            <ChevronDown
              className={cn('h-4 w-4 shrink-0 text-zinc-500 transition', open && 'rotate-180')}
            />
          )}
          <span
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold uppercase text-white"
            style={{ background: user.color }}
            aria-hidden
          >
            {user.name.trim().charAt(0) || '?'}
          </span>
          <span className="min-w-0">
            <span className="block truncate font-semibold text-zinc-100">{user.name}</span>
            {subtitleParts.length > 0 && (
              <span className="mt-0.5 block truncate text-xs text-zinc-500">
                {subtitleParts.join(' · ')}
              </span>
            )}
          </span>
        </button>
        <div className="flex shrink-0 items-center gap-2">
          <button
            onClick={onToggleFavorite}
            disabled={!favorited && !canFavorite}
            aria-pressed={favorited}
            title={
              favorited
                ? 'Unpin from top'
                : canFavorite
                  ? 'Pin to top of following'
                  : `You can favorite up to ${MAX_FAVORITES}`
            }
            className={cn(
              'rounded-lg border p-2 transition disabled:opacity-40',
              favorited
                ? 'border-gold/40 bg-gold/10 text-gold'
                : 'border-white/15 bg-ink-800 text-zinc-400 hover:border-white/30',
            )}
          >
            <Star className={cn('h-4 w-4', favorited && 'fill-current')} />
          </button>
          <button
            onClick={onUnfollow}
            disabled={busy}
            className="rounded-lg border border-white/15 bg-ink-800 px-3 py-2 text-sm font-semibold text-zinc-300 transition hover:border-white/30 disabled:opacity-50"
          >
            <UserMinus className="h-4 w-4" /> Unfollow
          </button>
        </div>
      </div>

      {open && hasShared && (
        <SharedContent
          userId={user.id}
          ownerName={user.name}
          programCount={user.program_count}
          exerciseCount={user.exercise_count}
        />
      )}
    </div>
  )
}
