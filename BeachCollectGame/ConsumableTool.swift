import Foundation
import SwiftUI

enum ConsumableTool: String, CaseIterable, Identifiable {
    case horasyuugou
    case enmonite
    case luckypearl
    case tokinohotate

    var id: String { rawValue }

    var name: String {
        switch self {
        case .horasyuugou: return "ホラシュウゴウ"
        case .enmonite: return "エンモナイト"
        case .luckypearl: return "ラッキーパール"
        case .tokinohotate: return "トキノホタテ"
        }
    }

    var imageName: String {
        switch self {
        case .horasyuugou: return "horasyuugou"
        case .enmonite: return "enmonite"
        case .luckypearl: return "luckypearl"
        case .tokinohotate: return "tokinohotate"
        }
    }

    var description: String {
        switch self {
        case .horasyuugou:
            return "10分間シオノコの出現確率を大幅に上げます。"
        case .enmonite:
            return "10分間アイテムの出現確率を大幅に上げます。"
        case .luckypearl:
            return "10分間アイテムの出現レアリティを上げます。"
        case .tokinohotate:
            return "好きな時間帯に変更できます。"
        }
    }
}
