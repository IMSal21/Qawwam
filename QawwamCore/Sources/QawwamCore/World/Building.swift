import Foundation

/// Buildings in Islamic styles that streak badges unlock. They stay on the farm for good.
public enum Building: String, CaseIterable, Sendable {
    case well, farmhouse, courtyard, gate, mosque

    /// The streak badge that unlocks this building.
    public var badge: Int {
        switch self {
        case .well: 3
        case .farmhouse: 7
        case .courtyard: 30
        case .gate: 40
        case .mosque: 100
        }
    }

    public var artName: String {
        "building.\(rawValue)"
    }

    /// The buildings `badges` unlock, in unlock order.
    public static func unlocked(by badges: [Int]) -> [Building] {
        allCases.filter { badges.contains($0.badge) }
    }
}
