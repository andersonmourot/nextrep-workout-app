import { useCallback, useEffect, useRef, useState } from 'react'
import { Check, ChevronDown, Plus, Search, UserMinus, UserPlus, Users } from 'lucide-react'
import {
  apiAddProgram,
  apiFollow,
  apiFollowing,
  apiSearchUsers,
  apiUnfollow,
  apiUserPrograms,
  type DiscoverUser,
  type FollowUser,
} from '../api'
import { getToken, useAuth } from '../auth'
import { useStore } from '../store'
import type { Program } from '../types'
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
          Find other athletes by name, follow them, and add their programs to your own.
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
              <div
                key={u.id}
                className="card flex items-center justify-between gap-3 border-l-4 p-4"
                style={{ borderLeftColor: u.color }}
              >
                <div className="flex min-w-0 items-center gap-3">
                  <span
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold uppercase text-white"
                    style={{ background: u.color }}
                    aria-hidden
                  >
                    {u.name.trim().charAt(0) || '?'}
                  </span>
                  <div className="min-w-0">
                    <p className="truncate font-semibold text-zinc-100">{u.name}</p>
                    <p className="mt-0.5 text-xs text-zinc-500">
                      {u.program_count} program{u.program_count === 1 ? '' : 's'}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => void toggleFollow(u)}
                  disabled={busyId === u.id}
                  className={cn(
                    'shrink-0 rounded-lg px-3 py-2 text-sm font-semibold transition disabled:opacity-50',
                    u.following
                      ? 'border border-white/15 bg-ink-800 text-zinc-300 hover:border-white/30'
                      : 'btn-gold',
                  )}
                >
                  {u.following ? (
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
