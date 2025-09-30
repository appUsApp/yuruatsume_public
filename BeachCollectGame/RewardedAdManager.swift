import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdManager: NSObject {

    enum RewardedAdError: LocalizedError {
        case missingAdUnitID
        case adNotReady
        case presentationInProgress
        case noRootViewController
        case failedToLoad

        var errorDescription: String? {
            switch self {
            case .missingAdUnitID:
                return "広告IDが設定されていません。"
            case .adNotReady:
                return "広告の読み込みに失敗しました。"
            case .presentationInProgress:
                return "広告を表示中です。"
            case .noRootViewController:
                return "広告を表示できる画面が見つかりません。"
            case .failedToLoad:
                return "広告の読み込みに失敗しました。"
            }
        }
    }

    static let shared = RewardedAdManager()

    private var rewardedAd: RewardedAd?
    private var isLoading = false
    private var loadContinuations: [CheckedContinuation<Void, Error>] = []
    private var presentationContinuation: CheckedContinuation<Bool, Error>?
    private var hasEarnedReward = false
    private let adUnitID: String

    private override init() {
        #if DEBUG
        // Google公式のテスト用（Rewarded）
        adUnitID = "ca-app-pub-3940256099942544/1712485313"
        #else
        adUnitID = (Bundle.main.object(forInfoDictionaryKey: "GADRewardedAdUnitID_Stamina") as? String) ?? ""
        #endif
        super.init()
    }

    func preload() {
        Task { [weak self] in
            guard let self else { return }
            _ = try? await self.loadAdIfNeeded(force: false)
        }
    }

    func present() async throws -> Bool {
        if rewardedAd == nil {
            try await loadAdIfNeeded(force: true)
        }
        guard let ad = rewardedAd else {
            throw adUnitID.isEmpty ? RewardedAdError.missingAdUnitID : RewardedAdError.adNotReady
        }
        guard presentationContinuation == nil else { throw RewardedAdError.presentationInProgress }
        guard let root = Self.topViewController() else { throw RewardedAdError.noRootViewController }

        hasEarnedReward = false
        return try await withCheckedThrowingContinuation { continuation in
            presentationContinuation = continuation
            ad.present(from: root) { [weak self] in
                self?.hasEarnedReward = true
            }
        }
    }

    private func loadAdIfNeeded(force: Bool) async throws {
        if !force, let ad = rewardedAd, ad.responseInfo != nil {
            return
        }
        if adUnitID.isEmpty { throw RewardedAdError.missingAdUnitID }
        if isLoading {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                loadContinuations.append(continuation)
            }
            return
        }
        isLoading = true
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loadContinuations.append(continuation)
            let request = Request()
            RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
                guard let self else { return }
                Task { @MainActor in
                    self.isLoading = false
                    let continuations = self.loadContinuations
                    self.loadContinuations.removeAll()
                    if let ad {
                        ad.fullScreenContentDelegate = self
                        self.rewardedAd = ad
                        continuations.forEach { $0.resume(returning: ()) }
                    } else {
                        let err = error ?? RewardedAdError.failedToLoad
                        self.rewardedAd = nil
                        continuations.forEach { $0.resume(throwing: err) }
                    }
                }
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        for scene in scenes {
            if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                return root.topMostViewController()
            }
        }
        return nil
    }
}

extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finishPresentation(with: hasEarnedReward)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finishPresentation(with: error)
    }

    private func finishPresentation(with result: Bool) {
        let continuation = presentationContinuation
        presentationContinuation = nil
        hasEarnedReward = false
        continuation?.resume(returning: result)
        rewardedAd = nil
        preload()
    }

    private func finishPresentation(with error: Error) {
        let continuation = presentationContinuation
        presentationContinuation = nil
        hasEarnedReward = false
        continuation?.resume(throwing: error)
        rewardedAd = nil
        preload()
    }
}

private extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostViewController()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController()
        }
        return self
    }
}
