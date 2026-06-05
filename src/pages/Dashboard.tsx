import { Link, useNavigate } from 'react-router-dom'
import { ArrowRight, Calendar, Dumbbell, Flame, Play, TrendingUp } from 'lucide-react'
import { useProgram, useStore } from '../store'
import { exerciseLabel } from '../data/exercises'
import { ProgressRing } from '../components/ProgressRing'
import {
  computeStreak,
  formatDate,
  greeting,
  nextDayIndex,
  workoutsThisWeek,
} from '../lib/utils'

export function Dashboard() {
  const { name, activeProgramId, logs, unit, activeWorkout, startWorkout } = useStore()
  const program = useProgram(activeProgramId ?? undefined)
  const navigate = useNavigate()

  const streak = computeStreak(logs)
  const weekCount = workoutsThisWeek(logs)
  const dayIdx = program ? nextDayIndex(program, logs) : 0
  const nextDay = program ? program.days[dayIdx] : undefined
  const weekTarget = program?.daysPerWeek ?? 4
  const recent = logs.slice(0, 3)

  return (
    <div className="animate-fade-in space-y-6">
      <div>
        <p className="label-eyebrow">{greeting()}</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">{name}</h1>
      </div>

      {/* Today's workout */}
      {program && nextDay ? (
        <section className="card overflow-hidden">
          <div
            className="px-5 pb-5 pt-4"
            style={{
              background: `linear-gradient(180deg, ${program.accent}1a, transparent 70%)`,
            }}
          >
            <div className="flex items-center justify-between">
              <span className="label-eyebrow">Today · {program.name}</span>
              <span className="chip">Day {dayIdx + 1}</span>
            </div>
            <h2 className="heading mt-2 text-2xl font-bold text-zinc-50">{nextDay.name}</h2>
            <p className="text-sm text-zinc-400">{nextDay.focus}</p>

            <div className="mt-3 flex flex-wrap gap-1.5">
              {nextDay.exercises.slice(0, 4).map((pe, i) => (
                <span key={`${pe.exerciseId}-${i}`} className="chip">
                  {exerciseLabel(pe)}
                </span>
              ))}
              {nextDay.exercises.length > 4 && (
                <span className="chip">+{nextDay.exercises.length - 4} more</span>
              )}
            </div>

            <div className="mt-4 flex gap-2">
              {activeWorkout ? (
                <button onClick={() => navigate('/programs')} className="btn-gold flex-1">
                  <Play className="h-4 w-4" />
                  Resume Workout
                </button>
              ) : (
                <button
                  onClick={() => {
                    startWorkout(program.id, nextDay.id)
                    navigate('/programs')
                  }}
                  className="btn-gold flex-1"
                >
                  <Play className="h-4 w-4" />
                  Start Workout
                </button>
              )}
              <Link to={`/programs/${program.id}`} className="btn-ghost">
                Details
              </Link>
            </div>
          </div>
        </section>
      ) : (
        <section className="card p-5">
          <h2 className="heading text-xl font-bold text-zinc-50">No active program</h2>
          <p className="mt-1 text-sm text-zinc-400">
            Pick a program to start training and we'll line up your next session here.
          </p>
          <Link to="/programs" className="btn-gold mt-4 w-full">
            Browse Programs
            <ArrowRight className="h-4 w-4" />
          </Link>
        </section>
      )}

      {/* Stats */}
      <section className="grid grid-cols-3 gap-3">
        <StatCard icon={<Flame className="h-4 w-4" />} label="Streak" value={`${streak}`} suffix="days" />
        <div className="card flex flex-col items-center justify-center gap-1 p-3">
          <ProgressRing value={weekTarget ? weekCount / weekTarget : 0} size={56} stroke={6}>
            <span className="text-sm font-bold text-zinc-50">{weekCount}</span>
          </ProgressRing>
          <span className="text-[11px] text-zinc-500">of {weekTarget}/wk</span>
        </div>
        <StatCard
          icon={<Dumbbell className="h-4 w-4" />}
          label="Workouts"
          value={`${logs.length}`}
          suffix="total"
        />
      </section>

      {/* Recent activity */}
      <section>
        <div className="mb-2 flex items-center justify-between">
          <h3 className="heading text-sm font-semibold tracking-wider text-zinc-300">
            Recent Activity
          </h3>
          {logs.length > 0 && (
            <Link to="/progress" className="text-xs font-medium text-gold">
              View all
            </Link>
          )}
        </div>
        {recent.length === 0 ? (
          <div className="card flex items-center gap-3 p-4 text-sm text-zinc-400">
            <Calendar className="h-5 w-5 text-zinc-600" />
            Your completed workouts will show up here.
          </div>
        ) : (
          <ul className="space-y-2">
            {recent.map((log) => (
              <li key={log.id} className="card flex items-center justify-between p-3.5">
                <div>
                  <p className="text-sm font-semibold text-zinc-100">{log.dayName}</p>
                  <p className="text-xs text-zinc-500">
                    {log.programName} · {formatDate(log.date)}
                  </p>
                </div>
                <div className="flex items-center gap-1 text-xs font-semibold text-gold">
                  <TrendingUp className="h-3.5 w-3.5" />
                  {Math.round(log.totalVolume).toLocaleString()} {unit}
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  )
}

function StatCard({
  icon,
  label,
  value,
  suffix,
}: {
  icon: React.ReactNode
  label: string
  value: string
  suffix: string
}) {
  return (
    <div className="card flex flex-col items-center justify-center gap-0.5 p-3 text-center">
      <span className="text-gold">{icon}</span>
      <span className="heading text-2xl font-bold leading-none text-zinc-50">{value}</span>
      <span className="text-[11px] text-zinc-500">{suffix}</span>
      <span className="sr-only">{label}</span>
    </div>
  )
}
