import { useRef } from 'react'
import { AlignLeft, ListPlus } from 'lucide-react'
import { useStore } from '../store'
import { cn } from '../lib/utils'

/**
 * Small header button that opens the cue editor for an exercise. It only shows
 * when the exercise has no cue yet — once a cue exists, the cue itself (rendered
 * by ExerciseSubheader under the title) is the tappable/editable element, so the
 * button drops off. Sits next to the notes button in the exercise header.
 */
export function ExerciseCueButton({
  exerciseId,
  className,
}: {
  exerciseId: string
  className?: string
}) {
  const text = useStore((s) => s.exerciseSubheaders[exerciseId] ?? '')
  const setEditingCueId = useStore((s) => s.setEditingCueId)
  const editing = useStore((s) => s.editingCueId === exerciseId)

  // Once a cue exists it's shown/edited inline under the title, so hide the
  // button. While actively editing an empty cue, keep it visible (the inline
  // input is open above the sets).
  if (text.trim()) return null

  return (
    <button
      type="button"
      onClick={(e: React.MouseEvent) => {
        e.stopPropagation()
        setEditingCueId(editing ? null : exerciseId)
      }}
      className={cn(
        'grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-400 transition hover:text-gold',
        editing && 'text-gold',
        className,
      )}
      aria-label="Add a cue"
      title="Add a cue"
    >
      <ListPlus className="h-5 w-5" />
    </button>
  )
}

/**
 * Private per-exercise "sub-header" cue, shown inline under the exercise title.
 * Keyed by exerciseId, so it sticks to the exercise in every program the user
 * adds it to. It is per-user and never shared when an exercise/program is
 * shared.
 *
 * When empty, nothing renders here — the cue is added via ExerciseCueButton in
 * the header. Once a cue exists it shows as the left-bar line and is click-to-
 * edit. Editing is coordinated through the store (editingCueId) so the header
 * button can open this inline editor.
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
  const editing = useStore((s) => s.editingCueId === exerciseId)
  const setEditingCueId = useStore((s) => s.setEditingCueId)
  // The input is uncontrolled (defaultValue + read on commit) so opening the
  // editor needs no state-sync effect. cancelingRef lets Escape skip the
  // save that the resulting blur would otherwise trigger.
  const cancelingRef = useRef(false)

  function commit(value: string) {
    if (cancelingRef.current) {
      cancelingRef.current = false
      return
    }
    setSubheader(exerciseId, value)
    setEditingCueId(null)
  }

  function cancel() {
    cancelingRef.current = true
    setEditingCueId(null)
  }

  if (editing) {
    return (
      <div className={cn('mt-3', className)}>
        <input
          autoFocus
          defaultValue={text}
          onBlur={(e) => commit(e.currentTarget.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault()
              commit(e.currentTarget.value)
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

  if (!text.trim()) return null

  return (
    <button
      type="button"
      onClick={(e: React.MouseEvent) => {
        e.stopPropagation()
        setEditingCueId(exerciseId)
      }}
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
