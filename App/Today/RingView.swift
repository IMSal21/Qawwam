import QawwamCore
import SwiftUI

/// Five arcs for today's prayers, Fajr first, from the top. Runs the reading direction's way.
struct RingView: View {
    let segments: [RingSegment]
    let lineWidth: CGFloat = 11
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                let gap = 0.02
                Circle()
                    .trim(from: Double(index) / 5 + gap, to: Double(index + 1) / 5 - gap)
                    .stroke(Self.color(segment), style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            }
        }
        .rotationEffect(.degrees(-90))
        .scaleEffect(x: direction == .rightToLeft ? -1 : 1, y: 1)
        .padding(lineWidth / 2)
        // Draw in a fixed direction; the flip above makes Arabic run counterclockwise from the top.
        .environment(\.layoutDirection, .leftToRight)
    }

    static func color(_ segment: RingSegment) -> Color {
        switch segment {
        case .onTime: Theme.palm
        case .late: Theme.lateRing
        case .due: Theme.dueRing
        case .upcoming: Theme.line
        case .missed: Theme.missed
        }
    }
}
