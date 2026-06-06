import { useState } from 'react'
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router-dom'
import { CheckCircle2, Dumbbell } from 'lucide-react'
import { useAuth } from '../auth'
import { PasswordField } from '../components/PasswordField'
import { PasswordHints } from '../components/PasswordHints'
import { apiResetPassword } from '../api'

export function ResetPassword() {
  const navigate = useNavigate()
  const token = useAuth((s) => s.token)
  const [params] = useSearchParams()
  const resetToken = params.get('token') ?? ''

  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [busy, setBusy] = useState(false)
  const [done, setDone] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (token) return <Navigate to="/" replace />

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    if (password.length < 6) {
      setError('Password must be at least 6 characters.')
      return
    }
    if (password !== confirm) {
      setError('Passwords do not match.')
      return
    }
    setBusy(true)
    const res = await apiResetPassword(resetToken, password)
    setBusy(false)
    if (res.ok) setDone(true)
    else setError(res.error ?? 'Something went wrong.')
  }

  return (
    <div className="flex min-h-full flex-col items-center justify-center px-4 py-12">
      <div className="w-full max-w-sm animate-fade-in">
        <div className="mb-8 text-center">
          <span className="mx-auto mb-4 grid h-12 w-12 place-items-center rounded-xl bg-gold text-white shadow-glow">
            <Dumbbell className="h-6 w-6" />
          </span>
          <h1 className="heading text-3xl font-bold tracking-[0.18em] text-zinc-100">
            Next<span className="text-gold">Rep</span>
          </h1>
          <p className="mt-2 text-sm text-zinc-400">Choose a new password.</p>
        </div>

        {done ? (
          <div className="card space-y-4 p-5 text-center">
            <span className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-gold/15 text-gold">
              <CheckCircle2 className="h-6 w-6" />
            </span>
            <p className="text-sm text-zinc-300">
              Your password has been reset. You can now log in with your new password.
            </p>
            <button onClick={() => navigate('/login', { replace: true })} className="btn-gold w-full">
              Go to log in
            </button>
          </div>
        ) : !resetToken ? (
          <div className="card space-y-4 p-5 text-center">
            <p className="text-sm text-red-300">
              This reset link is missing its token. Please request a new link.
            </p>
            <Link to="/forgot-password" className="btn-gold w-full">
              Request a new link
            </Link>
          </div>
        ) : (
          <form onSubmit={onSubmit} className="card space-y-4 p-5">
            <div className="space-y-2">
              <label className="mb-1.5 block text-sm font-medium text-zinc-300">New password</label>
              <PasswordField
                value={password}
                onChange={setPassword}
                placeholder="At least 6 characters"
                autoComplete="new-password"
              />
              <PasswordHints value={password} />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-300">
                Confirm password
              </label>
              <PasswordField
                value={confirm}
                onChange={setConfirm}
                placeholder="Re-enter password"
                autoComplete="new-password"
              />
            </div>

            {error && (
              <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{error}</p>
            )}

            <button type="submit" disabled={busy} className="btn-gold w-full">
              {busy ? 'Resetting…' : 'Reset password'}
            </button>
          </form>
        )}

        <p className="mt-5 text-center text-sm text-zinc-400">
          <Link to="/login" className="font-semibold text-gold hover:text-gold-400">
            Back to log in
          </Link>
        </p>
      </div>
    </div>
  )
}
