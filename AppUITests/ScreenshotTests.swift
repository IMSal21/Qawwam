import XCTest

/// Opens the app in each language, checks the today screen, and keeps a screenshot for the pull request.
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testTodayInArabic() {
        capture(language: "ar", locale: "ar_SA", expected: "الفجر", name: "today-ar")
    }

    func testTodayInEnglish() {
        capture(language: "en", locale: "en_SA", expected: "Fajr", name: "today-en")
    }

    private func capture(language: String, locale: String, expected: String, name: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()

        XCTAssertTrue(app.staticTexts[expected].waitForExistence(timeout: 10), "\(expected) not on screen")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
