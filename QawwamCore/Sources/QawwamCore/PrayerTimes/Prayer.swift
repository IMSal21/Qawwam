/// The five daily prayers, in the order they fall in a prayer day.
public enum Prayer: Int, CaseIterable, Codable, Sendable {
    case fajr, dhuhr, asr, maghrib, isha
}

/// Whether a prayer was logged inside its window or after it closed.
public enum PrayerTiming: String, Codable, Sendable {
    case onTime, late
}
