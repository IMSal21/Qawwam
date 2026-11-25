import Foundation

/// One line on the farm step: a bold start and the rest of the sentence.
public struct FarmPoint: Equatable, Sendable {
    public let bold: String
    public let rest: String
}

/// Words for the three onboarding steps.
extension Words {
    // MARK: Every step

    public func step(_ number: Int) -> String {
        pick("\(self.number(number)) من 3", "\(self.number(number)) of 3")
    }

    public func stepLabel(_ number: Int) -> String {
        pick("الخطوة \(self.number(number)) من 3", "Step \(self.number(number)) of 3")
    }

    public var back: String { pick("رجوع", "Back") }
    public var nextStep: String { pick("التالي", "Next") }

    // MARK: Step 1

    public var welcome: String { pick("أهلاً بك في قوّام", "Welcome to Qawwam") }
    public var whyTitle: String { pick("ما الذي جاء بك إلى قوّام؟", "What brings you to Qawwam?") }
    public var whySubtitle: String {
        pick(
            "اختر كل ما ينطبق عليك. نستخدم إجابتك لنضبط التذكيرات والتحديات لك.",
            "Choose all that apply. We use your answers to tune your reminders and challenges.")
    }

    public func reasonTitle(_ reason: OnboardingReason) -> String {
        switch reason {
        case .onTime: pick("أريد أن أصلي الخمس في وقتها", "I want to pray all five on time")
        case .keepFive: pick("أجد صعوبة في المحافظة على الخمس", "I find it hard to keep up all five")
        case .fajr: pick("صلاة الفجر صعبة عليّ", "Fajr is hard for me")
        case .jamaah: pick("أريد أن أصلي في جماعة أكثر", "I want to pray in congregation more")
        case .progress: pick("أريد أن أرى تقدّمي", "I want to see my progress")
        }
    }

    public func reasonDetail(_ reason: OnboardingReason) -> String {
        switch reason {
        case .onTime: pick("أصلي، لكن أؤخر الصلاة كثيراً", "I pray, but I often delay it")
        case .keepFive: pick("تفوتني صلاة أو أكثر في بعض الأيام", "I miss one or more prayers some days")
        case .fajr: pick("أحتاج عوناً على القيام لها في وقتها", "I need help getting up for it on time")
        case .jamaah: pick("خصوصاً الفجر والعشاء", "Especially Fajr and Isha")
        case .progress: pick("سلسلة أيام، ونقاط، ومزرعة تكبر", "A streak, points, and a farm that grows")
        }
    }

    // MARK: Step 2

    public var cityTitle: String { pick("أين تسكن؟", "Where do you live?") }
    public var citySubtitle: String {
        pick(
            "نحسب مواقيت الصلاة لمدينتك بتقويم أم القرى.",
            "We work out your city's prayer times with the Umm al-Qura calendar.")
    }
    public var useMyLocation: String { pick("استخدم موقعي الحالي", "Use my current location") }
    public var searchCity: String { pick("ابحث عن مدينتك", "Search for your city") }
    public var noCityFound: String {
        pick(
            "لم نجد هذه المدينة. جرّب اسماً آخر أو استخدم موقعك.",
            "We couldn't find that city. Try another name or use your location.")
    }
    public var locationFailed: String {
        pick(
            "لم نتمكن من معرفة موقعك. اختر مدينتك من القائمة.",
            "We couldn't get your location. Pick your city from the list.")
    }

    /// "منطقة الرياض" / "Riyadh Region". The Eastern Province is "المنطقة الشرقية".
    public func region(_ region: SaudiRegion) -> String {
        switch region {
        case .eastern: pick("المنطقة الشرقية", "Eastern Province")
        default: pick("منطقة \(region.arabicName)", "\(region.englishName) Region")
        }
    }

    public func cityName(_ city: City) -> String {
        pick(city.arabicName, city.englishName)
    }

    public func todaysTimes(in city: City) -> String {
        pick("مواقيت اليوم في \(city.arabicName) · أم القرى", "Today's times in \(city.englishName) · Umm al-Qura")
    }

    /// 12-hour clock in Riyadh time without ص/م: "4:48".
    public func shortTime(_ instant: Date) -> String {
        let parts = Self.riyadhCalendar.dateComponents([.hour, .minute], from: instant)
        let hour = parts.hour!
        let minute = parts.minute!
        return "\(hour % 12 == 0 ? 12 : hour % 12):\(minute < 10 ? "0" : "")\(minute)"
    }

    // MARK: Step 3

    public var farmTitle: String { pick("مزرعتك تكبر مع صلاتك", "Your farm grows with your prayers") }
    public var farmSubtitle: String {
        pick(
            "لماذا مزرعة؟ لأن رؤية أثر التزامك يكبر يوماً بعد يوم تجعل المحافظة أسهل.",
            "Why a farm? Because seeing your commitment grow day by day makes it easier to keep.")
    }
    public var growthOnTime: String { pick("5 في وقتها", "5 on time") }
    public var growthLabel: String {
        pick(
            "مراحل النخلة: أرض، ثم بذرة، ثم نبتة، ثم فسيلة، ثم نخلة صغيرة، ثم نخلة كاملة مثمرة",
            "Palm stages: soil, then a seed, a sprout, a sapling, a young palm, and a full palm with dates")
    }

    public var farmPoints: [FarmPoint] {
        switch language {
        case .arabic:
            [
                FarmPoint(bold: "كل صلاة تسقي نخلة اليوم", rest: " فتكبر مرحلة، حتى تكتمل بالصلوات الخمس."),
                FarmPoint(bold: "الخمس في وقتها", rest: " تجعل النخلة تثمر تمراً."),
                FarmPoint(bold: "إن فاتتك صلاة", rest: " تذبل نخلة ذلك اليوم، وتبقى في مزرعتك تذكيراً صادقاً."),
                FarmPoint(
                    bold: "حافظ على سلسلتك", rest: " لتبني بئراً، ثم بيتاً نجدياً، وصولاً إلى المسجد بعد 100 يوم."),
            ]
        case .english:
            [
                FarmPoint(
                    bold: "Every prayer waters today's palm", rest: ", so it grows a stage until all five complete it."),
                FarmPoint(bold: "All five on time", rest: " make the palm bear dates."),
                FarmPoint(
                    bold: "If you miss a prayer",
                    rest: ", that day's palm wilts and stays in your farm as an honest reminder."),
                FarmPoint(
                    bold: "Keep your streak",
                    rest: " to build a well, then a Najdi house, all the way to the mosque after 100 days."),
            ]
        }
    }

    public var hadith: String {
        pick(
            "سُئل النبي ﷺ: أيّ العمل أحبّ إلى الله؟ قال: «الصلاة على وقتها».",
            "The Prophet ﷺ was asked: which deed is most beloved to Allah? He said: “Prayer at its time.”")
    }
    public var hadithSource: String { pick("صحيح البخاري", "Sahih al-Bukhari") }
    public var startMyFarm: String { pick("ابدأ مزرعتي", "Start my farm") }
}
