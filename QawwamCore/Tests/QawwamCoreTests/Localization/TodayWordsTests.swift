import Testing

@testable import QawwamCore

@Suite struct TodayWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)

    @Test(arguments: [
        (0, "أقل من دقيقة"), (1, "دقيقة واحدة"), (2, "دقيقتان"), (3, "3 دقائق"), (10, "10 دقائق"),
        (11, "11 دقيقة"), (49, "49 دقيقة"), (60, "ساعة"), (61, "ساعة ودقيقة"), (62, "ساعة ودقيقتان"),
        (109, "ساعة و49 دقيقة"), (120, "ساعتان"), (125, "ساعتان و5 دقائق"), (180, "3 ساعات"),
        (660, "11 ساعة"),
    ])
    func arabicDurations(minutes: Int, expected: String) {
        #expect(Self.arabic.duration(minutes: minutes) == expected)
    }

    @Test(arguments: [
        (0, "less than a minute"), (1, "1 min"), (49, "49 min"), (60, "1 hr"), (109, "1 hr 49 min"),
        (120, "2 hr"),
    ])
    func englishDurations(minutes: Int, expected: String) {
        #expect(Self.english.duration(minutes: minutes) == expected)
    }

    @Test func heroPhrases() {
        #expect(Self.arabic.timeFor("العصر") == "حان وقت العصر")
        #expect(Self.arabic.next("المغرب") == "التالي: المغرب")
        #expect(Self.arabic.remaining(minutes: 109, before: "المغرب") == "باقي ساعة و49 دقيقة قبل المغرب")
        #expect(Self.arabic.starts(at: "5:09 م", in: 109) == "يبدأ 5:09 م · بعد ساعة و49 دقيقة")
        #expect(Self.arabic.allPrayedToday == "أتممت صلوات اليوم")

        #expect(Self.english.timeFor("Asr") == "Time for Asr")
        #expect(Self.english.next("Maghrib") == "Next: Maghrib")
        #expect(Self.english.remaining(minutes: 109, before: "Maghrib") == "1 hr 49 min left before Maghrib")
        #expect(Self.english.starts(at: "5:09 PM", in: 109) == "Starts 5:09 PM · in 1 hr 49 min")
        #expect(Self.english.allPrayedToday == "All of today's prayers are done")
    }

    @Test func summaryPhrases() {
        #expect(Self.arabic.today == "اليوم")
        #expect(Self.arabic.ofFivePrayers == "من 5 صلوات")
        #expect(Self.arabic.prayedOutOfFive(2) == "صُلّيت 2 من 5 صلوات اليوم")
        #expect(Self.arabic.pointsToday(15) == "+15 نقطة اليوم")
        #expect(Self.arabic.pointsToday(5) == "+5 نقاط اليوم")
        #expect(Self.arabic.pointsToday(0) == "+0 نقطة اليوم")
        #expect(Self.arabic.riyadh == "الرياض")

        #expect(Self.english.today == "Today")
        #expect(Self.english.ofFivePrayers == "of 5 prayers")
        #expect(Self.english.prayedOutOfFive(2) == "2 of 5 prayers prayed today")
        #expect(Self.english.pointsToday(1) == "+1 point today")
        #expect(Self.english.pointsToday(15) == "+15 points today")
        #expect(Self.english.riyadh == "Riyadh")
    }

    @Test func rowPhrases() {
        #expect(Self.arabic.due(until: "5:09 م") == "حان وقتها · حتى 5:09 م")
        #expect(Self.arabic.starts(at: "5:09 م") == "يبدأ 5:09 م")
        #expect(Self.arabic.notLoggedCountsLate == "لم تُسجَّل · تُحسب متأخرة")
        #expect(Self.arabic.prayed == "صلّيت")
        #expect(Self.arabic.undo == "تراجع")
        #expect(Self.arabic.undoLabel("الظهر") == "تراجع عن تسجيل الظهر")
        #expect(Self.arabic.inCongregation == "في جماعة")
        #expect(Self.arabic.addCongregation == "أضف جماعة")
        #expect(Self.arabic.prayedItOnTime == "صلّيتها في وقتها")
        #expect(Self.arabic.markLate == "أعدها متأخرة")

        #expect(Self.english.due(until: "5:09 PM") == "Time to pray · until 5:09 PM")
        #expect(Self.english.starts(at: "5:09 PM") == "Starts 5:09 PM")
        #expect(Self.english.notLoggedCountsLate == "Not logged · counts as late")
        #expect(Self.english.prayed == "Prayed")
        #expect(Self.english.undo == "Undo")
        #expect(Self.english.undoLabel("Dhuhr") == "Undo Dhuhr")
        #expect(Self.english.inCongregation == "In congregation")
        #expect(Self.english.addCongregation == "Add congregation")
        #expect(Self.english.prayedItOnTime == "I prayed it on time")
        #expect(Self.english.markLate == "Mark as late")
    }

    @Test func tabs() {
        #expect([Self.arabic.today, Self.arabic.farm, Self.arabic.profile] == ["اليوم", "المزرعة", "ملفي"])
        #expect([Self.english.today, Self.english.farm, Self.english.profile] == ["Today", "Farm", "Profile"])
        #expect(Self.arabic.comingSoon == "قريبًا")
        #expect(Self.english.comingSoon == "Coming soon")
    }
}
