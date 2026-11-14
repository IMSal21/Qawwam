import Foundation
import Testing

@testable import QawwamCore

private let saudi = TimeZone(identifier: "Asia/Riyadh")!
private let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
private let calculator = PrayerTimesCalculator(settings: .ummAlQura)

private func riyadhTime(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = saudi
    return calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
}

/// Prayer days from `first` up to and including `last` (both in November 2026, or October for negatives).
private func days(from first: DayKey, through last: DayKey) throws -> [PrayerDay] {
    var result: [PrayerDay] = []
    var key = first
    while key <= last {
        let components = DateComponents(year: key.year, month: key.month, day: key.day)
        result.append(try calculator.day(components, at: riyadh, in: saudi))
        key = key.adding(days: 1)
    }
    return result
}

private func logAt(_ prayer: Prayer, in day: PrayerDay, plus minutes: Int) -> Date {
    day.time(of: prayer).addingTimeInterval(TimeInterval(minutes * 60))
}

/// The mockup's scene: Tuesday 10 Nov 2026, 3:20 PM in Riyadh, after 12 complete days.
/// Fajr on time in congregation, Dhuhr late, Asr due, Maghrib and Isha upcoming.
private func mockupScene() throws -> (PrayerLog, [PrayerDay], Date) {
    let today = DayKey(year: 2026, month: 11, day: 10)
    let all = try days(from: today.adding(days: -12), through: today)
    var log = PrayerLog()
    for day in all.dropLast() {
        for prayer in Prayer.allCases {
            try log.markPrayed(prayer, in: day, at: logAt(prayer, in: day, plus: 5))
        }
    }
    let now = riyadhTime(11, 10, 15, 20)
    let last = all.last!
    try log.markPrayed(.fajr, in: last, at: logAt(.fajr, in: last, plus: 10), inCongregation: true)
    try log.markPrayed(.dhuhr, in: last, at: riyadhTime(11, 10, 15, 0))
    return (log, all, now)
}

@Suite struct TodayStateTests {
    @Test func mockupSceneInArabic() throws {
        let (log, days, now) = try mockupScene()
        let words = Words(.arabic)
        let day = days.last!

        let state = TodayState(log: log, days: days, words: words, city: words.riyadh, now: now)

        #expect(state.title == "اليوم")
        #expect(state.dateLine == "الثلاثاء 30 جمادى الأولى 1448 هـ")
        #expect(state.gregorianLine == "10 نوفمبر 2026م · الرياض")
        #expect(state.streakText == "12 يومًا")
        #expect(state.ring == [.onTime, .late, .due, .upcoming, .upcoming])
        #expect(state.prayedText == "2")
        #expect(state.ringLabel == "صُلّيت 2 من 5 صلوات اليوم")
        #expect(state.heroTitle == "حان وقت العصر")
        let left = Int(day.time(of: .maghrib).timeIntervalSince(now) / 60)
        #expect(state.heroSubtitle == words.remaining(minutes: left, before: "المغرب"))
        #expect(state.pointsText == "+15 نقطة اليوم")

        #expect(state.rows.map(\.name) == ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"])
        #expect(state.rows.map(\.time) == Prayer.allCases.map { words.time(day.time(of: $0)) })
        #expect(state.rows.map(\.pill) == [.onTime, .late, .due, .upcoming, .upcoming])
        #expect(state.rows[0].pillText == "في وقتها")
        #expect(state.rows[1].pillText == "متأخرة")
        #expect(state.rows[2].pillText == "حان وقتها · حتى \(words.time(day.time(of: .maghrib)))")
        #expect(state.rows[3].pillText == "قادمة")
        #expect(state.rows[3].startsText == "يبدأ \(words.time(day.time(of: .maghrib)))")
    }

    @Test func rowActionsFollowTheStatus() throws {
        let (log, days, now) = try mockupScene()
        let state = TodayState(log: log, days: days, words: Words(.arabic), city: "الرياض", now: now)

        #expect(state.rows[0].actions == [.undo, .toggleCongregation])
        #expect(state.rows[0].inCongregation)
        #expect(state.rows[0].congregationText == "في جماعة")
        #expect(state.rows[1].actions == [.undo, .toggleCongregation, .setOnTime])
        #expect(state.rows[1].congregationText == "أضف جماعة")
        #expect(state.rows[2].actions == [.pray])
        #expect(state.rows[3].actions.isEmpty)
        #expect(state.rows[1].undoLabel == "تراجع عن تسجيل الظهر")
    }

    @Test func aLatePrayerSwitchedToOnTimeOffersMarkLate() throws {
        var (log, days, now) = try mockupScene()
        try log.setTiming(.onTime, for: .dhuhr, in: days.last!, at: now)

        let state = TodayState(log: log, days: days, words: Words(.arabic), city: "الرياض", now: now)

        #expect(state.rows[1].pill == .onTime)
        #expect(state.rows[1].actions == [.undo, .toggleCongregation, .setLate])
    }

    @Test func anEarlierPrayerNotLoggedCountsAsLate() throws {
        var (log, days, now) = try mockupScene()
        try log.unmark(.dhuhr, in: days.last!, at: now)

        let state = TodayState(log: log, days: days, words: Words(.arabic), city: "الرياض", now: now)

        #expect(state.rows[1].pill == .notLoggedLate)
        #expect(state.rows[1].pillText == "لم تُسجَّل · تُحسب متأخرة")
        #expect(state.rows[1].actions == [.pray])
        #expect(state.heroTitle == "حان وقت العصر")
        #expect(state.pointsText == "+10 نقطة اليوم")
    }

    @Test func whenTheCurrentPrayerIsLoggedTheHeroShowsTheNextOne() throws {
        var (log, days, now) = try mockupScene()
        let day = days.last!
        try log.markPrayed(.asr, in: day, at: now)
        let words = Words(.arabic)

        let state = TodayState(log: log, days: days, words: words, city: "الرياض", now: now)

        let until = Int(day.time(of: .maghrib).timeIntervalSince(now) / 60)
        #expect(state.heroTitle == "التالي: المغرب")
        #expect(state.heroSubtitle == words.starts(at: words.time(day.time(of: .maghrib)), in: until))
        #expect(state.pointsText == "+25 نقطة اليوم")
        #expect(state.prayedText == "3")
    }

    @Test func allFiveOnTimeShowsDoneAndTheBonus() throws {
        let today = DayKey(year: 2026, month: 11, day: 10)
        let all = try days(from: today, through: today)
        let day = all[0]
        var log = PrayerLog()
        for prayer in Prayer.allCases {
            try log.markPrayed(prayer, in: day, at: logAt(prayer, in: day, plus: 5))
        }
        let now = logAt(.isha, in: day, plus: 10)

        let state = TodayState(log: log, days: all, words: Words(.english), city: "Riyadh", now: now)

        #expect(state.heroTitle == "All of today's prayers are done")
        #expect(state.heroSubtitle == "")
        #expect(state.pointsText == "+75 points today")
        #expect(state.streakText == "1 day")
    }

    @Test func fajrDueShowsTimeLeftBeforeSunrise() throws {
        let today = DayKey(year: 2026, month: 11, day: 10)
        let all = try days(from: today, through: today)
        let day = all[0]
        let now = logAt(.fajr, in: day, plus: 10)
        let words = Words(.english)

        let state = TodayState(log: PrayerLog(), days: all, words: words, city: "Riyadh", now: now)

        let left = Int(day.sunrise.timeIntervalSince(now) / 60)
        #expect(state.heroTitle == "Time for Fajr")
        #expect(state.heroSubtitle == words.remaining(minutes: left, before: "Sunrise"))
        #expect(state.rows[0].pillText == "Time to pray · until \(words.time(day.sunrise))")
        #expect(state.streakText == "0 days")
        #expect(state.pointsText == "+0 points today")
    }

    @Test func dhuhrIsJumuahOnFriday() throws {
        let friday = DayKey(year: 2026, month: 11, day: 13)
        let all = try days(from: friday, through: friday)
        let now = logAt(.fajr, in: all[0], plus: 10)

        let state = TodayState(log: PrayerLog(), days: all, words: Words(.arabic), city: "الرياض", now: now)

        #expect(state.rows[1].name == "الجمعة")
        #expect(state.heroTitle == "حان وقت الفجر")
        #expect(state.rows[1].startsText == "يبدأ \(Words(.arabic).time(all[0].time(of: .dhuhr)))")
    }
}
