import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

/// Today's plot (day 0) at `now`, built from the score of `log`.
private func plot(_ log: PrayerLog, at now: Date) -> Plot {
    let score = Scoring.score(log, days: F.days(1), at: now).days[0]
    let hijri = HijriDate(year: 1447, month: 7, day: 12)
    return Plot(score: score, hijri: hijri, isToday: true, position: PlotPosition(row: 0, column: 4))
}

@Suite struct PlotTests {
    @Test func noPrayersYetIsBareSoil() {
        let today = plot(PrayerLog(), at: F.at(0, 5, 30))

        #expect(today.stage == 0)
        #expect(today.state == .growing)
        #expect(today.artName == "soil")
    }

    @Test(arguments: 1...4)
    func eachPrayerGrowsThePalmOneStage(prayed: Int) {
        var log = PrayerLog()
        for prayer in Prayer.allCases.prefix(prayed) {
            F.pray(prayer, on: 0, in: &log)
        }

        let today = plot(log, at: F.at(0, 23))

        #expect(today.stage == prayed)
        #expect(today.state == .growing)
        #expect(today.artName == "palm.stage\(prayed)")
    }

    @Test func prayersGrowThePalmInAnyOrder() {
        var log = PrayerLog()
        F.pray(.maghrib, on: 0, in: &log)
        F.pray(.fajr, on: 0, .late, in: &log)

        #expect(plot(log, at: F.at(0, 18)).stage == 2)
    }

    @Test func allFiveOnTimeBearsFruit() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)

        let today = plot(log, at: F.at(0, 20))

        #expect(today.stage == 5)
        #expect(today.state == .fruiting)
        #expect(today.artName == "palm.stage5.fruit")
    }

    @Test func allFiveWithOneLateIsAFullPalmWithoutFruit() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)
        try! log.setTiming(.late, for: .dhuhr, in: F.day(0), at: F.at(0, 20))

        let today = plot(log, at: F.at(0, 20))

        #expect(today.state == .grown)
        #expect(today.artName == "palm.stage5")
    }

    @Test func aClosedDayWithAMissedPrayerWiltsAtItsStage() {
        var log = PrayerLog()
        for prayer in Prayer.allCases.prefix(3) {
            F.pray(prayer, on: 0, in: &log)
        }

        let missed = plot(log, at: F.at(1, 5, 20))

        #expect(missed.stage == 3)
        #expect(missed.state == .wilted)
        #expect(missed.artName == "palm.stage3.wilted")
    }

    @Test func aClosedDayWithNothingPrayedIsDrySoil() {
        let missed = plot(PrayerLog(), at: F.at(1, 6))

        #expect(missed.state == .wilted)
        #expect(missed.artName == "soil.dry")
    }

    @Test func undoAndTimingChangesUpdateThePlot() {
        var log = PrayerLog()
        F.prayAll(on: [0], .late, in: &log)
        for prayer in Prayer.allCases {
            try! log.setTiming(.onTime, for: prayer, in: F.day(0), at: F.at(0, 21))
        }
        #expect(plot(log, at: F.at(0, 21)).state == .fruiting)

        try! log.unmark(.isha, in: F.day(0), at: F.at(0, 21))

        #expect(plot(log, at: F.at(0, 21)).artName == "palm.stage4")
    }

    @Test func thePlotKeepsItsDatesAndPlace() {
        let today = plot(PrayerLog(), at: F.at(0, 12))

        #expect(today.day == DayKey(year: 2026, month: 1, day: 1))
        #expect(today.hijri == HijriDate(year: 1447, month: 7, day: 12))
        #expect(today.isToday)
        #expect(today.position == PlotPosition(row: 0, column: 4))
    }
}
