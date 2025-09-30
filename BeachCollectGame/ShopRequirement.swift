import Foundation

struct ShopRequirement {
    static let galleryEffects: [Int: [String]] = [
        0: ["ge01", "ge02", "ge03", "ge04", "ge05"],
        20: ["ge06", "ge07", "ge08", "ge09", "ge10"],
        40: ["ge11", "ge12", "ge13", "ge14", "ge15"],
        60: ["ge16", "ge17", "ge18", "ge19", "ge20"],
        80: ["ge21", "ge22", "ge23", "ge24", "ge25"],
        100: ["ge26", "ge27", "ge28", "ge29", "ge30"],
        120: ["ge31", "ge32"],
    ]

    static let backgrounds: [Int: [String]] = [
        0: ["bg1", "bg2", "bg3", "bg4", "bg5"],
        20: ["bg6", "bg7", "bg8", "bg9", "bg10"],
        40: ["bg11", "bg12", "bg13", "bg14", "bg15"],
        60: ["bg16", "bg17", "bg18", "bg19", "bg20"],
        80: ["bg21", "bg22", "bg23", "bg24", "bg25"],
        100: ["bg26", "bg27", "bg28", "bg29", "bg30"],
        120: ["bg31", "bg32", "bg33", "bg34", "bg35"],
        140: ["bg36", "bg37", "bg38", "bg39", "bg40"],
        160: ["bg41", "bg42", "bg43", "bg44", "bg45"],
        180: ["bg46", "bg47", "bg48", "bg49", "bg50"],
        200: ["bg51"],
    ]

    static let backgroundEffects: [Int: [String]] = [
        0: ["be01", "be02", "be03", "be04", "be05"],
        20: ["be06", "be07", "be08", "be09", "be10"],
        40: ["be11", "be12", "be13", "be14", "be15"],
        60: ["be16", "be17", "be18", "be19", "be20"],
        80: ["be21", "be22", "be23", "be24", "be25"],
        100: ["be26", "be27", "be28", "be29", "be30"],
        120: ["be31", "be32", "be33", "be34", "be35"],
        140: ["be36", "be37", "be38", "be39", "be40"],
        160: ["be41", "be42", "be43"],
    ]

    static let maps: [Int: [String]] = [
        0: ["うずしおオルガン", "くらげのそらまど", "さざめき浜", "ねむれる書の根", "ひかる石段"],
        20: ["ふたつ陽の海辺", "海の鳥居", "貝火のどうくつ", "星灯の読み処", "蒼環のらせん"],
        40: ["潮映回廊", "潮渡りの門", "波書のうまれる浜", "泡天のはて", "満月のテラス"],
        60: ["満月の船橋", "夕映の貝望台"],
    ]

    static func requiredFriendPoints(for id: String, category: ShopCategory) -> Int {
        let dictionary: [Int: [String]]
        switch category {
        case .gallery:
            dictionary = galleryEffects
        case .background:
            dictionary = backgrounds
        case .backgroundEffect:
            dictionary = backgroundEffects
        case .map:
            dictionary = maps
        default:
            return 0
        }
        for (fp, ids) in dictionary {
            if ids.contains(id) {
                return fp
            }
        }
        return 0
    }
}
