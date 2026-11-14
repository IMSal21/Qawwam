import QawwamCore
import SwiftUI

/// One prayer: name and time, status pill, and what can be done with it.
struct PrayerRowView: View {
    let row: TodayState.Row
    let words: Words
    let store: TodayStore
    @State private var pendingCongregation = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(row.name)
                    .font(Theme.heading(19))
                    .foregroundStyle(row.pill == .upcoming ? Theme.muted : Theme.ink)
                Text(row.time)
                    .font(Theme.text(13))
                    .foregroundStyle(Theme.muted)
                    .monospacedDigit()
            }
            .frame(minWidth: 74, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                pill
                if row.actions.contains(.undo) { prayedControls }
                if row.actions.contains(.pray) {
                    Toggle(isOn: $pendingCongregation) {
                        Text(words.inCongregation).font(Theme.text(13)).foregroundStyle(Theme.ink)
                    }
                    .toggleStyle(CheckboxStyle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 52)
        .background(row.pill == .upcoming ? Theme.upcomingRow : Theme.surface, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(borderColor, lineWidth: 2))
    }

    private var borderColor: Color {
        switch row.pill {
        case .due: Theme.palm
        case .notLoggedLate: Theme.lateRing
        default: .clear
        }
    }

    private var pill: some View {
        let (background, foreground): (Color, Color) =
            switch row.pill {
            case .onTime: (Theme.onTimeSoft, Theme.palm)
            case .late, .notLoggedLate: (Theme.lateSoft, Theme.late)
            case .due: (Theme.palm, .white)
            case .upcoming: (Theme.upcomingSoft, Theme.muted)
            case .missed: (Theme.missedSoft, Theme.missed)
            }
        return HStack(spacing: 4) {
            if row.pill == .onTime { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)) }
            if row.pill == .late { Image(systemName: "clock").font(.system(size: 11, weight: .semibold)) }
            Text(row.pillText).font(Theme.text(13, .semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background(background, in: .capsule)
    }

    private var prayedControls: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleCongregation(for: row.prayer)
            } label: {
                Label(row.congregationText, systemImage: "person.2")
                    .font(Theme.text(12))
                    .foregroundStyle(row.inCongregation ? Theme.palm : Theme.muted)
            }
            .accessibilityAddTraits(row.inCongregation ? .isSelected : [])
            if row.actions.contains(.setOnTime) {
                Button(words.prayedItOnTime) { store.setTiming(.onTime, for: row.prayer) }
                    .font(Theme.text(12, .semibold))
                    .foregroundStyle(Theme.palm)
                    .underline()
            }
            if row.actions.contains(.setLate) {
                Button(words.markLate) { store.setTiming(.late, for: row.prayer) }
                    .font(Theme.text(12))
                    .foregroundStyle(Theme.muted)
                    .underline()
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var trailing: some View {
        if row.actions.contains(.pray) {
            Button {
                store.markPrayed(row.prayer, inCongregation: pendingCongregation)
                pendingCongregation = false
            } label: {
                Text(words.prayed)
                    .font(Theme.text(17, .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 88, minHeight: 48)
                    .background(Theme.palm, in: .rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        } else if row.actions.contains(.undo) {
            Button {
                store.undo(row.prayer)
            } label: {
                Text(words.undo)
                    .font(Theme.text(13))
                    .foregroundStyle(Theme.muted)
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(.horizontal, 6)
                    .background(Theme.surface, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.line))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(row.undoLabel)
        } else if row.pill == .upcoming {
            Text(row.startsText).font(Theme.text(12)).foregroundStyle(Theme.muted)
        }
    }
}

/// A small square checkbox, as in the mockup.
struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(configuration.isOn ? Theme.palm : Theme.muted)
                configuration.label
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}
