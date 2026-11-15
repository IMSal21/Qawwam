import QawwamCore
import RealityKit
import SwiftUI

/// How the farm is being looked at: turned by `yaw`, tilted by `pitch`, and zoomed.
struct FarmCamera: Equatable {
    var yaw: Float = -0.62
    var pitch: Float = 0.6
    var zoom: Float = 1

    static let pitchRange: ClosedRange<Float> = 0.32...1.15
    static let zoomRange: ClosedRange<Float> = 0.6...2.6

    mutating func turn(by angle: Float) { yaw += angle }
    mutating func tilt(by angle: Float) { pitch = min(max(pitch + angle, Self.pitchRange.lowerBound), Self.pitchRange.upperBound) }
    mutating func zoom(by factor: Float) { zoom = min(max(zoom * factor, Self.zoomRange.lowerBound), Self.zoomRange.upperBound) }
}

/// The 3D farm. Drag to turn and tilt, pinch to zoom, tap a plot to select its day.
struct FarmSceneView: View {
    let plots: [Plot]
    let buildings: [Building]
    let selected: DayKey
    @Binding var camera: FarmCamera
    let onSelect: (DayKey) -> Void

    @State private var box = SceneBox()
    @State private var dragStart: CGSize = .zero
    @State private var zoomStart: Float?

    var body: some View {
        RealityView { content in
            content.camera = .virtual
            let scene = FarmScene(plots: plots, buildings: buildings)
            scene.select(selected)
            scene.root.orientation = simd_quatf(angle: camera.yaw, axis: [0, 1, 0])
            content.add(scene.root)
            box.scene = scene

            let key = DirectionalLight()
            key.light.intensity = 2600
            key.look(at: .zero, from: [-4.5, 8, 4], relativeTo: nil)
            content.add(key)
            let fill = DirectionalLight()
            fill.light.intensity = 900
            fill.look(at: .zero, from: [5, 4, -3], relativeTo: nil)
            content.add(fill)

            let lens = PerspectiveCamera()
            lens.camera.fieldOfViewInDegrees = 40
            Self.place(lens, camera: camera)
            content.add(lens)
            box.lens = lens
        } update: { content in
            guard var scene = box.scene else { return }
            if scene.signature != FarmScene.signature(plots, buildings) {
                content.remove(scene.root)
                scene = FarmScene(plots: plots, buildings: buildings)
                content.add(scene.root)
                box.scene = scene
            }
            scene.select(selected)
            scene.root.orientation = simd_quatf(angle: camera.yaw, axis: [0, 1, 0])
            if let lens = box.lens { Self.place(lens, camera: camera) }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let day = FarmScene.day(of: value.entity) { onSelect(day) }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    let dx = Float(value.translation.width - dragStart.width)
                    let dy = Float(value.translation.height - dragStart.height)
                    camera.turn(by: dx * 0.011)
                    camera.tilt(by: dy * 0.006)
                    dragStart = value.translation
                }
                .onEnded { _ in dragStart = .zero }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    let start = zoomStart ?? camera.zoom
                    zoomStart = start
                    camera.zoom = min(max(start * Float(value.magnification), FarmCamera.zoomRange.lowerBound),
                                      FarmCamera.zoomRange.upperBound)
                }
                .onEnded { _ in zoomStart = nil }
        )
    }

    /// The camera looks at the middle of the farm from a distance set by the zoom and a height set by the tilt.
    private static func place(_ lens: PerspectiveCamera, camera: FarmCamera) {
        let distance = 15 / camera.zoom
        let target: SIMD3<Float> = [0, 0, -0.4]
        let eye = target + [0, sin(camera.pitch) * distance, cos(camera.pitch) * distance]
        lens.look(at: target, from: eye, relativeTo: nil)
    }
}

/// Keeps the scene and camera between updates.
@MainActor
final class SceneBox {
    var scene: FarmScene?
    var lens: PerspectiveCamera?
}
