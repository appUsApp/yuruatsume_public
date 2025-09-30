import Foundation
import FirebaseFirestore

// MARK: - users/{uid}
struct UserDoc: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String?
    var friendCode: String?
    var friends: [String] = []

    struct Currencies: Codable { var gold: Int; var bubbleCrystal: Int; var bubbleStar: Int }
    var currencies: Currencies = .init(gold: 0, bubbleCrystal: 0, bubbleStar: 0)

    struct Stamina: Codable { var current: Int; var lastUpdatedAt: Date?; var max: Int }
    var stamina: Stamina = .init(current: 4, lastUpdatedAt: nil, max: 4)

    var friendPoints: Int = 0
    var xp: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, username, friendCode, friends, currencies, stamina, friendPoints, xp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id           = try c.decodeIfPresent(String.self, forKey: .id)
        self.username     = try c.decodeIfPresent(String.self, forKey: .username)
        self.friendCode   = try c.decodeIfPresent(String.self, forKey: .friendCode)
        self.friends      = try c.decodeIfPresent([String].self, forKey: .friends) ?? []
        self.currencies   = try c.decodeIfPresent(Currencies.self, forKey: .currencies)
                              ?? .init(gold: 0, bubbleCrystal: 0, bubbleStar: 0)
        self.stamina      = try c.decodeIfPresent(Stamina.self, forKey: .stamina)
                              ?? .init(current: 0, lastUpdatedAt: nil, max: 0)
        self.friendPoints = try c.decodeIfPresent(Int.self, forKey: .friendPoints) ?? 0
        self.xp           = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
    }
}

// MARK: - publicProfiles/{uid}
struct PublicProfileDoc: Codable, Identifiable {
    @DocumentID var id: String?
    var allowVisit: Bool = true
    var rand: Double = 0.0
    var gallerySummary: GallerySummaryDoc?
    @ServerTimestamp var updatedAt: Date?
    @ServerTimestamp var lastActiveAt: Date?
}

struct GallerySummaryDoc: Codable {
    var backgroundID: String
    var backgroundEffectID: String
    var galleryImageID: String
    var monsterIDs: [String]
    var itemIDs: [String]
    var galleryEffectID: String
    var bgmID: String
}

// MARK: - galleryConfigs/{uid}
struct GalleryConfigDoc: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String = ""
    var backgroundID: String
    var backgroundEffectID: String
    var galleryImageID: String
    var monsterIDs: [String]
    var itemIDs: [String]
    var galleryEffectID: String
    var bgmID: String
}

// MARK: - ownership/{uid}
struct OwnershipDoc: Codable, Identifiable {
    @DocumentID var id: String?
    var monsters: [String: MonsterOwn] = [:]
    var items: [String: ItemOwn] = [:] 
}

struct MonsterOwn: Codable { var owned: Bool; var preCount: Int; var rarity: Int }
struct ItemOwn: Codable    { var owned: Bool; var count: Int; var rarity: Int }

// MARK: - likeRecords/{uid}/targets/{targetUid}
struct LikeRecordDoc: Codable, Identifiable {
    @DocumentID var id: String?
    @ServerTimestamp var lastLikedAt: Date?
}

// フレンド申請
struct FriendRequestDoc: Codable, Identifiable {
    @DocumentID var id: String?
    var fromUid: String
    var toUid: String
    var status: String   // "pending" | "accepted" | "declined"
    @ServerTimestamp var createdAt: Date?
}
