import CoreLocation
import QawwamCore

/// Asks for location once, while the app is in use, and returns one rough location or nil if it was refused
/// or failed. Only the nearest city is kept; this point is never saved.
@MainActor
final class CityLocator: NSObject {
    private let manager = CLLocationManager()
    private var waiting: CheckedContinuation<GeoPoint?, Never>?

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func locate() async -> GeoPoint? {
        guard waiting == nil else { return nil }
        return await withCheckedContinuation { continuation in
            waiting = continuation
            manager.delegate = self
            proceed()
        }
    }

    private func proceed() {
        guard waiting != nil else { return }
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: finish(nil)
        }
    }

    private func finish(_ point: GeoPoint?) {
        waiting?.resume(returning: point)
        waiting = nil
    }
}

extension CityLocator: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.proceed() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let point = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        Task { @MainActor in self.finish(point) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }
}
