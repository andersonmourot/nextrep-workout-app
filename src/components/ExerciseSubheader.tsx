import { useEffect, useRef, useState } from 'react'
import { AlignLeft, Plus } from 'lucide-react'
import { useStore } from '../store'
import { cn } from '../lib/utils'

/**
 * Private per-exercise "sub-header" cue, shown inline under the exercise title.
 * Keyed by exerciseId, so it sticks to the exercise in every program the user
 * adds it to. It is per-user and never shared when an exercise/program is
 * shared. Tap to edit inline (Enter/blur saves, Esc cancels).
 */
export function ExerciseSubheader({
  exerciseId,
  className,
}: {
  exerciseId: string
  className?: string
}) {
  const text = useStore((s) => s.exerciseSubheaders[exerciseId] ?? '')
  const setSubheader = useStore((s) => s.setExerciseSubheader)
  const [editing, setEditing] = useState(false)
  const [draft, setDraft] = useState(text)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (editing) inputRef.current?.focus()
  }, [editing])

  function start() {
    setDraft(text)
    setEditing(true)
  }

  function commit() {
    setSubheader(exerciseId, draft)
    setEditing(false)
  }

  function cancel() {
    setDraft(text)
    setEditing(false)
  }

  if (editing) {
    return (
      <div className={cn('mt-3', className)}>
        <input
          ref={inputRef}
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onBlur={commit}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault()
              commit()
            } else if (e.key === 'Escape') {
              e.preventDefault()
              cancel()
            }
          }}
          maxLength={120}
          placeholder="Add a cue for this exercise…"
          className="input border-gold/60"
        />
      </div>
    )
  }

  if (!text.trim()) {
    return (
      <button
        type="button"
        onClick={start}
        className={cn(
          'mt-3 flex w-full items-center gap-1.5 rounded-lg border border-dashed border-white/10 px-3 py-2 text-left text-xs font-medium text-zinc-500 transition hover:border-gold/40 hover:text-gold',
          className,
        )}
      >
        <Plus className="h-3.5 w-3.5 shrink-0" />
        Add a cue
      </button>
    )
  }

  return (
    <button
      type="button"
      onClick={start}
      className={cn(
        'mt-3 flex w-full items-center gap-2 rounded-lg border border-white/5 border-l-[3px] border-l-gold bg-ink-900 px-3 py-2 text-left transition hover:border-l-gold hover:bg-ink-800',
        className,
      )}
    >
      <AlignLeft className="h-4 w-4 shrink-0 text-gold" />
      <span className="flex-1 text-sm font-semibold text-zinc-300">{text}</span>
    </button>
  )
}
