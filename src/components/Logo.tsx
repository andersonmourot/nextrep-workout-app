import { cn } from '../lib/utils'

export function Logo({ className, withText = true }: { className?: string; withText?: boolean }) {
  return (
    <div className={cn('flex items-center gap-2', className)}>
      {withText && (
        <span className="heading text-lg font-bold tracking-[0.18em] text-zinc-100">
          SMEL<span className="text-gold">LIS</span>
        </span>
      )}
    </div>
  )
}
