import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

private let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
private let riyadhTime = TimeZone(identifier: "Asia/Riyadh")!

private func riyadhInstant(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = riyadhTime
    return calendar.date(from: DateComponents(year: 2027, month: month, day: day, hour: hour, minute: minute))!
}

@Suite struct FarmTests {
    @Test func theFarmCarriesTheBuildingsForItsBadges() {
        var log = PrayerLog()
        F.prayAll(on: 0..<7, in: &log)

        let farm = FarmBuilder.farm(log, days: F.days(9), at: F.at(8, 12))

        #expect(farm.buildings == [.well, .farmhouse])
    }

    @Test func aNewFarmHasNoBuildings() {
        #expect(FarmBuilder.farm(PrayerLog(), days: F.days(1), at: F.at(0, 12)).buildings.isEmpty)
    }

    @Test func theArtListHoldsExactlyWhatPlotsCanShow() {
        let reachable: [(PlotState, ClosedRange<Int>)] = [
            (.growing, 0...4), (.grown, 5...5), (.fruiting, 5...5),
            (.wilted, 0...4), (.future, 0...0), (.unused, 0...0),
        ]
        var names = Set<String>()
        for (state, stages) in reachable {
            for stage in stages {
                let plot = Plot(
                    day: DayKey(year: 2027, month: 1, day: 1), hijri: HijriDate(year: 1448, month: 7, day: 23),
                    stage: stage, state: state, isToday: false, position: PlotPosition(row: 0, column: 0))
                names.insert(plot.artName)
            }
        }

        #expect(names == Set(Plot.allArtNames))
        #expect(Plot.allArtNames.count == 12)
        #expect(FarmArt.allNames.count == 12 + Building.allCases.count)
    }

    /// Riyadh from 1 January 2027: all five on time every day, except Asr missed on 15 February.
    /// Read on 20 February at 13:00, in Ramadan 1448, with only Fajr and Dhuhr logged so far.
    @Test func aRealRiyadhRamadan() throws {
        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        let gregorian = Calendar(identifier: .gregorian)
        let start = gregorian.date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 12))!
        let dates = (0..<51).map {
            gregorian.dateComponents([.year, .month, .day], from: gregorian.date(byAdding: .day, value: $0, to: start)!)
        }
        let days = try dates.map { try calculator.day($0, at: riyadh, in: riyadhTime) }
        var log = PrayerLog()
        for day in days {
            let key = DayKey(day)
            for prayer in Prayer.allCases {
                if key == DayKey(year: 2027, month: 2, day: 15), prayer == .asr { continue }
                if key == DayKey(year: 2027, month: 2, day: 20), prayer.rawValue > Prayer.dhuhr.rawValue { continue }
                try log.markPrayed(prayer, in: day, at: day.time(of: prayer).addingTimeInterval(300))
            }
        }
        let now = riyadhInstant(2, 20, 13, 0)

        let farm = FarmBuilder.farm(log, days: days, at: now)
        let month = farm.month(containing: DayKey(year: 2027, month: 2, day: 20))

        #expect(farm.today?.day == DayKey(year: 2027, month: 2, day: 20))
        #expect(farm.today?.stage == 2)
        #expect(farm.ring == [.onTime, .onTime, .upcoming, .upcoming, .upcoming])
        #expect(month.count == 29)
        #expect(month.first?.day == DayKey(year: 2027, month: 2, day: 8))
        #expect(month.allSatisfy { $0.hijri.year == 1448 && $0.hijri.month == 9 })
        let byDay = Dictionary(uniqueKeysWithValues: month.map { ($0.day, $0) })
        #expect(byDay[DayKey(year: 2027, month: 2, day: 14)]?.artName == "palm.stage5.fruit")
        #expect(byDay[DayKey(year: 2027, month: 2, day: 15)]?.artName == "palm.stage4.wilted")
        #expect(byDay[DayKey(year: 2027, month: 2, day: 20)]?.isToday == true)
        #expect(month.filter { $0.day > DayKey(year: 2027, month: 2, day: 20) }.allSatisfy { $0.state == .future })
        // 45 days in a row before the miss: badges 3, 7, 30 and 40, kept after the reset.
        #expect(farm.buildings == [.well, .farmhouse, .courtyard, .gate])
    }
}
