import QawwamCore
import RealityKit
import UIKit

/// Builds the 3D farm from the plots and buildings worked out in QawwamCore. It decides only where things
/// stand and how the tiles are coloured; what grows on each plot comes from its art name.
@MainActor
final class FarmScene {
    /// Everything that turns and zooms together.
    let root = Entity()
    /// One entity per day, named `plot-<day>`, that taps can find.
    private(set) var plotEntities: [DayKey: Entity] = [:]
    /// The art name each day shows, so a rebuild can tell which palms grew.
    private(set) var artNames: [DayKey: String] = [:]
    private var selection: Entity?
    private var selectedDay: DayKey?
    /// What the scene was built from, so it is rebuilt only when that changes.
    let signature: String

    static let spacing: Float = 1.08
    static let tileSize: Float = 0.96

    init(plots: [Plot], buildings: [Building]) {
        signature = Self.signature(plots, buildings)
        let rows = (plots.map(\.position.row).max() ?? 4) + 1
        let frontEdge = Self.z(row: rows - 1) + 0.7
        let backEdge: Float = -4.5
        let depth = frontEdge - backEdge
        let centre = (frontEdge + backEdge) / 2

        root.addChild(
            PlaceholderArt.box([8.5, 0.5, depth], UIColor(hex: 0xE3CFA8), at: [0, -0.25, centre]))
        root.addChild(
            PlaceholderArt.box([7.6, 0.45, depth - 0.9], UIColor(hex: 0xA9865E), at: [0, -0.72, centre]))

        for plot in plots {
            let entity = Self.plotEntity(plot)
            root.addChild(entity)
            plotEntities[plot.day] = entity
            artNames[plot.day] = plot.artName
        }

        for building in buildings {
            let entity = PlaceholderArt.entity(for: building.artName)
            entity.position = Self.place(of: building)
            root.addChild(entity)
        }
        for spot: SIMD3<Float> in [[0.3, 0, -3.9], [-1.2, 0, -3.4]] {
            let palm = PlaceholderArt.entity(for: "palm.stage5")
            palm.position = spot - [0, PlaceholderArt.tileTop, 0]
            root.addChild(palm)
        }
    }

    /// Moves the bright gold outline to `day`.
    func select(_ day: DayKey) {
        guard day != selectedDay else { return }
        selectedDay = day
        selection?.removeFromParent()
        guard let plot = plotEntities[day] else { return }
        let frame = Self.frame(color: UIColor(hex: 0xF2C766), width: 0.07)
        frame.position.y = 0.005
        plot.addChild(frame)
        selection = frame
    }

    /// Grows the palms in: all of them one after another on opening, or only those in `days`.
    func grow(only days: Set<DayKey>? = nil, from start: Float = 0.01) {
        let order = plotEntities.keys.sorted()
        for (index, day) in order.enumerated() where days?.contains(day) ?? true {
            guard let art = plotEntities[day]?.findEntity(named: "art"), !art.children.isEmpty else { continue }
            art.scale = SIMD3(repeating: start)
            let delay = days == nil ? 150 + index * 28 : 0
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(delay))
                var grown = art.transform
                grown.scale = .one
                art.move(to: grown, relativeTo: art.parent, duration: 0.52, timingFunction: .easeOut)
            }
        }
    }

    /// The day of the plot that `entity` belongs to.
    static func day(of entity: Entity) -> DayKey? {
        var current: Entity? = entity
        while let node = current {
            if node.name.hasPrefix("plot-") { return DayKey(String(node.name.dropFirst("plot-".count))) }
            current = node.parent
        }
        return nil
    }

    static func signature(_ plots: [Plot], _ buildings: [Building]) -> String {
        plots.map { "\($0.day)|\($0.artName)|\($0.state)|\($0.isToday);" }.joined()
            + buildings.map(\.rawValue).joined(separator: ",")
    }

    // MARK: Layout

    /// Sunday on the right, as the mockup reads in Arabic.
    static func x(column: Int) -> Float { Float(3 - column) * spacing }
    static func z(row: Int) -> Float { Float(row - 2) * spacing + 0.5 }

    static func place(of building: Building) -> SIMD3<Float> {
        switch building {
        case .well: [-2.6, 0, -3.7]
        case .farmhouse: [2.4, 0, -3.65]
        case .courtyard: [-0.6, 0, -3.6]
        case .gate: [-3.45, 0, -2.2]
        case .mosque: [3.45, 0, -2.0]
        }
    }

    private static func plotEntity(_ plot: Plot) -> Entity {
        let entity = Entity()
        entity.name = "plot-\(plot.day.description)"
        entity.position = [x(column: plot.position.column), 0, z(row: plot.position.row)]

        let (top, side) = tileColours(plot.state)
        let tile = PlaceholderArt.box([tileSize, 0.08, tileSize], top, at: [0, 0.04, 0])
        tile.addChild(PlaceholderArt.box([tileSize + 0.002, 0.06, tileSize + 0.002], side, at: [0, -0.012, 0]))
        tile.components.set(CollisionComponent(shapes: [.generateBox(size: [tileSize, 0.6, tileSize])]))
        tile.components.set(InputTargetComponent())
        entity.addChild(tile)

        if plot.state == .fruiting {
            entity.addChild(frame(color: UIColor(hex: 0xE2B13C), width: 0.045))
        } else if plot.isToday {
            entity.addChild(frame(color: UIColor(hex: 0x1E6B4E), width: 0.05))
        }

        let art = PlaceholderArt.entity(for: plot.artName)
        art.name = "art"
        entity.addChild(art)
        return entity
    }

    private static func tileColours(_ state: PlotState) -> (UIColor, UIColor) {
        switch state {
        case .unused: (UIColor(hex: 0xD8C49C), UIColor(hex: 0xC4AC82))
        case .wilted: (UIColor(hex: 0xA99A86), UIColor(hex: 0x8F826F))
        default: (UIColor(hex: 0x9C6B43), UIColor(hex: 0x7E5434))
        }
    }

    /// A thin square outline lying on top of a tile.
    private static func frame(color: UIColor, width: Float) -> Entity {
        let frame = Entity()
        let half = tileSize / 2 - width / 2
        let y = PlaceholderArt.tileTop + 0.006
        frame.addChild(PlaceholderArt.box([tileSize, 0.012, width], color, at: [0, y, half]))
        frame.addChild(PlaceholderArt.box([tileSize, 0.012, width], color, at: [0, y, -half]))
        frame.addChild(PlaceholderArt.box([width, 0.012, tileSize], color, at: [half, y, 0]))
        frame.addChild(PlaceholderArt.box([width, 0.012, tileSize], color, at: [-half, y, 0]))
        return frame
    }
}
