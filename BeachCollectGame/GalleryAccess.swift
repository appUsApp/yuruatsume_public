import SwiftData

/// Checks whether the player satisfies the requirements to access MyGallery related features.
/// - Parameters:
///   - items: Owned items with count > 0.
///   - monsters: Monster records that have been obtained.
/// - Returns: True if all rarities 1-4 are owned at least once and at least four monsters are obtained.
func meetsGalleryAccessRequirement(items: [GameItem], monsters: [MonsterRecord]) -> Bool {
    let ownedRarities = Set(items.map { $0.rarity })
    let hasAllRarities = (1...4).allSatisfy { ownedRarities.contains($0) }
    let monsterCount = monsters.count
    return hasAllRarities && monsterCount >= 4
}
