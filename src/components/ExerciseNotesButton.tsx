import { useState } from 'react'
import { NotebookPen, X } from 'lucide-react'
import { useStore } from '../store'
import { cn } from '../lib/utils'

/**
 * Pencil-and-paper button that opens a notes editor for a single exercise.
 * Notes are stored per exercise id (shared across every program/day it appears
 * in, and on the exercise's own card), so editing here updates everywhere.
 */
export function ExerciseNotesButton({
  exerciseId,
  label,
  className,
}: {
  exerciseId: string
  /** Exercise name, shown in the editor heading. */
  label?: string
  className?: string
}) {
  const note = useStore((s) => s.exerciseNotes[exerciseId] ?? '')
  const setExerciseNote = useStore((s) => s.setExerciseNote)
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState(note)

  const hasNote = note.trim().length > 0

  function openEditor() {
    setDraft(note)
    setOpen(true)
  }

  function close() {
    setOpen(false)
  }

  function save() {
    setExerciseNote(exerciseId, draft)
    setOpen(false)
  }

  return (
    <>
      <button
        type="button"
        onClick={(e: React.MouseEvent) => {
          e.stopPropagation()
          openEditor()
        }}
        className={cn(
          'relative grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-ink-800 text-zinc-400 transition hover:text-gold',
          className,
        )}
        aria-label={hasNote ? 'Edit exercise notes' : 'Add exercise notes'}
        title={hasNote ? 'Edit notes' : 'Add notes'}
      >
        <NotebookPen className="h-5 w-5" />
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/70 p-6"
          onClick={close}
        >
          <div
            className="card mt-[12vh] w-full max-w-sm p-5"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <h3 className="heading text-lg font-bold text-zinc-50">Notes</h3>
                {label && <p className="mt-0.5 text-sm text-zinc-400">{label}</p>}
              </div>
              <button
                onClick={close}
                className="grid h-8 w-8 place-items-center rounded-lg bg-ink-850 text-zinc-400 hover:text-zinc-100"
                aria-label="Close"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <textarea
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              placeholder="Form cues, weights to try, reminders…"
              rows={5}
              autoFocus
              className="input mt-4 resize-none"
            />
            <div className="mt-4 flex gap-2">
              <button onClick={save} className="btn-gold flex-1">
                Save
              </button>
              <button onClick={close} className="btn-ghost flex-1">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

/** Read-only inline display of an exercise's shared note (hidden when empty). */
export function ExerciseNote({ exerciseId }: { exerciseId: string }) {
  const note = useStore((s) => s.exerciseNotes[exerciseId] ?? '')
  if (!note.trim()) return null
  return (
    <p className="mt-3 whitespace-pre-wrap rounded-lg bg-ink-800/70 px-3 py-2 text-xs text-zinc-300">
      {note}
    </p>
  )
}
