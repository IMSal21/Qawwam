import QawwamCore
import SwiftUI

/// The three onboarding steps from the mockups: why you came, your city, and why a farm.
struct OnboardingView: View {
    let store: TodayStore
    @State private var step = 1
    @State private var reasons: Set<OnboardingReason> = []
    @State private var city: City?
    @State private var query = ""
    @State private var locating = false
    @State private var locationFailed = false
    @State private var locator = CityLocator()
    @FocusState private var searching: Bool

    private var words: Words { store.words }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topBar
            switch step {
            case 1: whyStep
            case 2: cityStep
            default: farmStep
            }
            primaryButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.ground)
        .foregroundStyle(Theme.ink)
    }

    // MARK: Every step

    private var topBar: some View {
        HStack(spacing: 10) {
            if step > 1 {
                Button {
                    step -= 1
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(words.back)
                .padding(.vertical, -10)
                .padding(.leading, -10)
            }
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { index in
                    Capsule().fill(index <= step ? Theme.palm : Theme.line).frame(height: 5)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(words.stepLabel(step))
            Text(words.step(step)).font(Theme.text(13)).foregroundStyle(Theme.muted)
        }
        .frame(minHeight: 24)
    }

    private var primaryButton: some View {
        let disabled = step == 2 && city == nil
        return Button {
            switch step {
            case 1, 2: step += 1
            default: store.finishOnboarding(city: city ?? SaudiCities.riyadh, reasons: reasons)
            }
        } label: {
            Text(step == 3 ? words.startMyFarm : words.nextStep)
                .font(Theme.text(17, .bold))
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundStyle(.white)
                .background(Theme.palm.opacity(disabled ? 0.4 : 1), in: .rect(cornerRadius: 16))
        }
        .disabled(disabled)
    }

    private func titles(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.heading(28)).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(Theme.text(15)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Step 1

    private var whyStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(words.welcome).font(Theme.text(15, .semibold)).foregroundStyle(Theme.palm)
                titles(words.whyTitle, words.whySubtitle)
                ForEach(OnboardingReason.allCases, id: \.self) { reason in
                    reasonCard(reason)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func reasonCard(_ reason: OnboardingReason) -> some View {
        let on = reasons.contains(reason)
        return Button {
            if on { reasons.remove(reason) } else { reasons.insert(reason) }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(words.reasonTitle(reason)).font(Theme.text(16, .semibold))
                    Text(words.reasonDetail(reason)).font(Theme.text(13)).foregroundStyle(Theme.muted)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(on ? Theme.palm : .white)
                    RoundedRectangle(cornerRadius: 7).strokeBorder(on ? Theme.palm : Theme.line, lineWidth: 1.5)
                    if on {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(on ? Theme.onTimeSoft : .white, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(on ? Theme.palm : Theme.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reason-\(reason.rawValue)")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Step 2

    private var cityStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            titles(words.cityTitle, words.citySubtitle)
            Button {
                useMyLocation()
            } label: {
                HStack(spacing: 8) {
                    if locating { ProgressView() } else { Image(systemName: "location") }
                    Text(words.useMyLocation).font(Theme.text(15, .bold))
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(Theme.palm)
                .background(.white, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.palm, lineWidth: 1.5))
            }
            .disabled(locating)
            if locationFailed {
                Text(words.locationFailed).font(Theme.text(13)).foregroundStyle(Theme.missed)
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted).accessibilityHidden(true)
                TextField(words.searchCity, text: $query)
                    .font(Theme.text(15))
                    .focused($searching)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityIdentifier("city-search")
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(.white, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: 0xD6D2C7)))
            cityList
            if let city, let day = store.previewDay(in: city) {
                timesCard(city, day)
            }
        }
    }

    private var cityList: some View {
        let groups = SaudiCities.grouped(SaudiCities.search(query))
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groups, id: \.region) { group in
                    Text(words.region(group.region))
                        .font(Theme.text(12, .semibold))
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(group.cities) { item in
                        cityRow(item)
                    }
                }
                if groups.isEmpty {
                    Text(words.noCityFound).font(Theme.text(14)).foregroundStyle(Theme.muted).padding(14)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: .infinity)
        .background(.white, in: .rect(cornerRadius: 16))
    }

    private func cityRow(_ item: City) -> some View {
        let on = item == city
        return Button {
            city = item
            searching = false
        } label: {
            HStack {
                Text(words.cityName(item)).font(Theme.text(16, on ? .bold : .medium))
                Spacer()
                if on {
                    Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.palm)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(on ? Theme.onTimeSoft : .white)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func timesCard(_ city: City, _ day: PrayerDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(words.todaysTimes(in: city)).font(Theme.text(13)).foregroundStyle(Color(hex: 0xCFDCD6))
            HStack(spacing: 4) {
                ForEach(Prayer.allCases, id: \.self) { prayer in
                    VStack(spacing: 0) {
                        Text(words.name(of: prayer, on: DayKey(day))).font(Theme.text(12))
                            .foregroundStyle(Color(hex: 0xCFDCD6))
                        Text(words.shortTime(day.time(of: prayer))).font(Theme.text(15, .bold)).monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(Theme.ink, in: .rect(cornerRadius: 16))
    }

    private func useMyLocation() {
        locating = true
        locationFailed = false
        Task {
            let point = await locator.locate()
            locating = false
            if let point {
                city = SaudiCities.nearest(to: point)
                query = ""
            } else {
                locationFailed = true
            }
        }
    }

    // MARK: Step 3

    private var farmStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                titles(words.farmTitle, words.farmSubtitle)
                GrowthStrip(words: words)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(words.farmPoints.enumerated()), id: \.offset) { index, point in
                        pointRow(index, point)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(words.hadith).font(Theme.text(14)).fixedSize(horizontal: false, vertical: true)
                    Text(words.hadithSource).font(Theme.text(12)).foregroundStyle(Color(hex: 0xCFDCD6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white)
                .background(Theme.ink, in: .rect(cornerRadius: 16))
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func pointRow(_ index: Int, _ point: FarmPoint) -> some View {
        let icons: [(String, Color, Color)] = [
            ("leaf", Theme.palm, Theme.onTimeSoft),
            ("circle.grid.cross.fill", Theme.dates, Theme.goldSoft),
            ("wind", Color(hex: 0x8C7A66), Color(hex: 0xECE6DC)),
            ("building.columns", Theme.palm, Theme.onTimeSoft),
        ]
        let (symbol, tint, back) = icons[index % icons.count]
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(back, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            (Text(point.bold).font(Theme.text(15, .bold)) + Text(point.rest).font(Theme.text(15)))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
