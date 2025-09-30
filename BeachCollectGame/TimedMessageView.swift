import SwiftUI

struct TimedMessageView: View {
    @Binding var message: String
    private let displayDuration: TimeInterval = 3
    @State private var show = false
    @State private var hideWorkItem: DispatchWorkItem? = nil

    var body: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(.white)
            .padding(8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .opacity(show ? 1 : 0)
            .animation(.easeInOut, value: show)
            .onChange(of: message) { _, newValue in
                handleChange(for: newValue)
            }
    }

    private func handleChange(for newValue: String) {
        guard !newValue.isEmpty else { return }
        show = true
        hideWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            withAnimation {
                show = false
                message = ""
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: workItem)
    }
}
