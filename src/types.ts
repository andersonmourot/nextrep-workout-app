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
  /** Recommended tempo in eccentric-pause-concentric-pause notation, e.g. "3-1-1-0". */
  tempo: string
  instructions: string[]
  tips: string[]
  /** Up to two reference photos (data URLs) shown on the exercise page. */
  photos?: string[]
}

export interface PlannedExercise {
  exerciseId: string
  /** Free-text exercise name for user-typed exercises not in the built-in library. */
  name?: string
  sets: number
  /** Target rep range as a display string, e.g. "8-12". */
  reps: string
  tempo: string
  restSec: number
  notes?: string
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
  goal: string
  coach: string
  durationWeeks: number
  daysPerWeek: number
  accent: string
  summary: string
  description: string
  tags: string[]
  days: ProgramDay[]
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
  durationSec: number
  exercises: LoggedExercise[]
  totalVolume: number
  notes?: string
}

export interface BodyWeightEntry {
  id: string
  date: string // ISO (date only)
  weight: number
}

export type Unit = 'kg' | 'lb'
