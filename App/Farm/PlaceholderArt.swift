import QawwamCore
import RealityKit
import UIKit

/// Simple low-poly shapes, in the mockup's style, for every art name the farm can ask for.
/// Real 3D models can replace these later under the same names.
@MainActor
enum PlaceholderArt {
    /// True when `name` has its own shape. Unknown names fall back to bare soil (an empty entity).
    static func isKnown(_ name: String) -> Bool {
        FarmArt.allNames.contains(name)
    }

    /// The shape for `name`, standing on the ground at the origin. Soil names give an empty entity,
    /// because the plot's tile is the soil.
    static func entity(for name: String) -> Entity {
        let root = Entity()
        root.name = name
        let parts = name.split(separator: ".").map(String.init)
        switch parts.first {
        case "palm":
            let stage = Int(parts[1].dropFirst("stage".count)) ?? 0
            palm(stage: stage, wilted: parts.contains("wilted"), fruit: parts.contains("fruit"), into: root)
        case "building":
            building(Building(rawValue: parts.count > 1 ? parts[1] : ""), into: root)
        default:
            break
        }
        return root
    }

    // MARK: Palms

    static let tileTop: Float = 0.08

    private static func palm(stage: Int, wilted: Bool, fruit: Bool, into root: Entity) {
        let y0 = tileTop
        let leafA = UIColor(hex: wilted ? 0xA38A6A : 0x2F7A52)
        let leafB = UIColor(hex: wilted ? 0xB39B78 : 0x3D8A5F)
        switch stage {
        case 1:
            root.addChild(box([0.16, 0.07, 0.16], UIColor(hex: 0x6B4A2E), at: [0, y0 + 0.035, 0]))
        case 2:
            root.addChild(box([0.036, 0.2, 0.036], leafB, at: [0, y0 + 0.1, 0]))
            let angles: [Float] = [0.4, 0.4 + Float.pi]
            for (index, angle) in angles.enumerated() {
                root.addChild(frond(length: 0.2, width: 0.07, yaw: angle, droop: -0.35,
                                    color: index == 0 ? leafA : leafB, at: [0, y0 + 0.2, 0]))
            }
        case 3...5:
            let (height, length, count, radius): (Float, Float, Int, Float) =
                switch stage {
                case 3: (0.3, 0.26, 5, 0.06)
                case 4: (0.52, 0.36, 6, 0.075)
                default: (0.82, 0.48, 8, 0.09)
                }
            let trunk = Entity()
            let segments = 4
            for index in 0..<segments {
                let segmentHeight = height / Float(segments)
                let shrink = 1 - Float(index) * 0.09
                let color = UIColor(hex: index % 2 == 1 ? 0x957049 : (wilted ? 0x8C7A66 : 0x8C6440))
                trunk.addChild(
                    box([radius * 2 * shrink, segmentHeight, radius * 2 * shrink], color,
                        at: [0, y0 + segmentHeight * (Float(index) + 0.5), 0]))
            }
            let crown = Entity()
            crown.position = [0, y0 + height, 0]
            for index in 0..<count {
                let yaw = Float(index) / Float(count) * 2 * .pi + 0.3
                crown.addChild(frond(length: length, width: length * 0.34, yaw: yaw, droop: wilted ? 1.0 : 0.45,
                                     color: index % 2 == 0 ? leafA : leafB, at: .zero))
            }
            if fruit { dates(around: crown, scale: 1) }
            trunk.addChild(crown)
            if wilted { trunk.orientation = simd_quatf(angle: -0.22, axis: [0, 0, 1]) }
            root.addChild(trunk)
        default:
            break
        }
    }

    /// A palm leaf: a thin slab from its base outward, turned by `yaw` and bent down by `droop`.
    private static func frond(
        length: Float, width: Float, yaw: Float, droop: Float, color: UIColor, at position: SIMD3<Float>
    ) -> Entity {
        let pivot = Entity()
        pivot.position = position
        pivot.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0]) * simd_quatf(angle: -droop, axis: [0, 0, 1])
        pivot.addChild(box([length, 0.014, width], color, at: [length / 2, 0, 0]))
        return pivot
    }

    /// Hanging date bunches (عذوق) in orange and red under the crown.
    private static func dates(around crown: Entity, scale: Float) {
        for bunch in 0..<6 {
            let angle = Float(bunch) * .pi / 3 + 0.5
            let x = cos(angle) * 0.15
            let z = sin(angle) * 0.15
            crown.addChild(box([0.02, 0.08, 0.02], UIColor(hex: 0xC99A2E), at: [x, -0.04, z]))
            for step in 0..<3 {
                let size = 0.13 - Float(step) * 0.018
                let color = UIColor(hex: (bunch + step) % 2 == 1 ? 0xE8892B : 0xC9461F)
                crown.addChild(box([size, 0.07, size], color, at: [x, -0.115 - Float(step) * 0.075, z]))
            }
        }
    }

    // MARK: Buildings

    private static func building(_ building: Building?, into root: Entity) {
        switch building {
        case .well: well(into: root)
        case .farmhouse: farmhouse(into: root)
        case .courtyard: courtyard(into: root)
        case .gate: gate(into: root)
        case .mosque: mosque(into: root)
        case nil: break
        }
    }

    private static func well(into root: Entity) {
        root.addChild(cylinder(height: 0.34, radius: 0.38, UIColor(hex: 0xBBA78B), at: [0, 0.17, 0]))
        root.addChild(cylinder(height: 0.01, radius: 0.27, UIColor(hex: 0x2E5A63), at: [0, 0.345, 0]))
        let wood = UIColor(hex: 0x8C6440)
        root.addChild(box([0.08, 0.66, 0.08], wood, at: [-0.32, 0.67, 0]))
        root.addChild(box([0.08, 0.66, 0.08], wood, at: [0.32, 0.67, 0]))
        root.addChild(box([0.84, 0.08, 0.12], wood, at: [0, 1.04, 0]))
        root.addChild(box([0.03, 0.38, 0.03], UIColor(hex: 0x6B4A2E), at: [0, 0.81, 0]))
    }

    /// A Najdi mud-brick house with a crenellated parapet, a door and triangle vents.
    private static func farmhouse(into root: Entity) {
        root.addChild(box([2.4, 1.0, 1.2], UIColor(hex: 0xDDBB90), at: [0, 0.5, 0]))
        let crenel = UIColor(hex: 0xBE9466)
        for index in 0..<12 {
            let x = -1.1 + Float(index) * 0.2
            root.addChild(box([0.1, 0.14, 0.1], crenel, at: [x, 1.07, 0.55]))
            root.addChild(box([0.1, 0.14, 0.1], crenel, at: [x, 1.07, -0.55]))
        }
        for index in 0..<6 {
            let z = -0.5 + Float(index) * 0.2
            root.addChild(box([0.1, 0.14, 0.1], crenel, at: [1.15, 1.07, z]))
            root.addChild(box([0.1, 0.14, 0.1], crenel, at: [-1.15, 1.07, z]))
        }
        root.addChild(box([0.3, 0.55, 0.02], UIColor(hex: 0x6B4A2E), at: [0, 0.275, 0.61]))
        for x: Float in [-0.8, 0.8] {
            root.addChild(box([0.32, 0.2, 0.02], UIColor(hex: 0x7A5634), at: [x, 0.65, 0.61]))
            root.addChild(box([0.12, 0.12, 0.02], UIColor(hex: 0x8E6844), at: [x, 0.88, 0.61]))
        }
    }

    /// A low-walled courtyard with a fountain.
    private static func courtyard(into root: Entity) {
        let wall = UIColor(hex: 0xD9BD94)
        root.addChild(box([1.6, 0.3, 0.1], wall, at: [0, 0.15, -0.75]))
        root.addChild(box([0.1, 0.3, 1.6], wall, at: [-0.75, 0.15, 0]))
        root.addChild(box([0.1, 0.3, 1.6], wall, at: [0.75, 0.15, 0]))
        root.addChild(box([1.4, 0.02, 1.4], UIColor(hex: 0xE9D9BC), at: [0, 0.01, 0]))
        root.addChild(cylinder(height: 0.16, radius: 0.32, UIColor(hex: 0xBBA78B), at: [0, 0.08, 0]))
        root.addChild(cylinder(height: 0.01, radius: 0.26, UIColor(hex: 0x5B9AA6), at: [0, 0.165, 0]))
        root.addChild(cylinder(height: 0.3, radius: 0.04, UIColor(hex: 0xBBA78B), at: [0, 0.3, 0]))
    }

    /// An arched gate between two pillars, with short walls.
    private static func gate(into root: Entity) {
        let stone = UIColor(hex: 0xCFA77B)
        root.addChild(box([0.3, 1.2, 0.3], stone, at: [-0.5, 0.6, 0]))
        root.addChild(box([0.3, 1.2, 0.3], stone, at: [0.5, 0.6, 0]))
        root.addChild(box([1.3, 0.25, 0.3], stone, at: [0, 1.25, 0]))
        root.addChild(cylinder(height: 0.3, radius: 0.36, stone, at: [0, 1.0, 0], axis: [1, 0, 0]))
        root.addChild(box([1.2, 0.45, 0.14], UIColor(hex: 0xDDBB90), at: [-1.25, 0.225, 0]))
        root.addChild(box([1.2, 0.45, 0.14], UIColor(hex: 0xDDBB90), at: [1.25, 0.225, 0]))
    }

    /// A small mosque with a dome and a minaret.
    private static func mosque(into root: Entity) {
        let white = UIColor(hex: 0xEDE6D6)
        root.addChild(box([1.3, 0.8, 1.3], white, at: [0, 0.4, 0]))
        root.addChild(sphere(radius: 0.45, UIColor(hex: 0x3E8E7E), at: [0, 0.85, 0]))
        root.addChild(cylinder(height: 1.8, radius: 0.13, white, at: [0.85, 0.9, -0.4]))
        root.addChild(cone(height: 0.3, radius: 0.16, UIColor(hex: 0x3E8E7E), at: [0.85, 1.95, -0.4]))
        root.addChild(box([0.32, 0.5, 0.02], UIColor(hex: 0x6B4A2E), at: [0, 0.25, 0.66]))
    }

    // MARK: Shapes

    static func material(_ color: UIColor) -> SimpleMaterial {
        SimpleMaterial(color: color, roughness: 0.9, isMetallic: false)
    }

    static func box(_ size: SIMD3<Float>, _ color: UIColor, at position: SIMD3<Float>) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateBox(size: size), materials: [material(color)])
        entity.position = position
        return entity
    }

    static func cylinder(
        height: Float, radius: Float, _ color: UIColor, at position: SIMD3<Float>, axis: SIMD3<Float>? = nil
    ) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateCylinder(height: height, radius: radius), materials: [material(color)])
        entity.position = position
        if let axis { entity.orientation = simd_quatf(angle: .pi / 2, axis: axis) }
        return entity
    }

    static func cone(height: Float, radius: Float, _ color: UIColor, at position: SIMD3<Float>) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateCone(height: height, radius: radius), materials: [material(color)])
        entity.position = position
        return entity
    }

    static func sphere(radius: Float, _ color: UIColor, at position: SIMD3<Float>) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material(color)])
        entity.position = position
        return entity
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
