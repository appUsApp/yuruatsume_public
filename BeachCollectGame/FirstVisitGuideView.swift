import SwiftUI

struct FirstVisitGuideView: View {
    let title: String
    let messages: [String]
    var onClose: () -> Void

    private let messageImageMap: [String: String] = [
        "海ではタップで発見！": "ope4",
        "左上のシルエットはまだ見つけていないアイテムが表示されている。": "ope5",
        "ガチャでシオノコを当てて、ビーチに出そう！": "ope6",
        "ツールやマイギャラリー素材、新マップなどを購入できる!": "ope7",
        "『いいね』ポイントでアイテムを解放しよう！": "ope8",
        "冒険の役に立つツールを使えるよ！": "ope9",
        "いろんな場所に遊びに行ける!": "ope10",
        "集めたアイテムやシオノコを確認できるギャラリー！": "ope11",
        "ここは他のプレイヤーが設定したギャラリーの世界": "ope12"
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(title)
                    .font(.title3)
                    .bold()

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(messages.indices, id: \.self) { index in
                        GuideMessageRow(text: messages[index],
                                        imageName: messageImageMap[messages[index]])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onClose) {
                    Text("わかった！")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .frame(maxWidth: 420)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(radius: 12)
            .padding()
        }
    }
}

private struct GuideMessageRow: View {
    let text: String
    let imageName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(alignment: .top, spacing: 12) {
                Image("c98")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                Text(text)
                    .font(.body)
            }
        }
    }
}

#Preview {
    FirstVisitGuideView(title: "テスト", messages: ["メッセージ1", "メッセージ2"]) {}
}
