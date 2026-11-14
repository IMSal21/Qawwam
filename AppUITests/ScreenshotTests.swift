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
        XCTAssertEqual(app.staticTexts.matching(identifier: "في وقتها").count, 1)

        app.buttons["صلّيت"].tap()

        XCTAssertTrue(app.staticTexts["التالي: المغرب"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "في وقتها").count, 2)
        XCTAssertTrue(app.staticTexts["+25 نقطة اليوم"].exists)
        keepScreenshot(app, name: "today-ar-after")
    }
}
