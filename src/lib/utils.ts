import type { Program, WorkoutLog } from '../types'

export function cn(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(' ')
}

export function uid(): string {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4)
}

export function todayISO(): string {
  return new Date().toISOString().slice(0, 10)
}

export function formatDate(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

export function formatDateLong(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
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

/** Number of consecutive days (ending today or yesterday) with at least one workout. */
export function computeStreak(logs: WorkoutLog[]): number {
  if (logs.length === 0) return 0
  const days = new Set(logs.map((l) => l.date.slice(0, 10)))
  let streak = 0
  const cursor = new Date()
  // Allow the streak to count even if today has no workout yet.
  if (!days.has(cursor.toISOString().slice(0, 10))) {
    cursor.setDate(cursor.getDate() - 1)
  }
  while (days.has(cursor.toISOString().slice(0, 10))) {
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

export function greeting(): string {
  const h = new Date().getHours()
  if (h < 12) return 'Good morning'
  if (h < 18) return 'Good afternoon'
  return 'Good evening'
}
