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
}

export interface PlannedExercise {
  exerciseId: string
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
