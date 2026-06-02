import { Link, Outlet, useLocation } from 'react-router-dom'
import { Settings as SettingsIcon } from 'lucide-react'
import { BottomNav } from './BottomNav'
import { Logo } from './Logo'

export function Layout() {
  const { pathname } = useLocation()
  // Hide the chrome during an active workout for a focused, full-screen feel.
  const immersive = pathname.startsWith('/workout/')

  if (immersive) {
    return (
      <div className="min-h-full">
        <Outlet />
      </div>
    )
  }

  return (
    <div className="min-h-full pb-20">
      <header className="sticky top-0 z-30 border-b border-white/5 bg-ink-950/80 backdrop-blur">
        <div className="container-app flex h-14 items-center justify-between">
          <Link to="/" aria-label="Home">
            <Logo />
          </Link>
          <Link
            to="/settings"
            aria-label="Settings"
            className="grid h-9 w-9 place-items-center rounded-lg border border-white/5 bg-ink-850 text-zinc-400 hover:text-gold"
          >
            <SettingsIcon className="h-5 w-5" />
          </Link>
        </div>
      </header>
      <main className="container-app py-5">
        <Outlet />
      </main>
      <BottomNav />
    </div>
  )
}
