import Foundation
import SwiftUI

/// Represents categories available in the shop.
enum ShopCategory: String, CaseIterable, Identifiable {
    case tools
    case gallery
    case background
    case backgroundEffect
    case map
    case monster

    var id: String { rawValue }

    /// Display label used in UI.
    var label: String {
        switch self {
        case .tools: return "ツール"
        case .gallery: return "ギャラリー"
        case .background: return "背景"
        case .backgroundEffect: return "背景エフェクト"
        case .map: return "マップ"
        case .monster: return "シオノコ"
        }
    }

    /// Background image name for each category.
    var backgroundImageName: String {
        switch self {
        case .tools: return "bg8"
        case .gallery: return "bg17"
        case .background: return "bg17"
        case .backgroundEffect: return "bg17"
        case .map: return "bg12"
        case .monster: return "bg12"
        }
    }
}

/// Basic representation of a purchasable item.
struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let price: Int
    /// Discount applied to the original price. ``price`` represents the final cost.
    var discount: Int = 0
}

/// Sample items used for UI placeholder.
let sampleToolItems: [ShopItem] = [
    ShopItem(name: "ホラシュウゴウ", imageName: "horasyuugou", price: 500),
    ShopItem(name: "エンモナイト", imageName: "enmonite", price: 500),
    ShopItem(name: "ラッキーパール", imageName: "luckypearl", price: 500),
    ShopItem(name: "トキノホタテ", imageName: "tokinohotate", price: 500)
]

/// Placeholder items for the gallery category.
let sampleGalleryItems: [ShopItem] = (1...32).map { index in
    ShopItem(
        name: String(format: "ギャラリーエフェクト%02d", index),
        imageName: String(format: "ge%02d", index),
        price: 500
    )
}

/// Items for the background category.
let sampleBackgroundEffectItems: [ShopItem] = (1...43).map { index in
    ShopItem(
        name: String(format: "バックグラウンドエフェクト%02d", index),
        imageName: String(format: "be%02d", index),
        price: 500
    )
}

let sampleBackgroundItems: [ShopItem] = (1...51).map { index in
    ShopItem(
        name: String(format: "背景%02d", index),
        imageName: "bg\(index)",
        price: 1500
    )
}

let backgroundBgmMapping: [String: String] = [
    "bg10": "潮映回廊",
    "bg15": "ねむれる書の根",
    "bg19": "貝火のどうくつ",
    "bg22": "潮渡りの門",
    "bg23": "満月のテラス",
    "bg27": "泡天のはて",
    "bg29": "ふたつ陽の海辺",
    "bg32": "ひかる石段",
    "bg33": "星灯の読み処",
    "bg34": "満月の船橋",
    "bg36": "くらげのそらまど",
    "bg37": "さざめき浜",
    "bg39": "海の鳥居",
    "bg41": "夕映の貝望台",
    "bg42": "波書のうまれる浜",
    "bg44": "蒼環のらせん",
    "bg45": "うずしおオルガン",
    "bg51": "Gacha",
]

let sampleMapItems: [ShopItem] = [
    "うずしおオルガン",
    "くらげのそらまど",
    "さざめき浜",
    "ねむれる書の根",
    "ひかる石段",
    "ふたつ陽の海辺",
    "海の鳥居",
    "貝火のどうくつ",
    "星灯の読み処",
    "蒼環のらせん",
    "潮映回廊",
    "潮渡りの門",
    "波書のうまれる浜",
    "泡天のはて",
    "満月のテラス",
    "満月の船橋",
    "夕映の貝望台",
].map { name in
    ShopItem(name: name, imageName: "\(name)m", price: 2000)
}
