import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

@Suite struct WeekTests {
    @Test func aWeekRunsFromSundayToSaturday() {
        let farm = FarmBuilder.farm(PrayerLog(), days: F.days(10), at: F.at(9, 12))

        let week = farm.week(containing: DayKey(year: 2026, month: 1, day: 7))  // a Wednesday

        #expect(week.map(\.day.day) == [4, 5, 6, 7, 8, 9, 10])
        #expect(week.map(\.position) == (0..<7).map { PlotPosition(row: 0, column: $0) })
    }

    @Test func todayIsMarkedAndLaterDaysAreFuture() {
        var log = PrayerLog()
        F.pray(.fajr, on: 5, in: &log)

        let week = FarmBuilder.farm(log, days: F.days(6), at: F.at(5, 8))
            .week(containing: DayKey(year: 2026, month: 1, day: 6))

        #expect(week.map(\.isToday) == [false, false, true, false, false, false, false])
        #expect(week[2].stage == 1)
        #expect(week[2].state == .growing)
        #expect(week[3...].allSatisfy { $0.state == .future && $0.artName == "soil" })
    }

    @Test func daysBeforeTheFirstDayAreUnusedNotWilted() {
        // 2026-01-01 is a Thursday, so Sunday to Wednesday come before the first day.
        let week = FarmBuilder.farm(PrayerLog(), days: F.days(1), at: F.at(0, 12))
            .week(containing: DayKey(year: 2026, month: 1, day: 1))

        #expect(week.map(\.day.day) == [28, 29, 30, 31, 1, 2, 3])
        #expect(week[..<4].allSatisfy { $0.state == .unused && $0.artName == "soil" })
        #expect(week[4].isToday)
    }

    @Test func closedDaysShowHowTheyWent() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)
        F.prayAll(on: [1], .late, in: &log)
        F.pray(.fajr, on: 2, in: &log)

        let week = FarmBuilder.farm(log, days: F.days(4), at: F.at(3, 12))
            .week(containing: DayKey(year: 2026, month: 1, day: 1))

        #expect(week[4].state == .fruiting)
        #expect(week[5].state == .grown)
        #expect(week[6].state == .wilted)
        #expect(week[6].artName == "palm.stage1.wilted")
    }

    @Test func aDateMissingFromTheHistoryIsAWiltedEmptyPlot() {
        let days = [F.day(0), F.day(2)]

        let week = FarmBuilder.farm(PrayerLog(), days: days, at: F.at(2, 12))
            .week(containing: DayKey(year: 2026, month: 1, day: 1))

        #expect(week[5].day.day == 2)
        #expect(week[5].state == .wilted)
        #expect(week[5].artName == "soil.dry")
    }

    @Test func todaysPlotAndRingAreOnTheFarm() {
        var log = PrayerLog()
        F.pray(.fajr, on: 1, in: &log)

        let farm = FarmBuilder.farm(log, days: F.days(2), at: F.at(1, 13))

        #expect(farm.today?.day == DayKey(year: 2026, month: 1, day: 2))
        #expect(farm.today?.stage == 1)
        #expect(farm.ring == [.onTime, .due, .upcoming, .upcoming, .upcoming])
    }

    @Test func plotsCarryTheirHijriDate() {
        let farm = FarmBuilder.farm(PrayerLog(), days: F.days(1), at: F.at(0, 12))

        // 2026-01-01 falls in Rajab 1447. Exact days are checked against the official calendar in MonthTests.
        #expect(farm.today?.hijri.year == 1447)
        #expect(farm.today?.hijri.month == 7)
    }
}
