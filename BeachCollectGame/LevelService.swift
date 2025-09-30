
enum LevelService {
    static func level(forXP xp: Int) -> Int { max(1, xp / 10 + 1) }
}
