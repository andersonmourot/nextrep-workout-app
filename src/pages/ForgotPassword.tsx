import { useState } from 'react'
import { Link, Navigate } from 'react-router-dom'
import { Dumbbell, MailCheck } from 'lucide-react'
import { useAuth } from '../auth'
import { apiForgotPassword } from '../api'

export function ForgotPassword() {
  const token = useAuth((s) => s.token)
  const [email, setEmail] = useState('')
  const [busy, setBusy] = useState(false)
  const [sent, setSent] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (token) return <Navigate to="/" replace />

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    if (!email.trim()) {
      setError('Enter your account email.')
      return
    }
    setBusy(true)
    const res = await apiForgotPassword(email.trim())
    setBusy(false)
    if (res.ok) setSent(true)
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
          <p className="mt-2 text-sm text-zinc-400">Reset your password.</p>
        </div>

        {sent ? (
          <div className="card space-y-4 p-5 text-center">
            <span className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-gold/15 text-gold">
              <MailCheck className="h-6 w-6" />
            </span>
            <p className="text-sm text-zinc-300">
              If an account exists for <span className="font-semibold">{email.trim()}</span>, we've
              sent a link to reset your password. Check your inbox (and spam folder). The link
              expires in 1 hour.
            </p>
            <Link to="/login" className="btn-gold w-full">
              Back to log in
            </Link>
          </div>
        ) : (
          <form onSubmit={onSubmit} className="card space-y-4 p-5">
            <p className="text-sm text-zinc-400">
              Enter the email tied to your account and we'll send you a reset link.
            </p>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-300">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
                className="input"
              />
            </div>

            {error && (
              <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{error}</p>
            )}

            <button type="submit" disabled={busy} className="btn-gold w-full">
              {busy ? 'Sending…' : 'Send reset link'}
            </button>
          </form>
        )}

        <p className="mt-5 text-center text-sm text-zinc-400">
          Remembered it?{' '}
          <Link to="/login" className="font-semibold text-gold hover:text-gold-400">
            Log in
          </Link>
        </p>
      </div>
    </div>
  )
}
