import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type { BodyWeightEntry, Program, Unit, WorkoutLog } from './types'
import { PROGRAMS, getProgram } from './data/programs'
import { getCurrentUserId } from './auth'

const DEFAULTS = {
  name: 'Athlete',
  unit: 'lb' as Unit,
  activeProgramId: null as string | null,
  logs: [] as WorkoutLog[],
  bodyWeight: [] as BodyWeightEntry[],
  customPrograms: [] as Program[],
  hiddenProgramIds: [] as string[],
}

/** Resolve the per-user storage key so each account keeps isolated data. */
function dataKey(fallback: string): string {
  const id = getCurrentUserId()
  return id ? `smellis-data-${id}` : fallback
}

const perUserStorage = createJSONStorage(() => ({
  getItem: (name: string) => localStorage.getItem(dataKey(name)),
  setItem: (name: string, value: string) => localStorage.setItem(dataKey(name), value),
  removeItem: (name: string) => localStorage.removeItem(dataKey(name)),
}))

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
      ...DEFAULTS,

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
    { name: 'smellis-store-v1', storage: perUserStorage, skipHydration: true },
  ),
)

/** Load the current user's saved data into the store (defaults if none). */
export async function loadCurrentUserData(): Promise<void> {
  const id = getCurrentUserId()
  const key = id ? `smellis-data-${id}` : 'smellis-store-v1'
  let next: typeof DEFAULTS = { ...DEFAULTS }
  try {
    const raw = localStorage.getItem(key)
    if (raw) {
      const parsed = JSON.parse(raw)
      const state = (parsed?.state ?? parsed) as Partial<typeof DEFAULTS>
      next = { ...DEFAULTS, ...state }
    }
  } catch {
    next = { ...DEFAULTS }
  }
  useStore.setState(next)
}

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
