import Foundation
import GoogleMobileAds
import UIKit

/// デイリーミッション専用の報酬型広告マネージャ（GMA SDK v11）
@MainActor
final class DailyMissionAdManager: NSObject {
    enum RewardedAdError: LocalizedError {
        case missingAdUnitID, adNotReady, presentationInProgress, noRootViewController, failedToLoad
        var errorDescription: String? {
            switch self {
            case .missingAdUnitID: return "広告IDが設定されていません。"
            case .adNotReady: return "広告の読み込みに失敗しました。"
            case .presentationInProgress: return "広告を表示中です。"
            case .noRootViewController: return "広告を表示できる画面が見つかりません。"
            case .failedToLoad: return "広告の読み込みに失敗しました。"
            }
        }
    }

    static let shared = DailyMissionAdManager()

    private var rewardedAd: RewardedAd?
    private var isLoading = false
    private var loadContinuations: [CheckedContinuation<Void, Error>] = []
    private var presentationContinuation: CheckedContinuation<Bool, Error>?
    private var hasEarnedReward = false

    private let adUnitID: String = {
        #if DEBUG
        // テスト用ユニットID
        return "ca-app-pub-3940256099942544/1712485313"
        #else
        return "ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"
        #endif
    }()

    func preload() {
        Task { [weak self] in
            guard let self else { return }
            _ = try? await self.loadAdIfNeeded(force: false)
        }
    }

    func present() async throws -> Bool {
        if rewardedAd == nil { try await loadAdIfNeeded(force: true) }
        guard let ad = rewardedAd else { throw RewardedAdError.adNotReady }
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
        if !force, let ad = rewardedAd, ad.responseInfo != nil { return }
        if adUnitID.isEmpty { throw RewardedAdError.missingAdUnitID }
        if isLoading {
            try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                loadContinuations.append(c)
            }
            return
        }
        isLoading = true
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            loadContinuations.append(c)
            let request = Request()
            RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
                guard let self else { return }
                Task { @MainActor in
                    self.isLoading = false
                    let conts = self.loadContinuations; self.loadContinuations.removeAll()
                    if let ad {
                        ad.fullScreenContentDelegate = self
                        self.rewardedAd = ad
                        conts.forEach { $0.resume(returning: ()) }
                    } else {
                        let err = error ?? RewardedAdError.failedToLoad
                        self.rewardedAd = nil
                        conts.forEach { $0.resume(throwing: err) }
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

extension DailyMissionAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finishPresentation(with: hasEarnedReward)
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finishPresentation(with: error)
    }
    private func finishPresentation(with result: Bool) {
        let c = presentationContinuation
        presentationContinuation = nil
        hasEarnedReward = false
        c?.resume(returning: result)
        rewardedAd = nil
        preload()
    }
    private func finishPresentation(with error: Error) {
        let c = presentationContinuation
        presentationContinuation = nil
        hasEarnedReward = false
        c?.resume(throwing: error)
        rewardedAd = nil
        preload()
    }
}

private extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let p = presentedViewController { return p.topMostViewController() }
        if let nav = self as? UINavigationController, let v = nav.visibleViewController { return v.topMostViewController() }
        if let tab = self as? UITabBarController, let s = tab.selectedViewController { return s.topMostViewController() }
        return self
    }
}
