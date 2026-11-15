/// Words for the farm screen.
extension Words {
    // MARK: Header

    public var myFarm: String { pick("مزرعتي", "My farm") }

    /// "جمادى الأولى 1448".
    public func hijriMonth(_ date: HijriDate) -> String {
        "\(hijriMonthName(date)) \(date.year)"
    }

    /// "30 جمادى الأولى".
    public func hijriDayMonth(_ date: HijriDate) -> String {
        "\(number(date.day)) \(hijriMonthName(date))"
    }

    /// "25 نخلة" / "25 palms".
    public func palms(_ count: Int) -> String {
        switch language {
        case .arabic: ArabicCountedNoun.palm.counted(count, digits: number(count))
        case .english: "\(number(count)) \(count == 1 ? "palm" : "palms")"
        }
    }

    /// "15 مثمرة" / "15 fruiting".
    public func fruiting(_ count: Int) -> String {
        switch language {
        case .arabic: ArabicCountedNoun.fruiting.counted(count, digits: number(count))
        case .english: "\(number(count)) fruiting"
        }
    }

    /// "التالي: الفناء بعد 18 يومًا" / "Next: Courtyard in 18 days".
    public func nextBuilding(_ building: Building, inDays count: Int) -> String {
        switch language {
        case .arabic:
            let days = ArabicCountedNoun.dayAfter.counted(count, digits: number(count))
            return "التالي: \(self.building(building)) بعد \(days)"
        case .english:
            return "Next: \(self.building(building)) in \(days(count))"
        }
    }

    // MARK: Selected day

    public var beforeYouStarted: String { pick("قبل بدايتك · أرض فارغة", "Before you started · bare soil") }

    public func growing(stage: Int) -> String {
        pick("نبتة تنمو · المرحلة \(number(stage)) من 5", "Growing · stage \(number(stage)) of 5")
    }

    public var fullPalm: String { pick("نخلة كاملة · صلّيت الخمس", "Full palm · all five prayed") }
    public var fruitingPalm: String { pick("نخلة مثمرة · الخمس في وقتها", "Fruiting palm · all five on time") }

    /// "ذابلة · فاتت صلاتان" / "Wilted · 2 prayers missed".
    public func wilted(missed count: Int) -> String {
        switch language {
        case .arabic:
            "ذابلة · فاتت \(ArabicCountedNoun.prayer.counted(count, digits: number(count)))"
        case .english:
            "Wilted · \(number(count)) \(count == 1 ? "prayer" : "prayers") missed"
        }
    }

    public var dayToCome: String { pick("يوم قادم · لم يبدأ بعد", "Still to come · not started yet") }

    /// The button that logs a prayer: "صلّيت العصر" / "Prayed Asr".
    public func prayed(_ prayerName: String) -> String {
        pick("صلّيت \(prayerName)", "Prayed \(prayerName)")
    }

    /// A prayer chip's spoken label: "الفجر: في وقتها".
    public func chipLabel(_ prayerName: String, status: String) -> String {
        "\(prayerName): \(status)"
    }

    // MARK: The 3D farm

    public var farmHint: String { pick("اسحب للتدوير · اضغط على يوم", "Drag to turn · tap a day") }
    public var fruitLegend: String { pick("مثمرة: عذوق تمر وإطار ذهبي", "Fruiting: date bunches and a gold frame") }
    public var turnLeft: String { pick("تدوير لليسار", "Turn left") }
    public var turnRight: String { pick("تدوير لليمين", "Turn right") }
    public var zoomIn: String { pick("تكبير", "Zoom in") }
    public var zoomOut: String { pick("تصغير", "Zoom out") }

    public func farmSceneLabel(_ month: HijriDate) -> String {
        let name = hijriMonthName(month)
        return pick(
            "مزرعة ثلاثية الأبعاد: كل يوم من \(name) قطعة أرض فيها نخلة. "
                + "اسحب للتدوير، وقرّب بإصبعين، واضغط على قطعة لعرض يومها.",
            "3D farm: each day of \(name) is a plot with a palm. "
                + "Drag to turn, pinch to zoom, and tap a plot to see its day.")
    }

    func hijriMonthName(_ date: HijriDate) -> String {
        pick(Self.arabicHijriMonths[date.month - 1], Self.englishHijriMonths[date.month - 1])
    }
}

extension ArabicCountedNoun {
    static let palm = ArabicCountedNoun(
        singular: "نخلة", one: "نخلة واحدة", two: "نخلتان", plural: "نخلات", accusative: "نخلة")
    static let fruiting = ArabicCountedNoun(
        singular: "مثمرة", one: "مثمرة واحدة", two: "مثمرتان", plural: "مثمرات", accusative: "مثمرة")
    static let prayer = ArabicCountedNoun(
        singular: "صلاة", one: "صلاة واحدة", two: "صلاتان", plural: "صلوات", accusative: "صلاة")
    /// Days after "بعد", where two days is "يومين".
    static let dayAfter = ArabicCountedNoun(
        singular: "يوم", one: "يوم واحد", two: "يومين", plural: "أيام", accusative: "يومًا")
}
