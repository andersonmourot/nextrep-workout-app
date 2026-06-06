import type { Program, WorkoutLog } from '../types'

export function cn(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(' ')
}

export function uid(): string {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4)
}

/** YYYY-MM-DD for a Date using the user's local calendar day (not UTC). */
function localDateKey(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

/**
 * Parse a stored date string into a Date. Date-only strings (YYYY-MM-DD) are
 * interpreted in the local timezone so the calendar day doesn't shift for users
 * behind UTC; full ISO timestamps are parsed as-is.
 */
function parseStoredDate(iso: string): Date {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso)
  if (m) return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]))
  return new Date(iso)
}

export function todayISO(): string {
  return localDateKey(new Date())
}

export function formatDate(iso: string): string {
  const d = parseStoredDate(iso)
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

export function formatDateLong(iso: string): string {
  const d = parseStoredDate(iso)
  return d.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

export function formatDateTime(iso: string): string {
  const d = parseStoredDate(iso)
  return d.toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

export function formatDuration(totalSec: number): string {
  const m = Math.floor(totalSec / 60)
  const s = totalSec % 60
  if (m >= 60) {
    const h = Math.floor(m / 60)
    return `${h}h ${m % 60}m`
  }
  return `${m}m ${s.toString().padStart(2, '0')}s`
}

export function formatClock(totalSec: number): string {
  const m = Math.floor(totalSec / 60)
  const s = totalSec % 60
  return `${m}:${s.toString().padStart(2, '0')}`
}

/** Pick the next day in a program based on how many workouts have been logged for it. */
export function nextDayIndex(program: Program, logs: WorkoutLog[]): number {
  const count = logs.filter((l) => l.programId === program.id).length
  return count % program.days.length
}

/**
 * Completed workouts for a program in chronological (oldest-first) order. Logs
 * are stored newest-first, so we reverse. When a reset anchor (ISO) is given,
 * only logs on/after it count toward progress (the program restarts there).
 */
export function programLogsChrono(
  program: Program,
  logs: WorkoutLog[],
  since?: string,
): WorkoutLog[] {
  return logs
    .filter((l) => l.programId === program.id && (!since || l.date >= since))
    .slice()
    .reverse()
}

export interface ProgramRun {
  /** Number of training days in one week of the program. */
  daysLen: number
  /** How many program days have been completed in this run. */
  completedCount: number
  /** Total weeks to show (program length, or further if the user kept going). */
  totalWeeks: number
  /** 0-based week index containing the next day to complete. */
  currentWeekIndex: number
  /** 0-based day index (within the week) that is up next. */
  nextDayIndex: number
}

/** Progress through a program derived from its completed workout logs. */
export function programRun(
  program: Program,
  logs: WorkoutLog[],
  since?: string,
): ProgramRun {
  const daysLen = Math.max(1, program.days.length)
  const completedCount = programLogsChrono(program, logs, since).length
  const currentWeekIndex = Math.floor(completedCount / daysLen)
  const nextDayIndex = completedCount % daysLen
  const totalWeeks = Math.max(program.durationWeeks || 1, currentWeekIndex + 1)
  return { daysLen, completedCount, totalWeeks, currentWeekIndex, nextDayIndex }
}

/** Number of consecutive days (ending today or yesterday) with at least one workout. */
export function computeStreak(logs: WorkoutLog[]): number {
  if (logs.length === 0) return 0
  const days = new Set(logs.map((l) => localDateKey(parseStoredDate(l.date))))
  let streak = 0
  const cursor = new Date()
  // Allow the streak to count even if today has no workout yet.
  if (!days.has(localDateKey(cursor))) {
    cursor.setDate(cursor.getDate() - 1)
  }
  while (days.has(localDateKey(cursor))) {
    streak += 1
    cursor.setDate(cursor.getDate() - 1)
  }
  return streak
}

export function startOfWeek(d = new Date()): Date {
  const date = new Date(d)
  const day = (date.getDay() + 6) % 7 // Monday = 0
  date.setHours(0, 0, 0, 0)
  date.setDate(date.getDate() - day)
  return date
}

export function workoutsThisWeek(logs: WorkoutLog[]): number {
  const start = startOfWeek().getTime()
  return logs.filter((l) => new Date(l.date).getTime() >= start).length
}

export function totalVolume(logs: WorkoutLog[]): number {
  return logs.reduce((sum, l) => sum + l.totalVolume, 0)
}

/**
 * Human-readable time left before a trashed item (deleted at `deletedAt` epoch
 * ms) is purged for good, given a total retention window in ms.
 */
export function trashTimeLeft(deletedAt: number, ttlMs: number): string {
  const remaining = deletedAt + ttlMs - Date.now()
  if (remaining <= 0) return 'Deleting soon'
  // Round up so an item deleted moments ago reads "7 days left", not "6".
  const days = Math.ceil(remaining / (24 * 60 * 60 * 1000))
  return `${days} day${days === 1 ? '' : 's'} left`
}

export function greeting(): string {
  const h = new Date().getHours()
  if (h < 12) return 'Good morning'
  if (h < 18) return 'Good afternoon'
  return 'Good evening'
}
