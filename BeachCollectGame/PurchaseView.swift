import SwiftUI
import StoreKit
import FirebaseFirestore

typealias SK2Transaction = StoreKit.Transaction

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService

    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var didAppear = false
    @State private var purchasingProductID: String?
    @State private var infoMessage: String?
    @State private var errorMessage: String?
    @State private var processedTransactionIDs: Set<UInt64> = []
    @State private var didStartObservingTransactions = false
    @State private var purchasedOneTimeKeys: Set<String> = []

    private static let transactionErrorDomain = "PurchaseView.Transaction"
    private static let alreadyPurchasedErrorCode = 1

    private let purchaseOptions: [PurchaseOption] = [
        .init(
            id: "com.appusapp.beachcorrect.releasepack.shou",
            title: "リリース感謝パック(松)",
            description: "泡沫結晶50個のお得なパック",
            fallbackPrice: "¥150",
            imageName: "release_shou",
            rewards: [PurchaseReward(asset: .bubbleCrystal, amount: 50)],
            oneTimeKey: "releaseThanksPackShou",
            successMessage: "リリース感謝パック(松)を購入しました！",
            alreadyPurchasedMessage: "リリース感謝パック(松)はすでに購入済みです。"
        ),
        .init(
            id: "com.appusapp.beachcorrect.releasepack.chiku",
            title: "リリース感謝パック(竹)",
            description: "泡沫結晶やゴールドがたっぷり手に入る一回限定パック",
            fallbackPrice: "¥1,550",
            imageName: "release_chiku",
            rewards: [
                PurchaseReward(asset: .bubbleCrystal, amount: 200),
                PurchaseReward(asset: .gold, amount: 10_000),
                PurchaseReward(asset: .friendPoints, amount: 30)
            ],
            oneTimeKey: "releaseThanksPackChiku",
            successMessage: "リリース感謝パック(竹)を購入しました！",
            alreadyPurchasedMessage: "リリース感謝パック(竹)はすでに購入済みです。"
        ),
        .init(
            id: "com.appusapp.beachcorrect.releasepack.bai",
            title: "リリース感謝パック(梅)",
            description: "泡沫結晶やバブルスターが入った特別セット",
            fallbackPrice: "¥4,400",
            imageName: "release_bai",
            rewards: [
                PurchaseReward(asset: .bubbleCrystal, amount: 500),
                PurchaseReward(asset: .gold, amount: 30_000),
                PurchaseReward(asset: .friendPoints, amount: 50),
                PurchaseReward(asset: .bubbleStar, amount: 500)
            ],
            oneTimeKey: "releaseThanksPackBai",
            successMessage: "リリース感謝パック(梅)を購入しました！",
            alreadyPurchasedMessage: "リリース感謝パック(梅)はすでに購入済みです。"
        ),
        .init(
            id: "com.appusapp.beachcorrect.crystal5",
            title: "泡沫結晶5個",
            description: "ちょっとだけ欲しいときに",
            fallbackPrice: "¥150",
            imageName: "泡沫結晶",
            rewards: [PurchaseReward(asset: .bubbleCrystal, amount: 5)],
            successMessage: "泡沫結晶を5個獲得しました！"
        ),
        .init(
            id: "com.appusapp.beachcorrect.crystal50",
            title: "泡沫結晶50個",
            description: "通常よりお得なまとめ買い",
            fallbackPrice: "¥1,300",
            imageName: "bubble_50",
            rewards: [PurchaseReward(asset: .bubbleCrystal, amount: 50)],
            successMessage: "泡沫結晶を50個獲得しました！"
        ),
        .init(
            id: "com.appusapp.beachcorrect.crystal120",
            title: "泡沫結晶120個",
            description: "たくさん引きたいときに",
            fallbackPrice: "¥2,800",
            imageName: "bubble_120",
            rewards: [PurchaseReward(asset: .bubbleCrystal, amount: 120)],
            successMessage: "泡沫結晶を120個獲得しました！"
        ),
        .init(
            id: "com.appusapp.beachcorrect.crystal200",
            title: "泡沫結晶200個",
            description: "たっぷり遊びたい人向け",
            fallbackPrice: "¥4,400",
            imageName: "bubble_200",
            rewards: [PurchaseReward(asset: .bubbleCrystal, amount: 200)],
            successMessage: "泡沫結晶を200個獲得しました！"
        )
    ]

    private var purchaseOptionMap: [String: PurchaseOption] {
        Dictionary(uniqueKeysWithValues: purchaseOptions.map { ($0.id, $0) })
    }

    private var displayedOptions: [PurchaseOption] {
        purchaseOptions.filter { option in
            guard let key = option.oneTimeKey else { return true }
            return !purchasedOneTimeKeys.contains(key)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("PurchaseBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerView

                        if isLoading {
                            ProgressView("商品を読み込み中です…")
                                .padding(.top, 16)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(displayedOptions) { option in
                                    PurchaseOptionRow(option: option,
                                                       product: product(for: option.id),
                                                       isPurchasing: purchasingProductID == option.id) {
                                        startPurchase(option: option)
                                    }
                                }
                            }
                        }

                        if let infoMessage {
                            messageView(text: infoMessage, color: .green)
                        }

                        if let errorMessage {
                            messageView(text: errorMessage, color: .red)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("泡沫結晶購入")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color(.white))
                }
            }
        }
        .task {
            guard !didAppear else { return }
            didAppear = true
            await loadProducts()
        }
        .task {
            await observeTransactionsIfNeeded()
        }
        .task(id: authService.uid) {
            await loadLimitedPurchaseState()
        }
    }

    private func loadProducts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            infoMessage = nil
        }
        await loadLimitedPurchaseState()
        do {
            let ids = purchaseOptions.map { $0.id }
            let fetched = try await Product.products(for: ids)
            await MainActor.run {
                products = fetched.sorted { lhs, rhs in
                    ids.firstIndex(of: lhs.id) ?? 0 < ids.firstIndex(of: rhs.id) ?? 0
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "商品の取得に失敗しました。時間をおいて再度お試しください。"
            }
        }
    }

    private func loadLimitedPurchaseState() async {
        guard let uid = authService.uid else { return }
        do {
            let snapshot = try await Firestore.firestore().document(FSPath.user(uid)).getDocument()
            guard let data = snapshot.data(), let limited = data["limitedPurchases"] as? [String: Bool] else { return }
            let purchased = limited.filter { $0.value }.map { $0.key }
            await MainActor.run {
                purchasedOneTimeKeys = Set(purchased)
            }
        } catch {
            print("Failed to load limited purchase state:", error)
        }
    }

    private func observeTransactionsIfNeeded() async {
        let shouldStart: Bool = await MainActor.run {
            if didStartObservingTransactions { return false }
            didStartObservingTransactions = true
            return true
        }
        guard shouldStart else { return }
        await checkUnfinishedTransactions()
        await observeTransactionUpdates()
    }

    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            await handleTransactionUpdate(update)
        }
    }

    private func checkUnfinishedTransactions() async {
        for await update in Transaction.unfinished {
            await handleTransactionUpdate(update)
        }
    }

    private func handleTransactionUpdate(_ update: VerificationResult<SK2Transaction>) async {
        switch update {
        case .verified(let transaction):
            guard let option = purchaseOptionMap[transaction.productID] else {
                await transaction.finish()
                return
            }
            await grantPurchase(for: option, transaction: transaction)
        case .unverified:
            await MainActor.run {
                errorMessage = "購入の検証に失敗しました。"
                infoMessage = nil
            }
        }
    }

    private func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    private func startPurchase(option: PurchaseOption) {
        guard purchasingProductID == nil else { return }
        guard let product = product(for: option.id) else {
            errorMessage = "商品情報を取得できませんでした。"
            return
        }
        errorMessage = nil
        infoMessage = nil
        purchasingProductID = option.id
        Task {
            do {
                let result = try await product.purchase()
                await handlePurchaseResult(result, option: option)
            } catch {
                await MainActor.run {
                    errorMessage = "購入処理に失敗しました。通信環境をご確認ください。"
                    infoMessage = nil
                }
            }
            await MainActor.run {
                purchasingProductID = nil
            }
        }
    }

    private func handlePurchaseResult(_ result: Product.PurchaseResult, option: PurchaseOption) async {
        switch result {
        case .success(let verification):
            await handleVerification(verification, option: option)
        case .pending:
            await MainActor.run {
                infoMessage = "購入が保留中です。完了までしばらくお待ちください。"
                errorMessage = nil
            }
        case .userCancelled:
            await MainActor.run {
                infoMessage = "購入がキャンセルされました。"
                errorMessage = nil
            }
        @unknown default:
            await MainActor.run {
                errorMessage = "予期しないエラーが発生しました。"
                infoMessage = nil
            }
        }
    }

    private func handleVerification(_ verification: VerificationResult<SK2Transaction>, option: PurchaseOption) async {
        switch verification {
        case .verified(let transaction):
            await grantPurchase(for: option, transaction: transaction)
        case .unverified:
            await MainActor.run {
                errorMessage = "購入の検証に失敗しました。"
                infoMessage = nil
            }
        }
    }

    @MainActor
    private func grantPurchase(for option: PurchaseOption, transaction: SK2Transaction) async {
        guard let uid = authService.uid else {
            errorMessage = "ユーザー情報を取得できませんでした。"
            infoMessage = nil
            return
        }
        if processedTransactionIDs.contains(transaction.id) {
            await transaction.finish()
            return
        }
        processedTransactionIDs.insert(transaction.id)
        do {
            try await applyRewards(for: option, uid: uid)
            if let key = option.oneTimeKey {
                purchasedOneTimeKeys.insert(key)
            }
            infoMessage = option.successMessage
            errorMessage = nil
            await transaction.finish()
        } catch PurchaseProcessingError.alreadyPurchased {
            errorMessage = option.alreadyPurchasedMessage ?? "この商品はすでに購入済みです。"
            infoMessage = nil
            await transaction.finish()
        } catch {
            processedTransactionIDs.remove(transaction.id)
            errorMessage = "購入内容の反映に失敗しました。時間をおいて再度お試しください。"
            infoMessage = nil
        }
    }

    private func applyRewards(for option: PurchaseOption, uid: String) async throws {
        let db = Firestore.firestore()
        let ref = db.document(FSPath.user(uid))
        do {
            try await db.runTransaction { txn, errorPointer in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try txn.getDocument(ref)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                if let key = option.oneTimeKey {
                    let limited = snapshot.data()?["limitedPurchases"] as? [String: Any]
                    let alreadyPurchased = (limited?[key] as? Bool) ?? false
                    if alreadyPurchased {
                        errorPointer?.pointee = NSError(domain: PurchaseView.transactionErrorDomain,
                                                         code: PurchaseView.alreadyPurchasedErrorCode,
                                                         userInfo: nil)
                        return nil
                    }
                }

                var updates: [String: Any] = [:]
                for reward in option.rewards {
                    updates[reward.asset.fieldPath] = FieldValue.increment(Int64(reward.amount))
                }
                if let key = option.oneTimeKey {
                    updates["limitedPurchases.\(key)"] = true
                }
                txn.updateData(updates, forDocument: ref)
                return nil
            }
        } catch let error as NSError {
            if error.domain == PurchaseView.transactionErrorDomain && error.code == PurchaseView.alreadyPurchasedErrorCode {
                throw PurchaseProcessingError.alreadyPurchased
            }
            throw error
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Image("PurchaseViewImage")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
            Text("泡沫結晶を手に入れて、新たな出会いを見つけよう！！")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func messageView(text: String, color: Color) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

private enum PurchaseProcessingError: Error {
    case alreadyPurchased
}

private struct PurchaseOption: Identifiable {
    let id: String
    let title: String
    let description: String
    let fallbackPrice: String
    let imageName: String
    let rewards: [PurchaseReward]
    let oneTimeKey: String?
    let successMessage: String
    let alreadyPurchasedMessage: String?

    init(
        id: String,
        title: String,
        description: String,
        fallbackPrice: String,
        imageName: String,
        rewards: [PurchaseReward],
        oneTimeKey: String? = nil,
        successMessage: String,
        alreadyPurchasedMessage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.fallbackPrice = fallbackPrice
        self.imageName = imageName
        self.rewards = rewards
        self.oneTimeKey = oneTimeKey
        self.successMessage = successMessage
        self.alreadyPurchasedMessage = alreadyPurchasedMessage
    }

    var isOneTime: Bool { oneTimeKey != nil }
}

private struct PurchaseReward: Identifiable {
    let asset: CurrencyService.Asset
    let amount: Int

    var id: String { "\(asset.rawValue)-\(amount)" }

    var displayText: String {
        let formattedAmount = PurchaseReward.numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        switch asset {
        case .bubbleCrystal:
            return "泡沫結晶\(formattedAmount)個"
        case .gold:
            return "\(formattedAmount)ゴールド"
        case .friendPoints:
            return "\(formattedAmount)いいね"
        case .bubbleStar:
            return "\(formattedAmount)泡沫星"
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

private struct PurchaseOptionRow: View {
    let option: PurchaseOption
    let product: Product?
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Image(option.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .shadow(radius: 4)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(option.title)
                            .font(.headline)
                        if option.isOneTime {
                            Text("1回限定")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#d9534f", alpha: 0.9))
                                .foregroundStyle(Color(.white))
                                .clipShape(Capsule())
                        }
                    }
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(option.rewards) { reward in
                            Text("・\(reward.displayText)")
                                .font(.subheadline)
                        }
                    }
                    Text(product?.displayPrice ?? option.fallbackPrice)
                        .font(.title3).bold()
                }
                Spacer()
                if isPurchasing {
                    ProgressView()
                } else {
                    Button(action: action) {
                        Text("購入")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#b3b336"))
                    .buttonStyle(.plain)
                    .background(Color(hex: "#b3b336"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "#75B336", alpha: 0.1))
                )
        )
        .shadow(radius: 6, y: 2)
    }
}

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8)  & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
