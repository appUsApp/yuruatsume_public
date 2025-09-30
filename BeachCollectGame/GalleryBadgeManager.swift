import SwiftUI

class GalleryBadgeManager: ObservableObject {
    /// Whether the gallery button should show a new content badge.
    @Published var hasNewContent: Bool = false
    /// Image name currently animating towards the gallery button.
    @Published var animatingImageName: String?

    /// Call when a brand new item or monster is obtained.
    func registerNewContent(imageName: String) {
        animatingImageName = imageName
    }

    /// Called by the animation view when the fly-in animation finishes.
    func animationCompleted() {
        animatingImageName = nil
        hasNewContent = true
    }

    /// Reset the badge status when the gallery is opened.
    func resetBadge() {
        hasNewContent = false
    }
}
