import { useEffect, useState } from 'react'
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

/** True when the focused element is a text-entry field that opens the keyboard. */
function isTextEntry(el: Element | null): boolean {
  if (!el) return false
  if (el.tagName === 'TEXTAREA') return true
  if (el.tagName === 'INPUT') {
    const type = (el as HTMLInputElement).type
    return !['checkbox', 'radio', 'button', 'submit', 'reset', 'range', 'color', 'file'].includes(
      type,
    )
  }
  return (el as HTMLElement).isContentEditable
}

export function BottomNav() {
  // On iOS, a fixed `bottom: 0` bar is pushed up above the on-screen keyboard,
  // which makes it look like it's floating too high (e.g. on the Search screen).
  // Hide the nav whenever a text field is focused so it never floats; it returns
  // as soon as the keyboard is dismissed.
  const [keyboardOpen, setKeyboardOpen] = useState(false)

  useEffect(() => {
    const onFocusIn = () => {
      if (isTextEntry(document.activeElement)) setKeyboardOpen(true)
    }
    const onFocusOut = () => {
      // Re-check after the focus has settled so moving between fields doesn't flash the nav.
      setTimeout(() => setKeyboardOpen(isTextEntry(document.activeElement)), 0)
    }
    document.addEventListener('focusin', onFocusIn)
    document.addEventListener('focusout', onFocusOut)
    return () => {
      document.removeEventListener('focusin', onFocusIn)
      document.removeEventListener('focusout', onFocusOut)
    }
  }, [])

  if (keyboardOpen) return null

  return (
    <nav className="fixed inset-x-0 bottom-0 z-40 border-t border-white/5 bg-ink-900/90 pb-[max(0px,calc(env(safe-area-inset-bottom)_-_1.5rem))] backdrop-blur">
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
