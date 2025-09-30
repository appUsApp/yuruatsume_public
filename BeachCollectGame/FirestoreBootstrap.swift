import Foundation
import FirebaseFirestore

enum FirestoreBootstrap {
    static func run(uid: String) async {
        let svc = FirestoreService.shared

        // 1) users upsert（無ければ作成）
        do {
            let path = FSPath.user(uid)
            if try await !svc.exists(path) {
                // stamina を送らない（ルールが弾くため）
                try await Firestore.firestore().document(path).setData([
                    "friends": [],
                    "currencies": [
                        "gold": 0,
                        "bubbleCrystal": 0,
                        "bubbleStar": 0
                    ],
                    "friendPoints": 0,
                    "xp": 0
                ], merge: true)
            }
        } catch { print("users upsert failed:", error) }

        // MyGallery 既定に合わせた初期 summary（リポジトリ基準）
        let initialSummary = GallerySummaryDoc(
            backgroundID: "MyGalleryBack01",
            backgroundEffectID: "MyGalleryBE01",
            galleryImageID: "e01_0%",
            monsterIDs: ["c1","c2","c3","c4"],
            itemIDs: ["i4","i2","i1","i3"],
            galleryEffectID: "MyGalleryGE01",
            bgmID: "BgmEvening"
        )

        // 2) publicProfiles upsert（randを一度だけ初期化、summary なければ設定）
        do {
            let path = FSPath.publicProfile(uid)
            let current: PublicProfileDoc? = try await svc.fetch(path)
            var next = current ?? PublicProfileDoc(
                id: uid,
                allowVisit: true,
                rand: Double.random(in: 0...1),
                gallerySummary: initialSummary,
                updatedAt: nil
            )
            if next.rand <= 0.0 { next.rand = Double.random(in: 0...1) }
            if next.gallerySummary == nil { next.gallerySummary = initialSummary }
            try await svc.upsert(path, next)
            do {
                try await Firestore.firestore().document(path)
                    .setData(["lastActiveAt": FieldValue.serverTimestamp()], merge: true)
            } catch { print("set lastActiveAt failed:", error) }
        } catch { print("publicProfiles upsert failed:", error) }

        // 3) galleryConfigs upsert（自己設定の初期形）
        do {
            let path = FSPath.galleryConfig(uid)
            if try await !svc.exists(path) {
                let cfg = GalleryConfigDoc(
                    id: uid,
                    userId: uid,
                    backgroundID: initialSummary.backgroundID,
                    backgroundEffectID: initialSummary.backgroundEffectID,
                    galleryImageID: initialSummary.galleryImageID,
                    monsterIDs: initialSummary.monsterIDs,
                    itemIDs: initialSummary.itemIDs,
                    galleryEffectID: initialSummary.galleryEffectID,
                    bgmID: initialSummary.bgmID
                )
                try await svc.upsert(path, cfg)
            }
        } catch { print("galleryConfigs upsert failed:", error) }

        // 4) ownership upsert（空で作成）
        do {
            let path = FSPath.ownership(uid)
            if try await !svc.exists(path) {
                let own = OwnershipDoc(id: uid, monsters: [:], items: [:])
                try await svc.upsert(path, own)
            }
        } catch { print("ownership upsert failed:", error) }
    }
}
