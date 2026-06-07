import type { Program, ProgramDay, WorkoutLog } from '../types'

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

/**
 * The 0-based slot index for a log within its program run, derived from its
 * explicit `week` + day position: (week - 1) * daysLen + dayLocalIdx. Returns
 * `undefined` for legacy logs that lack a `week` (or whose day no longer exists).
 */
export function logSlotIndex(program: Program, log: WorkoutLog): number | undefined {
  if (!log.week || log.week < 1) return undefined
  const daysLen = Math.max(1, program.days.length)
  const dayLocalIdx = program.days.findIndex((d) => d.id === log.dayId)
  if (dayLocalIdx < 0) return undefined
  return (log.week - 1) * daysLen + dayLocalIdx
}

/**
 * Place a program's logs into their day slots. Logs with an explicit week+day
 * land in that exact slot, so logging a later week's day before earlier days
 * keeps the data on the correct week. Legacy logs without a week fill the
 * earliest remaining slots in chronological order (back-compat). The returned
 * array is sparse — empty slots are `undefined`.
 */
export function programLogSlots(
  program: Program,
  logs: WorkoutLog[],
  since?: string,
): (WorkoutLog | undefined)[] {
  const chrono = programLogsChrono(program, logs, since)
  const slots: (WorkoutLog | undefined)[] = []
  const legacy: WorkoutLog[] = []
  for (const l of chrono) {
    const idx = logSlotIndex(program, l)
    if (idx === undefined || slots[idx] !== undefined) {
      legacy.push(l)
      continue
    }
    slots[idx] = l
  }
  let cursor = 0
  for (const l of legacy) {
    while (slots[cursor] !== undefined) cursor += 1
    slots[cursor] = l
  }
  return slots
}

export interface ProgramRun {
  /** Number of training days in one week of the program. */
  daysLen: number
  /** How many program days have been completed in this run. */
  completedCount: number
  /** Total weeks in the program (its scheduled length — never grows past it). */
  totalWeeks: number
  /** 0-based week index containing the next day to complete. */
  currentWeekIndex: number
  /** 0-based day index (within the week) that is up next. */
  nextDayIndex: number
  /** True once every scheduled day (totalWeeks × daysLen) has been logged. */
  isComplete: boolean
}

/** Progress through a program derived from its completed workout logs. */
export function programRun(
  program: Program,
  logs: WorkoutLog[],
  since?: string,
): ProgramRun {
  const daysLen = Math.max(1, program.days.length)
  const totalWeeks = Math.max(1, program.durationWeeks || 1)
  const totalDays = totalWeeks * daysLen
  // Map logs to their week+day slots so progress reflects which days are filled
  // (not just how many logs exist), and "up next" is the first unlogged day even
  // when days were logged out of order.
  const slots = programLogSlots(program, logs, since)
  let completedCount = 0
  let nextSlot = totalDays
  for (let i = 0; i < totalDays; i += 1) {
    if (slots[i]) {
      completedCount += 1
    } else if (nextSlot === totalDays) {
      nextSlot = i
    }
  }
  const isComplete = completedCount >= totalDays
  const currentWeekIndex = isComplete ? totalWeeks - 1 : Math.floor(nextSlot / daysLen)
  const nextDayIndex = isComplete ? 0 : nextSlot % daysLen
  return { daysLen, completedCount, totalWeeks, currentWeekIndex, nextDayIndex, isComplete }
}

/**
 * The plan for a program day in a given (1-based) week, applying any per-week
 * overrides. Picks the override with the largest `fromWeek` <= `week`; weeks
 * before the earliest override fall back to the base `program.days` entry.
 */
export function resolveProgramDay(
  program: Program,
  dayLocalIdx: number,
  week: number,
): ProgramDay | undefined {
  const base = program.days[dayLocalIdx]
  if (!base) return base
  const list = program.weekOverrides?.[base.id]
  if (!list || list.length === 0) return base
  let chosen: ProgramDay | undefined
  let best = 0
  for (const o of list) {
    if (o.fromWeek <= week && o.fromWeek > best) {
      best = o.fromWeek
      chosen = o.day
    }
  }
  return chosen ?? base
}

/**
 * Return a copy of `program` with `day` applied to the slot `baseDayId` from
 * `fromWeek` (1-based) onward. Editing Week 1 rewrites the base plan (all weeks
 * that lack their own override); later weeks store a per-week-onward override.
 * The stored day keeps the base id so it maps back to the same slot.
 */
export function withDayOverride(
  program: Program,
  baseDayId: string,
  fromWeek: number,
  day: ProgramDay,
): Program {
  const baseIdx = program.days.findIndex((d) => d.id === baseDayId)
  if (baseIdx < 0) return program
  const normalized: ProgramDay = { ...day, id: baseDayId }
  if (fromWeek <= 1) {
    return {
      ...program,
      days: program.days.map((d, i) => (i === baseIdx ? normalized : d)),
      version: Date.now(),
    }
  }
  const overrides = { ...(program.weekOverrides ?? {}) }
  const list = (overrides[baseDayId] ?? []).filter((o) => o.fromWeek !== fromWeek)
  list.push({ fromWeek, day: normalized })
  list.sort((a, b) => a.fromWeek - b.fromWeek)
  overrides[baseDayId] = list
  return { ...program, weekOverrides: overrides, version: Date.now() }
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

/**
 * Distinct calendar days in the current week (Mon-start) that have at least one
 * workout. Optionally scoped to a single program so the Home "days/week" ring
 * reflects the active program's progress rather than every log ever recorded.
 */
export function workoutsThisWeek(logs: WorkoutLog[], programId?: string): number {
  const start = startOfWeek().getTime()
  const days = new Set<string>()
  for (const l of logs) {
    if (programId !== undefined && l.programId !== programId) continue
    if (parseStoredDate(l.date).getTime() >= start) {
      days.add(localDateKey(parseStoredDate(l.date)))
    }
  }
  return days.size
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
