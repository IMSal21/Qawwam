import Testing

@testable import QawwamCore

@Suite struct PrayerWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)
    /// 2026-11-10 is a Tuesday; 2026-11-13 is a Friday.
    static let tuesday = DayKey(year: 2026, month: 11, day: 10)
    static let friday = DayKey(year: 2026, month: 11, day: 13)

    @Test func arabicIsTheDefaultLanguageAndHasTwoCodes() {
        #expect(AppLanguage.allCases == [.arabic, .english])
        #expect(AppLanguage.arabic.rawValue == "ar")
        #expect(AppLanguage.english.rawValue == "en")
    }

    @Test func arabicPrayerNames() {
        let names = Prayer.allCases.map { Self.arabic.name(of: $0, on: Self.tuesday) }
        #expect(names == ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"])
        #expect(Self.arabic.sunrise == "الشروق")
    }

    @Test func englishPrayerNames() {
        let names = Prayer.allCases.map { Self.english.name(of: $0, on: Self.tuesday) }
        #expect(names == ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"])
        #expect(Self.english.sunrise == "Sunrise")
    }

    @Test func dhuhrIsJumuahOnFridaysOnly() {
        #expect(Self.arabic.name(of: .dhuhr, on: Self.friday) == "الجمعة")
        #expect(Self.english.name(of: .dhuhr, on: Self.friday) == "Jumu'ah")
        #expect(Self.arabic.name(of: .asr, on: Self.friday) == "العصر")
        #expect(Self.english.name(of: .fajr, on: Self.friday) == "Fajr")
        for offset in [-5, -4, -3, -2, -1, 1] {
            let day = Self.friday.adding(days: offset)
            #expect(Self.arabic.name(of: .dhuhr, on: day) == "الظهر", "\(day)")
            #expect(Self.english.name(of: .dhuhr, on: day) == "Dhuhr", "\(day)")
        }
    }

    @Test func arabicStatuses() {
        #expect(Self.arabic.status(.upcoming) == "قادمة")
        #expect(Self.arabic.status(.due) == "حان وقتها")
        #expect(Self.arabic.status(.prayed(.onTime)) == "في وقتها")
        #expect(Self.arabic.status(.prayed(.late)) == "متأخرة")
        #expect(Self.arabic.status(.missed) == "فائتة")
    }

    @Test func englishStatuses() {
        #expect(Self.english.status(.upcoming) == "Upcoming")
        #expect(Self.english.status(.due) == "Time to pray")
        #expect(Self.english.status(.prayed(.onTime)) == "On time")
        #expect(Self.english.status(.prayed(.late)) == "Late")
        #expect(Self.english.status(.missed) == "Missed")
    }
}
