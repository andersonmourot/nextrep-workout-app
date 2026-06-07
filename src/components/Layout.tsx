import { Link, Outlet, useLocation } from 'react-router-dom'
import { Settings as SettingsIcon } from 'lucide-react'
import { BottomNav } from './BottomNav'
import { Logo } from './Logo'
import { Workout } from '../pages/Workout'
import { useStore } from '../store'

export function Layout() {
  const { pathname } = useLocation()
  const activeWorkout = useStore((s) => s.activeWorkout)
  const activeProgramId = useStore((s) => s.activeProgramId)
  // While a workout for the active program is live it takes over the Programs
  // tab, but the bottom nav stays visible so the user can hop to other tabs and
  // come back to it. An in-progress workout from a program that is no longer
  // active is kept in state (saved until that program is reset) but doesn't
  // hijack the Programs tab — it resurfaces when that program is active again.
  const showWorkout =
    !!activeWorkout && activeWorkout.programId === activeProgramId && pathname === '/programs'

  // App-shell layout: a flex column that fills #root, whose height is the
  // JS-measured real screen height (--app-height, see main.tsx + index.css).
  // This avoids the iOS standalone first-paint bug that left the bottom nav
  // floating high. Inside, only <main> scrolls and the bottom nav is an in-flow
  // element at the bottom, so it sits flush at the true bottom and the keyboard
  // simply covers it while typing.
  return (
    <div className="flex h-full flex-col overflow-hidden">
      {showWorkout ? (
        <main id="app-scroll" className="flex-1 overflow-y-auto pt-[env(safe-area-inset-top)]">
          <Workout />
        </main>
      ) : (
        <>
          <header className="z-30 border-b border-white/5 bg-ink-950/80 pt-[env(safe-area-inset-top)] backdrop-blur">
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
          <main id="app-scroll" className="flex-1 overflow-y-auto">
            <div className="container-app py-5">
              <Outlet />
            </div>
          </main>
        </>
      )}
      <BottomNav />
    </div>
  )
}
