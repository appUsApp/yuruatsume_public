import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct GachaItemStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(
        sort: [SortDescriptor(\GameItem.itemId)]
    ) private var items: [GameItem]

    private struct LocationGroup: Identifiable {
        let key: String
        let displayName: String
        let iconName: String
        let items: [GameItem]

        var id: String { key }
    }

    private var groupedItems: [LocationGroup] {
        var buckets: [String: [GameItem]] = [:]

        for item in items {
            let locations = item.appearLocations
            guard !locations.isEmpty else { continue }
            for key in locations {
                buckets[key, default: []].append(item)
            }
        }

        let sortedKeys = buckets.keys.sorted { lhs, rhs in
            locationSortOrder(lhs) < locationSortOrder(rhs)
        }

        return sortedKeys.map { key in
            let grouped = buckets[key]?.sorted(by: itemSortComparator(_:_:)) ?? []
            return LocationGroup(
                key: key,
                displayName: locationDisplayName(for: key),
                iconName: locationIconName(for: key),
                items: grouped
            )
        }
    }

    private func itemSortComparator(_ lhs: GameItem, _ rhs: GameItem) -> Bool {
        let lhsCategory = displayCategory(for: lhs)
        let rhsCategory = displayCategory(for: rhs)

        if lhsCategory != rhsCategory {
            return lhsCategory < rhsCategory
        }

        return lhs.itemId < rhs.itemId
    }

    private func displayCategory(for item: GameItem) -> Int {
        item.count > 0 ? 0 : 1
    }

    private func locationSortOrder(_ key: String) -> (Int, String) {
        switch key {
        case "BeachScratch":
            return (0, "")
        case "FishAppear":
            return (1, "")
        default:
            return (2, key)
        }
    }

    private func locationDisplayName(for key: String) -> String {
        switch key {
        case "BeachScratch":
            return "浜辺"
        case "FishAppear":
            return "海辺"
        default:
            return key
        }
    }

    private func locationIconName(for key: String) -> String {
        switch key {
        case "BeachScratch":
            return "moveSand"
        case "FishAppear":
            return "moveFish"
        default:
            return "\(key)m"
        }
    }

    private func itemDisplayName(for item: GameItem) -> String {
        item.count > 0 ? item.name : "？？？"
    }

    private func silhouetteImageName(for item: GameItem) -> String? {
        let candidates = ["\(item.imageName)_s", "\(item.imageName)s", "\(item.imageName)_shadow"]
        #if canImport(UIKit)
        for name in candidates {
            if UIImage(named: name) != nil {
                return name
            }
        }
        #endif
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("bg12")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                if groupedItems.isEmpty {
                    Text("アイテムがありません")
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedItems) { group in
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 12) {
                                        Image(group.iconName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 64, height: 64)
                                            .background(
                                                Circle()
                                                    .fill(Color.white.opacity(0.2))
                                            )
                                            .clipShape(Circle())

                                        Text(group.displayName)
                                            .font(.title3.bold())
                                            .foregroundStyle(.white)
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(group.items, id: \.id) { item in
                                                VStack(spacing: 8) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(Color.white.opacity(0.25))

                                                        if item.count == 0 {
                                                            if let silhouetteName = silhouetteImageName(for: item) {
                                                                Image(silhouetteName)
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .padding(6)
                                                            } else {
                                                                Image(item.imageName)
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .padding(6)
                                                                    .saturation(0)
                                                                    .opacity(0.1)
                                                            }
                                                        } else {
                                                            Image(item.imageName)
                                                                .resizable()
                                                                .scaledToFit()
                                                                .padding(6)
                                                        }
                                                    }
                                                    .frame(width: 72, height: 72)

                                                    Text(itemDisplayName(for: item))
                                                        .font(.caption)
                                                        .foregroundStyle(Color.white.opacity(item.count == 0 ? 0.7 : 1))
                                                        .multilineTextAlignment(.center)
                                                }
                                                .frame(width: 96)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.black.opacity(0.3))
                                )
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("アイテムの隠れ場所")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("とじる") { dismiss() }
                        .foregroundStyle(Color.white)
                }
            }
        }
    }
}
