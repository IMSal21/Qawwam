import QawwamCore
import SwiftUI

@main
struct QawwamApp: App {
    /// Arabic unless the phone's first language is English.
    private let language: AppLanguage =
        Locale.preferredLanguages.first?.hasPrefix("en") == true ? .english : .arabic

    var body: some Scene {
        WindowGroup {
            TodayView(words: Words(language))
                .environment(\.layoutDirection, language == .arabic ? .rightToLeft : .leftToRight)
                .environment(\.locale, Locale(identifier: language.rawValue))
        }
    }
}
