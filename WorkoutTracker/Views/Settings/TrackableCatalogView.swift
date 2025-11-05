import SwiftUI
import SwiftData

struct TrackableCatalogView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \TrackableItem.createdAt, order: .reverse) private var trackables: [TrackableItem]
    @Query(sort: \Exercise.createdAt, order: .reverse) private var exercises: [Exercise]

    var body: some View {
        List {
            ForEach(TrackableItem.Kind.allCases, id: \.self) { kind in
                let items = trackables.filter { $0.kind == kind }
                if !items.isEmpty {
                    Section(kind.displayName) {
                        ForEach(items) { trackable in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(trackable.name)
                                    .font(.headline)
                                if !trackable.defaultMuscleGroups.isEmpty {
                                    TagWrapView(tags: trackable.defaultMuscleGroups, title: "Muscles")
                                }
                                if !trackable.defaultTags.isEmpty {
                                    TagWrapView(tags: trackable.defaultTags, title: "Tags")
                                }
                                if let linkSummary = linkSummary(for: trackable) {
                                    Text(linkSummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let notes = trackable.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(trackable)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tracking Catalog")
    }

    private func delete(_ item: TrackableItem) {
        ctx.delete(item)
        let associated = exercises.filter { $0.trackableID == item.id }
        associated.forEach { ctx.delete($0) }
        _ = ctx.saveOrRollback(action: "delete trackable item", logger: AppLogger.settings)
    }

    private func linkSummary(for item: TrackableItem) -> String? {
        var components: [String] = []
        if let coingecko = item.coingeckoID { components.append("CoinGecko: \(coingecko)") }
        if let cmc = item.coinmarketcapID { components.append("CoinMarketCap: \(cmc)") }
        if let wiki = item.wikipediaURLString { components.append("Wiki: \(wiki)") }
        if let site = item.websiteURLString { components.append("Site: \(site)") }
        guard !components.isEmpty else { return nil }
        return components.joined(separator: " • ")
    }
}

private struct TagWrapView: View {
    let tags: [String]
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            WrapLayout(tags) { tag in
                Text(tag)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.gray.opacity(0.15)))
            }
        }
    }
}

private struct WrapLayout<Element: Hashable, Content: View>: View {
    let items: [Element]
    let content: (Element) -> Content

    init(_ data: some Sequence<Element>, @ViewBuilder content: @escaping (Element) -> Content) {
        self.items = Array(data)
        self.content = content
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .padding(4)
                        .alignmentGuide(.leading) { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= dimension.height
                            }
                            let result = width
                            if item == items.last { width = 0 }
                            return result
                        }
                        .alignmentGuide(.top) { dimension in
                            let result = height
                            if item == items.last { height = 0 }
                            width += dimension.width
                            return result
                        }
                }
            }
        }
        .frame(minHeight: 0)
    }
}
