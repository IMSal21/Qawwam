import Foundation

/// The point values from SPEC-scoring.md.
public struct ScoringRules: Equatable, Sendable {
    public var onTimePoints: Int
    public var latePoints: Int
    /// Added when all five prayers of a day are on time.
    public var allOnTimeBonus: Int
    /// Streak length → bonus, added every time a streak reaches that length.
    public var streakBonuses: [Int: Int]
    /// Streak lengths that earn a badge, once.
    public var badgeStreaks: [Int]

    public static let standard = ScoringRules(
        onTimePoints: 10, latePoints: 5, allOnTimeBonus: 25,
        streakBonuses: [7: 50, 30: 100, 40: 150, 100: 300],
        badgeStreaks: [3, 7, 30, 40, 100]
    )
}

/// How one prayer day went.
public struct DayScore: Equatable, Sendable {
    public let day: DayKey
    /// The day's prayers plus the all-on-time bonus.
    public let points: Int
    public let prayedCount: Int
    public let onTimeCount: Int
    /// All five prayed, on time or late.
    public let isComplete: Bool
    /// The next Fajr has begun.
    public let isClosed: Bool
}

public struct Score: Equatable, Sendable {
    /// Day points plus streak bonuses.
    public let totalPoints: Int
    public let level: Int
    public let currentStreak: Int
    public let bestStreak: Int
    public let currentFajrStreak: Int
    public let bestFajrStreak: Int
    /// The badge streak lengths reached at least once, smallest first.
    public let badges: [Int]
    /// Oldest first.
    public let days: [DayScore]
}

public enum Scoring {
    /// Scores `log` over `days`: every prayer day from the user's first day up to the one containing `now`.
    /// Days that haven't started by `now` are ignored, and duplicates are dropped.
    public static func score(
        _ log: PrayerLog, days: [PrayerDay], at now: Date, rules: ScoringRules = .standard
    ) -> Score {
        let started = startedDays(days, at: now)
        let dayScores = started.map { dayScore(log, for: $0, at: now, rules: rules) }
        let total = dayScores.reduce(0) { $0 + $1.points }
        let streak = walkStreak(dayScores)
        return Score(
            totalPoints: total, level: 1, currentStreak: streak.current, bestStreak: streak.best,
            currentFajrStreak: 0, bestFajrStreak: 0, badges: [], days: dayScores
        )
    }

    /// Walks the days oldest first. A complete day adds one, a closed incomplete day or a missing date resets
    /// to zero, and today, while still open and unfinished, leaves the streak as it is.
    private static func walkStreak(_ days: [DayScore]) -> (current: Int, best: Int) {
        var current = 0
        var best = 0
        var previous: DayKey?
        for day in days {
            if let previous, previous.next != day.day {
                current = 0
            }
            if day.isComplete {
                current += 1
                best = max(best, current)
            } else if day.isClosed {
                current = 0
            }
            previous = day.day
        }
        return (current, best)
    }

    private static func startedDays(_ days: [PrayerDay], at now: Date) -> [PrayerDay] {
        var seen = Set<DayKey>()
        let sorted = days.filter { now >= $0.time(of: .fajr) }.sorted { DayKey($0) < DayKey($1) }
        return sorted.filter { seen.insert(DayKey($0)).inserted }
    }

    private static func dayScore(_ log: PrayerLog, for day: PrayerDay, at now: Date, rules: ScoringRules) -> DayScore {
        let statuses = Prayer.allCases.map { log.status(of: $0, in: day, at: now) }
        let onTime = statuses.filter { $0 == .prayed(.onTime) }.count
        let late = statuses.filter { $0 == .prayed(.late) }.count
        let bonus = onTime == Prayer.allCases.count ? rules.allOnTimeBonus : 0
        return DayScore(
            day: DayKey(day),
            points: onTime * rules.onTimePoints + late * rules.latePoints + bonus,
            prayedCount: onTime + late,
            onTimeCount: onTime,
            isComplete: onTime + late == Prayer.allCases.count,
            isClosed: now >= day.nextFajr
        )
    }
}

extension DayKey {
    /// The calendar day after this one.
    var next: DayKey {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
        let following = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        return DayKey(year: following.year!, month: following.month!, day: following.day!)
    }
}
