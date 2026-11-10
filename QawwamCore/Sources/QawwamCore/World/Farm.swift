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

extension FarmBuilder {
    /// The farm for `days` (every prayer day from the user's first day up to the one containing `now`).
    public static func farm(_ log: PrayerLog, days: [PrayerDay], at now: Date) -> Farm {
        let score = Scoring.score(log, days: days, at: now)
        let latest = score.days.last
        let todayKey = latest.flatMap { $0.isClosed ? nil : $0.day }
        let latestDay = latest.flatMap { key in days.first { DayKey($0) == key.day } }
        let noDay = Array(repeating: RingSegment.upcoming, count: Prayer.allCases.count)
        let segments = latestDay.map { ring(log, for: $0, at: now) } ?? noDay
        return Farm(
            scores: Dictionary(score.days.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first }),
            firstDay: score.days.first?.day,
            lastDay: latest?.day,
            todayKey: todayKey,
            ring: segments,
            buildings: Building.unlocked(by: score.badges)
        )
    }
}

/// Everything the farm screen and the widgets draw.
public struct Farm: Equatable, Sendable {
    let scores: [DayKey: DayScore]
    let firstDay: DayKey?
    let lastDay: DayKey?
    let todayKey: DayKey?
    /// Five segments for today, Fajr first.
    public let ring: [RingSegment]
    /// Buildings unlocked by streak badges, in unlock order.
    public let buildings: [Building]

    /// Today's plot, while today is still open.
    public var today: Plot? {
        todayKey.map { plot(for: $0, position: PlotPosition(row: 0, column: $0.weekdayIndex)) }
    }

    /// Seven plots from Sunday to Saturday around `day`.
    public func week(containing day: DayKey) -> [Plot] {
        let sunday = day.adding(days: -day.weekdayIndex)
        return (0..<7).map { plot(for: sunday.adding(days: $0), position: PlotPosition(row: 0, column: $0)) }
    }

    /// Every day of the Umm al-Qura month around `day`, in order. Rows are weeks of the month and columns
    /// are weekdays, Sunday first, like a calendar page.
    public func month(containing day: DayKey) -> [Plot] {
        let first = day.adding(days: 1 - HijriDate(day).day)
        let length = HijriDate.ummAlQura.range(of: .day, in: .month, for: day.noon)!.count
        let firstColumn = first.weekdayIndex
        return (0..<length).map { offset in
            let cell = firstColumn + offset
            return plot(for: first.adding(days: offset), position: PlotPosition(row: cell / 7, column: cell % 7))
        }
    }

    func plot(for key: DayKey, position: PlotPosition) -> Plot {
        let hijri = HijriDate(key)
        let isToday = key == todayKey
        if let score = scores[key] {
            return Plot(score: score, hijri: hijri, isToday: isToday, position: position)
        }
        let state: PlotState
        if let firstDay, let lastDay {
            state = key < firstDay ? .unused : key > lastDay ? .future : .wilted
        } else {
            state = .future
        }
        return Plot(day: key, hijri: hijri, stage: 0, state: state, isToday: isToday, position: position)
    }
}

/// Every asset name the farm can ask for, so the artist knows exactly what to make.
public enum FarmArt {
    public static var allNames: [String] {
        Plot.allArtNames + Building.allCases.map(\.artName)
    }
}
