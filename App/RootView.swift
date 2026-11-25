import QawwamCore
import SwiftUI

/// Onboarding on the first launch, then the tab bar: today, farm, profile. Profile is a placeholder until its own spec.
struct RootView: View {
    let store: TodayStore
    @Environment(\.scenePhase) private var scenePhase
    private let minute = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if store.isOnboarded {
                tabs
            } else {
                OnboardingView(store: store)
            }
        }
        .onReceive(minute) { _ in store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
    }

    private var tabs: some View {
        let words = store.words
        return TabView {
            TodayView(store: store)
                .tabItem { Label(words.today, systemImage: "checkmark.circle") }
            FarmView(store: store)
                .tabItem { Label(words.farm, systemImage: "leaf") }
            Placeholder(title: words.profile, words: words)
                .tabItem { Label(words.profile, systemImage: "person") }
        }
        .tint(Theme.palm)
    }
}

private struct Placeholder: View {
    let title: String
    let words: Words

    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(Theme.heading(30))
            Text(words.comingSoon).font(Theme.text(15)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.ground)
        .foregroundStyle(Theme.ink)
    }
}
