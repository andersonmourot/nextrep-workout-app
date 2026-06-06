import { useState } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { Dumbbell } from 'lucide-react'
import { useAuth } from '../auth'
import { PasswordField } from '../components/PasswordField'
import { PasswordHints } from '../components/PasswordHints'

export function Auth({ mode }: { mode: 'login' | 'signup' }) {
  const navigate = useNavigate()
  const token = useAuth((s) => s.token)
  const signUp = useAuth((s) => s.signUp)
  const login = useAuth((s) => s.login)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  if (token) return <Navigate to="/" replace />

  const isSignup = mode === 'signup'

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setBusy(true)
    const res = isSignup ? await signUp(name, email, password) : await login(email, password)
    setBusy(false)
    if (res.ok) navigate('/', { replace: true })
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
          <p className="mt-2 text-sm text-zinc-400">
            {isSignup ? 'Create your account to start training.' : 'Welcome back. Log in to continue.'}
          </p>
        </div>

        <form onSubmit={onSubmit} className="card space-y-4 p-5">
          {isSignup && (
            <div>
              <label className="mb-1.5 block text-sm font-medium text-zinc-300">Name</label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Your name"
                autoComplete="name"
                className="input"
              />
            </div>
          )}
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
          <div className="space-y-2">
            <label className="mb-1.5 block text-sm font-medium text-zinc-300">Password</label>
            <PasswordField
              value={password}
              onChange={setPassword}
              placeholder={isSignup ? 'At least 6 characters' : 'Your password'}
              autoComplete={isSignup ? 'new-password' : 'current-password'}
            />
            <PasswordHints value={password} />
            {!isSignup && (
              <div className="text-right">
                <Link
                  to="/forgot-password"
                  className="text-sm font-medium text-gold hover:text-gold-400"
                >
                  Forgot password?
                </Link>
              </div>
            )}
          </div>

          {error && (
            <p className="rounded-lg bg-red-500/10 px-3 py-2 text-sm text-red-300">{error}</p>
          )}

          <button type="submit" disabled={busy} className="btn-gold w-full">
            {busy ? 'Please wait…' : isSignup ? 'Create account' : 'Log in'}
          </button>
        </form>

        <p className="mt-5 text-center text-sm text-zinc-400">
          {isSignup ? (
            <>
              Already have an account?{' '}
              <Link to="/login" className="font-semibold text-gold hover:text-gold-400">
                Log in
              </Link>
            </>
          ) : (
            <>
              New here?{' '}
              <Link to="/signup" className="font-semibold text-gold hover:text-gold-400">
                Create an account
              </Link>
            </>
          )}
        </p>
      </div>
    </div>
  )
}
