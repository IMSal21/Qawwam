import QawwamCore
import SwiftUI

@main
struct QawwamApp: App {
    /// Arabic unless the phone's first language is English.
    private let language: AppLanguage =
        Locale.preferredLanguages.first?.hasPrefix("en") == true ? .english : .arabic
    @State private var store: TodayStore

    init() {
        Theme.registerFonts()
        let words = Words(language)
        _store = State(initialValue: Self.makeStore(words: words))
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .environment(\.layoutDirection, language == .arabic ? .rightToLeft : .leftToRight)
                .environment(\.locale, Locale(identifier: language.rawValue))
        }
    }

    /// The real store, or for UI tests a fixed time (`-QawwamNow`) and a seeded scene (`-QawwamScene mockup`).
    @MainActor
    private static func makeStore(words: Words) -> TodayStore {
        let arguments = UserDefaults.standard
        let fixedNow = arguments.string(forKey: "QawwamNow").flatMap { ISO8601DateFormatter().date(from: $0) }
        let clock: @MainActor () -> Date = { fixedNow ?? Date() }

        if arguments.string(forKey: "QawwamScene") == "mockup", let fixedNow {
            let (store, defaults) = DemoScene.mockup(now: fixedNow)
            return TodayStore(store: store, defaults: defaults, words: words, clock: clock)
        }

        let folder =
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TodayStore.appGroup)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = FilePrayerLogStore(fileURL: folder.appendingPathComponent("prayer-log.json"))
        let defaults = UserDefaults(suiteName: TodayStore.appGroup) ?? .standard
        return TodayStore(store: file, defaults: defaults, words: words, clock: clock)
    }
}
