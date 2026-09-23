import { describe, it, expect } from 'vitest'
import type { Program, ProgramDay, WorkoutLog, LoggedExercise } from '../types'
import {
  programLogSlots,
  previousWeekWeights,
  programRun,
  resolveProgramDay,
  withDayOverride,
  supersetGroups,
  lastInGroupIndices,
  computeStreak,
  workoutsThisWeek,
  formatDuration,
  formatClock,
  nextDayIndex,
  trashTimeLeft,
} from './utils'

// ---------- fixtures ----------

const day1: ProgramDay = {
  id: 'd1',
  name: 'Push',
  focus: 'Chest',
  exercises: [
    { exerciseId: 'bench', sets: 4, reps: '6-10', restSec: 150 },
    { exerciseId: 'ohp', sets: 3, reps: '8-12', restSec: 120 },
  ],
}
const day2: ProgramDay = {
  id: 'd2',
  name: 'Pull',
  focus: 'Back',
  exercises: [{ exerciseId: 'row', sets: 4, reps: '8-10', restSec: 120 }],
}

const program: Program = {
  id: 'prog',
  name: 'Test',
  category: 'Strength',
  level: 'Beginner',
  coach: 'c',
  durationWeeks: 2,
  daysPerWeek: 2,
  accent: '#fff',
  summary: '',
  description: '',
  days: [day1, day2],
}

function log(dayId: string, week: number | undefined, opts: Partial<WorkoutLog> = {}): WorkoutLog {
  const day = program.days.find((d) => d.id === dayId)!
  const exercises: LoggedExercise[] = day.exercises.map((pe) => ({
    exerciseId: pe.exerciseId,
    sets: [{ weight: 100, reps: 8, completed: true }],
  }))
  return {
    id: `log-${dayId}-w${week ?? 'x'}-${Math.random()}`,
    date: '2026-01-05T10:00:00Z',
    programId: program.id,
    programName: program.name,
    dayId,
    dayName: day.name,
    week,
    durationSec: 60,
    exercises,
    totalVolume: 800,
    ...opts,
  }
}

// ---------- tests ----------

describe('programLogSlots', () => {
  it('places week+day logs in their exact slots', () => {
    const logs = [log('d2', 2), log('d1', 1), log('d1', 2)]
    const slots = programLogSlots(program, logs)
    // 2 days/week × 2 weeks = 4 slots: [d1w1, d2w1, d1w2, d2w2]
    expect(slots[0]?.dayId).toBe('d1')
    expect(slots[1]).toBeUndefined()
    expect(slots[2]?.dayId).toBe('d1')
    expect(slots[3]?.dayId).toBe('d2')
  })

  it('drops logs before a reset anchor', () => {
    const old = log('d1', 1, { date: '2026-01-01T10:00:00Z' })
    const fresh = log('d1', 1, { date: '2026-02-01T10:00:00Z' })
    const slots = programLogSlots(program, [old, fresh], '2026-01-15T00:00:00Z')
    expect(slots.filter(Boolean)).toHaveLength(1)
    expect(slots[0]?.id).toBe(fresh.id)
  })

  it('legacy logs without week fill earliest slots in chronological order', () => {
    const a = log('d1', undefined, { date: '2026-01-01T10:00:00Z' })
    const b = log('d2', undefined, { date: '2026-01-03T10:00:00Z' })
    const slots = programLogSlots(program, [a, b])
    expect(slots[0]?.id).toBe(a.id)
    expect(slots[1]?.id).toBe(b.id)
  })

  it('legacy logs fill around explicit week-bound slots', () => {
    const explicit = log('d2', 1, { date: '2026-01-03T10:00:00Z' }) // slot 1
    const legacy = log('d1', undefined, { date: '2026-01-04T10:00:00Z' })
    const slots = programLogSlots(program, [explicit, legacy])
    expect(slots[1]?.id).toBe(explicit.id)
    expect(slots[0]?.id).toBe(legacy.id) // earliest free slot
  })
})

describe('previousWeekWeights', () => {
  it('returns empty for week 1', () => {
    expect(previousWeekWeights(program, [], undefined, 0).size).toBe(0)
  })

  it('carries per-set weights from the previous week same slot', () => {
    const w1 = log('d1', 1, {
      exercises: [
        { exerciseId: 'bench', sets: [{ weight: 185, reps: 6, completed: true }, { weight: 190, reps: 6, completed: true }] },
        { exerciseId: 'ohp', sets: [{ weight: 95, reps: 10, completed: true }] },
      ],
    })
    const map = previousWeekWeights(program, [w1], undefined, 2) // w2 d1 = global slot 2
    expect(map.get('bench')).toEqual([185, 190])
    expect(map.get('ohp')).toEqual([95])
  })

  it('returns empty when the prior week slot was never logged', () => {
    expect(previousWeekWeights(program, [], undefined, 2).size).toBe(0)
  })
})

describe('programRun', () => {
  it('reports up-next day and completion', () => {
    expect(programRun(program, [])).toMatchObject({
      completedCount: 0, nextDayIndex: 0, currentWeekIndex: 0, isComplete: false,
    })
    const partial = programRun(program, [log('d1', 1)])
    expect(partial.nextDayIndex).toBe(1)
    expect(partial.completedCount).toBe(1)
    const done = programRun(program, [
      log('d1', 1), log('d2', 1), log('d1', 2), log('d2', 2),
    ])
    expect(done.isComplete).toBe(true)
    expect(done.completedCount).toBe(4)
  })

  it('out-of-order logging still picks the first unlogged day', () => {
    const run = programRun(program, [log('d2', 1)]) // logged day 2 first
    expect(run.nextDayIndex).toBe(0)
    expect(run.completedCount).toBe(1)
  })
})

describe('resolveProgramDay / withDayOverride', () => {
  it('returns the base day without overrides', () => {
    expect(resolveProgramDay(program, 0, 3)?.name).toBe('Push')
  })

  it('applies the latest override at or before the week', () => {
    const w2day = { ...day1, name: 'Push (heavy)' }
    const w3day = { ...day1, name: 'Push (peak)' }
    let p = withDayOverride(program, 'd1', 2, w2day)
    p = withDayOverride(p, 'd1', 3, w3day)
    expect(resolveProgramDay(p, 0, 1)?.name).toBe('Push')
    expect(resolveProgramDay(p, 0, 2)?.name).toBe('Push (heavy)')
    expect(resolveProgramDay(p, 0, 3)?.name).toBe('Push (peak)')
    expect(resolveProgramDay(p, 0, 5)?.name).toBe('Push (peak)')
  })

  it('week-1 edits rewrite the base day', () => {
    const edited = { ...day1, name: 'Push v2' }
    const p = withDayOverride(program, 'd1', 1, edited)
    expect(p.days[0].name).toBe('Push v2')
    expect(p.weekOverrides).toBeUndefined()
  })
})

describe('supersetGroups', () => {
  it('groups consecutive same-groupId exercises and letters them', () => {
    const groups = supersetGroups([
      { exerciseId: 'a' },
      { exerciseId: 'b', groupId: 'g1' },
      { exerciseId: 'c', groupId: 'g1' },
      { exerciseId: 'd', groupId: 'g2' },
      { exerciseId: 'e', groupId: 'g2' },
      { exerciseId: 'f' },
    ] as never)
    expect(groups.map((g) => g.indices)).toEqual([[0], [1, 2], [3, 4], [5]])
    expect(groups[1].isSuperset).toBe(true)
    expect(groups[1].label).toBe('A')
    expect(groups[2].label).toBe('B')
    expect(groups[0].isSuperset).toBe(false)
  })

  it('non-consecutive same groupId does not merge', () => {
    const groups = supersetGroups([
      { exerciseId: 'a', groupId: 'g' },
      { exerciseId: 'b' },
      { exerciseId: 'c', groupId: 'g' },
    ] as never)
    expect(groups).toHaveLength(3)
    expect(groups.every((g) => !g.isSuperset)).toBe(true)
  })

  it('lastInGroupIndices marks only round-end exercises for rest', () => {
    const last = lastInGroupIndices([
      { exerciseId: 'a' },
      { exerciseId: 'b', groupId: 'g1' },
      { exerciseId: 'c', groupId: 'g1' },
      { exerciseId: 'd' },
    ] as never)
    expect([...last].sort()).toEqual([0, 2, 3])
  })
})

describe('computeStreak', () => {
  it('counts consecutive days ending today or yesterday', () => {
    const today = new Date()
    const yesterday = new Date(today)
    yesterday.setDate(today.getDate() - 1)
    const iso = (d: Date) => d.toISOString()
    expect(computeStreak([])).toBe(0)
    expect(computeStreak([log('d1', 1, { date: iso(today) })])).toBe(1)
    expect(
      computeStreak([
        log('d1', 1, { date: iso(today) }),
        log('d1', 1, { date: iso(yesterday) }),
      ]),
    ).toBe(2)
    // Gap: streak ends at the missed day.
    const threeBack = new Date(today)
    threeBack.setDate(today.getDate() - 3)
    expect(
      computeStreak([
        log('d1', 1, { date: iso(today) }),
        log('d1', 1, { date: iso(threeBack) }),
      ]),
    ).toBe(1)
  })
})

describe('formatting', () => {
  it('formatDuration', () => {
    expect(formatDuration(65)).toBe('1m 05s')
    expect(formatDuration(3660)).toBe('1h 1m')
    expect(formatDuration(0)).toBe('0m 00s')
  })
  it('formatClock', () => {
    expect(formatClock(95)).toBe('1:35')
    expect(formatClock(0)).toBe('0:00')
  })
  it('trashTimeLeft rounds up', () => {
    const now = Date.now()
    expect(trashTimeLeft(now - 1000, 7 * 86400000)).toBe('7 days left')
    expect(trashTimeLeft(now - 8 * 86400000, 7 * 86400000)).toBe('Deleting soon')
  })
})

describe('nextDayIndex / workoutsThisWeek', () => {
  it('rotates days by log count', () => {
    expect(nextDayIndex(program, [])).toBe(0)
    expect(nextDayIndex(program, [log('d1', 1)])).toBe(1)
    expect(nextDayIndex(program, [log('d1', 1), log('d2', 1)])).toBe(0)
  })

  it('workoutsThisWeek counts distinct days only, scoped to program', () => {
    const today = new Date().toISOString()
    const twoToday = [log('d1', 1, { date: today }), log('d2', 1, { date: today })]
    expect(workoutsThisWeek(twoToday)).toBe(1)
    expect(workoutsThisWeek(twoToday, 'other-program')).toBe(0)
  })
})
