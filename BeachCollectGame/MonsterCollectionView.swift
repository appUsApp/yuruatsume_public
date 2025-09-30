import SwiftUI
import SwiftData

struct MonsterCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var monsters: [MonsterRecord]

    var body: some View {
        NavigationStack {
            List(monsters) { monster in
                HStack {
                    if monster.isRegistered {
                        Image(monster.imageName)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .saturation(monster.isFullyRegistered ? 1 : 0)
                        Text(MonsterData.displayName(for: monster.monsterId))
                            .foregroundColor(monster.isFullyRegistered ? .primary : .gray)
                    } else {
                        Image(systemName: "questionmark")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                        Text("????")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(min(monster.count,3))/3")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("モンスター図鑑")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    MonsterCollectionView()
}
