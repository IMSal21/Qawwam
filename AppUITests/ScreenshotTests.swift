import XCTest

/// Opens the app on the mockup's scene (Tuesday 10 Nov 2026, 3:20 PM in Riyadh, Fajr on time, Dhuhr late,
/// Asr due), checks the today screen, and keeps a screenshot for the pull request.
@MainActor
final class ScreenshotTests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func launch(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
            "-QawwamNow", "2026-11-10T12:20:00Z", "-QawwamScene", "mockup",
        ]
        app.launch()
        return app
    }

    private func keepScreenshot(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testTodayInArabic() {
        let app = launch(language: "ar", locale: "ar_SA")
        XCTAssertTrue(app.staticTexts["حان وقت العصر"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["+15 نقطة اليوم"].exists)
        XCTAssertTrue(app.staticTexts["12 يومًا"].exists)
        XCTAssertTrue(app.buttons["صلّيت"].exists)
        keepScreenshot(app, name: "today-ar")
    }

    func testTodayInEnglish() {
        let app = launch(language: "en", locale: "en_SA")
        XCTAssertTrue(app.staticTexts["Time for Asr"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["+15 points today"].exists)
        XCTAssertTrue(app.buttons["Prayed"].exists)
        keepScreenshot(app, name: "today-en")
    }

    func testPrayingAsrMarksItOnTime() {
        let app = launch(language: "ar", locale: "ar_SA")
        XCTAssertTrue(app.buttons["صلّيت"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "في وقتها")).count, 1)

        app.buttons["صلّيت"].tap()

        XCTAssertTrue(app.staticTexts["التالي: المغرب"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "في وقتها")).count, 2)
        XCTAssertTrue(app.staticTexts["+25 نقطة اليوم"].exists)
        keepScreenshot(app, name: "today-ar-after")
    }

    // MARK: Farm

    private func openFarm(_ app: XCUIApplication, tab: String) {
        XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 10))
        app.tabBars.buttons[tab].tap()
    }

    func testFarmInArabic() {
        let app = launch(language: "ar", locale: "ar_SA")
        openFarm(app, tab: "المزرعة")
        XCTAssertTrue(app.staticTexts["مزرعتي"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["25 نخلة"].exists)
        XCTAssertTrue(app.staticTexts["15 مثمرة"].exists)
        XCTAssertTrue(app.staticTexts["التالي: الفناء بعد 18 يومًا"].exists)
        XCTAssertTrue(app.staticTexts["نبتة تنمو · المرحلة 2 من 5"].exists)
        XCTAssertTrue(app.buttons["صلّيت العصر"].exists)
        sleep(3)  // let the 3D farm render
        keepScreenshot(app, name: "farm-ar")
    }

    func testFarmInEnglish() {
        let app = launch(language: "en", locale: "en_SA")
        openFarm(app, tab: "Farm")
        XCTAssertTrue(app.staticTexts["My farm"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["25 palms"].exists)
        XCTAssertTrue(app.buttons["Prayed Asr"].exists)
        sleep(3)
        keepScreenshot(app, name: "farm-en")
    }

    func testPrayingFromTheFarmGrowsTodaysPalm() {
        let app = launch(language: "ar", locale: "ar_SA")
        openFarm(app, tab: "المزرعة")
        XCTAssertTrue(app.buttons["صلّيت العصر"].waitForExistence(timeout: 10))

        app.buttons["صلّيت العصر"].tap()

        XCTAssertTrue(app.staticTexts["نبتة تنمو · المرحلة 3 من 5"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["صلّيت العصر"].exists)

        app.tabBars.buttons["اليوم"].tap()
        XCTAssertTrue(app.staticTexts["التالي: المغرب"].waitForExistence(timeout: 5))
    }
}
