import XCTest

/// Walks through the three onboarding steps on a fresh install and keeps screenshots for the pull request.
@MainActor
final class OnboardingTests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    /// `-QawwamScene fresh` keeps its log and settings between launches; `-QawwamReset YES` clears them.
    private func launch(language: String, locale: String, reset: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
            "-QawwamNow", "2026-11-10T12:20:00Z", "-QawwamScene", "fresh",
        ]
        if reset { app.launchArguments += ["-QawwamReset", "YES"] }
        app.launch()
        return app
    }

    private func keepScreenshot(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func label(containing text: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS %@", text)
    }

    func testOnboardingInArabic() {
        let app = launch(language: "ar", locale: "ar_SA")
        XCTAssertTrue(app.staticTexts["ما الذي جاء بك إلى قوّام؟"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["1 من 3"].exists)
        app.buttons["reason-onTime"].tap()
        app.buttons["reason-fajr"].tap()
        keepScreenshot(app, name: "onb-why-ar")
        app.buttons["التالي"].tap()

        XCTAssertTrue(app.staticTexts["أين تسكن؟"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["التالي"].isEnabled)
        app.buttons["الرياض"].tap()
        XCTAssertTrue(app.staticTexts["مواقيت اليوم في الرياض · أم القرى"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["التالي"].isEnabled)
        keepScreenshot(app, name: "onb-city-ar")

        let search = app.textFields["city-search"]
        search.tap()
        search.typeText("جده")
        XCTAssertFalse(app.buttons["الرياض"].exists)
        app.buttons["جدة"].tap()
        XCTAssertTrue(app.staticTexts["مواقيت اليوم في جدة · أم القرى"].waitForExistence(timeout: 5))
        app.buttons["التالي"].tap()

        XCTAssertTrue(app.staticTexts["مزرعتك تكبر مع صلاتك"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["3 من 3"].exists)
        keepScreenshot(app, name: "onb-farm-ar")
        app.buttons["ابدأ مزرعتي"].tap()

        XCTAssertTrue(app.staticTexts.matching(label(containing: "جدة")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["المزرعة"].exists)

        app.terminate()
        let again = launch(language: "ar", locale: "ar_SA", reset: false)
        XCTAssertTrue(again.tabBars.buttons["المزرعة"].waitForExistence(timeout: 10))
        XCTAssertFalse(again.staticTexts["ما الذي جاء بك إلى قوّام؟"].exists)
        XCTAssertTrue(again.staticTexts.matching(label(containing: "جدة")).firstMatch.exists)
    }

    func testOnboardingInEnglish() {
        let app = launch(language: "en", locale: "en_SA")
        XCTAssertTrue(app.staticTexts["What brings you to Qawwam?"].waitForExistence(timeout: 10))
        app.buttons["reason-onTime"].tap()
        app.buttons["reason-fajr"].tap()
        keepScreenshot(app, name: "onb-why-en")
        app.buttons["Next"].tap()

        XCTAssertTrue(app.staticTexts["Where do you live?"].waitForExistence(timeout: 5))
        app.buttons["Riyadh"].tap()
        XCTAssertTrue(app.staticTexts["Today's times in Riyadh · Umm al-Qura"].waitForExistence(timeout: 5))
        keepScreenshot(app, name: "onb-city-en")
        app.buttons["Next"].tap()

        XCTAssertTrue(app.staticTexts["Your farm grows with your prayers"].waitForExistence(timeout: 5))
        keepScreenshot(app, name: "onb-farm-en")
        app.buttons["Start my farm"].tap()
        XCTAssertTrue(app.tabBars.buttons["Farm"].waitForExistence(timeout: 5))
    }

    func testBackKeepsTheChoices() {
        let app = launch(language: "ar", locale: "ar_SA")
        XCTAssertTrue(app.buttons["reason-fajr"].waitForExistence(timeout: 10))
        app.buttons["reason-fajr"].tap()
        app.buttons["التالي"].tap()
        XCTAssertTrue(app.buttons["الرياض"].waitForExistence(timeout: 5))
        app.buttons["الرياض"].tap()
        app.buttons["التالي"].tap()
        XCTAssertTrue(app.buttons["رجوع"].waitForExistence(timeout: 5))

        app.buttons["رجوع"].tap()
        XCTAssertTrue(app.buttons["التالي"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["التالي"].isEnabled)
        app.buttons["رجوع"].tap()
        XCTAssertTrue(app.buttons["reason-fajr"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reason-fajr"].isSelected)
    }
}
