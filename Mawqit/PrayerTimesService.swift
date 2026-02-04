//
//  PrayerTimesService.swift
//  Mawqit
//

import Foundation
import CoreLocation

struct PrayerTimesDay: Hashable {
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let timeZone: TimeZone

    var ordered: [(PrayerName, Date)] {
        [
            (.fajr, fajr),
            (.sunrise, sunrise),
            (.dhuhr, dhuhr),
            (.asr, asr),
            (.maghrib, maghrib),
            (.isha, isha)
        ]
    }

    func nextPrayer(after date: Date) -> (PrayerName, Date) {
        if let upcoming = ordered.first(where: { $0.1 > date }) {
            return upcoming
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let nextFajr = calendar.date(byAdding: .day, value: 1, to: fajr) ?? fajr.addingTimeInterval(86_400)
        return (.fajr, nextFajr)
    }
}

enum PrayerName: String {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
}

@MainActor
final class PrayerTimesService: NSObject, ObservableObject {
    @Published var status: CLAuthorizationStatus
    @Published var locationName: String = "Current Location"
    @Published var times: PrayerTimesDay?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var lastFetchLocation: CLLocation?
    private var lastFetchDate: Date?

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.status = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestIfNeeded() {
        switch status {
        case .notDetermined:
            requestLocation()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func refresh() {
        manager.requestLocation()
    }

    private func shouldFetch(for location: CLLocation) -> Bool {
        if let last = lastFetchLocation, let lastDate = lastFetchDate {
            let distance = last.distance(from: location)
            let timeDelta = Date().timeIntervalSince(lastDate)
            if distance < 250 && timeDelta < 1_800 {
                return false
            }
        }
        return true
    }

    private func fetchPrayerTimes(for location: CLLocation) async {
        if !shouldFetch(for: location) { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await PrayerTimesAPI.fetchTimings(latitude: location.coordinate.latitude,
                                                                longitude: location.coordinate.longitude)
            let timezone = TimeZone(identifier: response.meta.timezone) ?? .current
            if let day = PrayerTimesParser.parseTimings(response.timings, timeZone: timezone) {
                times = day
                lastFetchLocation = location
                lastFetchDate = Date()
                await NotificationManager.shared.schedulePrayerAlerts(for: day)
            } else {
                errorMessage = "Could not parse prayer times."
            }
        } catch {
            errorMessage = "Unable to load prayer times."
        }

        isLoading = false
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
}

extension PrayerTimesService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateLocationName(for: location)
        Task { await fetchPrayerTimes(for: location) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location unavailable."
        isLoading = false
    }
}

private enum PrayerTimesAPI {
    static func fetchTimings(latitude: Double, longitude: Double) async throws -> PrayerTimesResponse {
        let dateString = formattedDate(Date())
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.aladhan.com"
        components.path = "/v1/timings/\(dateString)"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "method", value: "2"),
            URLQueryItem(name: "school", value: "0")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(PrayerTimesResponseWrapper.self, from: data)
        return decoded.data
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}

private enum PrayerTimesParser {
    static func parseTimings(_ timings: PrayerTimings, timeZone: TimeZone) -> PrayerTimesDay? {
        guard let fajr = makeDate(timings.fajr, timeZone: timeZone),
              let sunrise = makeDate(timings.sunrise, timeZone: timeZone),
              let dhuhr = makeDate(timings.dhuhr, timeZone: timeZone),
              let asr = makeDate(timings.asr, timeZone: timeZone),
              let maghrib = makeDate(timings.maghrib, timeZone: timeZone),
              let isha = makeDate(timings.isha, timeZone: timeZone) else {
            return nil
        }
        return PrayerTimesDay(fajr: fajr,
                              sunrise: sunrise,
                              dhuhr: dhuhr,
                              asr: asr,
                              maghrib: maghrib,
                              isha: isha,
                              timeZone: timeZone)
    }

    private static func makeDate(_ value: String, timeZone: TimeZone) -> Date? {
        let cleaned = value.components(separatedBy: " ").first ?? value
        let parts = cleaned.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)
    }
}

private struct PrayerTimesResponseWrapper: Decodable {
    let data: PrayerTimesResponse
}

private struct PrayerTimesResponse: Decodable {
    let timings: PrayerTimings
    let meta: PrayerMeta
}

private struct PrayerTimings: Decodable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String

    private enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case maghrib = "Maghrib"
        case isha = "Isha"
    }
}

private struct PrayerMeta: Decodable {
    let timezone: String
}
