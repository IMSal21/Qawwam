import QawwamCore
import SwiftUI

/// Placeholder today screen: today's five prayer times for Riyadh.
struct TodayView: View {
    let words: Words

    var body: some View {
        NavigationStack {
            if let model = try? TodayModel(words: words, now: Date()) {
                List {
                    Section {
                        ForEach(model.rows, id: \.prayer) { row in
                            HStack {
                                Text(row.name)
                                Spacer()
                                Text(row.time).monospacedDigit()
                            }
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text(model.hijri).font(.headline)
                            Text(model.gregorian).font(.caption)
                        }
                    }
                }
                .navigationTitle(model.weekday)
            } else {
                Text("—")
            }
        }
    }
}
