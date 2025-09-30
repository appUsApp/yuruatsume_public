import Foundation
import SwiftData

@Model
class GalleryConfig {
    var id: UUID
    var background: String
    var backgroundEffect: String
    var image: String
    var decoration: String
    var monsters: [String]
    var items: [String]
    var bgmID: String

    init(id: UUID = UUID(),
         background: String = "MyGalleryBack01",
         backgroundEffect: String = "MyGalleryBE01",
         image: String = "e01_0%",
         decoration: String = "MyGalleryGE01",
         monsters: [String] = [],
         items: [String] = [],
         bgmID: String = "BgmEvening") {
        self.id = id
        self.background = background
        self.backgroundEffect = backgroundEffect
        self.image = image
        self.decoration = decoration
        self.monsters = monsters
        self.items = items
        self.bgmID = bgmID
    }
}
