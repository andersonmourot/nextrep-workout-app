import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Check, ChevronRight, Clock, Dumbbell, Play, Target } from 'lucide-react'
import { getProgram } from '../data/programs'
import { getExercise } from '../data/exercises'
import { useStore } from '../store'

export function ProgramDetail() {
  const { programId } = useParams()
  const navigate = useNavigate()
  const program = programId ? getProgram(programId) : undefined
  const { activeProgramId, startProgram } = useStore()

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
        <span className="label-eyebrow" style={{ color: program.accent }}>
          {program.category} · {program.level}
        </span>
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
              {day.exercises.map((pe) => {
                const ex = getExercise(pe.exerciseId)
                return (
                  <li key={pe.exerciseId}>
                    <Link
                      to={`/exercises/${pe.exerciseId}`}
                      className="flex items-center justify-between px-4 py-3 hover:bg-white/[0.02]"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-zinc-100">
                          {ex?.name ?? pe.exerciseId}
                        </p>
                        <p className="text-xs text-zinc-500">
                          {pe.sets} × {pe.reps} · tempo {pe.tempo} · {pe.restSec}s rest
                        </p>
                      </div>
                      <ChevronRight className="h-4 w-4 shrink-0 text-zinc-600" />
                    </Link>
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
