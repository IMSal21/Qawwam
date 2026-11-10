/// The six Arabic plural forms (as in CLDR) for counting with digits.
enum ArabicPlural: Equatable {
    case zero, one, two, few, many, other

    init(_ count: Int) {
        let hundreds = abs(count) % 100
        switch abs(count) {
        case 0: self = .zero
        case 1: self = .one
        case 2: self = .two
        default:
            switch hundreds {
            case 3...10: self = .few
            case 11...99: self = .many
            default: self = .other
            }
        }
    }
}

/// How one Arabic noun is counted: "يوم واحد", "يومان", "3 أيام", "11 يومًا", "100 يوم".
struct ArabicCountedNoun {
    let singular: String
    let one: String
    let two: String
    let plural: String
    let accusative: String

    func counted(_ count: Int, digits: String) -> String {
        switch ArabicPlural(count) {
        case .one: one
        case .two: two
        case .few: "\(digits) \(plural)"
        case .many: "\(digits) \(accusative)"
        case .zero, .other: "\(digits) \(singular)"
        }
    }

    static let day = ArabicCountedNoun(
        singular: "يوم", one: "يوم واحد", two: "يومان", plural: "أيام", accusative: "يومًا")
    static let point = ArabicCountedNoun(
        singular: "نقطة", one: "نقطة واحدة", two: "نقطتان", plural: "نقاط", accusative: "نقطة")
}
