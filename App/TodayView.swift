import QawwamCore
import SwiftUI

/// The today screen from the mockup: header, summary card, five prayer rows.
struct TodayView: View {
    let store: TodayStore

    var body: some View {
        let state = store.state
        let words = store.words
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header(state)
                summary(state)
                VStack(spacing: 8) {
                    ForEach(state.rows) { row in
                        PrayerRowView(row: row, words: words, store: store)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Theme.ground)
        .foregroundStyle(Theme.ink)
    }

    private func header(_ state: TodayState) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.title).font(Theme.heading(30)).accessibilityAddTraits(.isHeader)
                Text(state.dateLine).font(Theme.text(15, .semibold))
                Text(state.gregorianLine).font(Theme.text(12)).foregroundStyle(Theme.muted)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "flame").foregroundStyle(Theme.gold).font(.system(size: 15, weight: .semibold))
                Text(state.streakText).font(Theme.text(15, .semibold))
            }
            .foregroundStyle(Theme.goldText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.goldSoft, in: .capsule)
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }

    private func summary(_ state: TodayState) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RingView(segments: state.ring)
                VStack(spacing: 0) {
                    Text(state.prayedText).font(Theme.heading(30))
                    Text(state.ofFiveText).font(Theme.text(13)).foregroundStyle(Theme.muted)
                }
            }
            .frame(width: 120, height: 120)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(state.ringLabel)

            VStack(alignment: .leading, spacing: 6) {
                Text(state.heroTitle).font(Theme.text(18, .bold))
                if !state.heroSubtitle.isEmpty {
                    Text(state.heroSubtitle).font(Theme.text(14)).foregroundStyle(Theme.muted)
                }
                HStack(spacing: 6) {
                    Image(systemName: "star").foregroundStyle(Theme.gold).font(.system(size: 14, weight: .semibold))
                    Text(state.pointsText).font(Theme.text(14, .semibold))
                }
                .foregroundStyle(Theme.goldText)
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.surface, in: .rect(cornerRadius: 20))
    }
}
