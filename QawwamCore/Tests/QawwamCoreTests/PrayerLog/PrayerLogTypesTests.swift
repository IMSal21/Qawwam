import Foundation
import Testing

@testable import QawwamCore

private let midnight = Date(timeIntervalSince1970: 1_767_214_800)  // 2026-01-01 00:00 Asia/Riyadh
private func at(_ hour: Int, _ minute: Int) -> Date {
    midnight.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
}

private let day = PrayerDay(
    date: DateComponents(year: 2026, month: 1, day: 1),
    times: [
        .fajr: at(5, 20), .dhuhr: at(12, 0), .asr: at(15, 10),
        .maghrib: at(17, 30), .isha: at(19, 0),
    ],
    sunrise: at(6, 40),
    nextFajr: at(29, 20)
)

@Suite struct DayKeyTests {
    @Test func keyComesFromThePrayerDaysDate() {
        #expect(DayKey(day) == DayKey(year: 2026, month: 1, day: 1))
    }

    @Test func keysAreOrderedByDate() {
        let keys = [
            DayKey(year: 2027, month: 1, day: 1),
            DayKey(year: 2026, month: 12, day: 31),
            DayKey(year: 2026, month: 2, day: 1),
            DayKey(year: 2026, month: 1, day: 31),
        ]

        #expect(
            keys.sorted() == [
                DayKey(year: 2026, month: 1, day: 31),
                DayKey(year: 2026, month: 2, day: 1),
                DayKey(year: 2026, month: 12, day: 31),
                DayKey(year: 2027, month: 1, day: 1),
            ])
    }

    @Test func keyIsWrittenAsAnIsoDate() {
        #expect(DayKey(year: 2026, month: 3, day: 7).description == "2026-03-07")
        #expect(DayKey("2026-03-07") == DayKey(year: 2026, month: 3, day: 7))
    }

    @Test(arguments: ["", "2026-3", "2026-13-01", "2026-02-30", "26-01-01x", "abcd-ef-gh"])
    func malformedTextIsNotAKey(text: String) {
        #expect(DayKey(text) == nil)
    }

    @Test func keySurvivesAJsonRoundTrip() throws {
        let key = DayKey(year: 2026, month: 11, day: 10)

        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(DayKey.self, from: data)

        #expect(String(decoding: data, as: UTF8.self) == "\"2026-11-10\"")
        #expect(decoded == key)
    }
}

@Suite struct PrayerEntryTests {
    @Test func entrySurvivesAJsonRoundTrip() throws {
        let entry = PrayerEntry(timing: .late, loggedAt: at(16, 3), inCongregation: true)

        let decoded = try JSONDecoder().decode(PrayerEntry.self, from: JSONEncoder().encode(entry))

        #expect(decoded == entry)
    }

    @Test func aNewLogIsEmpty() {
        #expect(PrayerLog().isEmpty)
    }
}
