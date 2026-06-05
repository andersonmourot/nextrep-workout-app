import { useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { ArrowLeft, ShieldCheck } from 'lucide-react'
import { getToken, useAuth } from '../auth'
import { apiAdminUsers, type AdminUser } from '../api'
import { formatDateLong, formatDateTime } from '../lib/utils'

export function AdminUsers() {
  const navigate = useNavigate()
  const account = useAuth((s) => s.user)
  const ready = useAuth((s) => s.ready)
  const [users, setUsers] = useState<AdminUser[]>([])
  const [loading, setLoading] = useState(() => getToken() != null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    const token = getToken()
    if (!token) return
    void apiAdminUsers(token).then((res) => {
      if (!active) return
      if (res.ok && res.data) setUsers(res.data)
      else setError(res.error ?? 'Could not load users.')
      setLoading(false)
    })
    return () => {
      active = false
    }
  }, [])

  // Non-admins should never reach this page.
  if (ready && account && !account.is_admin) return <Navigate to="/" replace />

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div>
        <p className="label-eyebrow flex items-center gap-1.5">
          <ShieldCheck className="h-3.5 w-3.5 text-gold" /> Admin
        </p>
        <h1 className="heading text-3xl font-bold text-zinc-50">Users</h1>
        <p className="mt-1 text-sm text-zinc-400">
          {loading ? 'Loading…' : `${users.length} registered ${users.length === 1 ? 'user' : 'users'}`}
        </p>
      </div>

      {error && <p className="card p-4 text-sm text-red-300">{error}</p>}

      {!loading && !error && (
        <div className="space-y-2">
          {users.map((u) => (
            <div key={u.id} className="card p-4">
              <div className="flex items-center justify-between gap-3">
                <p className="truncate font-semibold text-zinc-100">{u.name}</p>
                <span className="shrink-0 text-xs text-zinc-500">
                  Joined {u.created_at ? formatDateLong(u.created_at) : '—'}
                </span>
              </div>
              <p className="truncate text-sm text-zinc-400">{u.email}</p>
              <p className="mt-1 text-xs text-zinc-500">
                Last login: {u.last_login ? formatDateTime(u.last_login) : 'Never'}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
