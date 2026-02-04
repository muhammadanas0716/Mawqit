//
//  QiblaService.swift
//  Mawqit
//

import Foundation
import CoreLocation

@MainActor
final class QiblaService: NSObject, ObservableObject {
    @Published var status: CLAuthorizationStatus
    @Published var locationName: String = "Current Location"
    @Published var qiblaBearing: Double?
    @Published var heading: Double?
    @Published var isHeadingAvailable: Bool
    @Published var errorMessage: String?

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.status = manager.authorizationStatus
        self.isHeadingAvailable = CLLocationManager.headingAvailable()
        super.init()
        manager.delegate = self
    }

    func requestIfNeeded() {
        switch status {
        case .notDetermined:
            requestLocation()
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdates()
        default:
            break
        }
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        startUpdates()
    }

    func refresh() {
        startUpdates()
    }

    private func startUpdates() {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
            if isHeadingAvailable {
                manager.startUpdatingHeading()
            }
        }
    }

    private func updateLocationName(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let place = placemarks?.first
            let city = place?.locality
            let country = place?.country
            let name = [city, country].compactMap { $0 }.joined(separator: ", ")
            if !name.isEmpty {
                Task { @MainActor in
                    self.locationName = name
                }
            }
        }
    }

    private func updateQibla(for location: CLLocation) {
        let bearing = QiblaCalculator.bearing(from: location.coordinate)
        qiblaBearing = bearing
    }

    var relativeAngle: Double? {
        guard let bearing = qiblaBearing, let heading = heading else { return nil }
        let angle = bearing - heading
        return QiblaCalculator.normalize(angle)
    }
}

extension QiblaService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startUpdates()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateLocationName(for: location)
        updateQibla(for: location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        heading = value
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location unavailable."
    }
}

private enum QiblaCalculator {
    private static let kaaba = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    static func bearing(from coordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = degreesToRadians(coordinate.latitude)
        let lon1 = degreesToRadians(coordinate.longitude)
        let lat2 = degreesToRadians(kaaba.latitude)
        let lon2 = degreesToRadians(kaaba.longitude)

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let radians = atan2(y, x)
        let degrees = radiansToDegrees(radians)
        return normalize(degrees)
    }

    static func normalize(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }

    private static func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }

    private static func radiansToDegrees(_ value: Double) -> Double {
        value * 180 / .pi
    }
}
