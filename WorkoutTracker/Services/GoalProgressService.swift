import Foundation

struct GoalProgressSummary {
    enum Status {
        case missing
        case tracking
        case achieved
    }

    let status: Status
    let periodLabel: String
    let currentDescription: String
    let targetDescription: String
    let detailDescription: String?
    let progressFraction: Double?
}

struct GoalStreakInfo {
    let periodLabel: String
    let currentDescription: String
    let targetDescription: String
    let progressFraction: Double?
    let status: GoalProgressSummary.Status
    let currentStreak: Int
    let bestStreak: Int
    let lastMetDate: Date?
}

struct GoalProgressService {
    private struct AggregateValue {
        var value: Double
        var lastEventDate: Date?
    }

    private let exercisesByID: [UUID: Exercise]
    private let trackablesByID: [UUID: TrackableItem]
    private let strengthSets: [StrengthSet]
    private let cardioSessions: [CardioSession]
    private let weightEntries: [WeightEntry]
    private let trackableLogs: [TrackableLog]

    init(
        exercises: [Exercise],
        trackables: [TrackableItem],
        strengthSets: [StrengthSet],
        cardioSessions: [CardioSession],
        weightEntries: [WeightEntry],
        trackableLogs: [TrackableLog]
    ) {
        self.exercisesByID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        self.trackablesByID = Dictionary(uniqueKeysWithValues: trackables.map { ($0.id, $0) })
        self.strengthSets = strengthSets
        self.cardioSessions = cardioSessions
        self.weightEntries = weightEntries
        self.trackableLogs = trackableLogs
    }

    func summary(for goal: Goal, referenceDate: Date = Date()) -> GoalProgressSummary {
        if goal.cadence == .oneTime {
            return overallSummary(for: goal)
        } else {
            return cadenceSummary(for: goal, referenceDate: referenceDate)
        }
    }

    func contextLabel(for goal: Goal) -> String? {
        switch goal.kind {
        case .strengthMaxReps, .strengthMaxWeight, .cardioDistance, .cardioDuration:
            if let exerciseID = goal.exerciseID, let exercise = exercisesByID[exerciseID] {
                return exercise.name
            }
            return nil
        case .custom:
            if let trackableID = goal.trackableID, let trackable = trackablesByID[trackableID] {
                return trackable.name
            }
            return nil
        case .weightTarget:
            return nil
        }
    }

    func streakInfo(for goal: Goal, referenceDate: Date = Date()) -> GoalStreakInfo? {
        guard goal.cadence != .oneTime else { return nil }

        let cadence = goal.cadence
        let aggregates = aggregates(for: goal, cadence: cadence)
        let currentPeriod = periodKey(for: referenceDate, cadence: cadence)

        let target = formattedTargetComponents(for: goal)
        let targetDescription = targetDescription(
            formattedTarget: target.value,
            unitLabel: target.unitLabel,
            direction: goal.direction,
            cadence: cadence
        )

        let currentAggregate = aggregates[currentPeriod]
        let currentStatus = evaluate(direction: goal.direction, target: goal.targetValue, current: currentAggregate?.value)
        let currentDescription = currentAggregate.map { formattedValue(for: goal, value: $0.value) } ?? "No entries yet"
        let streaks = computeStreaks(
            for: goal,
            cadence: cadence,
            aggregates: aggregates,
            through: currentPeriod
        )

        return GoalStreakInfo(
            periodLabel: cadence.periodLabel,
            currentDescription: currentDescription,
            targetDescription: targetDescription,
            progressFraction: currentStatus.progress,
            status: currentStatus.status,
            currentStreak: streaks.current,
            bestStreak: streaks.best,
            lastMetDate: streaks.lastMetDate
        )
    }

    // MARK: - Summaries

    private func overallSummary(for goal: Goal) -> GoalProgressSummary {
        let cadence: Goal.Cadence = .oneTime
        let aggregates = aggregates(for: goal, cadence: cadence)
        let target = formattedTargetComponents(for: goal)
        let targetDescription = targetDescription(
            formattedTarget: target.value,
            unitLabel: target.unitLabel,
            direction: goal.direction,
            cadence: cadence
        )

        guard let aggregate = aggregates.values.first else {
            return GoalProgressSummary(
                status: .missing,
                periodLabel: cadence.periodLabel,
                currentDescription: "No entries yet",
                targetDescription: targetDescription,
                detailDescription: nil,
                progressFraction: nil
            )
        }

        let status = evaluate(direction: goal.direction, target: goal.targetValue, current: aggregate.value)
        let detail = aggregate.lastEventDate.map { "Updated \(formatEventDate($0))" }

        return GoalProgressSummary(
            status: status.status,
            periodLabel: cadence.periodLabel,
            currentDescription: formattedValue(for: goal, value: aggregate.value),
            targetDescription: targetDescription,
            detailDescription: detail,
            progressFraction: status.progress
        )
    }

    private func cadenceSummary(for goal: Goal, referenceDate: Date) -> GoalProgressSummary {
        let cadence = goal.cadence
        let aggregates = aggregates(for: goal, cadence: cadence)
        let periodStart = periodKey(for: referenceDate, cadence: cadence)
        let target = formattedTargetComponents(for: goal)
        let targetDescription = targetDescription(
            formattedTarget: target.value,
            unitLabel: target.unitLabel,
            direction: goal.direction,
            cadence: cadence
        )

        guard let aggregate = aggregates[periodStart] else {
            return GoalProgressSummary(
                status: .missing,
                periodLabel: cadence.periodLabel,
                currentDescription: "No entries yet",
                targetDescription: targetDescription,
                detailDescription: nil,
                progressFraction: nil
            )
        }

        let status = evaluate(direction: goal.direction, target: goal.targetValue, current: aggregate.value)
        let detail = aggregate.lastEventDate.map { "Updated \(formatEventDate($0))" }

        return GoalProgressSummary(
            status: status.status,
            periodLabel: cadence.periodLabel,
            currentDescription: formattedValue(for: goal, value: aggregate.value),
            targetDescription: targetDescription,
            detailDescription: detail,
            progressFraction: status.progress
        )
    }

    // MARK: - Aggregation

    private func aggregates(for goal: Goal, cadence: Goal.Cadence) -> [Date: AggregateValue] {
        switch goal.kind {
        case .strengthMaxReps:
            guard let exerciseID = goal.exerciseID else { return [:] }
            let entries = strengthSets
                .filter { $0.exercise.id == exerciseID }
                .map { ($0.date, Double($0.reps), $0.createdAt) }
            return aggregateSum(entries, cadence: cadence)

        case .strengthMaxWeight:
            guard let exerciseID = goal.exerciseID else { return [:] }
            let entries = strengthSets
                .filter { $0.exercise.id == exerciseID && $0.weight != nil }
                .map { ($0.date, $0.weight ?? 0, $0.createdAt) }
            return aggregateMax(entries, cadence: cadence)

        case .cardioDistance:
            guard let exerciseID = goal.exerciseID else { return [:] }
            let unit = DistanceUnit(rawValue: goal.unit) ?? .mi
            let entries = cardioSessions
                .filter { $0.exercise.id == exerciseID && $0.distanceKm != nil }
                .map { session -> (Date, Double, Date) in
                    let converted = fromKilometers(session.distanceKm ?? 0, to: unit)
                    return (session.date, converted, session.createdAt)
                }
            return aggregateSum(entries, cadence: cadence)

        case .cardioDuration:
            guard let exerciseID = goal.exerciseID else { return [:] }
            let entries = cardioSessions
                .filter { $0.exercise.id == exerciseID }
                .map { session -> (Date, Double, Date) in
                    let minutes = Double(session.durationSec) / 60.0
                    return (session.date, minutes, session.createdAt)
                }
            return aggregateSum(entries, cadence: cadence)

        case .weightTarget:
            let unit = WeightUnit(rawValue: goal.unit) ?? .lb
            let entries = weightEntries
                .map { entry -> (Date, Double, Date) in
                    let converted = fromKilograms(entry.kg, to: unit)
                    return (entry.at.dayOnly, converted, entry.at)
                }
            return aggregateLatest(entries, cadence: cadence)

        case .custom:
            guard let trackableID = goal.trackableID else { return [:] }
            let entries = trackableLogs
                .compactMap { log -> (Date, Double, Date)? in
                    guard log.trackableID == trackableID, let quantity = log.quantity else { return nil }
                    return (log.loggedAt.dayOnly, quantity, log.loggedAt)
                }
            return aggregateSum(entries, cadence: cadence)
        }
    }

    private func aggregateSum(_ entries: [(Date, Double, Date)], cadence: Goal.Cadence) -> [Date: AggregateValue] {
        var result: [Date: AggregateValue] = [:]
        for (date, value, eventDate) in entries {
            let key = periodKey(for: date, cadence: cadence)
            if var aggregate = result[key] {
                aggregate.value += value
                if let current = aggregate.lastEventDate {
                    aggregate.lastEventDate = max(current, eventDate)
                } else {
                    aggregate.lastEventDate = eventDate
                }
                result[key] = aggregate
            } else {
                result[key] = AggregateValue(value: value, lastEventDate: eventDate)
            }
        }
        return result
    }

    private func aggregateMax(_ entries: [(Date, Double, Date)], cadence: Goal.Cadence) -> [Date: AggregateValue] {
        var result: [Date: AggregateValue] = [:]
        for (date, value, eventDate) in entries {
            let key = periodKey(for: date, cadence: cadence)
            if var aggregate = result[key] {
                if value > aggregate.value {
                    aggregate.value = value
                    aggregate.lastEventDate = eventDate
                    result[key] = aggregate
                } else if aggregate.lastEventDate == nil || eventDate > aggregate.lastEventDate! {
                    aggregate.lastEventDate = eventDate
                    result[key] = aggregate
                }
            } else {
                result[key] = AggregateValue(value: value, lastEventDate: eventDate)
            }
        }
        return result
    }

    private func aggregateLatest(_ entries: [(Date, Double, Date)], cadence: Goal.Cadence) -> [Date: AggregateValue] {
        var result: [Date: AggregateValue] = [:]
        for (date, value, eventDate) in entries {
            let key = periodKey(for: date, cadence: cadence)
            if var aggregate = result[key] {
                if let currentDate = aggregate.lastEventDate {
                    if eventDate > currentDate {
                        aggregate.value = value
                        aggregate.lastEventDate = eventDate
                        result[key] = aggregate
                    }
                } else {
                    aggregate.value = value
                    aggregate.lastEventDate = eventDate
                    result[key] = aggregate
                }
            } else {
                result[key] = AggregateValue(value: value, lastEventDate: eventDate)
            }
        }
        return result
    }

    // MARK: - Streak computation

    private func computeStreaks(for goal: Goal,
                                cadence: Goal.Cadence,
                                aggregates: [Date: AggregateValue],
                                through currentPeriod: Date) -> (current: Int, best: Int, lastMetDate: Date?) {
        guard let earliest = aggregates.keys.min() else {
            return (current: 0, best: 0, lastMetDate: nil)
        }

        var cursor = earliest
        var currentRun = 0
        var bestRun = 0
        var currentStreak = 0
        var lastMetDate: Date?

        while cursor <= currentPeriod {
            let aggregate = aggregates[cursor]
            let status = evaluate(direction: goal.direction, target: goal.targetValue, current: aggregate?.value).status

            if status == .achieved {
                currentRun += 1
                if let eventDate = aggregate?.lastEventDate {
                    lastMetDate = max(lastMetDate ?? eventDate, eventDate)
                } else {
                    lastMetDate = max(lastMetDate ?? cursor, cursor)
                }
            } else {
                currentRun = 0
            }

            if cursor == currentPeriod {
                currentStreak = currentRun
            }

            bestRun = max(bestRun, currentRun)
            if let next = nextPeriodStart(after: cursor, cadence: cadence) {
                cursor = next
            } else {
                break
            }
        }

        return (current: currentStreak, best: bestRun, lastMetDate: lastMetDate)
    }

    // MARK: - Helpers

    private func evaluate(direction: Goal.Direction, target: Double, current: Double?) -> (status: GoalProgressSummary.Status, progress: Double?) {
        guard let current else { return (.missing, nil) }
        switch direction {
        case .atLeast:
            if current >= target {
                return (.achieved, 1)
            }
            let denominator = target != 0 ? target : 1
            let ratio = max(min(current / denominator, 1), 0)
            return (.tracking, ratio)
        case .atMost:
            if current <= target {
                return (.achieved, 1)
            }
            guard current > 0 else { return (.tracking, 0) }
            let ratio = max(min(target / current, 1), 0)
            return (.tracking, ratio)
        }
    }

    private func formattedValue(for goal: Goal, value: Double) -> String {
        switch goal.kind {
        case .strengthMaxReps:
            return "\(Int(value)) reps"
        case .strengthMaxWeight:
            return "\(formattedDecimal(value, digits: 1)) \(weightUnitLabel(goal.unit))"
        case .cardioDistance:
            return "\(formattedDecimal(value, digits: 2)) \(distanceUnitLabel(goal.unit))"
        case .cardioDuration:
            let seconds = Int(value * 60)
            return formatDuration(seconds)
        case .weightTarget:
            return "\(formattedDecimal(value, digits: 1)) \(weightUnitLabel(goal.unit))"
        case .custom:
            if goal.unit.isEmpty {
                return formattedDecimal(value, digits: 1)
            } else {
                return "\(formattedDecimal(value, digits: 1)) \(goal.unit)"
            }
        }
    }

    private func formattedTargetComponents(for goal: Goal) -> (value: String, unitLabel: String) {
        switch goal.kind {
        case .strengthMaxReps:
            return (formattedDecimal(goal.targetValue, digits: 0), "reps")
        case .strengthMaxWeight:
            return (formattedDecimal(goal.targetValue, digits: 1), weightUnitLabel(goal.unit))
        case .cardioDistance:
            return (formattedDecimal(goal.targetValue, digits: 2), distanceUnitLabel(goal.unit))
        case .cardioDuration:
            return (formatDuration(Int(goal.targetValue * 60)), "")
        case .weightTarget:
            return (formattedDecimal(goal.targetValue, digits: 1), weightUnitLabel(goal.unit))
        case .custom:
            let unit = goal.unit
            return (formattedDecimal(goal.targetValue, digits: 1), unit.isEmpty ? "" : unit)
        }
    }

    private func targetDescription(formattedTarget: String,
                                   unitLabel: String,
                                   direction: Goal.Direction,
                                   cadence: Goal.Cadence) -> String {
        let comparator = direction == .atLeast ? "≥" : "≤"
        let targetText: String
        if unitLabel.isEmpty {
            targetText = "\(formattedTarget)"
        } else {
            targetText = "\(formattedTarget) \(unitLabel)"
        }

        if cadence == .oneTime {
            return "Target \(comparator) \(targetText)"
        } else {
            return "Target \(comparator) \(targetText) • \(cadence.periodLabel)"
        }
    }

    private func formattedDecimal(_ value: Double, digits: Int) -> String {
        formatDecimal(value, maxFractionDigits: digits)
    }

    private func weightUnitLabel(_ raw: String) -> String {
        WeightUnit(rawValue: raw)?.label ?? raw.uppercased()
    }

    private func distanceUnitLabel(_ raw: String) -> String {
        DistanceUnit(rawValue: raw)?.label ?? raw.uppercased()
    }

    private func periodKey(for date: Date, cadence: Goal.Cadence) -> Date {
        switch cadence {
        case .oneTime:
            return Date(timeIntervalSince1970: 0)
        case .daily:
            return date.dayOnly
        case .weekly:
            return date.startOfWeek
        case .monthly:
            return date.startOfMonth
        case .yearly:
            return date.startOfYear
        }
    }

    private func nextPeriodStart(after start: Date, cadence: Goal.Cadence) -> Date? {
        switch cadence {
        case .oneTime:
            return nil
        case .daily:
            return start.addingDays(1)
        case .weekly:
            return start.addingWeeks(1)
        case .monthly:
            return start.addingMonths(1)
        case .yearly:
            return start.addingYears(1)
        }
    }

    private func formatEventDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}
