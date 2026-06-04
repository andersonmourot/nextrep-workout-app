import { Check, Circle } from 'lucide-react'
import { cn } from '../lib/utils'

export const PASSWORD_MIN_LENGTH = 6

interface Rule {
  label: string
  met: boolean
}

/** Live checklist of password requirements, shown while the user types. */
export function PasswordHints({ value }: { value: string }) {
  if (!value) return null
  const rules: Rule[] = [
    { label: `At least ${PASSWORD_MIN_LENGTH} characters`, met: value.length >= PASSWORD_MIN_LENGTH },
  ]
  return (
    <ul className="space-y-1">
      {rules.map((r) => (
        <li
          key={r.label}
          className={cn('flex items-center gap-1.5 text-xs', r.met ? 'text-gold' : 'text-zinc-500')}
        >
          {r.met ? <Check className="h-3.5 w-3.5" /> : <Circle className="h-3 w-3" />}
          {r.label}
        </li>
      ))}
    </ul>
  )
}
