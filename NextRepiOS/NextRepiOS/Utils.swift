import Foundation
import SwiftUI

// MARK: - Utility Functions

func uid() -> String {
    return String(format: "%08x%04x", arc4random(), arc4random())
}

/** YYYY-MM-DD for a Date using the user's local calendar day (not UTC). */
func localDateKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
}

/**
 * Parse a stored date string into a Date. Date-only strings (YYYY-MM-DD) are
 * interpreted in the local timezone so the calendar day doesn't shift for users
 * behind UTC. Full datetime strings that carry no timezone designator are
 * treated as UTC (server timestamps are UTC), so the time of day renders
 * correctly in the viewer's local zone instead of being read as local.
 */
func parseStoredDate(_ iso: String) -> Date {
    let formatter = DateFormatter()
    
    // Check if it's a date-only string (YYYY-MM-DD)
    if iso.count == 10 && iso.contains("-") {
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: iso) ?? Date()
    }
    
    // A "T"-separated datetime with no trailing Z/±HH:MM offset → assume UTC
    if iso.contains("T") && !iso.contains("Z") && !iso.contains("+") {
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: iso) ?? Date()
    }
    
    // Default parsing
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter.date(from: iso) ?? Date()
}

func todayISO() -> String {
    return localDateKey(Date())
}

func formatDate(_ iso: String) -> String {
    let date = parseStoredDate(iso)
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

func formatClock(totalSec: Int) -> String {
    let m = totalSec / 60
    let s = totalSec % 60
    return String(format: "%d:%02d", m, s)
}

func greeting() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 12 {
        return "Good morning"
    } else if hour < 18 {
        return "Good afternoon"
    } else {
        return "Good evening"
    }
}

// MARK: - Program Run State

struct ProgramRun {
    let daysLen: Int
    let completedCount: Int
    let totalWeeks: Int
    let currentWeekIndex: Int
    let nextDayIndex: Int
    let isComplete: Bool
}

/** Progress through a program derived from its completed workout logs. */
func programRun(program: Program, logs: [WorkoutLog], since: String? = nil) -> ProgramRun {
    let daysLen = max(1, program.days.count)
    let totalWeeks = max(1, program.durationWeeks)
    let totalDays = totalWeeks * daysLen
    
    // Map logs to their week+day slots so progress reflects which days are filled
    let slots = programLogSlots(program: program, logs: logs, since: since)
    
    var completedCount = 0
    var nextSlot = totalDays
    
    for i in 0..<totalDays {
        if slots[i] != nil {
            completedCount += 1
        } else if nextSlot == totalDays {
            nextSlot = i
        }
    }
    
    let isComplete = completedCount >= totalDays
    let currentWeekIndex = isComplete ? totalWeeks - 1 : nextSlot / daysLen
    let nextDayIndex = isComplete ? 0 : nextSlot % daysLen
    
    return ProgramRun(
        daysLen: daysLen,
        completedCount: completedCount,
        totalWeeks: totalWeeks,
        currentWeekIndex: currentWeekIndex,
        nextDayIndex: nextDayIndex,
        isComplete: isComplete
    )
}

/**
 * The 0-based slot index for a log within its program run, derived from its
 * explicit `week` + day position: (week - 1) * daysLen + dayLocalIdx. Returns
 * `nil` for legacy logs that lack a `week` (or whose day no longer exists).
 */
func logSlotIndex(program: Program, log: WorkoutLog) -> Int? {
    guard let week = log.week, week > 0 else { return nil }
    let daysLen = max(1, program.days.count)
    let dayLocalIdx = program.days.firstIndex { $0.id == log.dayId }
    guard let idx = dayLocalIdx else { return nil }
    return (week - 1) * daysLen + idx
}

/**
 * Place a program's logs into their day slots. Logs with an explicit week+day
 * land in that exact slot, so logging a later week's day before earlier days
 * keeps the data on the correct week. Legacy logs without a week fill the
 * earliest remaining slots in chronological order (back-compat). The returned
 * array is sparse — empty slots are `nil`.
 */
func programLogSlots(program: Program, logs: [WorkoutLog], since: String? = nil) -> [WorkoutLog?] {
    let chrono = programLogsChrono(program: program, logs: logs, since: since)
    var slots: [WorkoutLog?] = []
    var legacy: [WorkoutLog] = []
    
    for log in chrono {
        if let idx = logSlotIndex(program: program, log: log), slots.indices.contains(idx) {
            if slots[idx] == nil {
                slots[idx] = log
            } else {
                legacy.append(log)
            }
        } else {
            legacy.append(log)
        }
    }
    
    var cursor = 0
    for log in legacy {
        while cursor < slots.count && slots[cursor] != nil {
            cursor += 1
        }
        if cursor < slots.count {
            slots[cursor] = log
        } else {
            slots.append(log)
        }
        cursor += 1
    }
    
    // Fill remaining slots with nil
    while slots.count < (program.durationWeeks * program.days.count) {
        slots.append(nil)
    }
    
    return slots
}

/**
 * Completed workouts for a program in chronological (oldest-first) order. Logs
 * are stored newest-first, so we reverse. When a reset anchor (ISO) is given,
 * only logs on/after it count toward progress (the program restarts there).
 */
func programLogsChrono(program: Program, logs: [WorkoutLog], since: String? = nil) -> [WorkoutLog] {
    return logs
        .filter { $0.programId == program.id && (since == nil || $0.date >= since!) }
        .sorted { $0.date < $1.date }
}

/**
 * The plan for a program day in a given (1-based) week, applying any per-week
 * overrides. Picks the override with the largest `fromWeek` <= `week`; weeks
 * before the earliest override fall back to the base `program.days` entry.
 */
func resolveProgramDay(program: Program, dayLocalIdx: Int, week: Int) -> ProgramDay? {
    guard dayLocalIdx < program.days.count else { return nil }
    let base = program.days[dayLocalIdx]
    
    guard let overrideList = program.weekOverrides?[base.id], !overrideList.isEmpty else {
        return base
    }
    
    var chosen: ProgramDay?
    var best = 0
    
    for override in overrideList {
        if override.fromWeek <= week && override.fromWeek > best {
            best = override.fromWeek
            chosen = override.day
        }
    }
    
    return chosen ?? base
}

/** Number of consecutive days (ending today or yesterday) with at least one workout. */
func computeStreak(logs: [WorkoutLog]) -> Int {
    if logs.isEmpty { return 0 }
    
    let days = Set(logs.map { localDateKey(parseStoredDate($0.date)) })
    var streak = 0
    var cursor = Date()
    
    // Allow the streak to count even if today has no workout yet
    if !days.contains(localDateKey(cursor)) {
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }
    
    while days.contains(localDateKey(cursor)) {
        streak += 1
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }
    
    return streak
}

func startOfWeek(_ date: Date = Date()) -> Date {
    var calendar = Calendar.current
    calendar.firstWeekday = 2 // Monday = 1
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return calendar.date(from: components) ?? date
}

/**
 * Distinct calendar days in the current week (Mon-start) that have at least one
 * workout. Optionally scoped to a single program so the Home "days/week" ring
 * reflects the active program's progress rather than every log ever recorded.
 */
func workoutsThisWeek(logs: [WorkoutLog], programId: String? = nil, since: String? = nil) -> Int {
    let anchor = since != nil ? parseStoredDate(since!).timeIntervalSince1970 : 0
    let cutoff = max(startOfWeek().timeIntervalSince1970, anchor)
    
    var days = Set<String>()
    
    for log in logs {
        if let pid = programId, log.programId != pid {
            continue
        }
        
        let t = parseStoredDate(log.date).timeIntervalSince1970
        if t >= cutoff {
            days.insert(localDateKey(parseStoredDate(log.date)))
        }
    }
    
    return days.count
}

func exerciseLabel(for exercise: PlannedExercise, customName: String? = nil) -> String {
    return customName ?? exercise.name ?? "Exercise"
}

func supersetGroups(exercises: [PlannedExercise]) -> [(groupId: String?, indices: [Int], isSuperset: Bool, label: String?)] {
    var groups: [(groupId: String?, indices: [Int], isSuperset: Bool, label: String?)] = []
    
    for (i, exercise) in exercises.enumerated() {
        let gid = exercise.groupId
        let last = groups.last
        
        if let gid = gid, let last = last, last.groupId == gid {
            groups[groups.count - 1].indices.append(i)
        } else {
            groups.append((groupId: gid, indices: [i], isSuperset: false, label: nil))
        }
    }
    
    var letter = 0
    for i in 0..<groups.count {
        groups[i].isSuperset = groups[i].groupId != nil && groups[i].indices.count > 1
        if groups[i].isSuperset {
            groups[i].label = String(UnicodeScalar(65 + letter)!)
            letter += 1
        }
    }
    
    return groups
}

/**
 * Compute total volume across all workout logs.
 */
func totalVolume(logs: [WorkoutLog]) -> Double {
    return logs.reduce(0) { $0 + $1.totalVolume }
}

/**
 * Convert a hex color string to a SwiftUI Color.
 */
func hexToColor(_ hex: String) -> Color {
    let hexSanitized = hex.replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    
    Scanner(string: hexSanitized).scanHexInt64(&rgb)
    
    let r = Double((rgb & 0xFF0000) >> 16) / 255
    let g = Double((rgb & 0x00FF00) >> 8) / 255
    let b = Double(rgb & 0x0000FF) / 255
    
    return Color(red: r, green: g, blue: b)
}

/**
 * Format time in seconds to MM:SS format.
 */
func formatTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
}

/**
 * Format a date string to a short date format.
 */
func formatShortDate(_ dateString: String) -> String {
    let date = parseStoredDate(dateString)
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
}