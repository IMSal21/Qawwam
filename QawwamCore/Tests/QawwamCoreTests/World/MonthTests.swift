import Foundation
import Testing

@testable import QawwamCore

/// Gregorian day → official Umm al-Qura date, from the Riyadh 2027 export.
private func officialHijriDates() throws -> [(DayKey, HijriDate)] {
    let url = try #require(
        Bundle.module.url(forResource: "riyadh-2027", withExtension: "csv", subdirectory: "Fixtures/prayer-times"))
    let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n").dropFirst()

    let parser = DateFormatter()
    parser.locale = Locale(identifier: "en_US_POSIX")
    parser.timeZone = TimeZone(identifier: "UTC")
    parser.dateFormat = "MMMM d, yyyy"

    return try lines.map { line in
        // Day,"Month d, yyyy",d / m / yyyy AH,...
        let quoted = line.split(separator: "\"")
        let gregorian = try #require(parser.date(from: String(quoted[1])))
        let hijriText = quoted[2].split(separator: ",")[0].replacingOccurrences(of: "AH", with: "")
        let parts = hijriText.split(separator: "/").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        try #require(parts.count == 3)
        let day = DayKey(noon: gregorian.addingTimeInterval(12 * 3600))
        return (day, HijriDate(year: parts[2], month: parts[1], day: parts[0]))
    }
}

/// An empty farm: month layout doesn't depend on the log.
private let emptyFarm = FarmBuilder.farm(PrayerLog(), days: [], at: Date(timeIntervalSince1970: 0))

@Suite struct MonthTests {
    @Test func everyDayOf2027MatchesTheOfficialHijriCalendar() throws {
        let official = try officialHijriDates()

        let wrong = official.filter { HijriDate($0.0) != $0.1 }

        #expect(official.count == 365)
        #expect(wrong.isEmpty, "\(wrong.count) days differ, first: \(wrong.first.map { "\($0.0)" } ?? "-")")
    }

    @Test func monthLengthsMatchTheOfficialCalendar() throws {
        let official = try officialHijriDates()
        // Months that lie wholly inside 2027: every month after the first one and before the last one.
        let months = Dictionary(grouping: official, by: { [$0.1.year, $0.1.month] })
        let first = official.first!.1
        let last = official.last!.1
        let whole = months.filter {
            $0.key != [first.year, first.month] && $0.key != [last.year, last.month]
        }

        for (_, days) in whole {
            let month = emptyFarm.month(containing: days[0].0)
            #expect(month.count == days.count)
            #expect(month.map(\.day) == days.map(\.0))
        }
        #expect(Set(whole.values.map(\.count)).isSubset(of: [29, 30]))
    }

    @Test func ramadan1448IsOneMonthInOrder() throws {
        let ramadan = try officialHijriDates().filter { $0.1.year == 1448 && $0.1.month == 9 }

        let month = emptyFarm.month(containing: ramadan[10].0)

        #expect(month.map(\.hijri.day) == Array(1...ramadan.count))
        #expect(month.allSatisfy { $0.hijri.month == 9 && $0.hijri.year == 1448 })
        #expect(month.first?.day == ramadan.first?.0)
    }

    @Test func plotsAreLaidOutByWeekWithSundayFirst() throws {
        let ramadan = try officialHijriDates().filter { $0.1.year == 1448 && $0.1.month == 9 }
        let month = emptyFarm.month(containing: ramadan[0].0)
        let firstColumn = ramadan[0].0.weekdayIndex

        for (offset, plot) in month.enumerated() {
            #expect(plot.position == PlotPosition(row: (firstColumn + offset) / 7, column: (firstColumn + offset) % 7))
        }
        #expect(month[0].position.column == firstColumn)
    }
}
