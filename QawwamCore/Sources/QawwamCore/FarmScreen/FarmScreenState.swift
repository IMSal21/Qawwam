import Foundation

/// Everything the farm screen shows apart from the 3D shapes, worked out from the log and the time. No UI.
public struct FarmScreenState: Equatable, Sendable {
    /// One prayer of the selected day.
    public struct Chip: Equatable, Sendable, Identifiable {
        public let prayer: Prayer
        public let name: String
        public let segment: RingSegment
        public let label: String

        public var id: Prayer { prayer }
    }

    /// The card under the farm, for the selected day.
    public struct DayCard: Equatable, Sendable {
        public let day: DayKey
        public let hijriText: String
        public let gregorianText: String
        public let isToday: Bool
        public let todayText: String
        public let state: PlotState
        public let statusText: String
        /// Empty for days before the user started and days still to come.
        public let chips: [Chip]
        /// The prayer the button logs, while one is due today.
        public let prayer: Prayer?
        public let prayButtonText: String?
    }

    public let title: String
    public let monthText: String
    public let palmsText: String
    public let fruitText: String
    /// Hidden once every building is unlocked.
    public let nextBuildingText: String?
    public let sceneLabel: String
    /// Every day of the Hijri month, placed like a calendar page.
    public let plots: [Plot]
    public let buildings: [Building]
    public let selected: DayCard

    /// `days` runs from the user's first day up to the prayer day containing `now`, which is the last one.
    /// `selected` is the tapped day; nil selects today.
    public init(log: PrayerLog, days: [PrayerDay], words: Words, now: Date, selected: DayKey?) {
        let farm = FarmBuilder.farm(log, days: days, at: now)
        let score = Scoring.score(log, days: days, at: now)
        let latest = DayKey(days.last!)
        let plots = farm.month(containing: latest)
        let hijri = HijriDate(latest)

        title = words.myFarm
        monthText = words.hijriMonth(hijri)
        palmsText = words.palms(plots.filter { $0.state == .grown || $0.state == .fruiting }.count)
        fruitText = words.fruiting(plots.filter { $0.state == .fruiting }.count)
        nextBuildingText = Self.nextBuildingText(
            unlocked: farm.buildings, streak: score.currentStreak, words: words)
        sceneLabel = words.farmSceneLabel(hijri)
        self.plots = plots
        buildings = farm.buildings

        let key = selected ?? latest
        let plot = plots.first { $0.day == key } ?? farm.week(containing: key).first { $0.day == key }!
        let day = days.first { DayKey($0) == key }
        self.selected = Self.card(plot, day: day, log: log, words: words, now: now)
    }

    static func nextBuildingText(unlocked: [Building], streak: Int, words: Words) -> String? {
        guard let next = Building.allCases.first(where: { !unlocked.contains($0) }) else { return nil }
        return words.nextBuilding(next, inDays: max(next.badge - streak, 1))
    }

    private static func card(_ plot: Plot, day: PrayerDay?, log: PrayerLog, words: Words, now: Date) -> DayCard {
        let segments = day.map { FarmBuilder.ring(log, for: $0, at: now) } ?? []
        var chips: [Chip] = []
        if let day, plot.state != .unused, plot.state != .future {
            chips = zip(Prayer.allCases, segments).map { prayer, segment in
                let name = words.name(of: prayer, in: day, log: log, at: now)
                let status = words.status(log.status(of: prayer, in: day, at: now))
                return Chip(
                    prayer: prayer, name: name, segment: segment, label: words.chipLabel(name, status: status))
            }
        }

        let statusText: String
        switch plot.state {
        case .unused: statusText = words.beforeYouStarted
        case .future: statusText = words.dayToCome
        case .growing: statusText = words.growing(stage: plot.stage)
        case .grown: statusText = words.fullPalm
        case .fruiting: statusText = words.fruitingPalm
        case .wilted: statusText = words.wilted(missed: segments.filter { $0 == .missed }.count)
        }

        var prayer: Prayer?
        var prayButtonText: String?
        if plot.isToday, let day {
            let due = Prayer.allCases.filter { log.status(of: $0, in: day, at: now) == .due }
            prayer = due.first { now < day.window(for: $0).end } ?? due.first
            prayButtonText = prayer.map { words.prayed(words.name(of: $0, in: day, log: log, at: now)) }
        }

        return DayCard(
            day: plot.day,
            hijriText: words.hijriDayMonth(plot.hijri),
            gregorianText: words.gregorian(plot.day),
            isToday: plot.isToday,
            todayText: words.today,
            state: plot.state,
            statusText: statusText,
            chips: chips,
            prayer: prayer,
            prayButtonText: prayButtonText
        )
    }
}
