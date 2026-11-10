import Foundation

/// How a day's plot looks.
public enum PlotState: Equatable, Sendable {
    /// Today, still open, fewer than five prayed.
    case growing
    /// All five prayed, at least one late.
    case grown
    /// All five prayed on time: the palm carries dates.
    case fruiting
    /// The day closed with a prayer missed. The palm stays at its stage, wilted.
    case wilted
    /// A day that hasn't started yet.
    case future
    /// A day before the user's first day. Bare soil, never wilted.
    case unused
}

/// A date in the Umm al-Qura calendar.
public struct HijriDate: Equatable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
}

/// Where a plot sits on the farm, so the 3D scene can place it.
public struct PlotPosition: Equatable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

/// One prayer day on the farm.
public struct Plot: Equatable, Sendable {
    /// The Gregorian day, shown small.
    public let day: DayKey
    /// The main date.
    public let hijri: HijriDate
    /// Prayers prayed that day, 0 to 5.
    public let stage: Int
    public let state: PlotState
    public let isToday: Bool
    public let position: PlotPosition

    init(day: DayKey, hijri: HijriDate, stage: Int, state: PlotState, isToday: Bool, position: PlotPosition) {
        self.day = day
        self.hijri = hijri
        self.stage = stage
        self.state = state
        self.isToday = isToday
        self.position = position
    }

    init(score: DayScore, hijri: HijriDate, isToday: Bool, position: PlotPosition) {
        let state: PlotState
        if score.isComplete {
            state = score.onTimeCount == Prayer.allCases.count ? .fruiting : .grown
        } else {
            state = score.isClosed ? .wilted : .growing
        }
        self.init(
            day: score.day, hijri: hijri, stage: score.prayedCount, state: state, isToday: isToday,
            position: position)
    }

    /// Every name `artName` can return.
    public static let allArtNames: [String] =
        ["soil", "soil.dry"]
        + (1...5).map { "palm.stage\($0)" }
        + ["palm.stage5.fruit"]
        + (1...4).map { "palm.stage\($0).wilted" }

    /// The 3D model in the app, or the still image in widgets, for this plot.
    public var artName: String {
        switch state {
        case .future, .unused:
            "soil"
        case .wilted:
            stage == 0 ? "soil.dry" : "palm.stage\(stage).wilted"
        case .fruiting:
            "palm.stage\(stage).fruit"
        case .growing, .grown:
            stage == 0 ? "soil" : "palm.stage\(stage)"
        }
    }
}
