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
    /// Jumu'ah prayed on time is worth this many on-time prayers.
    public var jumuahMultiplier: Int
    /// Taken away the first Friday in a row that Jumu'ah is missed.
    public var jumuahMissedPenalty: Int
    /// Added to the penalty for each further Friday missed in a row.
    public var jumuahPenaltyStep: Int

    public static let standard = ScoringRules(
        onTimePoints: 10, latePoints: 5, allOnTimeBonus: 25,
        streakBonuses: [7: 50, 30: 100, 40: 150, 100: 300],
        badgeStreaks: [3, 7, 30, 40, 100],
        jumuahMultiplier: 5, jumuahMissedPenalty: 50, jumuahPenaltyStep: 10
    )
}

/// How one prayer day went.
public struct DayScore: Equatable, Sendable {
    public let day: DayKey
    /// The day's prayers (Jumu'ah on time counting several times) plus the all-on-time bonus.
    public let points: Int
    /// Taken away when Jumu'ah's time has passed without it: 0, or 50, 60, 70 … for Fridays missed in a row.
    public let jumuahPenalty: Int
    public let prayedCount: Int
    public let onTimeCount: Int
    /// All five prayed, on time or late.
    public let isComplete: Bool
    /// The next Fajr has begun.
    public let isClosed: Bool
}

public struct Score: Equatable, Sendable {
    /// Day points plus streak bonuses minus Jumu'ah penalties, added up day by day and never below zero.
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
        let penalties = jumuahPenalties(log, days: started, at: now, rules: rules)
        let dayScores = zip(started, penalties).map { day, penalty in
            dayScore(log, for: day, penalty: penalty, at: now, rules: rules)
        }
        let streak = walkStreak(dayScores, rules: rules)
        var total = 0
        for (day, bonus) in zip(dayScores, streak.bonuses) {
            total = max(total + day.points + bonus - day.jumuahPenalty, 0)
        }
        let fajr = walkFajrStreak(log, days: started, at: now)
        return Score(
            totalPoints: total, level: level(forPoints: total), currentStreak: streak.current, bestStreak: streak.best,
            currentFajrStreak: fajr.current, bestFajrStreak: fajr.best, badges: streak.badges, days: dayScores
        )
    }

    /// True on a Friday once Jumu'ah's time (up to Asr) has passed without it being prayed on time.
    /// After that the prayer can only be made up as Dhuhr.
    public static func jumuahMissed(_ log: PrayerLog, in day: PrayerDay, at now: Date) -> Bool {
        DayKey(day).weekdayIndex == 5
            && now >= day.window(for: .dhuhr).end
            && log.status(of: .dhuhr, in: day, at: now) != .prayed(.onTime)
    }

    /// One penalty per day: 0 except on Fridays whose Jumu'ah was missed. The penalty grows by a step for each
    /// Friday missed in a row, and Jumu'ah prayed on time starts the count again.
    private static func jumuahPenalties(
        _ log: PrayerLog, days: [PrayerDay], at now: Date, rules: ScoringRules
    ) -> [Int] {
        var missedInARow = 0
        return days.map { day in
            guard DayKey(day).weekdayIndex == 5 else { return 0 }
            if jumuahMissed(log, in: day, at: now) {
                let penalty = rules.jumuahMissedPenalty + missedInARow * rules.jumuahPenaltyStep
                missedInARow += 1
                return penalty
            }
            if log.status(of: .dhuhr, in: day, at: now) == .prayed(.onTime) { missedInARow = 0 }
            return 0
        }
    }

    /// Level *L* starts at 50 × *L* × (*L* − 1) points: level 2 at 100, level 3 at 300, level 4 at 600.
    public static func level(forPoints points: Int) -> Int {
        var level = 1
        while 50 * (level + 1) * level <= points {
            level += 1
        }
        return level
    }

    /// Walks the days oldest first. A complete day adds one, a closed incomplete day or a missing date resets
    /// to zero, and today, while still open and unfinished, leaves the streak as it is. Each time the streak
    /// reaches a bonus length its bonus is earned that day; badges are the badge lengths ever reached.
    private static func walkStreak(
        _ days: [DayScore], rules: ScoringRules
    ) -> (current: Int, best: Int, bonuses: [Int], badges: [Int]) {
        var current = 0
        var best = 0
        var bonuses: [Int] = []
        var badges = Set<Int>()
        var previous: DayKey?
        for day in days {
            if let previous, previous.next != day.day {
                current = 0
            }
            var bonus = 0
            if day.isComplete {
                current += 1
                best = max(best, current)
                bonus = rules.streakBonuses[current] ?? 0
                if rules.badgeStreaks.contains(current) {
                    badges.insert(current)
                }
            } else if day.isClosed {
                current = 0
            }
            bonuses.append(bonus)
            previous = day.day
        }
        return (current, best, bonuses, badges.sorted())
    }

    /// Days in a row with Fajr prayed on time. Today's Fajr breaks it only once sunrise has passed
    /// without an on-time log.
    private static func walkFajrStreak(_ log: PrayerLog, days: [PrayerDay], at now: Date) -> (current: Int, best: Int) {
        var current = 0
        var best = 0
        var previous: DayKey?
        for day in days {
            let key = DayKey(day)
            if let previous, previous.next != key {
                current = 0
            }
            if log.status(of: .fajr, in: day, at: now) == .prayed(.onTime) {
                current += 1
                best = max(best, current)
            } else if now >= day.sunrise {
                current = 0
            }
            previous = key
        }
        return (current, best)
    }

    private static func startedDays(_ days: [PrayerDay], at now: Date) -> [PrayerDay] {
        var seen = Set<DayKey>()
        let sorted = days.filter { now >= $0.time(of: .fajr) }.sorted { DayKey($0) < DayKey($1) }
        return sorted.filter { seen.insert(DayKey($0)).inserted }
    }

    private static func dayScore(
        _ log: PrayerLog, for day: PrayerDay, penalty: Int, at now: Date, rules: ScoringRules
    ) -> DayScore {
        let statuses = Prayer.allCases.map { log.status(of: $0, in: day, at: now) }
        let onTime = statuses.filter { $0 == .prayed(.onTime) }.count
        let late = statuses.filter { $0 == .prayed(.late) }.count
        let bonus = onTime == Prayer.allCases.count ? rules.allOnTimeBonus : 0
        var jumuah = 0
        if DayKey(day).weekdayIndex == 5 && log.status(of: .dhuhr, in: day, at: now) == .prayed(.onTime) {
            jumuah = (rules.jumuahMultiplier - 1) * rules.onTimePoints
        }
        return DayScore(
            day: DayKey(day),
            points: onTime * rules.onTimePoints + late * rules.latePoints + bonus + jumuah,
            jumuahPenalty: penalty,
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
