export type Muscle =
  | 'Chest'
  | 'Back'
  | 'Shoulders'
  | 'Biceps'
  | 'Triceps'
  | 'Quads'
  | 'Hamstrings'
  | 'Glutes'
  | 'Calves'
  | 'Core'
  | 'Forearms'
  | 'Full Body'

export type Equipment =
  | 'Barbell'
  | 'Dumbbell'
  | 'Machine'
  | 'Cable'
  | 'Bodyweight'
  | 'Kettlebell'
  | 'Bands'

export type Difficulty = 'Beginner' | 'Intermediate' | 'Advanced'

export type ProgramCategory =
  | 'Bodybuilding'
  | 'Strength'
  | 'HIIT'
  | 'Powerlifting'
  | 'Functional'
  | 'Bodyweight'

export interface Exercise {
  id: string
  name: string
  primaryMuscle: Muscle
  secondaryMuscles: Muscle[]
  equipment: Equipment
  difficulty: Difficulty
  instructions: string[]
  tips: string[]
  /** Up to two reference photos (data URLs) shown on the exercise page. */
  photos?: string[]
  /** When true, this custom exercise is shared on the creator's public profile. */
  shared?: boolean
  /** Display name of the creator, shown on shared exercises. */
  ownerName?: string
  /** Account id of the creator (set on shared exercises and copies others added). */
  ownerId?: string
  /** When true, anyone who added it can edit; otherwise only the creator can. */
  collaborative?: boolean
  /** Epoch-ms of the last edit; used to propagate edits to all who added it. */
  version?: number
}

export interface PlannedExercise {
  exerciseId: string
  /** Free-text exercise name for user-typed exercises not in the built-in library. */
  name?: string
  sets: number
  /** Target rep range as a display string, e.g. "8-12". */
  reps: string
  restSec: number
  notes?: string
  /**
   * Superset grouping. Consecutive exercises that share the same non-empty
   * `groupId` form a superset/triset/giant set: they're performed back-to-back
   * with no rest between, resting only after each round (the last exercise's
   * `restSec` is used as the round's rest). Undefined = a standalone exercise.
   */
  groupId?: string
}

export interface ProgramDay {
  id: string
  name: string
  focus: string
  exercises: PlannedExercise[]
}

export interface Program {
  id: string
  name: string
  category: ProgramCategory
  level: Difficulty
  goal?: string
  coach: string
  durationWeeks: number
  daysPerWeek: number
  accent: string
  summary: string
  description: string
  tags: string[]
  days: ProgramDay[]
  /**
   * Per-week-onward overrides of a day's plan, keyed by the base day's id. Each
   * entry replaces that day's plan starting at `fromWeek` (1-based) onward,
   * until a later override for the same day takes over. Weeks before the
   * earliest override use the base `days` entry. Lets a program be edited
   * independently per week (e.g. change Week 3 Day 1 without touching Weeks 1-2).
   */
  weekOverrides?: Record<string, { fromWeek: number; day: ProgramDay }[]>
  /** Id of the account that created this program (set once published/shared). */
  ownerId?: string
  /** Display name of the creator, shown on shared programs. */
  ownerName?: string
  /** When true, anyone who has added the program may edit it (edits propagate to all). */
  collaborative?: boolean
  /** Epoch-ms of the last edit; used to propagate the newest version across accounts. */
  version?: number
}

export interface SetLog {
  weight: number
  reps: number
  completed: boolean
}

/**
 * An in-progress workout session kept in the store so it stays live while the
 * user switches bottom-nav tabs (and survives a reload). Time-based fields use
 * epoch milliseconds so elapsed/rest resume correctly after remounting.
 */
export interface ActiveWorkout {
  programId: string
  dayId: string
  /** 1-based week the session belongs to, so per-week day overrides resolve. */
  week?: number
  startedAt: number // epoch ms; elapsed is derived from this
  sets: SetLog[][]
  /**
   * Exercise ids aligned 1:1 with `sets`, captured at start. Lets a live session
   * re-sync when the program/day is edited mid-workout (add/remove/reorder) while
   * preserving already-entered weights/reps and completed sets. Optional for
   * backward-compat with sessions saved before this field existed.
   */
  exerciseIds?: string[]
  restEndsAt: number | null // epoch ms when the current rest ends, or null
  restTotal: number // seconds, for the rest progress bar
}

export interface LoggedExercise {
  exerciseId: string
  sets: SetLog[]
}

export interface WorkoutLog {
  id: string
  date: string // ISO
  programId: string
  programName: string
  dayId: string
  dayName: string
  /**
   * 1-based week this log belongs to within the program run. Binds the log to a
   * specific week+day slot so logging a later week's day before earlier days
   * doesn't drop the data into an earlier week's slot. Legacy logs (created
   * before per-slot binding) omit this and fall back to chronological placement.
   */
  week?: number
  durationSec: number
  exercises: LoggedExercise[]
  totalVolume: number
  notes?: string
}

export interface BodyWeightEntry {
  id: string
  date: string // ISO (date only)
  weight: number
  createdAt?: string // full ISO timestamp of when it was logged
}

/** One day's logged nutrition totals (keyed by date). */
export interface NutritionEntry {
  date: string // ISO (date only)
  calories: number
  protein: number
  carbs: number
  fat: number
  water: number // glasses of water
  /** Up to 3 photos for the day, stored as compressed data URLs. */
  photos?: string[]
}

/** Daily nutrition targets the user is aiming for. */
export interface NutritionGoals {
  calories: number
  protein: number
  carbs: number
  fat: number
  water: number
}

/** A single dated max attempt for a tracked lift. */
export interface MaxRecord {
  id: string
  date: string // ISO (date only)
  weight: number
  reps: number
}

/** A tracked lift (one card) with its history of max attempts. */
export interface MaxTracker {
  id: string
  name: string
  records: MaxRecord[]
}

/**
 * A finished program archived in Program History. Captures a snapshot of the
 * program (its plan at completion, including per-week overrides) plus every
 * workout logged during the run, so the user can reference past programs in
 * full even after deleting or resetting the original.
 */
export interface CompletedProgram {
  /** Unique archive id (one per completed run). */
  id: string
  /** Id of the source program (may no longer exist). */
  programId: string
  name: string
  accent: string
  durationWeeks: number
  daysPerWeek: number
  /** ISO timestamp of when the final day was logged. */
  completedAt: string
  /** Snapshot of the program plan at completion. */
  program: Program
  /** The logs that make up this run, in chronological (day) order. */
  logs: WorkoutLog[]
}

/** A deleted custom program kept in Trash until it's purged (7 days). */
export interface TrashedProgram {
  program: Program
  deletedAt: number // epoch ms
}

/** A deleted custom exercise kept in Trash until it's purged (7 days). */
export interface TrashedExercise {
  exercise: Exercise
  deletedAt: number // epoch ms
}

export type Unit = 'kg' | 'lb'
