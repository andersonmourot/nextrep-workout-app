import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type {
  BodyWeightEntry,
  Exercise,
  MaxRecord,
  MaxTracker,
  NutritionEntry,
  NutritionGoals,
  Program,
  Unit,
  WorkoutLog,
} from './types'
import { PROGRAMS, getProgram } from './data/programs'
import { setCustomExercises, setExerciseOverrides } from './data/exercises'
import { getCurrentUserId, getToken } from './auth'
import { apiExercisesBatch, apiGetData, apiProgramsBatch, apiPutData } from './api'
import { DEFAULT_THEME_COLOR, DEFAULT_THEME_MODE, type ThemeMode } from './lib/theme'
import { uid } from './lib/utils'

export interface SavedTimer {
  id: string
  label: string
  seconds: number
}

export interface IntervalSettings {
  emomInterval: number
  emomRounds: number
  amrapCap: number
  tabataWork: number
  tabataRest: number
  tabataRounds: number
  forTimeCap: number
}

export const DEFAULT_NUTRITION_GOALS: NutritionGoals = {
  calories: 2200,
  protein: 160,
  carbs: 220,
  fat: 70,
  water: 8,
}

export const DEFAULT_INTERVAL_SETTINGS: IntervalSettings = {
  emomInterval: 60,
  emomRounds: 10,
  amrapCap: 600,
  tabataWork: 20,
  tabataRest: 10,
  tabataRounds: 8,
  forTimeCap: 1200,
}

const DEFAULTS = {
  name: 'Athlete',
  unit: 'lb' as Unit,
  themeColor: DEFAULT_THEME_COLOR,
  themeMode: DEFAULT_THEME_MODE as ThemeMode,
  activeProgramId: null as string | null,
  logs: [] as WorkoutLog[],
  bodyWeight: [] as BodyWeightEntry[],
  customPrograms: [] as Program[],
  customExercises: [] as Exercise[],
  hiddenProgramIds: [] as string[],
  hiddenExerciseIds: [] as string[],
  exerciseOverrides: {} as Record<string, Exercise>,
  savedTimers: [] as SavedTimer[],
  timerSound: 'beep' as string,
  intervalSettings: DEFAULT_INTERVAL_SETTINGS as IntervalSettings,
  favoriteUserIds: [] as string[],
  nutritionLog: [] as NutritionEntry[],
  nutritionGoals: DEFAULT_NUTRITION_GOALS as NutritionGoals,
  maxTrackers: [] as MaxTracker[],
}

/** Max number of users that can be pinned to the top of the following list. */
export const MAX_FAVORITES = 3

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
  themeColor: string
  themeMode: ThemeMode
  activeProgramId: string | null
  logs: WorkoutLog[]
  bodyWeight: BodyWeightEntry[]
  customPrograms: Program[]
  customExercises: Exercise[]
  hiddenProgramIds: string[]
  hiddenExerciseIds: string[]
  exerciseOverrides: Record<string, Exercise>
  savedTimers: SavedTimer[]
  timerSound: string
  intervalSettings: IntervalSettings
  favoriteUserIds: string[]
  nutritionLog: NutritionEntry[]
  nutritionGoals: NutritionGoals
  maxTrackers: MaxTracker[]

  setName: (name: string) => void
  setUnit: (unit: Unit) => void
  setThemeColor: (color: string) => void
  setThemeMode: (mode: ThemeMode) => void
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
  removeCustomExercise: (id: string) => void
  deleteExercise: (id: string) => void
  setExerciseOverride: (exercise: Exercise) => void
  restoreExercise: (id: string) => void
  restoreExercises: () => void
  restorePrograms: () => void
  addSavedTimer: (timer: SavedTimer) => void
  removeSavedTimer: (id: string) => void
  setTimerSound: (sound: string) => void
  setIntervalSettings: (settings: IntervalSettings) => void
  toggleFavoriteUser: (id: string) => void
  setNutritionEntry: (entry: NutritionEntry) => void
  setNutritionGoals: (goals: NutritionGoals) => void
  addMaxRecord: (name: string, record: MaxRecord) => void
  addMaxRecordToTracker: (trackerId: string, record: MaxRecord) => void
  deleteMaxRecord: (trackerId: string, recordId: string) => void
  deleteMaxTracker: (id: string) => void
  resetAll: () => void
}

export const useStore = create<AppState>()(
  persist(
    (set) => ({
      ...DEFAULTS,

      setName: (name) => set({ name }),
      setUnit: (unit) => set({ unit }),
      setThemeColor: (themeColor) => set({ themeColor }),
      setThemeMode: (themeMode) => set({ themeMode }),
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
      removeCustomExercise: (id) =>
        set((s) => {
          const next = s.customExercises.filter((e) => e.id !== id)
          setCustomExercises(next)
          return { customExercises: next }
        }),
      deleteExercise: (id) =>
        set((s) => {
          // Custom exercises are removed outright; built-in/default exercises
          // are hidden so they can be restored later.
          const isCustom = s.customExercises.some((e) => e.id === id)
          const nextCustom = s.customExercises.filter((e) => e.id !== id)
          setCustomExercises(nextCustom)
          return {
            customExercises: nextCustom,
            hiddenExerciseIds: isCustom
              ? s.hiddenExerciseIds
              : Array.from(new Set([...s.hiddenExerciseIds, id])),
          }
        }),
      setExerciseOverride: (exercise) =>
        set((s) => {
          const next = { ...s.exerciseOverrides, [exercise.id]: exercise }
          setExerciseOverrides(next)
          return { exerciseOverrides: next }
        }),
      restoreExercise: (id) =>
        set((s) => ({ hiddenExerciseIds: s.hiddenExerciseIds.filter((x) => x !== id) })),
      restoreExercises: () => set({ hiddenExerciseIds: [] }),
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
      addSavedTimer: (timer) =>
        set((s) => ({
          // Keep the five most recent, newest first; replace the oldest as new
          // ones come in and de-duplicate by duration.
          savedTimers: [
            timer,
            ...s.savedTimers.filter((t) => t.seconds !== timer.seconds),
          ].slice(0, 5),
        })),
      removeSavedTimer: (id) =>
        set((s) => ({ savedTimers: s.savedTimers.filter((t) => t.id !== id) })),
      setTimerSound: (timerSound) => set({ timerSound }),
      setIntervalSettings: (intervalSettings) => set({ intervalSettings }),
      toggleFavoriteUser: (id) =>
        set((s) => {
          if (s.favoriteUserIds.includes(id))
            return { favoriteUserIds: s.favoriteUserIds.filter((x) => x !== id) }
          // Cap the number of pinned favorites.
          if (s.favoriteUserIds.length >= MAX_FAVORITES) return {}
          return { favoriteUserIds: [...s.favoriteUserIds, id] }
        }),
      setNutritionEntry: (entry) =>
        set((s) => ({
          nutritionLog: [
            ...s.nutritionLog.filter((e) => e.date !== entry.date),
            entry,
          ].sort((a, b) => (a.date < b.date ? -1 : 1)),
        })),
      setNutritionGoals: (nutritionGoals) => set({ nutritionGoals }),
      addMaxRecord: (name, record) =>
        set((s) => {
          const clean = name.trim()
          const existing = s.maxTrackers.find(
            (t) => t.name.toLowerCase() === clean.toLowerCase(),
          )
          if (existing) {
            return {
              maxTrackers: s.maxTrackers.map((t) =>
                t.id === existing.id ? { ...t, records: [...t.records, record] } : t,
              ),
            }
          }
          const tracker: MaxTracker = { id: uid(), name: clean, records: [record] }
          return { maxTrackers: [tracker, ...s.maxTrackers] }
        }),
      addMaxRecordToTracker: (trackerId, record) =>
        set((s) => ({
          maxTrackers: s.maxTrackers.map((t) =>
            t.id === trackerId ? { ...t, records: [...t.records, record] } : t,
          ),
        })),
      deleteMaxRecord: (trackerId, recordId) =>
        set((s) => ({
          maxTrackers: s.maxTrackers.map((t) =>
            t.id === trackerId
              ? { ...t, records: t.records.filter((r) => r.id !== recordId) }
              : t,
          ),
        })),
      deleteMaxTracker: (id) =>
        set((s) => ({ maxTrackers: s.maxTrackers.filter((t) => t.id !== id) })),
      resetAll: () => {
        setCustomExercises([])
        setExerciseOverrides({})
        set({
          activeProgramId: null,
          logs: [],
          bodyWeight: [],
          customPrograms: [],
          customExercises: [],
          hiddenProgramIds: [],
          hiddenExerciseIds: [],
          exerciseOverrides: {},
          savedTimers: [],
          timerSound: 'beep',
          intervalSettings: DEFAULT_INTERVAL_SETTINGS,
          favoriteUserIds: [],
          nutritionLog: [],
          nutritionGoals: DEFAULT_NUTRITION_GOALS,
          maxTrackers: [],
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
    themeColor: s.themeColor,
    themeMode: s.themeMode,
    activeProgramId: s.activeProgramId,
    logs: s.logs,
    bodyWeight: s.bodyWeight,
    customPrograms: s.customPrograms,
    customExercises: s.customExercises,
    hiddenProgramIds: s.hiddenProgramIds,
    hiddenExerciseIds: s.hiddenExerciseIds,
    exerciseOverrides: s.exerciseOverrides,
    savedTimers: s.savedTimers,
    timerSound: s.timerSound,
    intervalSettings: s.intervalSettings,
    favoriteUserIds: s.favoriteUserIds,
    nutritionLog: s.nutritionLog,
    nutritionGoals: s.nutritionGoals,
    maxTrackers: s.maxTrackers,
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
    setExerciseOverrides(next.exerciseOverrides ?? {})
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
  await refreshSharedExercises()
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

/**
 * Pull the newest version of every shared exercise the user has added and
 * replace local copies whose content is stale. This propagates an owner's (or
 * collaborator's) edits across all accounts that added the exercise. Each
 * account's own sharing visibility (`shared`) is preserved, so pulling an
 * update never re-publishes someone else's exercise onto your profile.
 */
export async function refreshSharedExercises(): Promise<void> {
  const token = getToken()
  if (!token) return
  const mine = useStore.getState().customExercises
  const ids = mine.filter((e) => e.ownerId && e.id).map((e) => e.id)
  if (ids.length === 0) return
  const res = await apiExercisesBatch<Exercise>(token, ids)
  if (!res.ok || !res.data) return
  const canon = new Map(res.data.exercises.map((e) => [e.id, e]))
  let changed = false
  const updated = mine.map((e) => {
    const c = canon.get(e.id)
    if (c && (c.version ?? 0) > (e.version ?? 0)) {
      changed = true
      return { ...c, shared: e.shared }
    }
    return e
  })
  if (changed) {
    setCustomExercises(updated)
    useStore.setState({ customExercises: updated })
  }
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
