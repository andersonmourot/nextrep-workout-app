import { Link } from 'react-router-dom'
import { ArrowLeft, Dumbbell, Scale } from 'lucide-react'
import { useStore } from '../store'
import { BodyWeightRow, WorkoutHistoryItem } from './Progress'

/**
 * Full workout history — the user's 20 most recent finished workouts. Reached via
 * the "Show More" link on the Progress page's Workout History section.
 */
export function WorkoutHistory() {
  const { logs, unit, deleteLog } = useStore()
  const recent = logs.slice(0, 20)

  return (
    <div className="animate-fade-in space-y-5">
      <Link
        to="/progress"
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </Link>
      <div>
        <h1 className="heading text-3xl font-bold text-zinc-50">Workout History</h1>
        <p className="mt-1 text-sm text-zinc-400">Your 20 most recent finished workouts.</p>
      </div>

      {recent.length === 0 ? (
        <div className="card p-8 text-center">
          <Dumbbell className="mx-auto h-8 w-8 text-zinc-600" />
          <p className="mt-3 text-sm text-zinc-400">No workouts logged yet.</p>
        </div>
      ) : (
        <ul className="space-y-2">
          {recent.map((log) => (
            <WorkoutHistoryItem key={log.id} log={log} unit={unit} onDelete={deleteLog} />
          ))}
        </ul>
      )}
    </div>
  )
}

/**
 * Full body-weight history — every logged entry, newest first. Reached via the
 * "Show More" link on the Progress page's Body Weight card.
 */
export function BodyWeightHistory() {
  const { bodyWeight, unit, deleteBodyWeight } = useStore()
  const entries = [...bodyWeight].reverse()

  return (
    <div className="animate-fade-in space-y-5">
      <Link
        to="/progress"
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </Link>
      <div>
        <h1 className="heading text-3xl font-bold text-zinc-50">Body Weight</h1>
        <p className="mt-1 text-sm text-zinc-400">Every logged entry, newest first.</p>
      </div>

      {entries.length === 0 ? (
        <div className="card p-8 text-center">
          <Scale className="mx-auto h-8 w-8 text-zinc-600" />
          <p className="mt-3 text-sm text-zinc-400">No weight entries yet.</p>
        </div>
      ) : (
        <ul className="space-y-1.5">
          {entries.map((e) => (
            <BodyWeightRow key={e.id} entry={e} unit={unit} onDelete={deleteBodyWeight} />
          ))}
        </ul>
      )}
    </div>
  )
}
