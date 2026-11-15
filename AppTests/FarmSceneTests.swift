import QawwamCore
import RealityKit
import XCTest

@testable import Qawwam

@MainActor
final class FarmSceneTests: XCTestCase {
    func testEveryArtNameHasAShape() {
        for name in FarmArt.allNames {
            XCTAssertTrue(PlaceholderArt.isKnown(name), name)
            let entity = PlaceholderArt.entity(for: name)
            XCTAssertEqual(entity.name, name)
            if name.hasPrefix("palm") || name.hasPrefix("building") {
                XCTAssertFalse(entity.children.isEmpty, "\(name) has no shape")
            }
        }
    }

    func testAnUnknownNameIsBareSoil() {
        XCTAssertFalse(PlaceholderArt.isKnown("palm.stage9"))
        XCTAssertTrue(PlaceholderArt.entity(for: "tree.oak").children.isEmpty)
    }

    func testOnePlotPerDayOfTheMonth() throws {
        let (log, days, now) = try Self.month()
        let farm = FarmBuilder.farm(log, days: days, at: now)
        let plots = farm.month(containing: DayKey(days.last!))

        let scene = FarmScene(plots: plots, buildings: farm.buildings)

        XCTAssertEqual(scene.plotEntities.count, plots.count)
        for plot in plots {
            let entity = try XCTUnwrap(scene.plotEntities[plot.day])
            XCTAssertEqual(FarmScene.day(of: entity), plot.day)
            XCTAssertEqual(entity.findEntity(named: "art")?.children.isEmpty, plot.stage == 0)
        }
    }

    func testATapOnATileFindsItsDay() throws {
        let (log, days, now) = try Self.month()
        let farm = FarmBuilder.farm(log, days: days, at: now)
        let plots = farm.month(containing: DayKey(days.last!))
        let scene = FarmScene(plots: plots, buildings: farm.buildings)
        let plot = try XCTUnwrap(plots.first)

        let tile = try XCTUnwrap(scene.plotEntities[plot.day]?.children.first)

        XCTAssertNotNil(tile.components[CollisionComponent.self])
        XCTAssertEqual(FarmScene.day(of: tile), plot.day)
    }

    /// Three days in Riyadh, all five prayed on time, read on the third day at noon.
    private static func month() throws -> (PrayerLog, [PrayerDay], Date) {
        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        var log = PrayerLog()
        var days: [PrayerDay] = []
        for date in 1...3 {
            let day = try calculator.day(
                DateComponents(year: 2026, month: 11, day: date), at: TodayStore.riyadh, in: TodayStore.saudi)
            days.append(day)
            if date < 3 {
                for prayer in Prayer.allCases {
                    try log.markPrayed(prayer, in: day, at: day.time(of: prayer).addingTimeInterval(300))
                }
            }
        }
        return (log, days, days[2].time(of: .dhuhr).addingTimeInterval(600))
    }
}
