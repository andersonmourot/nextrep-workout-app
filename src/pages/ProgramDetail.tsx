import { useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
  ArrowLeft,
  Check,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  Clock,
  Copy,
  Dumbbell,
  MoreHorizontal,
  Pencil,
  Play,
  RotateCcw,
  Star,
  Target,
  Trash2,
  X,
} from 'lucide-react'
import { exerciseLabel, getExercise } from '../data/exercises'
import { MAX_FAVORITES, useIsCustomProgram, useProgram, useStore } from '../store'
import { cn, programLogSlots, programRun, resolveProgramDay, uid } from '../lib/utils'
import { accentVars } from '../lib/theme'
import { getToken, useAuth } from '../auth'
import { apiUpsertProgram } from '../api'
import type { Program } from '../types'

export function ProgramDetail() {
  const { programId } = useParams()
  const navigate = useNavigate()
  const program = useProgram(programId)
  const isCustom = useIsCustomProgram(programId)
  const { activeProgramId, startProgram, deleteProgram, addProgram, startWorkout } = useStore()
  const activeWorkout = useStore((s) => s.activeWorkout)
  const activeProgram = useProgram(activeProgramId ?? undefined)
  const resetProgramProgress = useStore((s) => s.resetProgramProgress)
  const logs = useStore((s) => s.logs)
  const unit = useStore((s) => s.unit)
  const programAnchors = useStore((s) => s.programAnchors)
  const favoriteProgramIds = useStore((s) => s.favoriteProgramIds)
  const toggleFavoriteProgram = useStore((s) => s.toggleFavoriteProgram)
  const currentUserId = useAuth((s) => s.user?.id)
  const currentUserName = useAuth((s) => s.user?.name)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmReset, setConfirmReset] = useState(false)
  const [confirmComplete, setConfirmComplete] = useState(false)
  const [duplicating, setDuplicating] = useState(false)
  const [showActions, setShowActions] = useState(false)
  // Set when Start is pressed on a day while a *different* active program has
  // saved progress: holds the day to start once the user confirms the switch.
  const [pendingStart, setPendingStart] = useState<{ dayId: string; week: number } | null>(null)
  // null = follow the current week automatically; a number = a week the user
  // navigated to manually.
  const [weekOverride, setWeekOverride] = useState<number | null>(null)

  const anchor = program ? programAnchors[program.id] : undefined
  const run = useMemo(
    () => (program ? programRun(program, logs, anchor) : null),
    [program, logs, anchor],
  )
  const slots = useMemo(
    () => (program ? programLogSlots(program, logs, anchor) : []),
    [program, logs, anchor],
  )
  // The week shown defaults to the one holding the next workout; the user can
  // page back/forward to review past or upcoming weeks.
  const totalWeeks = run?.totalWeeks ?? 1
  const selectedWeek = Math.min(
    Math.max(1, weekOverride ?? (run?.currentWeekIndex ?? 0) + 1),
    totalWeeks,
  )

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
  // A program with any logged workouts has progress worth resetting, even if it
  // isn't the currently active program (e.g. you finished it or switched away).
  const hasHistory = logs.some((l) => l.programId === program.id)
  const canReset = isActive || hasHistory
  // You can edit a custom program if you're its creator, or if it's marked
  // collaborative. Non-owners of a non-collaborative program are view-only.
  const isOwner = !program.ownerId || program.ownerId === currentUserId
  const canEdit = isCustom && (isOwner || !!program.collaborative)

  // True when a *different* program is active and has saved progress (logged
  // workouts or an in-progress session). Starting a day here would switch the
  // active program, so we warn first.
  const switchingActiveWithData =
    !!activeProgramId &&
    activeProgramId !== program.id &&
    (logs.some((l) => l.programId === activeProgramId) ||
      activeWorkout?.programId === activeProgramId)

  function doStartDay(dayId: string, week: number) {
    if (!program) return
    // Set this program active so its workout actually surfaces (the workout
    // overlay only shows while its program is the active one), then start.
    if (activeProgramId !== program.id) startProgram(program.id)
    startWorkout(program.id, dayId, week)
    setPendingStart(null)
    navigate('/programs')
  }

  function handleStartDay(dayId: string, week: number) {
    if (switchingActiveWithData) {
      setPendingStart({ dayId, week })
      return
    }
    doStartDay(dayId, week)
  }

  return (
    <div className="animate-fade-in space-y-6" style={accentVars(program.accent)}>
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div
        className="card relative p-5"
        style={{ background: `linear-gradient(160deg, ${program.accent}24, #141417 60%)` }}
      >
        {(() => {
          const isFavorite = favoriteProgramIds.includes(program.id)
          const favoriteFull = favoriteProgramIds.length >= MAX_FAVORITES
          return (
            <button
              onClick={() => toggleFavoriteProgram(program.id)}
              disabled={!isFavorite && favoriteFull}
              aria-label={isFavorite ? 'Unfavorite program' : 'Favorite program'}
              title={
                !isFavorite && favoriteFull
                  ? `You can favorite up to ${MAX_FAVORITES} programs`
                  : undefined
              }
              className={cn(
                'absolute right-3 top-3 grid h-9 w-9 place-items-center rounded-lg bg-ink-900/70 backdrop-blur transition',
                isFavorite
                  ? 'text-gold hover:text-gold-400'
                  : 'text-zinc-400 hover:text-gold disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:text-zinc-400',
              )}
            >
              <Star className={cn('h-5 w-5', isFavorite && 'fill-current')} />
            </button>
          )
        })()}
        <div className="flex items-center gap-2 pr-10">
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

        {isActive && run?.isComplete && (
          <div
            className="mt-4 rounded-xl border p-3 text-center"
            style={{ borderColor: `${program.accent}66`, background: `${program.accent}14` }}
          >
            <p className="text-sm font-semibold text-zinc-100">Program complete</p>
            <p className="mt-0.5 text-xs text-zinc-400">
              You finished all {program.durationWeeks} weeks — it's saved to{' '}
              <Link to="/programs/history" className="font-medium underline" style={{ color: program.accent }}>
                Program History
              </Link>
              .
            </p>
            {confirmComplete ? (
              <div className="mt-3 flex items-center justify-center gap-2">
                <button
                  onClick={() => {
                    resetProgramProgress(program.id)
                    setConfirmComplete(false)
                    setWeekOverride(null)
                  }}
                  className="btn-gold flex-1"
                >
                  <RotateCcw className="h-4 w-4" /> Reset & run again
                </button>
                <button onClick={() => setConfirmComplete(false)} className="btn-ghost flex-1">
                  Cancel
                </button>
              </div>
            ) : (
              <button
                onClick={() => setConfirmComplete(true)}
                className="btn-gold mt-3 w-full"
                title="Your history is already saved — this restarts the program at Week 1, Day 1"
              >
                <RotateCcw className="h-4 w-4" /> Save to History & Reset
              </button>
            )}
          </div>
        )}

        {isCustom && !canEdit && (
          <p className="mt-3 text-center text-xs text-zinc-500">
            View only · {program.ownerName ? `created by ${program.ownerName}` : 'created by another athlete'}.
            Only the creator can edit this program.
          </p>
        )}

        {(isCustom || isActive || hasHistory) && (
          showActions ? (
            <>
            <div className="mt-2 flex flex-wrap gap-2">
              {canEdit && (
                <Link
                  to={`/programs/${program.id}/edit`}
                  className="btn-ghost min-w-[120px] flex-1"
                >
                  <Pencil className="h-4 w-4" /> Edit
                </Link>
              )}
              {isCustom && (
                <button
                  onClick={() => void duplicate(program)}
                  disabled={duplicating}
                  className="btn-ghost min-w-[120px] flex-1 disabled:opacity-60"
                  title="Make an independent copy you fully own"
                >
                  <Copy className="h-4 w-4" /> {duplicating ? 'Duplicating…' : 'Duplicate'}
                </button>
              )}
              {canReset &&
                (confirmReset ? (
                  <div className="flex min-w-[120px] flex-1 items-center justify-center gap-2">
                    <button
                      onClick={() => {
                        resetProgramProgress(program.id)
                        setConfirmReset(false)
                        setWeekOverride(null)
                      }}
                      aria-label="Confirm reset"
                      className="btn flex-1 border border-amber-500/40 text-amber-300 hover:bg-amber-500/10"
                    >
                      <Check className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => setConfirmReset(false)}
                      aria-label="Cancel reset"
                      className="btn-ghost flex-1"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => setConfirmReset(true)}
                    className="btn-ghost min-w-[120px] flex-1 text-amber-300 hover:text-amber-200"
                    title="Restart this program at Week 1, Day 1 (keeps your workout history)"
                  >
                    <RotateCcw className="h-4 w-4" /> Reset
                  </button>
                ))}
              {isCustom &&
                (confirmDelete ? (
                  <div className="flex min-w-[120px] flex-1 items-center justify-center gap-2">
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
                    className="btn-ghost min-w-[120px] flex-1 text-red-300 hover:text-red-200"
                  >
                    <Trash2 className="h-4 w-4" /> Delete
                  </button>
                ))}
            </div>
            <button
              onClick={() => {
                setShowActions(false)
                setConfirmDelete(false)
                setConfirmReset(false)
              }}
              className="btn-ghost mt-2 w-full"
              aria-label="Collapse actions"
            >
              <ChevronUp className="h-5 w-5" />
            </button>
            </>
          ) : (
            <button
              onClick={() => setShowActions(true)}
              className="btn-ghost mt-2 w-full"
              aria-label="More actions"
            >
              <MoreHorizontal className="h-5 w-5" />
            </button>
          )
        )}
        {canReset && confirmReset && (
          <p className="mt-2 text-center text-xs text-zinc-500">
            Restart this program at Week 1, Day 1. Your logged workouts and stats are kept.
          </p>
        )}
      </div>

      <section className="space-y-3">
        <div className="flex items-center justify-between gap-2">
          <h2 className="heading text-sm font-semibold tracking-wider text-zinc-300">
            The Split · {program.days.length} Days
          </h2>
          {totalWeeks > 1 && (
            <div className="flex items-center gap-1">
              <button
                onClick={() => setWeekOverride(Math.max(1, selectedWeek - 1))}
                disabled={selectedWeek <= 1}
                aria-label="Previous week"
                className="grid h-8 w-8 place-items-center rounded-lg bg-ink-800 text-zinc-400 hover:text-zinc-100 disabled:opacity-40"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <span className="min-w-[78px] text-center text-xs font-semibold text-zinc-300">
                Week {selectedWeek} / {totalWeeks}
              </span>
              <button
                onClick={() => setWeekOverride(Math.min(totalWeeks, selectedWeek + 1))}
                disabled={selectedWeek >= totalWeeks}
                aria-label="Next week"
                className="grid h-8 w-8 place-items-center rounded-lg bg-ink-800 text-zinc-400 hover:text-zinc-100 disabled:opacity-40"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          )}
        </div>
        {program.days.map((baseDay, i) => {
          // Show the plan resolved for the week being viewed (per-week edits).
          const day = resolveProgramDay(program, i, selectedWeek) ?? baseDay
          const globalIdx = (selectedWeek - 1) * program.days.length + i
          const log = slots[globalIdx]
          const completed = !!log
          // The next day up is the first unlogged slot (handles out-of-order logging).
          const nextGlobalIdx = run
            ? run.currentWeekIndex * program.days.length + run.nextDayIndex
            : 0
          const isNext = isActive && !run?.isComplete && globalIdx === nextGlobalIdx
          return (
            <div
              key={baseDay.id}
              className="card overflow-hidden"
              style={
                isNext
                  ? {
                      borderColor: program.accent,
                      boxShadow: `0 0 0 1.5px ${program.accent}, 0 0 18px ${program.accent}66`,
                    }
                  : undefined
              }
            >
              {/* Entire top section is one clickable target that opens the day
                  review, except the Start button which stops propagation. */}
              <div
                role="button"
                tabIndex={0}
                onClick={() => navigate(`/programs/${program.id}/day/${globalIdx}`)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault()
                    navigate(`/programs/${program.id}/day/${globalIdx}`)
                  }
                }}
                className="flex cursor-pointer items-start justify-between gap-2 px-4 pb-4 pt-4 hover:bg-white/[0.02]"
              >
                <div className="min-w-0 text-left">
                  <span className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-zinc-500">
                    Day {i + 1}
                    {completed && (
                      <span className="inline-flex items-center gap-0.5 text-emerald-400">
                        <Check className="h-3 w-3" /> Done
                      </span>
                    )}
                    {isNext && <span style={{ color: program.accent }}>Up next</span>}
                  </span>
                  <h3 className="heading text-lg font-bold text-zinc-50">{day.name}</h3>
                  <p className="text-xs text-zinc-400">{day.focus}</p>
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    handleStartDay(baseDay.id, selectedWeek)
                  }}
                  className="btn-outline shrink-0 px-3 py-2 text-xs"
                >
                  <Play className="h-3.5 w-3.5" /> Start
                </button>
              </div>
              <ul className="divide-y divide-white/5 border-t border-white/5">
                {day.exercises.map((pe, j) => {
                  const ex = getExercise(pe.exerciseId)
                  const logged = log?.exercises[j]
                  const doneSummary =
                    logged && logged.sets.length > 0
                      ? `${logged.sets.map((s) => `${s.weight}×${s.reps}`).join(' · ')} ${unit}`
                      : null
                  const meta = (
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium text-zinc-100">
                        {exerciseLabel(pe)}
                      </p>
                      <p
                        className={cn(
                          'text-xs',
                          doneSummary ? 'text-emerald-400/80' : 'text-zinc-500',
                        )}
                      >
                        {doneSummary ?? `${pe.sets} × ${pe.reps} · ${pe.restSec}s rest`}
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
          )
        })}
      </section>

      {pendingStart && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-6"
          onClick={() => setPendingStart(null)}
        >
          <div
            className="card w-full max-w-sm p-5 text-center"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="heading text-lg font-bold text-zinc-50">Switch active program?</h3>
            <p className="mt-2 text-sm text-zinc-400">
              You already have an active program
              {activeProgram?.name ? ` (“${activeProgram.name}”)` : ''} with saved progress.
              Starting this day will make “{program.name}” your active program. Your logged
              workouts and history are kept.
            </p>
            <div className="mt-4 flex gap-2">
              <button
                onClick={() => doStartDay(pendingStart.dayId, pendingStart.week)}
                className="btn-gold flex-1"
              >
                <Play className="h-4 w-4" /> Switch & Start
              </button>
              <button onClick={() => setPendingStart(null)} className="btn-ghost flex-1">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
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
