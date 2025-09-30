import Foundation
import SwiftData

@Model
class ToolCountState {
    @Attribute(.unique) var tool: String
    var count: Int
    init(tool: String, count: Int = 0) {
        self.tool = tool
        self.count = count
    }
}
