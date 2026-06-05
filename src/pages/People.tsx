import { useCallback, useEffect, useRef, useState } from 'react'
import { Check, ChevronDown, Dumbbell, Plus, Search, UserMinus, UserPlus, Users } from 'lucide-react'
import {
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
import { useStore } from '../store'
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
            {following.map((f) => (
              <FollowingCard key={f.id} user={f} onUnfollow={() => void unfollow(f.id)} busy={busyId === f.id} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

function FollowingCard({
  user,
  onUnfollow,
  busy,
}: {
  user: FollowUser
  onUnfollow: () => void
  busy: boolean
}) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [programs, setPrograms] = useState<Program[] | null>(null)
  const [added, setAdded] = useState<Set<string>>(new Set())
  const customPrograms = useStore((s) => s.customPrograms)
  const addProgram = useStore((s) => s.addProgram)
  const currentUserId = useAuth((s) => s.user?.id)

  async function toggleOpen() {
    const next = !open
    setOpen(next)
    if (next && programs === null) {
      const token = getToken()
      if (!token) return
      setLoading(true)
      const res = await apiUserPrograms<Program>(token, user.id)
      setLoading(false)
      if (res.ok && res.data) setPrograms(res.data.programs ?? [])
      else setPrograms([])
    }
  }

  async function addToMine(p: Program) {
    const token = getToken()
    if (!token) return
    // Keep the same id so this account references the shared (canonical)
    // program; edits by the owner/collaborators then sync to everyone.
    const res = await apiAddProgram<Program>(token, p.id)
    const program = res.ok && res.data ? res.data.program : { ...p, coach: p.coach || user.name }
    addProgram({ ...program, coach: program.coach || user.name })
    setAdded((prev) => new Set(prev).add(p.id))
  }

  return (
    <div
      className="card overflow-hidden border-l-4 p-0"
      style={{ borderLeftColor: user.color }}
    >
      <div className="flex items-center justify-between gap-3 p-4">
        <button onClick={() => void toggleOpen()} className="flex min-w-0 flex-1 items-center gap-3 text-left">
          <ChevronDown
            className={cn('h-4 w-4 shrink-0 text-zinc-500 transition', open && 'rotate-180')}
          />
          <span
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold uppercase text-white"
            style={{ background: user.color }}
            aria-hidden
          >
            {user.name.trim().charAt(0) || '?'}
          </span>
          <span className="min-w-0">
            <span className="block truncate font-semibold text-zinc-100">{user.name}</span>
            <span className="block truncate text-xs text-zinc-500">
              {user.program_count} program{user.program_count === 1 ? '' : 's'}
            </span>
          </span>
        </button>
        <button
          onClick={onUnfollow}
          disabled={busy}
          className="shrink-0 rounded-lg border border-white/15 bg-ink-800 px-3 py-2 text-sm font-semibold text-zinc-300 transition hover:border-white/30 disabled:opacity-50"
        >
          <UserMinus className="h-4 w-4" /> Unfollow
        </button>
      </div>

      {open && (
        <div className="border-t border-white/5 p-4">
          {loading && <p className="text-sm text-zinc-500">Loading programs…</p>}
          {!loading && programs && programs.length === 0 && (
            <p className="text-sm text-zinc-500">This user hasn’t shared any custom programs yet.</p>
          )}
          {!loading && programs && programs.length > 0 && (
            <div className="space-y-2">
              {programs.map((p) => {
                const isOwner = !!currentUserId && p.ownerId === currentUserId
                const isAdded = added.has(p.id) || customPrograms.some((c) => c.id === p.id)
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
                    <div className="flex shrink-0 items-center gap-2">
                      {isOwner ? (
                        <span className="inline-flex items-center gap-1 rounded-lg border border-white/10 bg-ink-800 px-3 py-2 text-sm font-semibold text-zinc-400">
                          <Check className="h-4 w-4" /> Yours
                        </span>
                      ) : (
                        <button
                          onClick={() => void addToMine(p)}
                          disabled={isAdded}
                          className={cn(
                            'rounded-lg px-3 py-2 text-sm font-semibold transition disabled:opacity-60',
                            isAdded
                              ? 'border border-white/10 bg-ink-800 text-zinc-400'
                              : 'btn-gold',
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
                  </div>
                )
              })}
            </div>
          )}
        </div>
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
  const [loading, setLoading] = useState(false)
  const [programs, setPrograms] = useState<Program[] | null>(null)
  const [exercises, setExercises] = useState<Exercise[] | null>(null)
  const [addedPrograms, setAddedPrograms] = useState<Set<string>>(new Set())
  const [addedExercises, setAddedExercises] = useState<Set<string>>(new Set())
  const customPrograms = useStore((s) => s.customPrograms)
  const addProgram = useStore((s) => s.addProgram)
  const customExercises = useStore((s) => s.customExercises)
  const addCustomExercise = useStore((s) => s.addCustomExercise)
  const currentUserId = useAuth((s) => s.user?.id)

  const hasShared = user.program_count > 0 || user.exercise_count > 0

  async function toggleOpen() {
    const next = !open
    setOpen(next)
    if (!next || !hasShared) return
    const token = getToken()
    if (!token) return
    setLoading(true)
    const tasks: Promise<void>[] = []
    if (user.program_count > 0 && programs === null) {
      tasks.push(
        apiUserPrograms<Program>(token, user.id).then((res) => {
          setPrograms(res.ok && res.data ? res.data.programs ?? [] : [])
        }),
      )
    }
    if (user.exercise_count > 0 && exercises === null) {
      tasks.push(
        apiUserExercises<Exercise>(token, user.id).then((res) => {
          setExercises(res.ok && res.data ? res.data.exercises ?? [] : [])
        }),
      )
    }
    await Promise.all(tasks)
    setLoading(false)
  }

  async function addProgramToMine(p: Program) {
    const token = getToken()
    if (!token) return
    const res = await apiAddProgram<Program>(token, p.id)
    const program = res.ok && res.data ? res.data.program : { ...p, coach: p.coach || user.name }
    addProgram({ ...program, coach: program.coach || user.name })
    setAddedPrograms((prev) => new Set(prev).add(p.id))
  }

  function addExerciseToMine(e: Exercise) {
    // Copy into the current user's library; don't auto-reshare from their profile.
    addCustomExercise({ ...e, shared: false, ownerName: e.ownerName || user.name })
    setAddedExercises((prev) => new Set(prev).add(e.id))
  }

  const subtitleParts: string[] = []
  if (user.program_count > 0)
    subtitleParts.push(`${user.program_count} program${user.program_count === 1 ? '' : 's'}`)
  if (user.exercise_count > 0)
    subtitleParts.push(`${user.exercise_count} exercise${user.exercise_count === 1 ? '' : 's'}`)

  return (
    <div className="card overflow-hidden border-l-4 p-0" style={{ borderLeftColor: user.color }}>
      <div className="flex items-center justify-between gap-3 p-4">
        <button
          onClick={() => void toggleOpen()}
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
            <span className="mt-0.5 block truncate text-xs text-zinc-500">
              {subtitleParts.length ? subtitleParts.join(' · ') : 'No shared content'}
            </span>
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
        <div className="space-y-4 border-t border-white/5 p-4">
          {loading && <p className="text-sm text-zinc-500">Loading…</p>}

          {programs && programs.length > 0 && (
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

          {exercises && exercises.length > 0 && (
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
                        onClick={() => addExerciseToMine(e)}
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

          {!loading &&
            (programs?.length ?? 0) === 0 &&
            (exercises?.length ?? 0) === 0 && (
              <p className="text-sm text-zinc-500">This athlete hasn’t shared anything yet.</p>
            )}
        </div>
      )}
    </div>
  )
}
