import UIKit

enum HapticLevel: Int {
    case light = 0
    case medium
    case strong
    case heavy

    /// Return next stronger level capped at heavy
    func next() -> HapticLevel {
        HapticLevel(rawValue: min(self.rawValue + 1, HapticLevel.heavy.rawValue)) ?? .heavy
    }
}

/// Trigger a haptic feedback for given level
func triggerHaptic(_ level: HapticLevel) {
    let generator: UIImpactFeedbackGenerator
    switch level {
    case .light:
        generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    case .medium:
        generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    case .strong:
        generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: 0.7)
    case .heavy:
        generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: 1.0)
    }
}

/// Determine haptic level for discovery based on rarity and type
func hapticLevelForDiscovery(rarity: Int, isItem: Bool) -> HapticLevel {
    if isItem {
        switch rarity {
        case 4: return .heavy
        case 3: return .strong
        case 2: return .medium
        default: return .light
        }
    } else {
        switch rarity {
        case 5: return .heavy
        case 4: return .strong
        case 3: return .medium
        default: return .light
        }
    }
}

/// Determine haptic level for a tap based on base level and tap index (1..3)
func hapticLevelForTap(base: HapticLevel, tapIndex: Int) -> HapticLevel {
    let cappedIndex = min(base.rawValue + tapIndex - 1, HapticLevel.heavy.rawValue)
    var level = HapticLevel(rawValue: cappedIndex) ?? .light
    if tapIndex == 3 && level.rawValue < HapticLevel.strong.rawValue {
        level = .strong
    }
    return level
}

