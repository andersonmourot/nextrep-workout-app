import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Trash2 } from 'lucide-react'
import { useProgram, useStore } from '../store'
import { cn } from '../lib/utils'
import type { Unit } from '../types'

export function Settings() {
  const navigate = useNavigate()
  const { name, unit, activeProgramId, setName, setUnit, clearProgram, resetAll } = useStore()
  const [confirmReset, setConfirmReset] = useState(false)
  const program = useProgram(activeProgramId ?? undefined)

  return (
    <div className="animate-fade-in space-y-6">
      <button
        onClick={() => navigate(-1)}
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-zinc-200"
      >
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div>
        <p className="label-eyebrow">Make it yours</p>
        <h1 className="heading text-3xl font-bold text-zinc-50">Settings</h1>
      </div>

      <section className="card space-y-4 p-5">
        <div>
          <label className="mb-1.5 block text-sm font-medium text-zinc-300">Display name</label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name"
            className="input"
          />
        </div>

        <div>
          <span className="mb-1.5 block text-sm font-medium text-zinc-300">Weight unit</span>
          <div className="grid grid-cols-2 gap-2">
            {(['lb', 'kg'] as Unit[]).map((u) => (
              <button
                key={u}
                onClick={() => setUnit(u)}
                className={cn(
                  'rounded-xl border py-2.5 text-sm font-semibold uppercase transition',
                  unit === u
                    ? 'border-gold bg-gold text-ink-950'
                    : 'border-white/10 bg-ink-900 text-zinc-300',
                )}
              >
                {u}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="card p-5">
        <h2 className="heading text-lg font-bold text-zinc-50">Active Program</h2>
        {program ? (
          <div className="mt-2">
            <p className="text-sm text-zinc-300">{program.name}</p>
            <p className="text-xs text-zinc-500">
              {program.daysPerWeek} days / week · {program.durationWeeks} weeks
            </p>
            <div className="mt-3 flex gap-2">
              <Link to={`/programs/${program.id}`} className="btn-ghost flex-1">
                View
              </Link>
              <button onClick={clearProgram} className="btn-ghost flex-1">
                Clear
              </button>
            </div>
          </div>
        ) : (
          <div className="mt-2">
            <p className="text-sm text-zinc-400">No active program selected.</p>
            <Link to="/programs" className="btn-gold mt-3 w-full">
              Browse Programs
            </Link>
          </div>
        )}
      </section>

      <section className="card border-red-500/20 p-5">
        <h2 className="heading text-lg font-bold text-red-300">Danger Zone</h2>
        <p className="mt-1 text-sm text-zinc-400">
          Reset clears your active program, workout history, and body-weight log. This can't be undone.
        </p>
        {confirmReset ? (
          <div className="mt-3 flex gap-2">
            <button
              onClick={() => {
                resetAll()
                setConfirmReset(false)
              }}
              className="btn flex-1 bg-red-500/90 text-white hover:bg-red-500"
            >
              <Trash2 className="h-4 w-4" /> Confirm Reset
            </button>
            <button onClick={() => setConfirmReset(false)} className="btn-ghost flex-1">
              Cancel
            </button>
          </div>
        ) : (
          <button
            onClick={() => setConfirmReset(true)}
            className="btn mt-3 w-full border border-red-500/40 text-red-300 hover:bg-red-500/10"
          >
            Reset All Data
          </button>
        )}
      </section>

      <p className="pb-2 text-center text-xs text-zinc-600">
        SMELLIS · Set the standard. Inspired by the STNDRD training app.
      </p>
    </div>
  )
}
