import type { Exercise, Program } from '../types'
import { apiGetCatalog } from '../api'
import { setBuiltInExercises } from './exercises'
import { setBuiltInPrograms } from './programs'

/**
 * Load the built-in program/exercise catalog from the backend and apply it over
 * the bundled fallback. Run once at startup before the app renders so every
 * synchronous lookup sees the server data. Falls back silently to the bundled
 * copy if the request fails or times out, so the app is never blocked offline.
 */
export async function hydrateCatalog(timeoutMs = 2500): Promise<void> {
  const timeout = new Promise<null>((resolve) => setTimeout(() => resolve(null), timeoutMs))
  const result = await Promise.race([apiGetCatalog<Program, Exercise>(), timeout])
  if (result && result.ok && result.data) {
    setBuiltInPrograms(result.data.programs)
    setBuiltInExercises(result.data.exercises)
  }
}
