import QawwamCore
import SwiftUI

/// The farm screen from the mockup: header pills, the 3D farm with its controls, and the selected day.
struct FarmView: View {
    let store: TodayStore
    @State private var selected: DayKey?
    @State private var camera = FarmCamera()

    var body: some View {
        let state = store.farmState(selected: selected)
        let words = store.words
        VStack(alignment: .leading, spacing: 0) {
            header(state)
            scene(state, words: words)
            DayCardView(card: state.selected, store: store)
                .padding(.horizontal, 16)
                .padding(.top, 10)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.ground)
        .foregroundStyle(Theme.ink)
    }

    private func header(_ state: FarmScreenState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(state.title).font(Theme.heading(30)).accessibilityAddTraits(.isHeader)
                Spacer()
                Text(state.monthText).font(Theme.text(14, .semibold))
            }
            HStack(spacing: 6) {
                pill(state.palmsText, background: Theme.surface, foreground: Theme.ink)
                pill(state.fruitText, background: Theme.goldSoft, foreground: Theme.fruitText)
                if let next = state.nextBuildingText {
                    pill(next, background: Theme.surface, foreground: Theme.muted, weight: .regular)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private func pill(
        _ text: String, background: Color, foreground: Color, weight: Theme.Weight = .semibold
    ) -> some View {
        Text(text)
            .font(Theme.text(13, weight))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(background, in: .capsule)
    }

    private func scene(_ state: FarmScreenState, words: Words) -> some View {
        ZStack {
            FarmSceneView(
                plots: state.plots, buildings: state.buildings, selected: state.selected.day, camera: $camera
            ) { day in
                selected = day
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(state.sceneLabel)

            VStack(alignment: .leading, spacing: 4) {
                hint(Text(words.farmHint).foregroundStyle(Theme.muted))
                hint(
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.fruitFrame, lineWidth: 2)
                            .frame(width: 10, height: 10)
                        Circle().fill(Theme.dates).frame(width: 8, height: 8)
                        Text(words.fruitLegend)
                    })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(10)

            HStack(spacing: 6) {
                control("arrow.counterclockwise", label: words.turnLeft) { camera.turn(by: .pi / 4) }
                control("arrow.clockwise", label: words.turnRight) { camera.turn(by: -.pi / 4) }
                control("plus", label: words.zoomIn) { camera.zoom(by: 1.25) }
                control("minus", label: words.zoomOut) { camera.zoom(by: 1 / 1.25) }
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(10)
        }
        .frame(height: 380)
        .background(Theme.farmSky, in: .rect(cornerRadius: 20))
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 16)
    }

    private func hint(_ content: some View) -> some View {
        content
            .font(Theme.text(12))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.white.opacity(0.85), in: .rect(cornerRadius: 8))
    }

    private func control(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.92), in: .rect(cornerRadius: 12))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityLabel(label)
    }
}

/// The selected day: its dates, how its palm is doing, its five prayers, and on today the pray button.
private struct DayCardView: View {
    let card: FarmScreenState.DayCard
    let store: TodayStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(card.hijriText).font(Theme.heading(19))
                if card.isToday {
                    Text(card.todayText)
                        .font(Theme.text(12, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 1)
                        .background(Theme.palm, in: .capsule)
                }
                Spacer()
                Text(card.gregorianText).font(Theme.text(12)).foregroundStyle(Theme.muted)
            }
            Text(card.statusText)
                .font(Theme.text(14, .semibold))
                .foregroundStyle(tone)
            if !card.chips.isEmpty {
                HStack(spacing: 4) {
                    ForEach(card.chips) { chip in
                        ChipView(chip: chip)
                    }
                }
            }
            if let prayer = card.prayer, let text = card.prayButtonText {
                Button {
                    store.markPrayed(prayer, inCongregation: false)
                } label: {
                    Text(text)
                        .font(Theme.text(15, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Theme.palm, in: .rect(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .contain)
    }

    private var tone: Color {
        switch card.state {
        case .unused, .future: Theme.muted
        case .growing, .grown: Theme.palm
        case .fruiting: Theme.fruitText
        case .wilted: Theme.wiltedText
        }
    }
}

private struct ChipView: View {
    let chip: FarmScreenState.Chip

    var body: some View {
        let (background, foreground, border): (Color, Color, Color) =
            switch chip.segment {
            case .onTime: (Theme.onTimeSoft, Theme.palm, Theme.onTimeSoft)
            case .late: (Theme.lateSoft, Theme.late, Theme.lateSoft)
            case .missed: (Theme.missedSoft, Theme.wiltedText, Theme.missedSoft)
            case .due: (Theme.surface, Theme.palm, Theme.palm)
            case .upcoming: (Theme.ground, Theme.muted, Theme.ground)
            }
        Text(chip.name)
            .font(Theme.text(12, .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(background, in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(border, lineWidth: 1.5))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(chip.label)
    }
}
