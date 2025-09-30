import SwiftUI

struct ToolEffectTimerView: View {
    @EnvironmentObject private var missionManager: MissionManager

    private var tools: [ConsumableTool] {
        [.horasyuugou, .enmonite, .luckypearl]
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ForEach(tools, id: \.self) { tool in
                if let remain = missionManager.remainingTimeString(for: tool) {
                    HStack(spacing: 4) {
                        Image(tool.imageName)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text(remain)
                            .font(.caption2)
                            .monospacedDigit()
                    }
                    .padding(4)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .padding(8)
    }
}

#Preview {
    ToolEffectTimerView()
        .environmentObject(MissionManager())
}
