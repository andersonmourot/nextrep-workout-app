import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { BodyWeightEntry, Unit, WorkoutLog } from './types'

interface AppState {
  name: string
  unit: Unit
  activeProgramId: string | null
  logs: WorkoutLog[]
  bodyWeight: BodyWeightEntry[]

  setName: (name: string) => void
  setUnit: (unit: Unit) => void
  startProgram: (id: string) => void
  clearProgram: () => void
  addLog: (log: WorkoutLog) => void
  deleteLog: (id: string) => void
  addBodyWeight: (entry: BodyWeightEntry) => void
  deleteBodyWeight: (id: string) => void
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
      resetAll: () =>
        set({ activeProgramId: null, logs: [], bodyWeight: [] }),
    }),
    { name: 'stndrd-store-v1' },
  ),
)
