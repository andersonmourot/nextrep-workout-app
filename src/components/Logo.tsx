import { cn } from '../lib/utils'

export function Logo({ className, withText = true }: { className?: string; withText?: boolean }) {
  return (
    <div className={cn('flex items-center gap-2', className)}>
      <span className="grid h-8 w-8 place-items-center rounded-lg bg-gold text-white shadow-glow">
        <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round">
          <path d="M4 9v6M20 9v6M7 7v10M17 7v10M7 12h10" />
        </svg>
      </span>
      {withText && (
        <span className="heading text-lg font-bold tracking-[0.18em] text-zinc-100">
          SMEL<span className="text-gold">LIS</span>
        </span>
      )}
    </div>
  )
}
