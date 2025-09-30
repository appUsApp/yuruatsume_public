import SwiftUI

struct SettingsMenuView: View {
    var onTerms: () -> Void
    var onPrivacy: () -> Void
    var onContact: () -> Void
    var onOperationGuide: () -> Void
    var onAccountDeletion: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var audioBinding: Binding<Bool> {
        Binding(
            get: { AudioSettings.isAudioEnabled },
            set: { AudioSettings.isAudioEnabled = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section("サポート") {
                    Button("利用規約") {
                        dismiss()
                        onTerms()
                    }
                    Button("プライバシーポリシー") {
                        dismiss()
                        onPrivacy()
                    }
                    Button("お問い合わせ") {
                        dismiss()
                        onContact()
                    }
                }

                Section("一般") {
                    Toggle("BGM/SE オン・オフ", isOn: audioBinding)
                    Button("操作ガイドを見る") {
                        dismiss()
                        onOperationGuide()
                    }
                }

                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("アカウントとデータ") {
                    Button(role: .destructive) {
                        dismiss()
                        onAccountDeletion()
                    } label: {
                        Text("アカウント削除")
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    SettingsMenuView(onTerms: {}, onPrivacy: {}, onContact: {}, onOperationGuide: {}, onAccountDeletion: {})
}
