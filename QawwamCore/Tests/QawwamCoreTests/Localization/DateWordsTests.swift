import Testing

@testable import QawwamCore

@Suite struct DateWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)

    // Pairs from the official Riyadh 2027 export.
    static let newYear2027 = DayKey(year: 2027, month: 1, day: 1)  // 23 / 7 / 1448
    static let firstOfRamadan = DayKey(year: 2027, month: 2, day: 8)  // 1 / 9 / 1448
    static let eidAlAdha = DayKey(year: 2027, month: 5, day: 16)  // 10 / 12 / 1448

    @Test func hijriDatesMatchTheOfficialCalendar() {
        #expect(Self.arabic.hijri(HijriDate(Self.newYear2027)) == "23 رجب 1448 هـ")
        #expect(Self.arabic.hijri(HijriDate(Self.firstOfRamadan)) == "1 رمضان 1448 هـ")
        #expect(Self.arabic.hijri(HijriDate(Self.eidAlAdha)) == "10 ذو الحجة 1448 هـ")
        #expect(Self.english.hijri(HijriDate(Self.newYear2027)) == "23 Rajab 1448 AH")
        #expect(Self.english.hijri(HijriDate(Self.firstOfRamadan)) == "1 Ramadan 1448 AH")
        #expect(Self.english.hijri(HijriDate(Self.eidAlAdha)) == "10 Dhu al-Hijjah 1448 AH")
    }

    @Test func allTwelveHijriMonths() {
        let arabic = (1...12).map { Self.arabic.hijri(HijriDate(year: 1447, month: $0, day: 12)) }
        #expect(
            arabic == [
                "12 محرم 1447 هـ", "12 صفر 1447 هـ", "12 ربيع الأول 1447 هـ", "12 ربيع الآخر 1447 هـ",
                "12 جمادى الأولى 1447 هـ", "12 جمادى الآخرة 1447 هـ", "12 رجب 1447 هـ", "12 شعبان 1447 هـ",
                "12 رمضان 1447 هـ", "12 شوال 1447 هـ", "12 ذو القعدة 1447 هـ", "12 ذو الحجة 1447 هـ",
            ])
        let english = (1...12).map { Self.english.hijri(HijriDate(year: 1447, month: $0, day: 12)) }
        #expect(
            english == [
                "12 Muharram 1447 AH", "12 Safar 1447 AH", "12 Rabi' al-Awwal 1447 AH", "12 Rabi' al-Akhir 1447 AH",
                "12 Jumada al-Ula 1447 AH", "12 Jumada al-Akhirah 1447 AH", "12 Rajab 1447 AH",
                "12 Sha'ban 1447 AH", "12 Ramadan 1447 AH", "12 Shawwal 1447 AH", "12 Dhu al-Qa'dah 1447 AH",
                "12 Dhu al-Hijjah 1447 AH",
            ])
    }

    @Test func gregorianDates() {
        #expect(Self.arabic.gregorian(DayKey(year: 2026, month: 1, day: 1)) == "1 يناير 2026م")
        #expect(Self.english.gregorian(DayKey(year: 2026, month: 1, day: 1)) == "1 January 2026")
        let arabic = (1...12).map { Self.arabic.gregorian(DayKey(year: 2027, month: $0, day: 15)) }
        #expect(
            arabic == [
                "15 يناير 2027م", "15 فبراير 2027م", "15 مارس 2027م", "15 أبريل 2027م", "15 مايو 2027م",
                "15 يونيو 2027م", "15 يوليو 2027م", "15 أغسطس 2027م", "15 سبتمبر 2027م", "15 أكتوبر 2027م",
                "15 نوفمبر 2027م", "15 ديسمبر 2027م",
            ])
        #expect(Self.english.gregorian(DayKey(year: 2027, month: 12, day: 31)) == "31 December 2027")
    }

    @Test func weekdaysFromSunday() {
        // 2026-11-08 is a Sunday.
        let week = (0..<7).map { DayKey(year: 2026, month: 11, day: 8).adding(days: $0) }
        #expect(
            week.map(Self.arabic.weekday) == ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"])
        #expect(
            week.map(Self.english.weekday) == [
                "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
            ])
        #expect(Self.arabic.weekday(Self.newYear2027) == "الجمعة")
    }
}
