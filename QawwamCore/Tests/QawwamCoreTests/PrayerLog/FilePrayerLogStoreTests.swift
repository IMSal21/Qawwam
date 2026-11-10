import Foundation
import Testing

@testable import QawwamCore

private let midnight = Date(timeIntervalSince1970: 1_767_214_800)  // 2026-01-01 00:00 Asia/Riyadh
private func at(_ hour: Int, _ minute: Int) -> Date {
    midnight.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
}

private func prayerDay(_ dayOfMonth: Int) -> PrayerDay {
    let offset = (dayOfMonth - 1) * 24
    return PrayerDay(
        date: DateComponents(year: 2026, month: 1, day: dayOfMonth),
        times: [
            .fajr: at(offset + 5, 20), .dhuhr: at(offset + 12, 0), .asr: at(offset + 15, 10),
            .maghrib: at(offset + 17, 30), .isha: at(offset + 19, 0),
        ],
        sunrise: at(offset + 6, 40),
        nextFajr: at(offset + 29, 20)
    )
}

/// A fresh, empty folder for each test.
private func makeFolder() throws -> URL {
    let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("prayer-log-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
}

@Suite struct FilePrayerLogStoreTests {
    @Test func savedLogLoadsBackIdentically() throws {
        let file = try makeFolder().appendingPathComponent("log.json")
        let store = FilePrayerLogStore(fileURL: file)
        var log = PrayerLog()
        try log.markPrayed(.fajr, in: prayerDay(1), at: at(5, 31).addingTimeInterval(0.125), inCongregation: true)
        try log.markPrayed(.dhuhr, in: prayerDay(1), at: at(16, 0))
        try log.markPrayed(.isha, in: prayerDay(2), at: at(24 + 21, 45))

        try store.save(log)
        let loaded = try store.load()

        #expect(loaded == log)
        #expect(loaded.entry(for: .dhuhr, in: prayerDay(1))?.timing == .late)
    }

    @Test func aMissingFileLoadsAsAnEmptyLog() throws {
        let file = try makeFolder().appendingPathComponent("log.json")

        #expect(try FilePrayerLogStore(fileURL: file).load() == PrayerLog())
    }

    @Test func aCorruptFileThrowsAndIsLeftUntouched() throws {
        let file = try makeFolder().appendingPathComponent("log.json")
        let garbage = Data("{\"days\": not json".utf8)
        try garbage.write(to: file)

        #expect(throws: (any Error).self) {
            try FilePrayerLogStore(fileURL: file).load()
        }
        #expect(try Data(contentsOf: file) == garbage)
    }

    @Test func aFileWithAnUnknownPrayerThrows() throws {
        let file = try makeFolder().appendingPathComponent("log.json")
        let json = """
            {"version": 1, "days": {"2026-01-01": {
                "duha": {"timing": "onTime", "loggedAt": 0, "inCongregation": false}
            }}}
            """
        try Data(json.utf8).write(to: file)

        #expect(throws: (any Error).self) {
            try FilePrayerLogStore(fileURL: file).load()
        }
    }

    @Test func theFileNamesDaysAndPrayersInPlainText() throws {
        let file = try makeFolder().appendingPathComponent("log.json")
        var log = PrayerLog()
        try log.markPrayed(.maghrib, in: prayerDay(1), at: at(17, 40))

        try FilePrayerLogStore(fileURL: file).save(log)
        let text = try String(contentsOf: file, encoding: .utf8)

        #expect(text.contains("\"2026-01-01\""))
        #expect(text.contains("\"maghrib\""))
        #expect(text.contains("\"version\" : 1"))
    }

    @Test func savingAgainReplacesTheFileAndLeavesNoTemporaryFiles() throws {
        let folder = try makeFolder()
        let file = folder.appendingPathComponent("log.json")
        let store = FilePrayerLogStore(fileURL: file)
        var log = PrayerLog()
        try log.markPrayed(.asr, in: prayerDay(1), at: at(16, 0))
        try store.save(log)

        try log.unmark(.asr, in: prayerDay(1), at: at(16, 5))
        try store.save(log)

        #expect(try store.load() == PrayerLog())
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == ["log.json"])
    }
}
