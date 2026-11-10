import Foundation
import Testing

@testable import QawwamCore

/// One row of an official yearly timetable export.
private struct ReferenceDay {
    let date: DateComponents
    let hijriMonth: Int
    /// Minutes after local midnight, keyed by column name.
    let minutes: [String: Int]
}

private let columns = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
private let saudi = TimeZone(identifier: "Asia/Riyadh")!

private func loadReference(_ name: String) throws -> [ReferenceDay] {
    let url = try #require(
        Bundle.module.url(forResource: name, withExtension: "csv", subdirectory: "Fixtures/prayer-times"))
    let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n").dropFirst()

    let parser = DateFormatter()
    parser.locale = Locale(identifier: "en_US_POSIX")
    parser.timeZone = TimeZone(identifier: "UTC")
    parser.dateFormat = "MMMM d, yyyy"

    return try lines.map { line in
        // Day,"Month d, yyyy",d / m / yyyy AH,Fajr,Sunrise,Dhuhr,Asr,Maghrib,Isha
        let quoted = line.split(separator: "\"")
        let gregorian = try #require(parser.date(from: String(quoted[1])))
        let rest = quoted[2].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let hijriMonth = try #require(Int(rest[0].split(separator: "/")[1].trimmingCharacters(in: .whitespaces)))

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        var minutes: [String: Int] = [:]
        for (column, text) in zip(columns, rest.dropFirst()) {
            minutes[column] = try minutesAfterMidnight(text)
        }
        return ReferenceDay(
            date: utc.dateComponents([.year, .month, .day], from: gregorian), hijriMonth: hijriMonth,
            minutes: minutes)
    }
}

/// "05:15 AM" -> 315
private func minutesAfterMidnight(_ text: String) throws -> Int {
    let parts = text.split(separator: " ")
    let clock = parts[0].split(separator: ":").compactMap { Int($0) }
    let hour = clock[0] % 12 + (parts[1] == "PM" ? 12 : 0)
    return hour * 60 + clock[1]
}

private func minutesAfterMidnight(_ date: Date) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = saudi
    let parts = calendar.dateComponents([.hour, .minute], from: date)
    return parts.hour! * 60 + parts.minute!
}

@Suite struct GoldenTimesTests {
    static let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)

    @Test func riyadh2027MatchesTheOfficialCalendarWithinOneMinute() throws {
        let reference = try loadReference("riyadh-2027")
        #expect(reference.count == 365)

        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        var mismatches: [String] = []
        var histogram: [String: [Int: Int]] = [:]
        for row in reference {
            let day = try calculator.day(row.date, at: Self.riyadh, in: saudi)
            let computed = [
                "Fajr": day.time(of: .fajr), "Sunrise": day.sunrise, "Dhuhr": day.time(of: .dhuhr),
                "Asr": day.time(of: .asr), "Maghrib": day.time(of: .maghrib), "Isha": day.time(of: .isha),
            ]
            for column in columns {
                let difference = minutesAfterMidnight(computed[column]!) - row.minutes[column]!
                histogram[column, default: [:]][difference, default: 0] += 1
                if abs(difference) > 1 {
                    let sign = difference > 0 ? "+" : ""
                    mismatches.append("\(row.date.month!)/\(row.date.day!) \(column) \(sign)\(difference)m")
                }
            }
        }

        let spread = columns.map { column in
            let counts = histogram[column, default: [:]].sorted { $0.key < $1.key }
            return "\(column) " + counts.map { "\($0.key)m×\($0.value)" }.joined(separator: " ")
        }
        let listed = mismatches.prefix(60).joined(separator: ", ")
        #expect(
            mismatches.isEmpty,
            "\(mismatches.count) mismatches: \(listed). Spread: \(spread.joined(separator: "; "))"
        )
    }

    @Test func ramadanDetectionMatchesTheOfficialHijriCalendar() throws {
        let reference = try loadReference("riyadh-2027")

        let wrong = reference.filter { PrayerTimesCalculator.isRamadan($0.date, in: saudi) != ($0.hijriMonth == 9) }

        #expect(wrong.isEmpty, "Ramadan mismatch on: \(wrong.map { "\($0.date.month!)/\($0.date.day!)" })")
    }
}
