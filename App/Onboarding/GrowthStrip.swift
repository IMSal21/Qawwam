import QawwamCore
import SwiftUI

/// The mockup's strip from bare soil to a fruiting palm, stages 0 to 5. Drawn in the mockup's 342 × 84
/// coordinates, soil on the right; mirrored for left-to-right.
struct GrowthStrip: View {
    let words: Words
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        VStack(spacing: 2) {
            Canvas { context, size in
                let scale = min(size.width / 342, size.height / 84)
                context.translateBy(x: (size.width - 342 * scale) / 2, y: 0)
                context.scaleBy(x: scale, y: scale)
                if direction == .leftToRight {
                    context.translateBy(x: 342, y: 0)
                    context.scaleBy(x: -1, y: 1)
                }
                Self.draw(in: &context)
            }
            .frame(height: 84)
            HStack(spacing: 0) {
                ForEach(0..<5) { stage in
                    Text(words.number(stage)).frame(maxWidth: .infinity)
                }
                Text(words.growthOnTime).font(Theme.text(11, .bold)).foregroundStyle(Theme.fruitText)
                    .frame(maxWidth: .infinity)
            }
            .font(Theme.text(11))
            .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.white, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(words.growthLabel)
        .accessibilityAddTraits(.isImage)
    }

    private static let soil = Color(hex: 0xB98A5A)
    private static let trunk = Color(hex: 0x8C6440)
    private static let frond = Color(hex: 0x2F7A52)

    private static func draw(in context: inout GraphicsContext) {
        for x in [314.0, 257, 200, 143, 86, 29] {
            context.fill(Path(ellipseIn: CGRect(x: x - 22, y: 71, width: 44, height: 10)), with: .color(soil))
        }
        // 1: seed
        context.fill(Path(ellipseIn: CGRect(x: 252, y: 67.5, width: 10, height: 7)), with: .color(Color(hex: 0x6B4A2E)))
        // 2: sprout
        line(&context, from: (200, 75), to: (200, 60), color: Color(hex: 0x3D8A5F), width: 3)
        let leaves: [[(Double, Double)]] = [
            [(200, 64), (191, 62), (189, 54), (198, 54)], [(200, 62), (209, 60), (211, 52), (202, 52)],
        ]
        for leaf in leaves {
            var path = Path()
            path.move(to: CGPoint(x: leaf[0].0, y: leaf[0].1))
            path.addQuadCurve(to: CGPoint(x: leaf[2].0, y: leaf[2].1), control: CGPoint(x: leaf[1].0, y: leaf[1].1))
            path.addQuadCurve(to: CGPoint(x: leaf[0].0, y: leaf[0].1), control: CGPoint(x: leaf[3].0, y: leaf[3].1))
            context.fill(path, with: .color(Color(hex: 0x4E9A6C)))
            context.stroke(path, with: .color(Color(hex: 0x3D8A5F)), lineWidth: 1.5)
        }
        // 3: sapling
        line(&context, from: (143, 75), to: (143, 54), color: trunk, width: 3.5)
        fronds(&context, at: (143, 54), [(-8, -4, -15, 2), (8, -4, 15, 2), (-5, -8, -11, -8), (5, -8, 11, -8)], 3)
        // 4: young palm
        curve(&context, from: (86, 75), control: (87, 58), to: (86, 42), width: 4)
        fronds(
            &context, at: (86, 42),
            [(-10, -5, -19, 2), (10, -5, 19, 2), (-7, -10, -14, -10), (7, -10, 14, -10), (-11, 0, -17, 10), (11, 0, 17, 10)],
            3)
        // 5: fruiting palm
        curve(&context, from: (29, 75), control: (30, 52), to: (29, 26), width: 4.5)
        fronds(
            &context, at: (29, 26),
            [(-12, -6, -23, 2), (12, -6, 23, 2), (-8, -12, -16, -12), (8, -12, 16, -12), (-13, 0, -21, 12), (13, 0, 21, 12)],
            3.2)
        let orange = Color(hex: 0xE8892B)
        let red = Color(hex: 0xC9461F)
        let dates: [(Double, Double, Double, Color)] = [
            (23, 33, 3.4, orange), (27, 38, 3.4, red), (33, 33, 3.4, red), (35, 38, 3.4, orange), (21, 39, 3, orange),
        ]
        for (x, y, r, color) in dates {
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(color))
        }
    }

    private static func line(
        _ context: inout GraphicsContext, from: (Double, Double), to: (Double, Double), color: Color, width: Double
    ) {
        var path = Path()
        path.move(to: CGPoint(x: from.0, y: from.1))
        path.addLine(to: CGPoint(x: to.0, y: to.1))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private static func curve(
        _ context: inout GraphicsContext, from: (Double, Double), control: (Double, Double), to: (Double, Double),
        width: Double
    ) {
        var path = Path()
        path.move(to: CGPoint(x: from.0, y: from.1))
        path.addQuadCurve(to: CGPoint(x: to.0, y: to.1), control: CGPoint(x: control.0, y: control.1))
        context.stroke(path, with: .color(trunk), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// Fronds from `origin`, each a quadratic curve given relative to it as (control x, control y, end x, end y).
    private static func fronds(
        _ context: inout GraphicsContext, at origin: (Double, Double), _ curves: [(Double, Double, Double, Double)],
        _ width: Double
    ) {
        var path = Path()
        for (cx, cy, ex, ey) in curves {
            path.move(to: CGPoint(x: origin.0, y: origin.1))
            path.addQuadCurve(
                to: CGPoint(x: origin.0 + ex, y: origin.1 + ey), control: CGPoint(x: origin.0 + cx, y: origin.1 + cy))
        }
        context.stroke(path, with: .color(frond), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}
