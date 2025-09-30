import Foundation
import SwiftData

@Model
class OwnedGalleryEffect {
    @Attribute(.unique) var id: String
    init(id: String) {
        self.id = id
    }
}

@Model
class OwnedBackground {
    @Attribute(.unique) var id: String
    init(id: String) {
        self.id = id
    }
}

@Model
class OwnedBackgroundEffect {
    @Attribute(.unique) var id: String
    init(id: String) {
        self.id = id
    }
}

@Model
class OwnedMapItem {
    @Attribute(.unique) var name: String
    init(name: String) {
        self.name = name
    }
}

@Model
class OwnedGalleryImage {
    @Attribute(.unique) var id: String
    init(id: String) {
        self.id = id
    }
}

@Model
class OwnedBGM {
    @Attribute(.unique) var id: String  
    init(id: String) {
        self.id = id
    }
}
