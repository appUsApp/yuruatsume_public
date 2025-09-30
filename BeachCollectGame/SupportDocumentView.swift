import SwiftUI
import UIKit

struct SupportDocumentView: View {
    let document: MainGameView.SupportDocument
    @Environment(\.dismiss) private var dismiss
    @State private var showCopyConfirmation = false

    private var fullText: String {
        document.paragraphs.joined(separator: "\n\n")
    }

    private var paragraphItems: [ParagraphItem] {
        document.paragraphs.enumerated().map { ParagraphItem(id: $0.offset, text: $0.element) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(paragraphItems) { paragraph in
                        Text(paragraph.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = fullText
                        showCopyConfirmation = true
                    } label: {
                        Label("コピー", systemImage: "doc.on.doc")
                    }
                }
            }
            .alert("コピーしました", isPresented: $showCopyConfirmation) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

#Preview {
    SupportDocumentView(document: .terms)
}

private struct ParagraphItem: Identifiable {
    let id: Int
    let text: String
}
