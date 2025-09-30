//
//  LastActive.swift
//  BeachCollectGame
//
//  Created by のりやまのりを on 2025/09/24.
//

import Foundation
import FirebaseFirestore

enum LastActive {
    /// publicProfiles/{uid}.lastActiveAt を serverTimestamp() で更新
    static func ping(uid: String) async {
        let ref = Firestore.firestore().document(FSPath.publicProfile(uid))
        do {
            try await ref.setData(["lastActiveAt": FieldValue.serverTimestamp()], merge: true)
        } catch {
            print("lastActive ping failed:", error)
        }
    }
}
