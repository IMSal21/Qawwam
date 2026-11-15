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

private func onTime(_ prayer: Prayer, in day: PrayerDay) -> Date {
    day.time(of: prayer).addingTimeInterval(300)
}

private func late(_ prayer: Prayer, in day: PrayerDay) -> Date {
    day.window(for: prayer).end.addingTimeInterval(600)
}

/// The farm mockup's month, Jumada al-Ula 1448 (12 Oct to 10 Nov 2026). The user started on day 4.
/// Day 17 has Maghrib and Isha missed. The listed days are all on time; the others have one prayer late.
/// Today is day 30, at 3:20 PM: Fajr on time, Dhuhr late, Asr due.
private let fruitDays: Set = [4, 6, 7, 9, 11, 12, 14, 16, 19, 20, 22, 24, 26, 28, 29]

private func mockupMonth() throws -> (PrayerLog, [PrayerDay], Date) {
    let first = DayKey(year: 2026, month: 10, day: 15)
    let all = try days(from: first, through: DayKey(year: 2026, month: 11, day: 10))
    var log = PrayerLog()
    for (offset, day) in all.dropLast().enumerated() {
        let hijriDay = offset + 4
        for (index, prayer) in Prayer.allCases.enumerated() {
            if hijriDay == 17 && index >= 3 { continue }
            let isLate = !fruitDays.contains(hijriDay) && hijriDay != 17 && index == hijriDay % 5
            try log.markPrayed(prayer, in: day, at: isLate ? late(prayer, in: day) : onTime(prayer, in: day))
        }
    }
    let today = all.last!
    try log.markPrayed(.fajr, in: today, at: onTime(.fajr, in: today), inCongregation: true)
    try log.markPrayed(.dhuhr, in: today, at: riyadhTime(11, 10, 15, 0))
    return (log, all, riyadhTime(11, 10, 15, 20))
}

@Suite struct FarmScreenStateTests {
    @Test func mockupHeaderInArabic() throws {
        let (log, days, now) = try mockupMonth()

        let state = FarmScreenState(log: log, days: days, words: Words(.arabic), now: now, selected: nil)

        #expect(state.title == "مزرعتي")
        #expect(state.monthText == "جمادى الأولى 1448")
        #expect(state.palmsText == "25 نخلة")
        #expect(state.fruitText == "15 مثمرة")
        #expect(state.nextBuildingText == "التالي: الفناء بعد 18 يومًا")
        #expect(state.buildings == [.well, .farmhouse])
        #expect(state.plots.count == 30)
        #expect(state.plots.filter { $0.state == .unused }.count == 3)
        #expect(state.plots.filter { $0.state == .wilted }.map(\.hijri.day) == [17])
        #expect(state.sceneLabel.hasPrefix("مزرعة ثلاثية الأبعاد"))
    }

    @Test func todayIsSelectedByDefault() throws {
        let (log, days, now) = try mockupMonth()

        let card = FarmScreenState(log: log, days: days, words: Words(.arabic), now: now, selected: nil).selected

        #expect(card.day == DayKey(year: 2026, month: 11, day: 10))
        #expect(card.hijriText == "30 جمادى الأولى")
        #expect(card.gregorianText == "10 نوفمبر 2026م")
        #expect(card.isToday)
        #expect(card.todayText == "اليوم")
        #expect(card.state == .growing)
        #expect(card.statusText == "نبتة تنمو · المرحلة 2 من 5")
        #expect(card.chips.map(\.name) == ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"])
        #expect(card.chips.map(\.segment) == [.onTime, .late, .due, .upcoming, .upcoming])
        #expect(card.chips[0].label == "الفجر: في وقتها")
        #expect(card.prayer == .asr)
        #expect(card.prayButtonText == "صلّيت العصر")
    }

    @Test func everyKindOfDay() throws {
        let (log, days, now) = try mockupMonth()
        func card(_ month: Int, _ day: Int) -> FarmScreenState.DayCard {
            FarmScreenState(
                log: log, days: days, words: Words(.arabic), now: now,
                selected: DayKey(year: 2026, month: month, day: day)
            ).selected
        }

        let wilted = card(10, 28)
        #expect(wilted.hijriText == "17 جمادى الأولى")
        #expect(wilted.state == .wilted)
        #expect(wilted.statusText == "ذابلة · فاتت صلاتان")
        #expect(wilted.chips.map(\.segment) == [.onTime, .onTime, .onTime, .missed, .missed])
        #expect(!wilted.isToday)
        #expect(wilted.prayButtonText == nil)

        #expect(card(10, 15).statusText == "نخلة مثمرة · الخمس في وقتها")
        #expect(card(10, 15).state == .fruiting)
        #expect(card(10, 16).statusText == "نخلة كاملة · صلّيت الخمس")
        #expect(card(10, 16).chips.map(\.segment) == [.late, .onTime, .onTime, .onTime, .onTime])
        #expect(card(10, 13).statusText == "قبل بدايتك · أرض فارغة")
        #expect(card(10, 13).chips.isEmpty)
    }

    @Test func aDayStillToCome() throws {
        let today = DayKey(year: 2026, month: 11, day: 1)
        let all = try days(from: today, through: today)

        let card = FarmScreenState(
            log: PrayerLog(), days: all, words: Words(.english), now: riyadhTime(11, 1, 13, 0),
            selected: DayKey(year: 2026, month: 11, day: 5)
        ).selected

        #expect(card.state == .future)
        #expect(card.statusText == "Still to come · not started yet")
        #expect(card.chips.isEmpty)
        #expect(card.prayButtonText == nil)
    }

    @Test func thePrayButtonPrefersThePrayerInItsTime() throws {
        let today = DayKey(year: 2026, month: 11, day: 1)
        let all = try days(from: today, through: today)
        let day = all[0]
        let now = day.time(of: .asr).addingTimeInterval(600)

        let card = FarmScreenState(log: PrayerLog(), days: all, words: Words(.english), now: now, selected: nil)
            .selected

        #expect(card.chips.map(\.segment) == [.due, .due, .due, .upcoming, .upcoming])
        #expect(card.prayer == .asr)
        #expect(card.prayButtonText == "Prayed Asr")
        #expect(card.statusText == "Growing · stage 0 of 5")
    }

    @Test func thePrayButtonFallsBackToAnEarlierUnloggedPrayer() throws {
        let today = DayKey(year: 2026, month: 11, day: 1)
        let all = try days(from: today, through: today)
        let day = all[0]
        var log = PrayerLog()
        try log.markPrayed(.asr, in: day, at: onTime(.asr, in: day))

        let now = onTime(.asr, in: day)

        let card = FarmScreenState(log: log, days: all, words: Words(.english), now: now, selected: nil).selected

        #expect(card.prayer == .fajr)
        #expect(card.prayButtonText == "Prayed Fajr")
    }

    @Test func nextBuilding() {
        let words = Words(.arabic)
        #expect(FarmScreenState.nextBuildingText(unlocked: [], streak: 0, words: words) == "التالي: البئر بعد 3 أيام")
        #expect(
            FarmScreenState.nextBuildingText(unlocked: [.well], streak: 0, words: words)
                == "التالي: البيت النجدي بعد 7 أيام")
        #expect(
            FarmScreenState.nextBuildingText(unlocked: [.well, .farmhouse, .courtyard, .gate], streak: 41, words: words)
                == "التالي: المسجد بعد 59 يومًا")
        #expect(FarmScreenState.nextBuildingText(unlocked: Building.allCases, streak: 120, words: words) == nil)
    }

    @Test func englishHeader() throws {
        let (log, days, now) = try mockupMonth()

        let state = FarmScreenState(log: log, days: days, words: Words(.english), now: now, selected: nil)

        #expect(state.title == "My farm")
        #expect(state.monthText == "Jumada al-Ula 1448")
        #expect(state.palmsText == "25 palms")
        #expect(state.fruitText == "15 fruiting")
        #expect(state.nextBuildingText == "Next: Courtyard in 18 days")
        #expect(state.selected.prayButtonText == "Prayed Asr")
    }
}
