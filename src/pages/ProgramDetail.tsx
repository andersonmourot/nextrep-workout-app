import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
  ArrowLeft,
  Check,
  ChevronRight,
  Clock,
  Copy,
  Dumbbell,
  Pencil,
  Play,
  Target,
  Trash2,
  X,
} from 'lucide-react'
import { exerciseLabel, getExercise } from '../data/exercises'
import { useIsCustomProgram, useProgram, useStore } from '../store'
import { getToken, useAuth } from '../auth'
import { apiUpsertProgram } from '../api'
import type { Program } from '../types'
import { uid } from '../lib/utils'

export function ProgramDetail() {
  const { programId } = useParams()
  const navigate = useNavigate()
  const program = useProgram(programId)
  const isCustom = useIsCustomProgram(programId)
  const { activeProgramId, startProgram, deleteProgram, addProgram } = useStore()
  const currentUserId = useAuth((s) => s.user?.id)
  const currentUserName = useAuth((s) => s.user?.name)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [duplicating, setDuplicating] = useState(false)

  async function duplicate(p: Program) {
    const token = getToken()
    setDuplicating(true)
    // Independent copy: new id + you as owner, so edits never sync back to the
    // original. You can then edit it and share it (collaborative or not) yourself.
    const copy: Program = {
      ...p,
      id: `custom-${uid()}`,
      name: `${p.name} (copy)`,
      ownerId: currentUserId,
      ownerName: currentUserName ?? p.ownerName,
      coach: currentUserName || p.coach,
      collaborative: false,
      version: Date.now(),
    }
    addProgram(copy)
    if (token) await apiUpsertProgram<Program>(token, copy)
    setDuplicating(false)
    navigate('/programs')
  }

  if (!program) {
    return (
      <div className="animate-fade-in py-10 text-center">
        <p className="text-zinc-400">Program not found.</p>
        <Link to="/programs" className="btn-outline mt-4">
          Back to Programs
        </Link>
      </div>
    )
  }

  const isActive = program.id === activeProgramId
  // You can edit a custom program if you're its creator, or if it's marked
  // collaborative. Non-owners of a non-collaborative program are view-only.
  const isOwner = !program.ownerId || program.ownerId === currentUserId
  const canEdit = isCustom && (isOwner || !!program.collaborative)

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div
        className="card p-5"
        style={{ background: `linear-gradient(160deg, ${program.accent}24, #141417 60%)` }}
      >
        <div className="flex items-center gap-2">
          <span className="label-eyebrow" style={{ color: program.accent }}>
            {program.category} · {program.level}
          </span>
          {isCustom && (
            <span className="rounded-full bg-gold/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-gold">
              Custom
            </span>
          )}
        </div>
        <h1 className="heading mt-1 text-3xl font-bold text-zinc-50">{program.name}</h1>
        <p className="mt-2 text-sm text-zinc-300">{program.description}</p>

        <div className="mt-4 grid grid-cols-3 gap-3 text-center">
          <Meta icon={<Clock className="h-4 w-4" />} label="Weeks" value={program.durationWeeks} />
          <Meta icon={<Dumbbell className="h-4 w-4" />} label="Days/wk" value={program.daysPerWeek} />
          <Meta icon={<Target className="h-4 w-4" />} label="Days" value={program.days.length} />
        </div>

        <div className="mt-4 flex flex-wrap gap-1.5">
          {program.tags.map((t) => (
            <span key={t} className="chip">
              {t}
            </span>
          ))}
        </div>

        <button
          onClick={() => startProgram(program.id)}
          disabled={isActive}
          className="btn-gold mt-5 w-full"
        >
          {isActive ? (
            <>
              <Check className="h-4 w-4" /> Active Program
            </>
          ) : (
            'Set as Active Program'
          )}
        </button>

        {isCustom && !canEdit && (
          <p className="mt-3 text-center text-xs text-zinc-500">
            View only · {program.ownerName ? `created by ${program.ownerName}` : 'created by another athlete'}.
            Only the creator can edit this program.
          </p>
        )}

        {isCustom && (
          <div className="mt-2 flex gap-2">
            {canEdit && (
              <Link to={`/programs/${program.id}/edit`} className="btn-ghost flex-1">
                <Pencil className="h-4 w-4" /> Edit
              </Link>
            )}
            {!isOwner && (
              <button
                onClick={() => void duplicate(program)}
                disabled={duplicating}
                className="btn-ghost flex-1 disabled:opacity-60"
                title="Make an independent copy you fully own"
              >
                <Copy className="h-4 w-4" /> {duplicating ? 'Duplicating…' : 'Duplicate'}
              </button>
            )}
            {confirmDelete ? (
              <div className="flex flex-1 items-center justify-center gap-2">
                <button
                  onClick={() => {
                    deleteProgram(program.id)
                    navigate('/programs')
                  }}
                  aria-label="Confirm delete"
                  className="btn flex-1 border border-red-500/40 text-red-300 hover:bg-red-500/10"
                >
                  <Check className="h-4 w-4" />
                </button>
                <button
                  onClick={() => setConfirmDelete(false)}
                  aria-label="Cancel"
                  className="btn-ghost flex-1"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            ) : (
              <button
                onClick={() => setConfirmDelete(true)}
                className="btn-ghost flex-1 text-red-300 hover:text-red-200"
              >
                <Trash2 className="h-4 w-4" /> Delete
              </button>
            )}
          </div>
        )}
      </div>

      <section className="space-y-3">
        <h2 className="heading text-sm font-semibold tracking-wider text-zinc-300">
          The Split · {program.days.length} Days
        </h2>
        {program.days.map((day, i) => (
          <div key={day.id} className="card overflow-hidden">
            <div className="flex items-center justify-between px-4 pt-4">
              <div>
                <span className="text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
                  Day {i + 1}
                </span>
                <h3 className="heading text-lg font-bold text-zinc-50">{day.name}</h3>
                <p className="text-xs text-zinc-400">{day.focus}</p>
              </div>
              <Link
                to={`/workout/${program.id}/${day.id}`}
                className="btn-outline px-3 py-2 text-xs"
              >
                <Play className="h-3.5 w-3.5" /> Start
              </Link>
            </div>
            <ul className="mt-3 divide-y divide-white/5 border-t border-white/5">
              {day.exercises.map((pe, j) => {
                const ex = getExercise(pe.exerciseId)
                const meta = (
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-zinc-100">
                      {exerciseLabel(pe)}
                    </p>
                    <p className="text-xs text-zinc-500">
                      {pe.sets} × {pe.reps} · tempo {pe.tempo} · {pe.restSec}s rest
                    </p>
                  </div>
                )
                return (
                  <li key={`${pe.exerciseId}-${j}`}>
                    {ex ? (
                      <Link
                        to={`/exercises/${pe.exerciseId}`}
                        className="flex items-center justify-between px-4 py-3 hover:bg-white/[0.02]"
                      >
                        {meta}
                        <ChevronRight className="h-4 w-4 shrink-0 text-zinc-600" />
                      </Link>
                    ) : (
                      <div className="px-4 py-3">{meta}</div>
                    )}
                  </li>
                )
              })}
            </ul>
          </div>
        ))}
      </section>
    </div>
  )
}

function Meta({ icon, label, value }: { icon: React.ReactNode; label: string; value: number }) {
  return (
    <div className="rounded-xl border border-white/5 bg-ink-900/50 py-2.5">
      <div className="flex items-center justify-center text-gold">{icon}</div>
      <div className="heading mt-1 text-lg font-bold text-zinc-50">{value}</div>
      <div className="text-[11px] text-zinc-500">{label}</div>
    </div>
  )
}
