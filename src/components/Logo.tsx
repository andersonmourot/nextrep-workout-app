import { cn } from '../lib/utils'

export function Logo({ className, withText = true }: { className?: string; withText?: boolean }) {
  return (
    <div className={cn('flex items-center gap-2', className)}>
      {withText && (
        <span className="heading text-lg font-bold tracking-tight text-zinc-100">
          Next<span className="text-gold">Rep</span>
        </span>
      )}
    </div>
  )
}
