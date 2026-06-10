import { Link, Navigate, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { Play, Settings as SettingsIcon } from 'lucide-react'
import { BottomNav } from './BottomNav'
import { Logo } from './Logo'
import { Workout } from '../pages/Workout'
import { useStore } from '../store'

export function Layout() {
  const { pathname } = useLocation()
  const navigate = useNavigate()
  const activeWorkout = useStore((s) => s.activeWorkout)
  const activeProgramId = useStore((s) => s.activeProgramId)
  // A workout is "live" while there's an active session for the active program.
  // It lives on its own /workout route so the Programs tab always shows the
  // program list (no more loop between the workout and a program's page). A
  // persistent "Resume workout" banner gives a one-tap way back into it.
  const workoutLive = !!activeWorkout && activeWorkout.programId === activeProgramId
  const onWorkout = pathname === '/workout'
  const showWorkout = workoutLive && onWorkout

  // Landed on /workout with nothing live (e.g. finished/ended) — go to the list.
  if (onWorkout && !workoutLive) return <Navigate to="/programs" replace />

  // App-shell layout: a flex column that fills #root, whose height is
  // screen.height in standalone via --app-height (see main.tsx + index.css).
  // Flow-based (h-full) instead of position:fixed avoids the iOS bug where
  // fixed elements size to a too-short viewport on first paint.
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
            {workoutLive && (
              <div className="sticky top-0 z-20 bg-ink-950/80 backdrop-blur">
                <div className="container-app py-2">
                  <button
                    onClick={() => navigate('/workout')}
                    className="btn-gold flex w-full items-center justify-center gap-2"
                  >
                    <Play className="h-4 w-4" /> Resume workout
                  </button>
                </div>
              </div>
            )}
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
