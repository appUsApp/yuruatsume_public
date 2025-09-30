import Foundation
import SwiftData

@Model
class MissionState {
    @Attribute(.unique) var id: String
    var type: String
    var progress: Int
    var received: Bool
    var stageIndex: Int

    init(id: String, type: String, progress: Int = 0, received: Bool = false, stageIndex: Int = 0) {
        self.id = id
        self.type = type
        self.progress = progress
        self.received = received
        self.stageIndex = stageIndex
    }
}

@Model
class MissionMeta {
    @Attribute(.unique) var id: String
    var lastLogin: Date?

    init(id: String = "meta", lastLogin: Date? = nil) {
        self.id = id
        self.lastLogin = lastLogin
    }
}
