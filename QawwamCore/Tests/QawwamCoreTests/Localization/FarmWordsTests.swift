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
