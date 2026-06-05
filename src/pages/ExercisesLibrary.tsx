import { ExercisesPage } from './Exercises'

/**
 * Standalone Exercises page reached from the Programs screen. It reuses the main
 * Exercises page so the two stay in sync, adding a Back link to Programs.
 */
export function ExercisesLibrary() {
  return <ExercisesPage showBack />
}
