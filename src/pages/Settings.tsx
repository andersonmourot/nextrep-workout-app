import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Check,
  ChevronRight,
  Download,
  KeyRound,
  LogOut,
  Moon,
  Plus,
  Share,
  ShieldCheck,
  Sun,
  Trash2,
  X,
} from 'lucide-react'
import { useProgram, useStore } from '../store'
import { getToken, useAuth } from '../auth'
import { apiChangePassword } from '../api'
import { cn } from '../lib/utils'
import { usePwaInstall } from '../lib/usePwaInstall'
import { THEME_COLORS, type ThemeMode } from '../lib/theme'
import { PasswordField } from '../components/PasswordField'
import { PasswordHints, PASSWORD_MIN_LENGTH } from '../components/PasswordHints'
import type { Unit } from '../types'

export function Settings() {
  const navigate = useNavigate()
  const { name, unit, activeProgramId, setName, setUnit, clearProgram, resetAll } = useStore()
  const themeColor = useStore((s) => s.themeColor)
  const themeMode = useStore((s) => s.themeMode)
  const setThemeColor = useStore((s) => s.setThemeColor)
  const setThemeMode = useStore((s) => s.setThemeMode)
  const logout = useAuth((s) => s.logout)
  const account = useAuth((s) => s.user)
  const [confirmReset, setConfirmReset] = useState(false)
  const program = useProgram(activeProgramId ?? undefined)

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div>
        <h1 className="heading text-3xl font-bold text-zinc-50">Settings</h1>
      </div>

      <section className="card space-y-4 p-5">
        <div>
          <label className="mb-1.5 block text-sm font-medium text-zinc-300">Display name</label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name"
            className="input"
          />
        </div>
      </section>

      {account?.is_admin && (
        <section className="card p-2">
          <Link
            to="/admin/users"
            className="flex items-center justify-between rounded-xl p-3 transition hover:bg-white/5"
          >
            <span className="flex items-center gap-3">
              <span className="grid h-9 w-9 place-items-center rounded-xl bg-gold/15 text-gold">
                <ShieldCheck className="h-5 w-5" />
              </span>
              <span>
                <span className="block font-semibold text-zinc-100">Users</span>
                <span className="block text-xs text-zinc-500">Admin · view registered users</span>
              </span>
            </span>
            <ChevronRight className="h-5 w-5 text-zinc-500" />
          </Link>
        </section>
      )}

      <section className="card space-y-4 p-5">
        <h2 className="heading text-lg font-bold text-zinc-50">Appearance</h2>

        <div>
          <span className="mb-2 block text-sm font-medium text-zinc-300">Theme color</span>
          <div className="flex flex-wrap gap-2">
            {THEME_COLORS.map((c) => (
              <button
                key={c}
                onClick={() => setThemeColor(c)}
                aria-label={`Use ${c} theme color`}
                aria-pressed={themeColor === c}
                className={cn(
                  'flex h-9 w-9 items-center justify-center rounded-full border-2 transition',
                  themeColor === c ? 'border-zinc-50' : 'border-transparent',
                )}
                style={{ background: c }}
              >
                {themeColor === c && <Check className="h-4 w-4 text-white" />}
              </button>
            ))}
          </div>
        </div>

        <div>
          <span className="mb-1.5 block text-sm font-medium text-zinc-300">Theme</span>
          <div className="grid grid-cols-2 gap-2">
            {(
              [
                { mode: 'dark', label: 'Dark', Icon: Moon },
                { mode: 'light', label: 'Light', Icon: Sun },
              ] as { mode: ThemeMode; label: string; Icon: typeof Moon }[]
            ).map(({ mode, label, Icon }) => (
              <button
                key={mode}
                onClick={() => setThemeMode(mode)}
                className={cn(
                  'inline-flex items-center justify-center gap-2 rounded-xl border py-2.5 text-sm font-semibold transition',
                  themeMode === mode
                    ? 'border-gold bg-gold text-white'
                    : 'border-white/10 bg-ink-900 text-zinc-300',
                )}
              >
                <Icon className="h-4 w-4" /> {label}
              </button>
            ))}
          </div>
        </div>

        <div>
          <span className="mb-1.5 block text-sm font-medium text-zinc-300">Weight unit</span>
          <div className="grid grid-cols-2 gap-2">
            {(['lb', 'kg'] as Unit[]).map((u) => (
              <button
                key={u}
                onClick={() => setUnit(u)}
                className={cn(
                  'rounded-xl border py-2.5 text-sm font-semibold uppercase transition',
                  unit === u
                    ? 'border-gold bg-gold text-white'
                    : 'border-white/10 bg-ink-900 text-zinc-300',
                )}
              >
                {u}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="card p-5">
        <h2 className="heading text-lg font-bold text-zinc-50">Active Program</h2>
        {program ? (
          <div className="mt-2">
            <p className="text-sm text-zinc-300">{program.name}</p>
            <p className="text-xs text-zinc-500">
              {program.daysPerWeek} days / week · {program.durationWeeks} weeks
            </p>
            <div className="mt-3 flex gap-2">
              <Link to={`/programs/${program.id}`} className="btn-ghost flex-1">
                View
              </Link>
              <button onClick={clearProgram} className="btn-ghost flex-1">
                Clear
              </button>
            </div>
          </div>
        ) : (
          <div className="mt-2">
            <p className="text-sm text-zinc-400">No active program selected.</p>
            <Link to="/programs" className="btn-gold mt-3 w-full">
              Browse Programs
            </Link>
          </div>
        )}
      </section>

      {account && (
        <section className="card space-y-3 p-5">
          <h2 className="heading text-lg font-bold text-zinc-50">Account</h2>
          <div>
            <p className="text-sm font-medium text-zinc-200">{account.name}</p>
            <p className="text-xs text-zinc-500">{account.email}</p>
          </div>

          <ChangePassword />

          <button
            onClick={() => {
              logout()
              navigate('/login', { replace: true })
            }}
            className="btn-ghost w-full"
          >
            <LogOut className="h-4 w-4" /> Log out
          </button>
        </section>
      )}

      <InstallApp />

      <section className="card border-red-500/20 p-5">
        <h2 className="heading text-lg font-bold text-red-300">Data Reset</h2>
        <p className="mt-1 text-sm text-zinc-400">
          Reset clears your active program, workout history, and body-weight log. This can't be undone.
        </p>
        {confirmReset ? (
          <div className="mt-3 flex gap-2">
            <button
              onClick={() => {
                resetAll()
                setConfirmReset(false)
              }}
              className="btn flex-1 bg-red-500/90 text-white hover:bg-red-500"
            >
              <Trash2 className="h-4 w-4" /> Confirm Reset
            </button>
            <button onClick={() => setConfirmReset(false)} className="btn-ghost flex-1">
              Cancel
            </button>
          </div>
        ) : (
          <button
            onClick={() => setConfirmReset(true)}
            className="btn mt-3 w-full border border-red-500/40 text-red-300 hover:bg-red-500/10"
          >
            Reset All Data
          </button>
        )}
      </section>

      <section className="card p-2">
        <Link
          to="/legal/privacy"
          className="flex items-center justify-between rounded-xl px-3 py-2.5 text-sm text-zinc-300 transition hover:bg-white/5"
        >
          Privacy Policy
          <ChevronRight className="h-4 w-4 text-zinc-500" />
        </Link>
        <Link
          to="/legal/terms"
          className="flex items-center justify-between rounded-xl px-3 py-2.5 text-sm text-zinc-300 transition hover:bg-white/5"
        >
          Terms of Service
          <ChevronRight className="h-4 w-4 text-zinc-500" />
        </Link>
        <Link
          to="/legal/disclaimer"
          className="flex items-center justify-between rounded-xl px-3 py-2.5 text-sm text-zinc-300 transition hover:bg-white/5"
        >
          Health &amp; Fitness Disclaimer
          <ChevronRight className="h-4 w-4 text-zinc-500" />
        </Link>
      </section>

      <p className="pb-2 text-center text-xs text-zinc-600">
        SMELLIS · Train with intent.
      </p>
    </div>
  )
}

function InstallApp() {
  const { canPrompt, promptInstall, isIOS, isStandalone } = usePwaInstall()
  const [showIOS, setShowIOS] = useState(false)

  // Already installed / launched from the home screen — nothing to do.
  if (isStandalone) return null

  async function handleClick() {
    if (canPrompt) {
      await promptInstall()
      return
    }
    // iOS (and any browser without a native prompt): show manual instructions.
    setShowIOS(true)
  }

  return (
    <section className="card space-y-3 p-5">
      <div>
        <h2 className="heading text-lg font-bold text-zinc-50">Install app</h2>
        <p className="mt-1 text-sm text-zinc-400">
          Add SMELLIS to your home screen to launch it fullscreen, like a native app.
        </p>
      </div>

      <button onClick={handleClick} className="btn-gold w-full">
        <Download className="h-4 w-4" /> Install app
      </button>

      {showIOS && (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 p-4 sm:items-center"
          onClick={() => setShowIOS(false)}
        >
          <div
            className="card w-full max-w-sm space-y-4 p-5"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h3 className="heading text-lg font-bold text-zinc-50">Add to Home Screen</h3>
              <button
                onClick={() => setShowIOS(false)}
                aria-label="Close"
                className="rounded-md p-1 text-zinc-400 hover:bg-white/5 hover:text-zinc-200"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <p className="text-sm text-zinc-400">
              {isIOS
                ? 'On iPhone, install from the Safari Share menu:'
                : 'To install, use your browser menu:'}
            </p>
            <ol className="space-y-3 text-sm text-zinc-200">
              <li className="flex items-center gap-3">
                <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-gold/15 text-gold">
                  <Share className="h-5 w-5" />
                </span>
                <span>
                  Tap the <span className="font-semibold">Share</span> button in Safari's toolbar.
                </span>
              </li>
              <li className="flex items-center gap-3">
                <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-gold/15 text-gold">
                  <Plus className="h-5 w-5" />
                </span>
                <span>
                  Scroll down and tap{' '}
                  <span className="font-semibold">Add to Home Screen</span>.
                </span>
              </li>
              <li className="flex items-center gap-3">
                <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-gold/15 text-gold">
                  <Check className="h-5 w-5" />
                </span>
                <span>
                  Make sure <span className="font-semibold">Open as Web App</span> is on, then tap{' '}
                  <span className="font-semibold">Add</span> — SMELLIS will appear on your home
                  screen and launch fullscreen.
                </span>
              </li>
            </ol>
            <button onClick={() => setShowIOS(false)} className="btn-ghost w-full">
              Got it
            </button>
          </div>
        </div>
      )}
    </section>
  )
}

function ChangePassword() {
  const [open, setOpen] = useState(false)
  const [current, setCurrent] = useState('')
  const [next, setNext] = useState('')
  const [confirm, setConfirm] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [done, setDone] = useState(false)

  function reset() {
    setCurrent('')
    setNext('')
    setConfirm('')
    setError(null)
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    if (next.length < PASSWORD_MIN_LENGTH) {
      setError(`New password must be at least ${PASSWORD_MIN_LENGTH} characters.`)
      return
    }
    if (next !== confirm) {
      setError('New passwords do not match.')
      return
    }
    const token = getToken()
    if (!token) {
      setError('You are not signed in.')
      return
    }
    setSaving(true)
    const res = await apiChangePassword(token, current, next)
    setSaving(false)
    if (!res.ok) {
      setError(res.error ?? 'Could not change password.')
      return
    }
    reset()
    setOpen(false)
    setDone(true)
    setTimeout(() => setDone(false), 4000)
  }

  if (!open) {
    return (
      <div>
        <button
          onClick={() => {
            setDone(false)
            setOpen(true)
          }}
          className="btn-ghost w-full"
        >
          <KeyRound className="h-4 w-4" /> Change password
        </button>
        {done && (
          <p className="mt-2 text-center text-xs font-medium text-gold">Password updated.</p>
        )}
      </div>
    )
  }

  return (
    <form onSubmit={submit} className="space-y-2.5 rounded-xl border border-white/10 p-3">
      <PasswordField
        autoComplete="current-password"
        value={current}
        onChange={setCurrent}
        placeholder="Current password"
      />
      <PasswordField
        autoComplete="new-password"
        value={next}
        onChange={setNext}
        placeholder="New password"
      />
      <PasswordHints value={next} />
      <PasswordField
        autoComplete="new-password"
        value={confirm}
        onChange={setConfirm}
        placeholder="Confirm new password"
      />
      {error && <p className="text-xs font-medium text-red-400">{error}</p>}
      <div className="flex gap-2">
        <button type="submit" disabled={saving} className="btn-gold flex-1">
          {saving ? 'Saving…' : 'Update password'}
        </button>
        <button
          type="button"
          onClick={() => {
            reset()
            setOpen(false)
          }}
          className="btn-ghost flex-1"
        >
          Cancel
        </button>
      </div>
    </form>
  )
}
