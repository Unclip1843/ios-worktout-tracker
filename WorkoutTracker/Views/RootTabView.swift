import SwiftUI

struct RootTabView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case track, prs, goals, analyze, journal

        var id: String { rawValue }

        var title: String {
            switch self {
            case .track: return "Track"
            case .prs: return "PRs"
            case .goals: return "Goals"
            case .analyze: return "Analyze"
            case .journal: return "Journal"
            }
        }

        var systemImage: String {
            switch self {
            case .track: return "list.bullet"
            case .prs: return "trophy"
            case .goals: return "target"
            case .analyze: return "chart.line.uptrend.xyaxis"
            case .journal: return "book"
            }
        }
    }

    @State private var selection: Tab = .track

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selection {
                case .track:
                    NavigationStack { TrackView() }
                case .prs:
                    NavigationStack { PRsView() }
                case .goals:
                    NavigationStack { GoalsView() }
                case .analyze:
                    NavigationStack { AnalyzeView() }
                case .journal:
                    NavigationStack { JournalView() }
                }
            }
            Divider()
            HStack {
                ForEach(Tab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 18, weight: .medium))
                            Text(tab.title)
                                .font(.caption2)
                        }
                        .foregroundStyle(selection == tab ? Color.accentColor : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selection == tab ? Color.accentColor.opacity(0.12) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
