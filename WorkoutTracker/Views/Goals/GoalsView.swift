import SwiftUI
import SwiftData
import OSLog

struct GoalsView: View {
    @Environment(\.modelContext) private var ctx

    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]
    @Query(sort: \TrackableItem.createdAt) private var trackables: [TrackableItem]
    @Query(sort: \StrengthSet.createdAt, order: .reverse) private var strengthSets: [StrengthSet]
    @Query(sort: \CardioSession.createdAt, order: .reverse) private var cardioSessions: [CardioSession]
    @Query(sort: \WeightEntry.at, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \TrackableLog.loggedAt, order: .reverse) private var trackableLogs: [TrackableLog]

    @State private var showingCreateGoal = false
    @State private var editingGoal: Goal?
    @State private var errorAlert: UserFacingError?

    private var progressService: GoalProgressService {
        GoalProgressService(
            exercises: exercises,
            trackables: trackables,
            strengthSets: strengthSets,
            cardioSessions: cardioSessions,
            weightEntries: weightEntries,
            trackableLogs: trackableLogs
        )
    }

    var body: some View {
        List {
            if goals.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set your first goal")
                            .font(.headline)
                        Text("Track PRs, weight targets, and cardio milestones to keep motivation high.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            showingCreateGoal = true
                        } label: {
                            Label("Create Goal", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 12)
                }
            } else {
                Section {
                    ForEach(goals) { goal in
                        let summary = progressService.summary(for: goal)
                        let streak = progressService.streakInfo(for: goal)
                        Button {
                            editingGoal = goal
                        } label: {
                            GoalRow(
                                goal: goal,
                                contextLabel: progressService.contextLabel(for: goal),
                                summary: summary,
                                streak: streak
                            )
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(goal)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: goals.count)
        .listStyle(.insetGrouped)
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateGoal = true
                    AppLogger.goals.notice("Presenting create goal sheet")
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
                .accessibilityIdentifier("add-goal-button")
            }
        }
        .sheet(isPresented: $showingCreateGoal) {
            NavigationStack {
                GoalEditorView(mode: .create)
            }
        }
        .sheet(item: $editingGoal) { goal in
            NavigationStack {
                GoalEditorView(mode: .edit(goal))
            }
        }
        .alert(item: $errorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func delete(_ goal: Goal) {
        AppLogger.goals.notice("Deleting goal \(goal.title, privacy: .public)")
        ctx.delete(goal)
        if let error = ctx.saveOrRollback(action: "delete goal", logger: AppLogger.goals) {
            errorAlert = UserFacingError(
                title: "Unable to Delete",
                message: "We couldn't remove that goal. \(error.localizedDescription)"
            )
        }
    }
}

private struct GoalRow: View {
    let goal: Goal
    let contextLabel: String?
    let summary: GoalProgressSummary
    let streak: GoalStreakInfo?

    private var statusLabel: (text: String, color: Color, icon: String) {
        switch summary.status {
        case .achieved: return ("Achieved", .green, "checkmark.circle.fill")
        case .tracking: return ("In Progress", .blue, "target")
        case .missing: return ("Needs data", .orange, "exclamationmark.triangle.fill")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text(goal.kind.displayName)
                        Text("•")
                        Text(goal.cadence.displayName)
                        if let contextLabel {
                            Text("•")
                            Text(contextLabel)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                let status = statusLabel
                Label(status.text, systemImage: status.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.15), in: Capsule())
                    .foregroundStyle(status.color)
            }

            SummaryCard(summary.periodLabel.uppercased(), value: summary.currentDescription, footnote: summary.targetDescription)

            if let progress = summary.progressFraction {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(statusLabel.color)
            }

            if let streak {
                streakSection(for: goal, streak: streak)
            }

            if let detail = summary.detailDescription {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let note = goal.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let deadline = goal.deadline {
                let formatted = deadline.formatted(.dateTime.month(.abbreviated).day().year())
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text("Due \(formatted)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func streakSection(for goal: Goal, streak: GoalStreakInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                let currentUnit = goal.cadence.streakUnit(for: streak.currentStreak)
                Label {
                    Text("\(streak.currentStreak) \(currentUnit)")
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                }
                if streak.bestStreak > 0 {
                    let bestUnit = goal.cadence.streakUnit(for: streak.bestStreak)
                    Label {
                        Text("Best \(streak.bestStreak) \(bestUnit)")
                    } icon: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let lastMet = streak.lastMetDate {
                Text("Last achieved \(lastMet.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }
}
