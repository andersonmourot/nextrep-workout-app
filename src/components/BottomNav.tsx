import { NavLink } from 'react-router-dom'
import { Home, LayoutGrid, Timer, Search, User } from 'lucide-react'
import { cn } from '../lib/utils'

const TABS = [
  { to: '/', label: 'Home', icon: Home, end: true },
  { to: '/programs', label: 'Programs', icon: LayoutGrid, end: false },
  { to: '/timer', label: 'Timer', icon: Timer, end: false },
  { to: '/people', label: 'Search', icon: Search, end: false },
  { to: '/progress', label: 'Profile', icon: User, end: false },
]

export function BottomNav() {
  // In-flow element at the bottom of the app-shell flex column (see Layout). No
  // `position: fixed`, so it sits flush at the true bottom on every page and the
  // keyboard simply covers it while typing.
  return (
    <nav className="z-40 shrink-0 border-t border-white/5 bg-ink-900/90 pb-[env(safe-area-inset-bottom)] backdrop-blur">
      <div className="container-app flex items-stretch justify-between">
        {TABS.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              cn(
                'flex flex-1 flex-col items-center gap-1 py-2.5 text-[11px] font-medium transition',
                isActive ? 'text-gold' : 'text-zinc-500 hover:text-zinc-300',
              )
            }
          >
            {({ isActive }) => (
              <>
                <Icon className={cn('h-5 w-5', isActive && 'drop-shadow-[0_0_6px_rgba(76,138,85,0.6)]')} />
                {label}
              </>
            )}
          </NavLink>
        ))}
      </div>
    </nav>
  )
}
