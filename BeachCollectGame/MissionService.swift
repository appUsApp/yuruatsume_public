import Foundation


enum MissionService {
    /// 既存の呼び出し互換API。type: "daily" | "lifetime"
    static func awardXP10(for missionId: String, type: String) async {
        let missionType: MissionType = (type == "daily") ? .daily : .lifetime
        _ = try? await MissionXP.awardOnce(type: missionType, missionId: missionId, amount: 10)
    }
}
