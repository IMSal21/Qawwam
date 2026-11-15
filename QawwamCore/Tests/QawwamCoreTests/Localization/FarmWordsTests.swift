import Testing

@testable import QawwamCore

@Suite struct FarmWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)

    @Test func badges() {
        #expect([3, 7, 30, 40, 100].map(Self.arabic.badge) == ["3 أيام", "أسبوع", "شهر", "أربعون يومًا", "مئة يوم"])
        #expect([3, 7, 30, 40, 100].map(Self.english.badge) == ["3 days", "A week", "A month", "40 days", "100 days"])
    }

    @Test func buildings() {
        #expect(
            Building.allCases.map(Self.arabic.building) == ["البئر", "البيت النجدي", "الفناء", "البوابة", "المسجد"])
        #expect(
            Building.allCases.map(Self.english.building) == ["Well", "Najdi farmhouse", "Courtyard", "Gate", "Mosque"])
    }
}

@Suite struct FarmScreenWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)
    static let month = HijriDate(year: 1448, month: 5, day: 30)

    @Test func header() {
        #expect(Self.arabic.myFarm == "مزرعتي")
        #expect(Self.english.myFarm == "My farm")
        #expect(Self.arabic.hijriMonth(Self.month) == "جمادى الأولى 1448")
        #expect(Self.english.hijriMonth(Self.month) == "Jumada al-Ula 1448")
        #expect(Self.arabic.hijriDayMonth(Self.month) == "30 جمادى الأولى")
        #expect(Self.english.hijriDayMonth(Self.month) == "30 Jumada al-Ula")
    }

    @Test func palmCounts() {
        #expect(
            [0, 1, 2, 3, 11, 25].map(Self.arabic.palms)
                == ["0 نخلة", "نخلة واحدة", "نخلتان", "3 نخلات", "11 نخلة", "25 نخلة"])
        #expect([1, 25].map(Self.english.palms) == ["1 palm", "25 palms"])
        #expect([1, 2, 3, 15].map(Self.arabic.fruiting) == ["مثمرة واحدة", "مثمرتان", "3 مثمرات", "15 مثمرة"])
        #expect([1, 15].map(Self.english.fruiting) == ["1 fruiting", "15 fruiting"])
    }

    @Test func nextBuilding() {
        #expect(Self.arabic.nextBuilding(.courtyard, inDays: 18) == "التالي: الفناء بعد 18 يومًا")
        #expect(Self.arabic.nextBuilding(.well, inDays: 1) == "التالي: البئر بعد يوم واحد")
        #expect(Self.arabic.nextBuilding(.well, inDays: 2) == "التالي: البئر بعد يومين")
        #expect(Self.arabic.nextBuilding(.farmhouse, inDays: 4) == "التالي: البيت النجدي بعد 4 أيام")
        #expect(Self.english.nextBuilding(.courtyard, inDays: 18) == "Next: Courtyard in 18 days")
        #expect(Self.english.nextBuilding(.well, inDays: 1) == "Next: Well in 1 day")
    }

    @Test func statusLines() {
        #expect(Self.arabic.beforeYouStarted == "قبل بدايتك · أرض فارغة")
        #expect(Self.arabic.growing(stage: 2) == "نبتة تنمو · المرحلة 2 من 5")
        #expect(Self.arabic.fullPalm == "نخلة كاملة · صلّيت الخمس")
        #expect(Self.arabic.fruitingPalm == "نخلة مثمرة · الخمس في وقتها")
        #expect(
            [1, 2, 3, 5].map(Self.arabic.wilted) == [
                "ذابلة · فاتت صلاة واحدة", "ذابلة · فاتت صلاتان", "ذابلة · فاتت 3 صلوات", "ذابلة · فاتت 5 صلوات",
            ])
        #expect(Self.arabic.dayToCome == "يوم قادم · لم يبدأ بعد")

        #expect(Self.english.beforeYouStarted == "Before you started · bare soil")
        #expect(Self.english.growing(stage: 2) == "Growing · stage 2 of 5")
        #expect(Self.english.fullPalm == "Full palm · all five prayed")
        #expect(Self.english.fruitingPalm == "Fruiting palm · all five on time")
        #expect([1, 2].map(Self.english.wilted) == ["Wilted · 1 prayer missed", "Wilted · 2 prayers missed"])
        #expect(Self.english.dayToCome == "Still to come · not started yet")
    }

    @Test func actionsAndHints() {
        #expect(Self.arabic.prayed("العصر") == "صلّيت العصر")
        #expect(Self.english.prayed("Asr") == "Prayed Asr")
        #expect(Self.arabic.chipLabel("الفجر", status: "في وقتها") == "الفجر: في وقتها")
        #expect(Self.arabic.farmHint == "اسحب للتدوير · اضغط على يوم")
        #expect(Self.arabic.fruitLegend == "مثمرة: عذوق تمر وإطار ذهبي")
        #expect(
            [Self.arabic.turnLeft, Self.arabic.turnRight, Self.arabic.zoomIn, Self.arabic.zoomOut]
                == ["تدوير لليسار", "تدوير لليمين", "تكبير", "تصغير"])
        #expect(
            [Self.english.turnLeft, Self.english.turnRight, Self.english.zoomIn, Self.english.zoomOut]
                == ["Turn left", "Turn right", "Zoom in", "Zoom out"])
        #expect(
            Self.arabic.farmSceneLabel(Self.month)
                == "مزرعة ثلاثية الأبعاد: كل يوم من جمادى الأولى قطعة أرض فيها نخلة. "
                + "اسحب للتدوير، وقرّب بإصبعين، واضغط على قطعة لعرض يومها.")
        #expect(
            Self.english.farmSceneLabel(Self.month)
                == "3D farm: each day of Jumada al-Ula is a plot with a palm. "
                + "Drag to turn, pinch to zoom, and tap a plot to see its day.")
    }
}
