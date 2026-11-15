import Foundation

/// Everything the today screen shows, worked out from the log and the time. No UI.
public struct TodayState: Equatable, Sendable {
    /// What a row lets the user do.
    public enum Action: Hashable, Sendable {
        case pray, undo, setOnTime, setLate, toggleCongregation
    }

    /// How a row's status pill looks.
    public enum Pill: Equatable, Sendable {
        case onTime, late, due, notLoggedLate, upcoming, missed
    }

    public struct Row: Equatable, Sendable, Identifiable {
        public let prayer: Prayer
        public let name: String
        public let time: String
        public let pill: Pill
        public let pillText: String
        public let actions: Set<Action>
        public let inCongregation: Bool
        public let congregationText: String
        public let startsText: String
        public let undoLabel: String

        public var id: Prayer { prayer }
    }

    public let title: String
    public let dateLine: String
    public let gregorianLine: String
    public let streakText: String
    public let ring: [RingSegment]
    public let prayedText: String
    public let ofFiveText: String
    public let ringLabel: String
    public let heroTitle: String
    public let heroSubtitle: String
    public let pointsText: String
    public let rows: [Row]

    /// `days` runs from the user's first day up to the prayer day containing `now`, which is the last one.
    public init(log: PrayerLog, days: [PrayerDay], words: Words, city: String, now: Date) {
        let day = days.last!
        let key = DayKey(day)
        let score = Scoring.score(log, days: days, at: now)
        let todayScore = score.days.last { $0.day == key }

        title = words.today
        dateLine = "\(words.weekday(key)) \(words.hijri(HijriDate(key)))"
        gregorianLine = "\(words.gregorian(key)) · \(city)"
        streakText = words.days(score.currentStreak)
        ring = FarmBuilder.ring(log, for: day, at: now)
        let prayed = todayScore?.prayedCount ?? 0
        prayedText = words.number(prayed)
        ofFiveText = words.ofFivePrayers
        ringLabel = words.prayedOutOfFive(prayed)
        pointsText = words.pointsToday(todayScore?.points ?? 0)

        rows = Prayer.allCases.map { Self.row($0, log: log, day: day, key: key, words: words, now: now) }

        let current = Prayer.allCases.first { prayer in
            log.status(of: prayer, in: day, at: now) == .due && now < day.window(for: prayer).end
        }
        let upcoming = Prayer.allCases.first { log.status(of: $0, in: day, at: now) == .upcoming }
        if let current {
            let end = day.window(for: current).end
            heroTitle = words.timeFor(words.name(of: current, on: key))
            heroSubtitle = words.remaining(
                minutes: Self.minutes(from: now, to: end), before: Self.nameAfter(current, key: key, words: words))
        } else if let upcoming {
            let start = day.time(of: upcoming)
            heroTitle = words.next(words.name(of: upcoming, on: key))
            heroSubtitle = words.starts(at: words.time(start), in: Self.minutes(from: now, to: start))
        } else {
            heroTitle = words.allPrayedToday
            heroSubtitle = ""
        }
    }

    private static func row(
        _ prayer: Prayer, log: PrayerLog, day: PrayerDay, key: DayKey, words: Words, now: Date
    ) -> Row {
        let name = words.name(of: prayer, in: day, log: log, at: now)
        let window = day.window(for: prayer)
        let entry = log.entry(for: prayer, in: day)
        let status = log.status(of: prayer, in: day, at: now)

        let pill: Pill
        let pillText: String
        var actions: Set<Action> = []
        switch status {
        case .prayed(.onTime):
            pill = .onTime
            pillText = words.status(status)
            actions = [.undo, .toggleCongregation]
            if let entry, day.timing(of: prayer, loggedAt: entry.loggedAt) == .late { actions.insert(.setLate) }
        case .prayed(.late):
            pill = .late
            pillText = words.status(status)
            actions = [.undo, .toggleCongregation, .setOnTime]
        case .due where now < window.end:
            pill = .due
            pillText = words.due(until: words.time(window.end))
            actions = [.pray]
        case .due:
            pill = .notLoggedLate
            pillText = words.notLoggedCountsLate
            actions = [.pray]
        case .upcoming:
            pill = .upcoming
            pillText = words.status(status)
        case .missed:
            pill = .missed
            pillText = words.status(status)
        }

        let inCongregation = entry?.inCongregation ?? false
        return Row(
            prayer: prayer,
            name: name,
            time: words.time(day.time(of: prayer)),
            pill: pill,
            pillText: pillText,
            actions: actions,
            inCongregation: inCongregation,
            congregationText: inCongregation ? words.inCongregation : words.addCongregation,
            startsText: words.starts(at: words.time(day.time(of: prayer))),
            undoLabel: words.undoLabel(name)
        )
    }

    /// What ends `prayer`'s window: sunrise after Fajr, the next prayer otherwise, and Fajr after Isha.
    private static func nameAfter(_ prayer: Prayer, key: DayKey, words: Words) -> String {
        switch prayer {
        case .fajr: words.sunrise
        case .dhuhr: words.name(of: .asr, on: key)
        case .asr: words.name(of: .maghrib, on: key)
        case .maghrib: words.name(of: .isha, on: key)
        case .isha: words.name(of: .fajr, on: key)
        }
    }

    private static func minutes(from start: Date, to end: Date) -> Int {
        max(Int(end.timeIntervalSince(start) / 60), 0)
    }
}
