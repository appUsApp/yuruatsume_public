import SwiftUI
import SwiftData

struct ItemCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [GameItem]

    var body: some View {
        NavigationStack {
            List(items) { item in
                HStack {
                    if item.discovered {
                        Image(item.imageName)
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text(item.name)
                    } else {
                        Image(systemName: "questionmark")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                        Text("????")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("図鑑")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ItemCollectionView()
}
