import SwiftUI
import SwiftData

struct GachaMonsterStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(
        sort: [SortDescriptor(\MonsterRecord.monsterId)]
    ) private var monsterRecords: [MonsterRecord]

    private struct LocationGroup: Identifiable {
        let key: String
        let displayName: String
        let iconName: String
        let monsters: [MonsterRecord]

        var id: String { key }
    }

    private var groupedMonsters: [LocationGroup] {
        var buckets: [String: [MonsterRecord]] = [:]

        for record in monsterRecords {
            let locations = MonsterData.appearLocations(for: record.monsterId)
            guard !locations.isEmpty else { continue }
            for key in locations {
                buckets[key, default: []].append(record)
            }
        }

        let sortedKeys = buckets.keys.sorted { lhs, rhs in
            locationSortOrder(lhs) < locationSortOrder(rhs)
        }

        return sortedKeys.map { key in
            let records = buckets[key]?.sorted(by: monsterSortComparator(_:_:)) ?? []
            return LocationGroup(
                key: key,
                displayName: locationDisplayName(for: key),
                iconName: locationIconName(for: key),
                monsters: records
            )
        }
    }

    private func monsterSortComparator(_ lhs: MonsterRecord, _ rhs: MonsterRecord) -> Bool {
        let lhsCategory = monsterDisplayCategory(lhs)
        let rhsCategory = monsterDisplayCategory(rhs)

        if lhsCategory != rhsCategory {
            return lhsCategory < rhsCategory
        }

        return lhs.monsterId < rhs.monsterId
    }

    private func monsterDisplayCategory(_ record: MonsterRecord) -> Int {
        if record.obtained {
            return record.hasPage ? 1 : 0
        } else {
            return 2
        }
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

    private func monsterName(for record: MonsterRecord) -> String {
        guard record.obtained else { return "？？？" }
        return MonsterData.displayName(for: record.monsterId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("bg12")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                if groupedMonsters.isEmpty {
                    Text("まだガチャで出会ったシオノコはいません")
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedMonsters) { group in
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
                                            ForEach(group.monsters, id: \.id) { record in
                                                VStack(spacing: 8) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(Color.white.opacity(0.25))

                                                        if record.obtained {
                                                            Image(record.imageName)
                                                                .resizable()
                                                                .scaledToFit()
                                                                .padding(6)
                                                                .grayscale(record.hasPage ? 0 : 1)
                                                                .opacity(record.hasPage ? 1 : 0.6)
                                                        } else {
                                                            Text("？")
                                                                .font(.system(size: 40, weight: .bold))
                                                                .foregroundStyle(Color.white.opacity(0.8))
                                                        }
                                                    }
                                                    .frame(width: 72, height: 72)

                                                    Text(monsterName(for: record))
                                                        .font(.caption)
                                                        .foregroundStyle(Color.white.opacity(textOpacity(for: record)))
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
            .navigationTitle("シオノコの隠れ場所")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("とじる") { dismiss() }
                        .foregroundStyle(Color.white)
                }
            }
        }
    }
}

extension GachaMonsterStatusView {
    private func textOpacity(for record: MonsterRecord) -> Double {
        if record.obtained {
            return record.hasPage ? 1.0 : 0.6
        } else {
            return 0.7
        }
    }
}
