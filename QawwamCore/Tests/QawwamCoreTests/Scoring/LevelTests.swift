import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

@Suite struct LevelTests {
    @Test(arguments: [
        (0, 1), (99, 1), (100, 2), (299, 2), (300, 3), (599, 3), (600, 4), (999, 4), (1_000, 5), (4_500, 10),
    ])
    func eachLevelNeedsOneHundredMoreThanTheLast(points: Int, level: Int) {
        #expect(Scoring.level(forPoints: points) == level)
    }

    @Test func theScoreCarriesTheLevelForItsPoints() {
        var log = PrayerLog()
        F.prayAll(on: 0..<4, in: &log)

        let score = Scoring.score(log, days: F.days(4), at: F.at(4, 5, 30))

        // Four perfect days, with Jumu'ah on time on day 1 (a Friday): 40 more than Dhuhr.
        #expect(score.totalPoints == 4 * 75 + 40)
        #expect(score.level == 3)
    }

    @Test func aNewUserIsLevelOne() {
        #expect(Scoring.score(PrayerLog(), days: [], at: F.at(0, 12)).level == 1)
    }
}
