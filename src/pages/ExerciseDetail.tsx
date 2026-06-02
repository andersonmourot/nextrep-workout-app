import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Lightbulb, Timer } from 'lucide-react'
import { getExercise } from '../data/exercises'

export function ExerciseDetail() {
  const { exerciseId } = useParams()
  const navigate = useNavigate()
  const ex = exerciseId ? getExercise(exerciseId) : undefined

  if (!ex) {
    return (
      <div className="animate-fade-in py-10 text-center">
        <p className="text-zinc-400">Exercise not found.</p>
        <Link to="/exercises" className="btn-outline mt-4">
          Back to Exercises
        </Link>
      </div>
    )
  }

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div>
        <span className="label-eyebrow">{ex.primaryMuscle}</span>
        <h1 className="heading text-3xl font-bold text-zinc-50">{ex.name}</h1>
        <div className="mt-3 flex flex-wrap gap-1.5">
          <span className="chip">{ex.equipment}</span>
          <span className="chip">{ex.difficulty}</span>
          {ex.secondaryMuscles.map((m) => (
            <span key={m} className="chip">
              {m}
            </span>
          ))}
        </div>
      </div>

      {/* Muscle visual */}
      <div className="card grid place-items-center p-8">
        <div
          className="grid h-28 w-28 place-items-center rounded-full"
          style={{ background: 'radial-gradient(circle, rgba(233,185,73,0.18), transparent 70%)' }}
        >
          <span className="heading text-center text-lg font-bold leading-tight text-gold">
            {ex.primaryMuscle}
          </span>
        </div>
      </div>

      <div className="card flex items-center justify-between p-4">
        <div className="flex items-center gap-2 text-sm text-zinc-300">
          <Timer className="h-4 w-4 text-gold" /> Recommended tempo
        </div>
        <span className="heading text-lg font-bold text-zinc-50">{ex.tempo}</span>
      </div>

      <section>
        <h2 className="heading mb-2 text-sm font-semibold tracking-wider text-zinc-300">
          How to perform
        </h2>
        <ol className="card divide-y divide-white/5 p-0">
          {ex.instructions.map((step, i) => (
            <li key={i} className="flex gap-3 p-4">
              <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-gold text-xs font-bold text-ink-950">
                {i + 1}
              </span>
              <p className="text-sm text-zinc-300">{step}</p>
            </li>
          ))}
        </ol>
      </section>

      <section>
        <h2 className="heading mb-2 text-sm font-semibold tracking-wider text-zinc-300">
          Coaching cues
        </h2>
        <ul className="space-y-2">
          {ex.tips.map((tip, i) => (
            <li key={i} className="card flex items-start gap-3 p-4">
              <Lightbulb className="mt-0.5 h-4 w-4 shrink-0 text-gold" />
              <p className="text-sm text-zinc-300">{tip}</p>
            </li>
          ))}
        </ul>
      </section>
    </div>
  )
}
