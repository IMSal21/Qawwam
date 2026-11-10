import Foundation

/// One of the five parts of today's ring.
public enum RingSegment: Equatable, Sendable {
    case onTime, late, due, upcoming, missed
}

/// Turns the prayer log and score into the farm the app and widgets draw.
public enum FarmBuilder {
    /// Five segments for `day`, Fajr first.
    public static func ring(_ log: PrayerLog, for day: PrayerDay, at now: Date) -> [RingSegment] {
        Prayer.allCases.map { prayer in
            switch log.status(of: prayer, in: day, at: now) {
            case .upcoming: .upcoming
            case .due: .due
            case .prayed(.onTime): .onTime
            case .prayed(.late): .late
            case .missed: .missed
            }
        }
    }
}
