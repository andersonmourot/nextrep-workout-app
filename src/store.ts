import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type { BodyWeightEntry, Exercise, Program, Unit, WorkoutLog } from './types'
import { PROGRAMS, getProgram } from './data/programs'
import { setCustomExercises } from './data/exercises'
import { getCurrentUserId, getToken } from './auth'
import { apiGetData, apiProgramsBatch, apiPutData } from './api'

const DEFAULTS = {
  name: 'Athlete',
  unit: 'lb' as Unit,
  activeProgramId: null as string | null,
  logs: [] as WorkoutLog[],
  bodyWeight: [] as BodyWeightEntry[],
  customPrograms: [] as Program[],
  customExercises: [] as Exercise[],
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
  customExercises: Exercise[]
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
  addCustomExercise: (exercise: Exercise) => void
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
      addCustomExercise: (exercise) =>
        set((s) => {
          const next = [exercise, ...s.customExercises.filter((e) => e.id !== exercise.id)]
          setCustomExercises(next)
          return { customExercises: next }
        }),
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
      resetAll: () => {
        setCustomExercises([])
        set({
          activeProgramId: null,
          logs: [],
          bodyWeight: [],
          customPrograms: [],
          customExercises: [],
          hiddenProgramIds: [],
        })
      },
    }),
    { name: 'smellis-store-v1', storage: perUserStorage, skipHydration: true },
  ),
)

/** The persisted slice of state that syncs to the server (no actions). */
function snapshot(s: AppState): typeof DEFAULTS {
  return {
    name: s.name,
    unit: s.unit,
    activeProgramId: s.activeProgramId,
    logs: s.logs,
    bodyWeight: s.bodyWeight,
    customPrograms: s.customPrograms,
    customExercises: s.customExercises,
    hiddenProgramIds: s.hiddenProgramIds,
  }
}

// Guard so applying server/cache data doesn't immediately push it back up.
let applyingRemote = false
let syncTimer: ReturnType<typeof setTimeout> | undefined

/** Debounced push of the current state to the backend (when logged in). */
useStore.subscribe((state) => {
  if (applyingRemote) return
  const token = getToken()
  if (!token) return
  if (syncTimer) clearTimeout(syncTimer)
  syncTimer = setTimeout(() => {
    void apiPutData(token, snapshot(state))
  }, 600)
})

function applyState(next: typeof DEFAULTS): void {
  applyingRemote = true
  try {
    useStore.setState(next)
    setCustomExercises(next.customExercises ?? [])
  } finally {
    applyingRemote = false
  }
}

/** Load the current user's locally-cached data into the store (defaults if none). */
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
  applyState(next)
}

/** Pull authoritative data from the server and hydrate the store. */
export async function syncFromServer(): Promise<void> {
  const token = getToken()
  if (!token) return
  const res = await apiGetData<Partial<typeof DEFAULTS>>(token)
  if (res.ok && res.data) {
    applyState({ ...DEFAULTS, ...res.data })
  }
  await refreshSharedPrograms()
}

/**
 * Pull the newest version of every shared program the user has added and
 * replace local copies whose content is stale. This is what propagates an
 * owner's (or collaborator's) edits across all accounts. Logged history lives
 * in separate `logs` records, so updating a program never erases past data —
 * only future workouts use the new version.
 */
export async function refreshSharedPrograms(): Promise<void> {
  const token = getToken()
  if (!token) return
  const mine = useStore.getState().customPrograms
  const ids = mine.filter((p) => p.ownerId && p.id).map((p) => p.id)
  if (ids.length === 0) return
  const res = await apiProgramsBatch<Program>(token, ids)
  if (!res.ok || !res.data) return
  const canon = new Map(res.data.programs.map((p) => [p.id, p]))
  let changed = false
  const updated = mine.map((p) => {
    const c = canon.get(p.id)
    if (c && (c.version ?? 0) > (p.version ?? 0)) {
      changed = true
      return { ...c }
    }
    return p
  })
  if (changed) useStore.setState({ customPrograms: updated })
}

/** Reset the in-memory store to defaults (used on logout). */
export function clearStore(): void {
  applyState({ ...DEFAULTS })
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
