import Foundation
import FirebaseFirestore

enum PublicProfileSync {
    static func syncFrom(config: GalleryConfigDoc, uid: String) async {
        let svc = FirestoreService.shared
        // 1) GalleryConfigDoc -> GallerySummaryDoc を生成
        let summary = GallerySummaryDoc(
            backgroundID:       config.backgroundID,
            backgroundEffectID: config.backgroundEffectID,
            galleryImageID:     config.galleryImageID,
            monsterIDs:         Array(config.monsterIDs.prefix(4)),
            itemIDs:            Array(config.itemIDs.prefix(4)),
            galleryEffectID:    config.galleryEffectID,
            bgmID:              config.bgmID
        )

        // 2) publicProfiles/{uid} を取得 or 生成
        do {
            let path = FSPath.publicProfile(uid)
            var current: PublicProfileDoc? = try await svc.fetch(path)
            if current == nil {
                current = PublicProfileDoc(
                    id: uid,
                    allowVisit: true,
                    rand: Double.random(in: 0...1),
                    gallerySummary: summary,
                    updatedAt: nil
                )
            } else {
                current?.gallerySummary = summary
                if current?.allowVisit == false { current?.allowVisit = true }
            }
            current?.updatedAt = Date()
            try await svc.upsert(path, current!)
        } catch {
            print("PublicProfileSync upsert failed:", error)
        }
    }
}
