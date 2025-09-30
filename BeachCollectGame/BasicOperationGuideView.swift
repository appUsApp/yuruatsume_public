import SwiftUI

struct BasicOperationGuideView: View {
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("あそびかた")
                    .font(.title2)
                    .bold()

                VStack(alignment: .leading, spacing: 24) {
                    OperationGuideSection(imageName: "ope1",
                                           systemImage: "1.circle.fill",
                                           text: "砂浜を指でなぞってアイテムを見つけよう！")

                    OperationGuideSection(imageName: "ope2",
                                           systemImage: "2.circle.fill",
                                           text: "アイテムはもっていないとギャラリーに登録、もっているとお金に変わるよ！")

                    OperationGuideSection(imageName: "ope3",
                                           systemImage: "3.circle.fill",
                                           text: "時間が流れると、登場するアイテムや流れているBGMが変わるんだ。")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onClose) {
                    Text("はじめる")
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

private struct GuideRow: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.orange)
            Text(text)
                .font(.body)
        }
    }
}

private struct OperationGuideSection: View {
    let imageName: String
    let systemImage: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            GuideRow(systemImage: systemImage, text: text)
        }
    }
}

#Preview {
    BasicOperationGuideView(onClose: {})
}
