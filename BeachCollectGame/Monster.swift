import Foundation

struct Monster: Identifiable {
    /// Unique monster ID used for icon lookups
    let id: Int
    /// Display name. Can change independently from the ID
    let name: String

    /// Image name based on the monster ID (e.g. "25" -> c25.png)
    var imageName: String { "c\(id)" }
}
