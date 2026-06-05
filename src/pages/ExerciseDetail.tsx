import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Lightbulb, Pencil } from 'lucide-react'
import { EXERCISE_MAP } from '../data/exercises'
import { useStore } from '../store'
import { ExerciseModal } from './Exercises'

export function ExerciseDetail() {
  const { exerciseId } = useParams()
  const navigate = useNavigate()
  const [editing, setEditing] = useState(false)
  // Read store slices so the page re-renders after an edit/override.
  const customExercises = useStore((s) => s.customExercises)
  const overrides = useStore((s) => s.exerciseOverrides)
  const ex = exerciseId
    ? customExercises.find((e) => e.id === exerciseId) ??
      overrides[exerciseId] ??
      EXERCISE_MAP[exerciseId]
    : undefined

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

  const photos = ex.photos ?? []

  return (
    <div className="animate-fade-in space-y-6">
      <div className="flex items-center justify-between gap-3">
        <button
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
        >
          <ArrowLeft className="h-4 w-4" /> Back
        </button>
        <button
          onClick={() => setEditing(true)}
          className="inline-flex items-center gap-1.5 rounded-lg border border-white/15 bg-ink-800 px-3 py-1.5 text-sm font-semibold text-zinc-200 hover:border-white/30"
        >
          <Pencil className="h-4 w-4" /> Edit
        </button>
      </div>

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
          style={{ background: 'radial-gradient(circle, rgba(53,94,59,0.22), transparent 70%)' }}
        >
          <span className="heading text-center text-lg font-bold leading-tight text-gold">
            {ex.primaryMuscle}
          </span>
        </div>
      </div>

      {ex.instructions.length > 0 && (
        <section>
          <h2 className="heading mb-2 text-sm font-semibold tracking-wider text-zinc-300">
            How to perform
          </h2>
          <ol className="card divide-y divide-white/5 p-0">
            {ex.instructions.map((step, i) => (
              <li key={i} className="flex gap-3 p-4">
                <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-gold text-xs font-bold text-white">
                  {i + 1}
                </span>
                <p className="text-sm text-zinc-300">{step}</p>
              </li>
            ))}
          </ol>
        </section>
      )}

      {ex.tips.length > 0 && (
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
      )}

      {photos.length > 0 && (
        <section>
          <h2 className="heading mb-2 text-sm font-semibold tracking-wider text-zinc-300">
            Photos
          </h2>
          <div className="grid grid-cols-2 gap-3">
            {photos.map((src, i) => (
              <img
                key={i}
                src={src}
                alt={`${ex.name} ${i + 1}`}
                className="aspect-square w-full rounded-xl border border-white/10 object-cover"
              />
            ))}
          </div>
        </section>
      )}

      {editing && <ExerciseModal editing={ex} onClose={() => setEditing(false)} />}
    </div>
  )
}
