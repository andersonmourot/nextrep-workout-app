import Foundation

struct ProgramRun {
    let week: Int
    let dayIndex: Int
    let daysLength: Int
    let completedSlots: Int
    let totalSlots: Int
    let isComplete: Bool
}

struct SupersetGroup {
    let groupId: String?
    let label: String
    let indices: [Int]

    var isSuperset: Bool {
        indices.count > 1
    }
}

func domainParseStoredDate(_ value: String) -> Date {
    if let date = ISO8601DateFormatter().date(from: value) {
        return date
    }

    if let date = DomainDateFormatter.fractionalInternet.date(from: value) {
        return date
    }

    if let date = DomainDateFormatter.dateOnly.date(from: value) {
        return date
    }

    return .distantPast
}

func domainResolveProgramDay(_ program: Program, dayIndex: Int, week: Int) -> ProgramDay? {
    guard program.days.indices.contains(dayIndex) else {
        return nil
    }

    let baseDay = program.days[dayIndex]
    guard let overrides = program.weekOverrides?[baseDay.id], !overrides.isEmpty else {
        return baseDay
    }

    return overrides
        .filter { $0.fromWeek <= max(1, week) }
        .sorted { $0.fromWeek > $1.fromWeek }
        .first?
        .day ?? baseDay
}

func domainLogSlotIndex(program: Program, log: WorkoutLog) -> Int? {
    guard let week = log.week, week >= 1 else {
        return nil
    }

    let daysLength = max(1, program.days.count)
    guard let dayIndex = program.days.firstIndex(where: { $0.id == log.dayId }) else {
        return nil
    }

    return (week - 1) * daysLength + dayIndex
}

func domainProgramLogsChrono(program: Program, logs: [WorkoutLog], since: String? = nil) -> [WorkoutLog] {
    logs
        .filter { log in
            guard log.programId == program.id else { return false }
            guard let since else { return true }
            return domainParseStoredDate(log.date) >= domainParseStoredDate(since)
        }
        .sorted { domainParseStoredDate($0.date) < domainParseStoredDate($1.date) }
}

func domainProgramLogSlots(program: Program, logs: [WorkoutLog], since: String? = nil) -> [WorkoutLog?] {
    let chrono = domainProgramLogsChrono(program: program, logs: logs, since: since)
    var slots: [WorkoutLog?] = []
    var legacy: [WorkoutLog] = []

    for log in chrono {
        guard let index = domainLogSlotIndex(program: program, log: log), slots.indices.contains(index) == false || slots[index] == nil else {
            legacy.append(log)
            continue
        }

        while slots.count <= index {
            slots.append(nil)
        }
        slots[index] = log
    }

    for log in legacy {
        if let emptyIndex = slots.firstIndex(where: { $0 == nil }) {
            slots[emptyIndex] = log
        } else {
            slots.append(log)
        }
    }

    return slots
}

func domainProgramRun(program: Program, logs: [WorkoutLog], since: String? = nil) -> ProgramRun {
    let daysLength = max(1, program.days.count)
    let totalSlots = max(1, program.durationWeeks) * daysLength
    let slots = domainProgramLogSlots(program: program, logs: logs, since: since)
    let completed = min(totalSlots, slots.prefix(totalSlots).filter { $0 != nil }.count)

    if completed >= totalSlots {
        return ProgramRun(
            week: max(1, program.durationWeeks),
            dayIndex: daysLength - 1,
            daysLength: daysLength,
            completedSlots: completed,
            totalSlots: totalSlots,
            isComplete: true
        )
    }

    let nextIndex = nextEmptySlot(slots: slots, totalSlots: totalSlots)
    return ProgramRun(
        week: (nextIndex / daysLength) + 1,
        dayIndex: nextIndex % daysLength,
        daysLength: daysLength,
        completedSlots: completed,
        totalSlots: totalSlots,
        isComplete: false
    )
}

func domainComputeStreak(logs: [WorkoutLog]) -> Int {
    guard !logs.isEmpty else {
        return 0
    }

    let days = Set(logs.map { domainLocalDayKey(domainParseStoredDate($0.date)) })
    var cursor = Calendar.current.startOfDay(for: Date())
    if !days.contains(domainLocalDayKey(cursor)) {
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }

    var streak = 0
    while days.contains(domainLocalDayKey(cursor)) {
        streak += 1
        cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
    }

    return streak
}

func domainWorkoutsThisWeek(logs: [WorkoutLog], programId: String? = nil, since: String? = nil) -> Int {
    let anchor = since.map { domainParseStoredDate($0) } ?? .distantPast
    let cutoff = max(domainStartOfWeek(), anchor)

    let days = logs.compactMap { log -> String? in
        if let programId, log.programId != programId {
            return nil
        }

        let date = domainParseStoredDate(log.date)
        guard date >= cutoff else {
            return nil
        }

        return domainLocalDayKey(date)
    }

    return Set(days).count
}

func domainTotalVolume(_ logs: [WorkoutLog]) -> Double {
    logs.reduce(0) { total, log in
        total + log.totalVolume
    }
}

func domainPreviousWeekWeights(
    program: Program,
    logs: [WorkoutLog],
    since: String? = nil,
    globalIndex: Int
) -> [String: [Double]] {
    let daysLength = max(1, program.days.count)
    let previousIndex = globalIndex - daysLength
    guard previousIndex >= 0 else {
        return [:]
    }

    let slots = domainProgramLogSlots(program: program, logs: logs, since: since)
    guard slots.indices.contains(previousIndex), let log = slots[previousIndex] else {
        return [:]
    }

    var output: [String: [Double]] = [:]
    for exercise in log.exercises {
        output[exercise.exerciseId] = exercise.sets.map(\.weight)
    }
    return output
}

func domainSupersetGroups(_ exercises: [PlannedExercise]) -> [SupersetGroup] {
    var groups: [SupersetGroup] = []
    var index = 0
    var labelIndex = 0

    while index < exercises.count {
        let groupId = exercises[index].groupId?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let groupId, !groupId.isEmpty else {
            groups.append(SupersetGroup(groupId: nil, label: "\(index + 1)", indices: [index]))
            index += 1
            continue
        }

        var indices = [index]
        var cursor = index + 1
        while cursor < exercises.count, exercises[cursor].groupId == groupId {
            indices.append(cursor)
            cursor += 1
        }

        labelIndex += 1
        groups.append(SupersetGroup(groupId: groupId, label: supersetLabel(labelIndex), indices: indices))
        index = cursor
    }

    return groups
}

private func nextEmptySlot(slots: [WorkoutLog?], totalSlots: Int) -> Int {
    for index in 0..<totalSlots {
        if !slots.indices.contains(index) || slots[index] == nil {
            return index
        }
    }
    return max(0, totalSlots - 1)
}

private func domainStartOfWeek(_ date: Date = Date()) -> Date {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)
    let daysFromMonday = (weekday + 5) % 7
    let startOfDay = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
}

private func domainLocalDayKey(_ date: Date) -> String {
    DomainDateFormatter.dateOnly.string(from: date)
}

private func supersetLabel(_ index: Int) -> String {
    let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    guard index > 0 else { return "A" }
    return String(letters[(index - 1) % letters.count])
}

private enum DomainDateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let fractionalInternet: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
