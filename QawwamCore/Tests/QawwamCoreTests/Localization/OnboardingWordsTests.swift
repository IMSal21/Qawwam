import Foundation
import Testing

@testable import QawwamCore

@Suite struct OnboardingWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)

    @Test func progress() {
        #expect(Self.arabic.step(2) == "2 من 3")
        #expect(Self.arabic.stepLabel(2) == "الخطوة 2 من 3")
        #expect(Self.english.step(2) == "2 of 3")
        #expect(Self.english.stepLabel(2) == "Step 2 of 3")
        #expect(Self.arabic.back == "رجوع")
        #expect(Self.arabic.nextStep == "التالي")
        #expect(Self.english.nextStep == "Next")
    }

    @Test func whyStep() {
        #expect(Self.arabic.welcome == "أهلاً بك في قوّام")
        #expect(Self.arabic.whyTitle == "ما الذي جاء بك إلى قوّام؟")
        #expect(Self.arabic.whySubtitle == "اختر كل ما ينطبق عليك. نستخدم إجابتك لنضبط التذكيرات والتحديات لك.")
        let titles: [String] = OnboardingReason.allCases.map(Self.arabic.reasonTitle)
        #expect(
            titles == [
                "أريد أن أصلي الخمس في وقتها", "أجد صعوبة في المحافظة على الخمس", "صلاة الفجر صعبة عليّ",
                "أريد أن أصلي في جماعة أكثر", "أريد أن أرى تقدّمي",
            ])
        let details: [String] = OnboardingReason.allCases.map(Self.arabic.reasonDetail)
        #expect(
            details == [
                "أصلي، لكن أؤخر الصلاة كثيراً", "تفوتني صلاة أو أكثر في بعض الأيام",
                "أحتاج عوناً على القيام لها في وقتها",
                "خصوصاً الفجر والعشاء", "سلسلة أيام، ونقاط، ومزرعة تكبر",
            ])
        #expect(Self.english.reasonTitle(.fajr) == "Fajr is hard for me")
    }

    @Test func cityStep() {
        #expect(Self.arabic.cityTitle == "أين تسكن؟")
        #expect(Self.arabic.citySubtitle == "نحسب مواقيت الصلاة لمدينتك بتقويم أم القرى.")
        #expect(Self.arabic.useMyLocation == "استخدم موقعي الحالي")
        #expect(Self.arabic.searchCity == "ابحث عن مدينتك")
        #expect(Self.arabic.noCityFound == "لم نجد هذه المدينة. جرّب اسماً آخر أو استخدم موقعك.")
        #expect(Self.arabic.region(.riyadh) == "منطقة الرياض")
        #expect(Self.arabic.region(.eastern) == "المنطقة الشرقية")
        #expect(Self.english.region(.riyadh) == "Riyadh Region")
        let jeddah = SaudiCities.city(id: "jeddah")!
        #expect(Self.arabic.cityName(jeddah) == "جدة")
        #expect(Self.english.cityName(jeddah) == "Jeddah")
        #expect(Self.arabic.todaysTimes(in: jeddah) == "مواقيت اليوم في جدة · أم القرى")
        #expect(Self.english.todaysTimes(in: jeddah) == "Today's times in Jeddah · Umm al-Qura")
    }

    @Test func shortTimeHasNoSuffix() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh")!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 4, minute: 48))!
        let afternoon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 14, minute: 45))!
        #expect(Self.arabic.shortTime(morning) == "4:48")
        #expect(Self.arabic.shortTime(afternoon) == "2:45")
    }

    @Test func farmStep() {
        #expect(Self.arabic.farmTitle == "مزرعتك تكبر مع صلاتك")
        #expect(
            Self.arabic.farmSubtitle == "لماذا مزرعة؟ لأن رؤية أثر التزامك يكبر يوماً بعد يوم تجعل المحافظة أسهل.")
        #expect(Self.arabic.growthOnTime == "5 في وقتها")
        #expect(
            Self.arabic.growthLabel
                == "مراحل النخلة: أرض، ثم بذرة، ثم نبتة، ثم فسيلة، ثم نخلة صغيرة، ثم نخلة كاملة مثمرة")
        let points: [String] = Self.arabic.farmPoints.map { $0.bold + $0.rest }
        #expect(
            points == [
                "كل صلاة تسقي نخلة اليوم فتكبر مرحلة، حتى تكتمل بالصلوات الخمس.",
                "الخمس في وقتها تجعل النخلة تثمر تمراً.",
                "إن فاتتك صلاة تذبل نخلة ذلك اليوم، وتبقى في مزرعتك تذكيراً صادقاً.",
                "حافظ على سلسلتك لتبني بئراً، ثم بيتاً نجدياً، وصولاً إلى المسجد بعد 100 يوم.",
            ])
        #expect(Self.english.farmPoints.count == 4)
        #expect(Self.arabic.hadith == "سُئل النبي ﷺ: أيّ العمل أحبّ إلى الله؟ قال: «الصلاة على وقتها».")
        #expect(Self.arabic.hadithSource == "صحيح البخاري")
        #expect(Self.arabic.startMyFarm == "ابدأ مزرعتي")
        #expect(Self.english.startMyFarm == "Start my farm")
    }

    @Test func locationFailure() {
        #expect(Self.arabic.locationFailed == "لم نتمكن من معرفة موقعك. اختر مدينتك من القائمة.")
        #expect(Self.english.locationFailed == "We couldn't get your location. Pick your city from the list.")
    }
}
