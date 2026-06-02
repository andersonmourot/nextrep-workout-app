import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { BodyWeightEntry, Program, Unit, WorkoutLog } from './types'
import { PROGRAMS, getProgram } from './data/programs'

interface AppState {
  name: string
  unit: Unit
  activeProgramId: string | null
  logs: WorkoutLog[]
  bodyWeight: BodyWeightEntry[]
  customPrograms: Program[]
  hiddenProgramIds: string[]

  setName: (name: string) => void
  setUnit: (unit: Unit) => void
  startProgram: (id: string) => void
  clearProgram: () => void
  addLog: (log: WorkoutLog) => void
  deleteLog: (id: string) => void
  addBodyWeight: (entry: BodyWeightEntry) => void
  deleteBodyWeight: (id: string) => void
  addProgram: (program: Program) => void
  updateProgram: (program: Program) => void
  deleteProgram: (id: string) => void
  restorePrograms: () => void
  resetAll: () => void
}

export const useStore = create<AppState>()(
  persist(
    (set) => ({
      name: 'Athlete',
      unit: 'lb',
      activeProgramId: null,
      logs: [],
      bodyWeight: [],
      customPrograms: [],
      hiddenProgramIds: [],

      setName: (name) => set({ name }),
      setUnit: (unit) => set({ unit }),
      startProgram: (id) => set({ activeProgramId: id }),
      clearProgram: () => set({ activeProgramId: null }),
      addLog: (log) => set((s) => ({ logs: [log, ...s.logs] })),
      deleteLog: (id) => set((s) => ({ logs: s.logs.filter((l) => l.id !== id) })),
      addBodyWeight: (entry) =>
        set((s) => ({
          bodyWeight: [...s.bodyWeight.filter((e) => e.date !== entry.date), entry].sort((a, b) =>
            a.date < b.date ? -1 : 1,
          ),
        })),
      deleteBodyWeight: (id) =>
        set((s) => ({ bodyWeight: s.bodyWeight.filter((e) => e.id !== id) })),
      addProgram: (program) =>
        set((s) => ({ customPrograms: [program, ...s.customPrograms] })),
      updateProgram: (program) =>
        set((s) => ({
          customPrograms: s.customPrograms.map((p) => (p.id === program.id ? program : p)),
        })),
      deleteProgram: (id) =>
        set((s) => {
          const isCustom = s.customPrograms.some((p) => p.id === id)
          return {
            customPrograms: s.customPrograms.filter((p) => p.id !== id),
            hiddenProgramIds: isCustom
              ? s.hiddenProgramIds
              : Array.from(new Set([...s.hiddenProgramIds, id])),
            activeProgramId: s.activeProgramId === id ? null : s.activeProgramId,
          }
        }),
      restorePrograms: () => set({ hiddenProgramIds: [] }),
      resetAll: () =>
        set({
          activeProgramId: null,
          logs: [],
          bodyWeight: [],
          customPrograms: [],
          hiddenProgramIds: [],
        }),
    }),
    { name: 'smellis-store-v1' },
  ),
)

/** All programs: user-created first, then the built-in library (minus hidden). */
export function useAllPrograms(): Program[] {
  const custom = useStore((s) => s.customPrograms)
  const hidden = useStore((s) => s.hiddenProgramIds)
  return [...custom, ...PROGRAMS.filter((p) => !hidden.includes(p.id))]
}

/** Look up a program by id across custom and built-in programs. */
export function useProgram(id?: string): Program | undefined {
  const custom = useStore((s) => s.customPrograms)
  if (!id) return undefined
  return custom.find((p) => p.id === id) ?? getProgram(id)
}

/** True when the program id belongs to a user-created program. */
export function useIsCustomProgram(id?: string): boolean {
  const custom = useStore((s) => s.customPrograms)
  return !!id && custom.some((p) => p.id === id)
}
