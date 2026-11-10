import Foundation
import Testing

@testable import QawwamCore

/// Every string the module can produce for one language, over a wide sample of inputs.
private func everyString(_ words: Words) -> [String] {
    let tuesday = DayKey(year: 2026, month: 11, day: 10)
    let friday = DayKey(year: 2026, month: 11, day: 13)
    var all: [String] = [words.sunrise]
    for day in [tuesday, friday] { all += Prayer.allCases.map { words.name(of: $0, on: day) } }
    let statuses: [PrayerStatus] = [.upcoming, .due, .prayed(.onTime), .prayed(.late), .missed]
    all += statuses.map(words.status)
    all += [0, 1, 2, 3, 10, 11, 99, 100, 101, 2390].flatMap { [words.days($0), words.points($0), words.number($0)] }
    all += (1...10).map(words.level)
    all += (1...12).map { words.hijri(HijriDate(year: 1448, month: $0, day: 1)) }
    all += (1...12).map { words.gregorian(DayKey(year: 2027, month: $0, day: 1)) }
    all += (0..<7).map { words.weekday(tuesday.adding(days: $0)) }
    all += stride(from: 0, to: 86_400, by: 1_800).map { words.time(Date(timeIntervalSince1970: Double($0))) }
    all += [3, 7, 30, 40, 100].map(words.badge)
    all += Building.allCases.map(words.building)
    return all
}

private func has(_ text: String, in range: ClosedRange<UInt32>) -> Bool {
    text.unicodeScalars.contains { range.contains($0.value) }
}

@Suite struct ScriptTests {
    @Test func arabicStringsHaveNoLatinLetters() {
        let latin = everyString(Words(.arabic)).filter { $0.contains(where: { $0.isASCII && $0.isLetter }) }
        #expect(latin.isEmpty, "\(latin)")
    }

    @Test func englishStringsHaveNoArabicLetters() {
        let arabic = everyString(Words(.english)).filter { has($0, in: 0x0600...0x06FF) }
        #expect(arabic.isEmpty, "\(arabic)")
    }

    @Test func digitsAreWesternInBothLanguages() {
        for language in AppLanguage.allCases {
            let eastern = everyString(Words(language)).filter {
                has($0, in: 0x0660...0x0669) || has($0, in: 0x06F0...0x06F9)
            }
            #expect(eastern.isEmpty, "\(language): \(eastern)")
        }
    }
}
