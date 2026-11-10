/// The calculation methods Qawwam supports. Umm al-Qura only for now.
public enum CalculationMethodID: String, Codable, Sendable {
    case ummAlQura
}

/// How Asr is calculated: `standard` (shadow equals length, used by Umm al-Qura)
/// or `hanafi` (shadow twice the length, later).
public enum AsrMadhab: String, Codable, Sendable {
    case standard, hanafi
}

/// The user's prayer time preferences.
public struct PrayerSettings: Codable, Equatable, Sendable {
    /// The largest adjustment, in minutes, either way.
    public static let adjustmentLimit = 30

    public static let ummAlQura = PrayerSettings(method: .ummAlQura, madhab: .standard)

    public var method: CalculationMethodID
    public var madhab: AsrMadhab
    private var adjustments: [Prayer: Int]

    public init(method: CalculationMethodID, madhab: AsrMadhab, adjustments: [Prayer: Int] = [:]) {
        self.method = method
        self.madhab = madhab
        self.adjustments = adjustments.mapValues(Self.clamped)
    }

    /// Minutes added to the calculated time of `prayer`.
    public func adjustment(for prayer: Prayer) -> Int {
        adjustments[prayer] ?? 0
    }

    /// Sets the adjustment for `prayer`, clamped to ±`adjustmentLimit` minutes.
    public mutating func setAdjustment(_ minutes: Int, for prayer: Prayer) {
        adjustments[prayer] = Self.clamped(minutes)
    }

    private static func clamped(_ minutes: Int) -> Int {
        min(max(minutes, -adjustmentLimit), adjustmentLimit)
    }
}
