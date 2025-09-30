import Foundation

enum AudioSettings {
    private static let audioEnabledKey = "AudioSettings.isAudioEnabled"

    static var isAudioEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: audioEnabledKey) != nil else {
                return true
            }
            return UserDefaults.standard.bool(forKey: audioEnabledKey)
        }
        set {
            let defaults = UserDefaults.standard
            let previous = (defaults.object(forKey: audioEnabledKey) as? Bool) ?? true
            defaults.set(newValue, forKey: audioEnabledKey)
            if previous != newValue {
                NotificationCenter.default.post(name: .audioSettingsDidChange, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let audioSettingsDidChange = Notification.Name("AudioSettingsDidChange")
}
