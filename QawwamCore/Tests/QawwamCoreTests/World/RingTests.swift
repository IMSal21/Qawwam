import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

@Suite struct RingTests {
    @Test func beforeFajrEverySegmentIsUpcoming() {
        let ring = FarmBuilder.ring(PrayerLog(), for: F.day(0), at: F.at(0, 5))

        #expect(ring == Array(repeating: .upcoming, count: 5))
    }

    @Test func theRingShowsEachPrayerFajrFirst() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)
        F.pray(.dhuhr, on: 0, .late, in: &log)

        let ring = FarmBuilder.ring(log, for: F.day(0), at: F.at(0, 16))

        #expect(ring == [.onTime, .late, .due, .upcoming, .upcoming])
    }

    @Test func afterTheDayClosesUnloggedPrayersAreMissed() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)

        let ring = FarmBuilder.ring(log, for: F.day(0), at: F.at(1, 5, 20))

        #expect(ring == [.onTime, .missed, .missed, .missed, .missed])
    }
}
