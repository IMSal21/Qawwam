import Testing

@testable import QawwamCore

@Suite struct NumberWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)

    @Test func westernDigitsInBothLanguagesWithThousandsGrouped() {
        for words in [Self.arabic, Self.english] {
            #expect(words.number(0) == "0")
            #expect(words.number(7) == "7")
            #expect(words.number(999) == "999")
            #expect(words.number(2390) == "2,390")
            #expect(words.number(1_000_000) == "1,000,000")
        }
    }

    @Test(arguments: [
        (0, "0 يوم"), (1, "يوم واحد"), (2, "يومان"), (3, "3 أيام"), (10, "10 أيام"),
        (11, "11 يومًا"), (99, "99 يومًا"), (100, "100 يوم"), (101, "101 يوم"), (102, "102 يوم"),
        (103, "103 أيام"), (111, "111 يومًا"), (1000, "1,000 يوم"),
    ])
    func arabicDays(count: Int, expected: String) {
        #expect(Self.arabic.days(count) == expected)
    }

    @Test func englishDays() {
        #expect(Self.english.days(0) == "0 days")
        #expect(Self.english.days(1) == "1 day")
        #expect(Self.english.days(2) == "2 days")
        #expect(Self.english.days(11) == "11 days")
    }

    @Test(arguments: [
        (0, "0 نقطة"), (1, "نقطة واحدة"), (2, "نقطتان"), (5, "5 نقاط"), (10, "10 نقاط"),
        (25, "25 نقطة"), (100, "100 نقطة"), (2390, "2,390 نقطة"),
    ])
    func arabicPoints(count: Int, expected: String) {
        #expect(Self.arabic.points(count) == expected)
    }

    @Test func englishPoints() {
        #expect(Self.english.points(1) == "1 point")
        #expect(Self.english.points(5) == "5 points")
        #expect(Self.english.points(2390) == "2,390 points")
    }

    @Test func levels() {
        #expect(Self.arabic.level(7) == "المستوى 7")
        #expect(Self.english.level(7) == "Level 7")
    }
}
