import Foundation
import Testing

@testable import QawwamCore

@Suite struct BuildingTests {
    @Test(arguments: [
        ([Int](), [Building]()),
        ([3], [.well]),
        ([3, 7], [.well, .farmhouse]),
        ([3, 7, 30], [.well, .farmhouse, .courtyard]),
        ([3, 7, 30, 40], [.well, .farmhouse, .courtyard, .gate]),
        ([3, 7, 30, 40, 100], [.well, .farmhouse, .courtyard, .gate, .mosque]),
    ])
    func badgesUnlockBuildingsInOrder(badges: [Int], buildings: [Building]) {
        #expect(Building.unlocked(by: badges) == buildings)
    }

    @Test func eachBuildingNamesItsBadgeAndArt() {
        #expect(Building.allCases.map(\.badge) == [3, 7, 30, 40, 100])
        #expect(Building.mosque.artName == "building.mosque")
    }

    @Test func badgeOrderInTheInputDoesNotMatter() {
        #expect(Building.unlocked(by: [7, 3]) == [.well, .farmhouse])
    }
}
