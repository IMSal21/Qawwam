import QawwamCore
import SwiftUI
import WidgetKit

/// Placeholder widget so the extension and App Group are part of every build. The real widgets come later.
struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry { PlaceholderEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: Date())], policy: .never))
    }
}

struct PlaceholderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "placeholder", provider: PlaceholderProvider()) { _ in
            Text(Words(.arabic).sunrise)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("فلاح")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct QawwamWidgets: WidgetBundle {
    var body: some Widget {
        PlaceholderWidget()
    }
}
