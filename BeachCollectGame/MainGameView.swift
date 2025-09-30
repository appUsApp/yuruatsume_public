import SwiftUI
import AVFoundation
import SwiftData

struct MainGameView: View {
    enum Screen { case beachScratch, fishAppear, gacha }

    enum SupportDocument: Identifiable {
        case terms
        case privacy
        case contact

        var id: String { title }

        var title: String {
            switch self {
            case .terms:
                return "利用規約"
            case .privacy:
                return "プライバシーポリシー"
            case .contact:
                return "サポート"
            }
        }

        var paragraphs: [String] {
            switch self {
            case .terms:
                return [
                    "ゆるあつめ 利用規約",
                    "制定：2025年9月28日",
                    "最終改定：2025年9月28日",
                    "運営者：磯田 慎之助（個人）",
                    "お問い合わせ：shinnosuke.171717@gmail.com",
                    "――",
                    "第1条（定義）",
                    "1) 「アプリ」：当社が提供する「ゆるあつめ」。",
                    "2) 「ユーザーコンテンツ」：名称・プロフィール・ギャラリー配置・スクショ・コメント等、ユーザーが生成/送信/保存/公開する一切の情報。",
                    "3) 「有償通貨」：App Store 決済で取得する通貨（例：泡沫結晶）。",
                    "4) 「無償通貨」：プレイや報酬で取得する通貨（例：ゴールド、フレンドポイント等）。",
                    "5) 「アイテム」：仮想的な道具・キャラクター・素材・機能解放等。",
                    "6) 「サブスクリプション」：所定期間ごとに自動更新される定期購入（導入時）。",
                    "――",
                    "第2条（適用・変更）",
                    "本規約は本サービスの一切の利用に適用します。重要な変更はアプリ内表示等で周知し、変更後の利用により同意したものとみなします。",
                    "――",
                    "第3条（未成年の利用）",
                    "未成年者は保護者（法定代理人）の同意を得た上で利用してください。有償コンテンツの購入も同様です。",
                    "――",
                    "第4条（アカウント・引継ぎ）",
                    "一部機能はログイン（匿名ログイン含む）を要する場合があります。",
                    "端末紛失/初期化/アプリ削除でデータ喪失の恐れあり。提供時は案内に従いアカウント連携（例：Sign in with Apple）を設定してください。",
                    "アカウントの譲渡・売買・貸与は禁止します。",
                    "――",
                    "第5条（有料コンテンツ・課金）",
                    "購入は Apple の決済/規約に従います。法令で認められる場合を除き、購入確定後のキャンセル/返金は原則不可。",
                    "デジタルコンテンツにクーリング・オフは適用されません。",
                    "サブスク導入時は App Store で自動更新の停止/管理が可能。期間途中解約でも既払期間分の返金は行いません。",
                    "消耗型 IAP（例：泡沫結晶）は Apple の「購入の復元」の対象外です。",
                    "――",
                    "第6条（通貨・アイテムの性質）",
                    "有償/無償通貨・アイテムは本サービス内でのみ使用可。現金等価物との交換/払戻しは不可（法令で義務付けられる場合を除く）。",
                    "有効期間・上限・提供条件・提供割合（ガチャ等）はアプリ内で掲示する場合があります。",
                    "不正取得が疑われる場合、当社は無効化やアカウント措置を行うことがあります。",
                    "――",
                    "第7条（広告・測定・第三者サービス）",
                    "本サービスに広告枠を設ける場合があります。報酬型広告の視聴条件/付与内容はアプリ内表示に従います。",
                    "品質向上・不正対策・機能提供のため、Firebase/AdMob 等の第三者サービスを利用する場合があります。詳細はプライバシーポリシー参照。",
                    "――",
                    "第8条（ユーザーコンテンツ）",
                    "ユーザーは自己責任で投稿し、第三者の権利を侵害しないことを保証します。",
                    "当社は、本サービス提供・告知・不具合調査等の目的で、ユーザーコンテンツを無償/非独占的に必要最小限の範囲で利用（複製/表示/改変）できます。",
                    "法令/規約違反または運営上の必要がある場合、公開範囲変更・削除等を行うことがあります。",
                    "ギャラリー公開を選択した場合、内容は他ユーザーから閲覧可能となります。",
                    "――",
                    "第9条（禁止事項）",
                    "法令/公序良俗/本規約に違反する行為。",
                    "権利侵害（著作権/商標/プライバシー等）。",
                    "不正アクセス、チート、Bot・マクロ、リバースエンジニアリング（法令許容範囲除く）、通信改変、脆弱性悪用。",
                    "アカウント/通貨/アイテム等の売買・譲渡・貸与。",
                    "過度な連続通信/スパム等によりサーバーや他者に負荷・支障を与える行為。",
                    "児童・差別・自傷・違法薬物等の不適切表現、わいせつ/暴力的表現の投稿/表示。",
                    "許可なき営利・宣伝行為。",
                    "その他、当社が不適切と合理的に判断する行為。",
                    "――",
                    "第10条（知的財産権）",
                    "アプリ内の画像・音楽・プログラム・データ等の知的財産権は当社または正当な権利者に帰属します。利用は本サービスの範囲内に限ります。",
                    "――",
                    "第11条（サービスの提供・変更・中断・終了）",
                    "システム保守・混雑対策・天災・通信障害・法令対応等がある場合、予告なく全部/一部を変更・中断・終了できます。",
                    "サービス終了時の有償通貨の取扱いは資金決済法等の法令に従う場合があります。",
                    "――",
                    "第12条（免責）",
                    "当社は特定目的適合性・恒常的提供・正確性/完全性/安全性等を保証しません。",
                    "通信/端末/OSやアプリのバージョン差等に起因する不具合/損害について、当社の故意・重過失を除き責任を負いません。",
                    "消費者契約法等で免責が制限される場合は当該法令に従います。",
                    "――",
                    "第13条（損害賠償の範囲・上限）",
                    "当社の責任は、当社の故意・重過失を除き、過去6か月間にユーザーが本サービスに現実に支払った金額を上限とします（法令により無効/制限される場合を除く）。",
                    "――",
                    "第14条（反社会的勢力の排除）",
                    "ユーザーは反社会的勢力に該当せず関係しないことを表明/保証します。違反時は直ちに利用停止等を行うことがあります。",
                    "――",
                    "第15条（個人情報の取扱い）",
                    "個人情報はプライバシーポリシーに従い適切に取り扱います。アプリ内「設定＞プライバシーポリシー」またはサポートページ記載URLから閲覧可。",
                    "――",
                    "第16条（データの保存・エクスポート・アカウント削除）",
                    "運営上必要な範囲でデータの保存/削除/匿名化を行う場合があります。",
                    "エクスポート機能提供時はアプリ内案内に従ってください。未提供時はお問い合わせください。",
                    "「設定＞アカウント＞アカウント削除」（提供時）から削除可能。削除後は復元不可。法令上必要な情報は所定期間保存する場合があります。",
                    "――",
                    "第17条（権利義務の譲渡禁止）",
                    "当社の事前書面承諾なく、本規約上の地位/権利義務の全部または一部を第三者に譲渡/移転/担保提供できません。",
                    "――",
                    "第18条（通知方法）",
                    "当社からの通知は、アプリ内表示、ウェブ掲示、メールその他当社が適切と判断する方法で行います。",
                    "――",
                    "第19条（分離可能性）",
                    "条項の一部が無効/執行不能でも、その他の条項は引き続き有効に存続します。",
                    "――",
                    "第20条（準拠法・裁判管轄）",
                    "本規約は日本法に準拠します。紛争は東京地方裁判所を第一審の専属的合意管轄とします。",
                    "――",
                    "第21条（優先関係）",
                    "App Store 等のプラットフォーム規約と本規約が矛盾する場合、矛盾する範囲でプラットフォーム規約が優先します。",
                    "――",
                    "お問い合わせ窓口",
                    "運営者：磯田 慎之助",
                    "メール：shinnosuke.171717@gmail.com",

                ]
            case .privacy:
                return [
                    "プライバシーポリシー（ゆるあつめ）",
                    "最終改定日：2025年9月28日",
                    "事業者名：磯田 慎之助（個人）",
                    "所在地（任意）：北海道",
                    "お問い合わせ：shinnosuke.171717@gmail.com",
                    "――",
                    "■ 本ポリシーについて",
                    "本ポリシーはアプリ『ゆるあつめ』におけるユーザー情報の取扱いを定めるものです（日本法および各ストア規約を遵守）。",
                    "――",
                    "■ 1. 取得する情報",
                    "アカウント・識別子：FirebaseユーザーID（匿名ログイン含む）／端末識別情報（IDFV等）／広告識別子（IDFA：OS許可時のみ）。",
                    "ゲーム内データ：所持アイテム・通貨・達成状況・設定、フレンド情報（公開名・フレンドID・いいね/訪問履歴）、ギャラリー公開設定等。",
                    "購入・課金情報：App内課金の購入状況（Appleによる決済確認の範囲）。",
                    "利用状況・ログ：機能提供に伴うイベント・操作履歴、エラーログ等（Crashlytics等の専用SDKは現時点で未導入）。",
                    "お問い合わせ情報：連絡用メールアドレス、問い合わせ内容等。",
                    "取得しない主な情報：正確な位置情報・連絡先・健康情報・生体認証・写真/マイク（明示許可がない限り取得しません）。",
                    "――",
                    "■ 2. 利用目的",
                    "アプリ提供・維持・改善（進行管理、同期、機能開発、不具合対応）。",
                    "アカウント管理（ログイン、不正・チート防止）。",
                    "フレンド/ギャラリー機能の提供（閲覧・交流）。",
                    "App内課金の処理・サポート。",
                    "広告配信（報酬型広告含む）・効果測定・不正対策。",
                    "お問い合わせ対応、重要なお知らせの通知、法令遵守・紛争対応。",
                    "――",
                    "■ 3. 外部送信・第三者提供・委託",
                    "Google（Firebase Authentication/Firestore/Functions/Storage等）：ユーザーID・セーブデータ等を保存/同期（国外サーバーに保管される場合あり）。",
                    "Google（AdMob）：広告関連データ・端末情報・IP（短期）・アプリイベントを利用（配信/最適化/効果測定/不正対策/報酬広告）。",
                    "Apple（App Store/IAP）：購入トランザクション情報（決済処理・購入検証）。",
                    "第三者提供：法令等に基づく場合・生命/財産保護・委託先への提供を除き、本人同意なく第三者提供しません。",
                    "（参考）Crashlyticsは現時点で未導入、導入時は本ポリシーを更新します。",
                    "――",
                    "■ 4. 追跡・広告（IDFA）",
                    "本アプリはAdMobを利用しますが、初期状態ではATT（トラッキング許可）を求めておらずIDFAは利用しません（非パーソナライズ広告）。",
                    "将来パーソナライズ広告を行う場合はATTで許可を取得し、許可時に限りIDFAを利用します。",
                    "EEA等では初回起動時に広告同意（UMP）を表示する場合があります。",
                    "同意の変更/撤回はアプリ内設定（提供時）またはOS設定から可能です。",
                    "――",
                    "■ 5. データの保存期間",
                    "ゲーム内データ：アカウント削除まで（バックアップ保持期間を含む場合あり）。",
                    "ログ等：必要最小限の期間（目安6〜18か月）保管後、統計化・匿名化または削除。",
                    "お問い合わせ情報：対応完了後、法令・紛争対応上必要な期間を除き適切に削除。",
                    "――",
                    "■ 6. 安全管理措置",
                    "アクセス制御・権限管理・通信暗号化・ログ監査等により、漏えい/滅失/毀損防止に努めます。",
                    "――",
                    "■ 7. 海外保管・移転",
                    "業務委託先のサーバー等により国外で保管/処理される場合がありますが、適用法令および本ポリシーに従い保護措置を講じます。",
                    "――",
                    "■ 8. 未成年の利用",
                    "13歳未満の方は保護者の同意の上でご利用ください。保護者からの依頼に基づき情報の削除等を行う場合があります。",
                    "――",
                    "■ 9. ユーザーの権利",
                    "開示・訂正・利用停止・削除の請求／広告・追跡設定の変更（アプリ内/OS設定）。手続き時に本人確認をお願いする場合があります。",
                    "――",
                    "■ 10. アカウント削除とデータの消去",
                    "アプリ内「設定 ＞ アカウント削除」から削除可能です。削除後は復元できません（バックアップ保持期間があっても復元対応なし）。操作不可時はお問い合わせください。",
                    "――",
                    "■ 11. データのエクスポート・引き継ぎ",
                    "エクスポートをご希望の場合はお問い合わせください（技術的に可能な範囲で対応）。匿名ログインのみの場合は復元不可のことがあります。確実な引き継ぎには連携機能の利用を推奨します。",
                    "――",
                    "■ 12. アプリストア表示（要約）",
                    "追跡に使用されるデータ：現時点ではなし（将来ATT許可取得時はIDFAを追跡目的で利用する可能性あり）。",
                    "ユーザーに関連付けられる可能性のあるデータ：識別子（ユーザーID）、購入、広告関連の使用状況（AdMob）。",
                    "診断：Crashlytics等を導入した場合に更新します。",
                    "――",
                    "■ 13. ポリシーの変更",
                    "必要に応じて改定し、重要な変更はアプリ内のお知らせ等で周知します。表示時点から効力を生じます。",
                    "――",
                    "■ 14. お問い合わせ窓口",
                    "メール：shinnosuke.171717@gmail.com／事業者名：磯田 慎之助",

                ]
            case .contact:
                return [
                    "ゆるあつめ｜サポートページ",
                    "最終更新：2025年9月28日",
                    "ようこそ「ゆるあつめ」サポートページへ。遊び方・不具合・課金・データ関連で困ったらまずこちらをご確認ください。解決しない場合はお問い合わせから個別にサポートします。",
                    "――",
                    "■ お問い合わせ方法",
                    "アプリ内：アプリを起動 → [設定] ＞ [お問い合わせ] → フォーム送信（発生手順・時刻・スクショ/録画があると助かります）。",
                    "起動できない場合：端末名（例：iPhone 15 Pro）・iOSバージョン・状況・発生手順を明記してメールでご連絡ください。",
                    "メール宛先：shinnosuke.171717@gmail.com",
                    "――",
                    "■ よくある質問（FAQ）",
                    "1) 課金（泡沫結晶）が反映されない",
                    "・端末を再起動 → 安定した通信で再起動 → [設定] ＞ [購入の復元/同期] を実行。",
                    "・改善しなければ、購入日時・Apple IDの一部（@より前は不要）・領収書の注文番号を添えてご連絡ください（返金はAppleの審査に準じます）。",
                    "2) 広告が再生できない／リワード未付与",
                    "・通信状態を確認し、アプリ再起動後に再試行。広告在庫不足や短時間の連続再生制限がある場合があります。",
                    "・未付与時は、発生時刻・広告種別（報酬/インタースティシャル等）・残スタミナ/残ポイントを添えてご連絡ください。",
                    "3) データの引き継ぎ（機種変更）",
                    "[設定] ＞ [アカウント連携（例：Sign in with Apple）] を有効にすると、連携アカウントで引き継げます。匿名のみの場合は復元できないことがあります。",
                    "4) データのエクスポート（控えの取得）",
                    "[設定] ＞ [データのエクスポート] から閲覧/ダウンロード。機能が見当たらない・エラー時はお問い合わせください。",
                    "5) アカウント削除（個人情報の削除）",
                    "[設定] ＞ [プライバシー] ＞ [アカウント削除] から申請可能。削除後は進行・特典・フレンド情報など復元不可（法令等により最小限の記録を一定期間保持する場合あり）。",
                    "6) 通知が届かない／音が出ない",
                    "iOS設定 → 通知 ＞ ゆるあつめ を許可、iOSのサウンド設定とアプリ内 [設定] ＞ [サウンド/通知] を確認してください。",
                    "7) 動作が重い／落ちる",
                    "端末の空き容量（1〜2GB以上推奨）確保、バックグラウンド終了、OS/アプリを最新に。改善しなければ発生画面・手順・時刻（JST）を添えてご連絡ください。",
                    "8) スタミナ・ボーナス・時間帯",
                    "アプリ内ヘルプ/「？」で仕様を確認。表示差異がある場合は時刻（JST）と見た画面を記載してください。目安：回復スロットは 4:00 / 10:00 / 16:00 / 22:00（JST）。",
                    "9) 推奨環境",
                    "対応OSや必要容量はApp Store製品ページをご確認ください。最新版でのご利用を推奨します。",
                    "――",
                    "■ 不具合報告の際にあると助かる情報",
                    "端末名／iOSバージョン、アプリのバージョン（[設定]＞[アプリ情報]）、発生日時（JST）・画面名、再現手順（1→2→3…）、スクショ/画面録画、課金の場合は購入日時と注文番号。",
                    "――",
                    "■ 法的情報",
                    "プライバシーポリシー：アプリ内 [設定] ＞ [プライバシーポリシー]。",
                    "利用規約：アプリ内 [設定] ＞ [利用規約]。",
                    "デジタル商品の性質上、購入後のキャンセルは原則不可。返金可否はAppleのポリシーに準じます。",
                    "――",
                    "■ セーフプレイのお願い・保護者の方へ",
                    "未成年の方は「アプリ内課金」「利用時間」について保護者とルールを相談のうえご利用ください（iOSのスクリーンタイム活用推奨）。",
                    "――",
                    "■ 運営からのお知らせ",
                    "メンテナンスや大きな変更はアプリ内お知らせやストア記載で案内します。ご不明点は [設定] ＞ [お問い合わせ] からどうぞ。",

                ]
            }
        }
    }

    private let accountDeletionService = AccountDeletionService()

    @State private var screen: Screen = .beachScratch
    @State private var showCollection = false
    @State private var showMission = false
    @State private var showShop = false
    @State private var showBag = false
    @State private var showMyGallery = false
    @State private var showMapSelect = false
    @State private var showFriendHub = false
    @State private var showGachaMonsters = false
    @State private var showGachaItems = false
    @State private var showSettings = false
    @State private var supportDocument: SupportDocument? = nil
    @EnvironmentObject private var missionManager: MissionManager
    @EnvironmentObject private var galleryBadge: GalleryBadgeManager
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject private var listeners = FirestoreListeners()
    @State private var audioPlayer: AVAudioPlayer? = nil
    @Environment(\.modelContext) private var context
    @State private var missionsLoaded = false
    @Query(filter: #Predicate<GameItem> { $0.count > 0 }) private var ownedItems: [GameItem]
    @Query(filter: #Predicate<MonsterRecord> { $0.obtained }) private var ownedMonsters: [MonsterRecord]
    @State private var accessMessage = ""
    @AppStorage("MainGameView.hasSeenBasicOperationGuide") private var hasSeenBasicOperationGuide = false
    @State private var showBasicOperationGuide = false
    @State private var showOfflineAlert = false
    @State private var popupMessage: String? = nil
    @State private var showAccountDeletionConfirm = false
    @State private var isDeletingAccount = false

    private var canAccessGallery: Bool {
        meetsGalleryAccessRequirement(items: ownedItems, monsters: ownedMonsters)
    }

    private func playPageMoveSound() {
        guard let path = Bundle.main.path(forResource: "pageMove", ofType: "caf"),
              let player = AudioCache.shared.player(forPath: path) else {
            return
        }
        audioPlayer = player
        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    private func showSupportMessage(_ message: String) {
        popupMessage = message
    }

    private func performAccountDeletion() async {
        if await MainActor.run(body: { isDeletingAccount }) { return }
        guard let uid = await MainActor.run(body: { authService.uid }) else {
            await MainActor.run {
                showSupportMessage("アカウント情報が見つかりませんでした。再度お試しください。")
            }
            return
        }

        await MainActor.run { isDeletingAccount = true }
        do {
            try await accountDeletionService.deleteAccount(uid: uid, context: context)
            await MainActor.run {
                listeners.stopAll()
                missionManager.resetForAccountDeletion()
                galleryBadge.resetBadge()
                popupMessage = nil
                hasSeenBasicOperationGuide = false
                showBasicOperationGuide = false
                showSupportMessage("アカウントを削除しました。新しいデータで再開します。")
                authService.uid = nil
            }
            authService.signInAnonymouslyIfNeeded()
        } catch {
            await MainActor.run {
                showSupportMessage("アカウントの削除に失敗しました。通信環境を確認して再度お試しください。")
            }
            print("Account deletion failed:", error)
        }
        await MainActor.run { isDeletingAccount = false }
    }

    var body: some View {
        ZStack {
            // ① ゲーム画面 (背景) をフルスクリーン表示
            Group {
                switch screen {
                case .beachScratch:
                    BeachScratchView()
                        .transition(.move(edge: .bottom))
                case .fishAppear:
                    FishAppearView()
                        .transition(.move(edge: .top))
                case .gacha:
                    GachaView { withAnimation { screen = .beachScratch } }
                        .transition(.move(edge: .trailing))
                }
            }
            .ignoresSafeArea()
        }
        // ② 上部・プレイヤー情報と各種ボタン
        .safeAreaInset(edge: .top) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    PlayerStatusView()
                    if screen != .gacha {
                        HintStripView(
                            appearLocation: screen == .fishAppear ? "FishAppear" : "BeachScratch",
                            message: $accessMessage,
                            popupMessage: $popupMessage
                        )
                    }
                }
                Spacer()
                if screen != .gacha {
                    VStack(alignment: .trailing, spacing: 20) {
                        GalleryNavigationButton {
                            playPageMoveSound()
                            showCollection = true
                        }
                        .environmentObject(galleryBadge)

                        GachaItemNavigationButton {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            showGachaItems = true
                        }

                        GachaMonsterNavigationButton {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            showGachaMonsters = true
                        }

                        Button {
                            withAnimation(.spring()) {
                                screen = .gacha
                            }
                        } label: {
                            Image("Gacham")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )
                        .clipShape(Circle())
                        .shadow(radius: 2)

                    Button {
                        SoundEffect.play("pageMove", player: &audioPlayer)
                        showMission = true
                        } label: {
                            Image("MissionIcon")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)
                        .overlay(alignment: .topTrailing) {
                            if missionManager.hasUnclaimedRewards {
                                Circle()
                                    .fill(Color.indigo)
                                    .frame(width: 12, height: 12)
                                    .offset(x: -3, y: 2)
                            }
                        }

                        Button {
                            showShop = true
                        } label: {
                            Image("ShopIcon")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)

                        Button {
                            SoundEffect.play("open", player: &audioPlayer)
                            showBag = true
                        } label: {
                            Image("BagIcon")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)

                        Button {
                            if canAccessGallery {
                                playPageMoveSound()
                                showMyGallery = true
                            } else {
                                accessMessage = "「各レア度(1~4)のアイテム入手」＋「シオノコ4体とガチャで出会う」で開放されます"
                            }
                        } label: {
                            Image("e01_0%")
                                .resizable()
                                .scaledToFit()
                                .opacity(canAccessGallery ? 0.8 : 0.2)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)

                        Button {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            showFriendHub = true
                        } label: {
                            Image("FriendIcon")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.8)
                                .padding(8)
                        }
                        .frame(width: 55, height: 55)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )                        .clipShape(Circle())
                        .shadow(radius: 2)

                        Button {
                            SoundEffect.play("pageMove", player: &audioPlayer)
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Color.primary.opacity(0.85))
                                .frame(width: 55, height: 55)
                        }
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .fill(Color(hex: "#86C3D1", alpha: 0.1))
                                )
                        )
                        .clipShape(Circle())
                        .shadow(radius: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
        // ③ 下部・左寄せ「海へ / 砂浜へ」切り替えボタン
        .safeAreaInset(edge: .bottom) {
            if screen != .gacha {
                HStack {
                    Button {
                        if screen == .beachScratch {
                            SoundEffect.play("moveFish", player: &audioPlayer)
                        } else {
                            SoundEffect.play("moveSand", player: &audioPlayer)
                        }
                        withAnimation(.spring()) {
                            screen = (screen == .beachScratch) ? .fishAppear : .beachScratch
                        }
                    } label: {
                        Image(screen == .beachScratch ? "moveFish" : "moveSand")
                            .resizable()
                            .scaledToFit()
                            .opacity(0.8)
                            .padding(8)
                    }
                    .frame(width: 55, height: 55)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "#86C3D1", alpha: 0.1))
                            )
                    )                    .clipShape(Circle())
                    .shadow(radius: 2)

                    Button {
                        SoundEffect.play("pageMove", player: &audioPlayer)
                        showMapSelect = true
                    } label: {
                        Image("蒼環のらせんm")
                            .resizable()
                            .scaledToFit()
                            .opacity(0.8)
                            .padding(8)
                    }
                    .frame(width: 55, height: 55)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "#86C3D1", alpha: 0.1))
                            )
                    )                    .clipShape(Circle())
                    .shadow(radius: 2)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 6) 
            }
        }
        .overlay {
            GeometryReader { geo in
                TimedMessageView(message: $accessMessage)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.28)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ToolEffectTimerView()
                .environmentObject(missionManager)
                .padding([.trailing, .bottom], 8)
        }
        .overlay {
            if showBasicOperationGuide {
                BasicOperationGuideView {
                    withAnimation {
                        hasSeenBasicOperationGuide = true
                        showBasicOperationGuide = false
                    }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if let message = popupMessage {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { popupMessage = nil }
                    SimpleMessagePopupView(message: message) {
                        popupMessage = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if showOfflineAlert {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    SimpleMessagePopupView(
                        message: "インターネットに接続できません。通信環境を確認してから再度お試しください。"
                    ) {
                        if networkMonitor.isConnected {
                            withAnimation {
                                showOfflineAlert = false
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if showAccountDeletionConfirm {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    ConfirmPopupView(
                        message: "アカウントを削除しますか？\nこの操作は取り消せません。",
                        onCancel: { showAccountDeletionConfirm = false },
                        onConfirm: {
                            showAccountDeletionConfirm = false
                            Task { await performAccountDeletion() }
                        }
                    )
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    ProgressView("アカウントを削除しています…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .transition(.opacity)
            }
        }
        .overlay {
            NameOnboardingGate(listeners: listeners)
        }
        .fullScreenCover(isPresented: $showCollection) {
            GalleryView()
        }
        .fullScreenCover(isPresented: $showMission) {
            MissionView()
        }
        .fullScreenCover(isPresented: $showShop) {
            ShopView()
        }
        .fullScreenCover(isPresented: $showBag) {
            BagView()
        }
        .fullScreenCover(isPresented: $showMyGallery) {
            MyGalleryView()
        }
        .fullScreenCover(isPresented: $showFriendHub) {
            FriendHubView()
        }
        .fullScreenCover(isPresented: $showMapSelect) {
            MapSelectView()
        }
        .sheet(isPresented: $showGachaMonsters) {
            GachaMonsterStatusView()
        }
        .sheet(isPresented: $showGachaItems) {
            GachaItemStatusView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsMenuView(
                onTerms: { supportDocument = .terms },
                onPrivacy: { supportDocument = .privacy },
                onContact: { supportDocument = .contact },
                onOperationGuide: {
                    showBasicOperationGuide = true
                },
                onAccountDeletion: {
                    showAccountDeletionConfirm = true
                }
            )
        }
        .sheet(item: $supportDocument) { document in
            SupportDocumentView(document: document)
        }
        .onAppear {
            if !missionsLoaded {
                missionManager.context = context
                missionManager.loadState(context: context)
                missionsLoaded = true
            }
            missionManager.recordLogin()
            authService.signInAnonymouslyIfNeeded()
            if let uid = authService.uid {
                listeners.listenUser(uid: uid)
                listeners.listenPublicProfile(uid: uid)
                listeners.listenGalleryConfig(uid: uid)
                Task { await LastActive.ping(uid: uid) }
            }
            if !hasSeenBasicOperationGuide {
                DispatchQueue.main.async {
                    withAnimation {
                        showBasicOperationGuide = true
                    }
                }
            }
            updateOfflineAlert()
        }
        .onChange(of: authService.uid) {
            listeners.stopAll()
            guard let uid = authService.uid else { return }
            listeners.listenUser(uid: uid)
            listeners.listenPublicProfile(uid: uid)
            listeners.listenGalleryConfig(uid: uid)
            Task { await LastActive.ping(uid: uid) }
        }
        .onChange(of: networkMonitor.isConnected) {
            let isConnected = networkMonitor.isConnected
            if isConnected {
                authService.signInAnonymouslyIfNeeded()
            }
            withAnimation {
                showOfflineAlert = !isConnected
            }
        }
        .onDisappear {
            listeners.stopAll()
        }
        .environmentObject(listeners)
    }
}

private extension MainGameView {
    func updateOfflineAlert() {
        withAnimation {
            showOfflineAlert = !networkMonitor.isConnected
        }
    }
}
