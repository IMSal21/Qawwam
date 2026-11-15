import Foundation
import QawwamCore
import Testing

@testable import Qawwam

@MainActor
private final class Clock {
    var now: Date
    init(_ now: Date) { self.now = now }
}

private func riyadh(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Riyadh")!
    return calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
}

@MainActor
@Suite struct TodayStoreTests {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let defaults = UserDefaults(suiteName: UUID().uuidString)!

    private func makeStore(_ clock: Clock) throws -> TodayStore {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = FilePrayerLogStore(fileURL: folder.appendingPathComponent("prayer-log.json"))
        return TodayStore(store: file, defaults: defaults, words: Words(.arabic), clock: { clock.now })
    }

    @Test func theFirstLaunchDayIsRemembered() throws {
        let clock = Clock(riyadh(10, 15, 20))
        _ = try makeStore(clock)

        clock.now = riyadh(12, 9, 0)
        let later = try makeStore(clock)

        #expect(later.firstDay == DayKey(year: 2026, month: 11, day: 10))
        #expect(later.days.count == 3)
    }

    @Test func loggingIsSavedAndSurvivesARestart() throws {
        let clock = Clock(riyadh(10, 15, 20))
        let store = try makeStore(clock)

        store.markPrayed(.asr, inCongregation: true)

        #expect(store.state.rows[2].pill == .onTime)
        #expect(store.state.rows[2].inCongregation)
        let restarted = try makeStore(clock)
        #expect(restarted.state.rows[2].pill == .onTime)
        #expect(restarted.state.rows[2].inCongregation)
    }

    @Test func undoTimingAndCongregationAreSaved() throws {
        let clock = Clock(riyadh(10, 15, 20))
        let store = try makeStore(clock)
        store.markPrayed(.dhuhr, inCongregation: false)
        #expect(store.state.rows[1].pill == .late)

        store.setTiming(.onTime, for: .dhuhr)
        store.toggleCongregation(for: .dhuhr)
        #expect(try makeStore(clock).state.rows[1].pill == .onTime)
        #expect(try makeStore(clock).state.rows[1].inCongregation)

        store.undo(.dhuhr)
        #expect(try makeStore(clock).state.rows[1].pill == .notLoggedLate)
    }

    @Test func refreshReadsTheClockAgain() throws {
        let clock = Clock(riyadh(10, 15, 20))
        let store = try makeStore(clock)
        #expect(store.state.rows[3].pill == .upcoming)

        clock.now = riyadh(10, 17, 30)
        store.refresh()

        #expect(store.state.rows[3].pill == .due)
    }
}
