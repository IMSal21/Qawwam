import QawwamCore
import SwiftUI

/// Placeholder today screen: today's five prayer times for Riyadh.
struct TodayView: View {
    let words: Words

    private static let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
    private static let saudi = TimeZone(identifier: "Asia/Riyadh")!

    var body: some View {
        NavigationStack {
            if let day = try? PrayerTimesCalculator(settings: .ummAlQura)
                .prayerDay(containing: Date(), at: Self.riyadh, in: Self.saudi)
            {
                let key = DayKey(day)
                List {
                    Section {
                        ForEach(Prayer.allCases, id: \.self) { prayer in
                            HStack {
                                Text(words.name(of: prayer, on: key))
                                Spacer()
                                Text(words.time(day.time(of: prayer))).monospacedDigit()
                            }
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text(words.hijri(HijriDate(key))).font(.headline)
                            Text(words.gregorian(key)).font(.caption)
                        }
                    }
                }
                .navigationTitle(words.weekday(key))
            } else {
                Text("—")
            }
        }
    }
}
