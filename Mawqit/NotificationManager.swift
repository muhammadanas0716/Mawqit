//
//  NotificationManager.swift
//  Mawqit
//

import Foundation
import UserNotifications

struct ReminderSettings: Hashable {
    var hadithEnabled: Bool
    var hadithTimeSeconds: Double
    var dhikrEnabled: Bool
    var dhikrTimeSeconds: Double
    var jumuahEnabled: Bool
    var jumuahTimeSeconds: Double
}

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private let hadithId = "mawqit.hadith.daily"
    private let dhikrId = "mawqit.dhikr.daily"
    private let jumuahId = "mawqit.jumuah.weekly"
    private let prayerIds = [
        "mawqit.prayer.fajr",
        "mawqit.prayer.dhuhr",
        "mawqit.prayer.asr",
        "mawqit.prayer.maghrib",
        "mawqit.prayer.isha"
    ]

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func apply(settings: ReminderSettings) async {
        let ids = [hadithId, dhikrId, jumuahId]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)

        let greeting = "Salam Alykum"

        if settings.hadithEnabled {
            let components = timeComponents(from: settings.hadithTimeSeconds)
            let content = UNMutableNotificationContent()
            content.title = greeting
            content.body = "Your daily hadith is ready in Mawqit."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: hadithId, content: content, trigger: trigger)
            try? await center.add(request)
        }

        if settings.dhikrEnabled {
            let components = timeComponents(from: settings.dhikrTimeSeconds)
            let content = UNMutableNotificationContent()
            content.title = greeting
            content.body = "Take a moment for dhikr and reflection."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: dhikrId, content: content, trigger: trigger)
            try? await center.add(request)
        }

        if settings.jumuahEnabled {
            var components = timeComponents(from: settings.jumuahTimeSeconds)
            components.weekday = 6 // Friday (1 = Sunday)
            let content = UNMutableNotificationContent()
            content.title = greeting
            content.body = "Prepare for Jumu'ah prayers and khutbah."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: jumuahId, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func schedulePrayerAlerts(for day: PrayerTimesDay) async {
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: prayerIds)
        center.removeDeliveredNotifications(withIdentifiers: prayerIds)

        let greeting = "Salam Alykum"
        let calendar = Calendar(identifier: .gregorian)

        let prayerTimes: [(PrayerName, Date, String)] = [
            (.fajr, day.fajr, prayerIds[0]),
            (.dhuhr, day.dhuhr, prayerIds[1]),
            (.asr, day.asr, prayerIds[2]),
            (.maghrib, day.maghrib, prayerIds[3]),
            (.isha, day.isha, prayerIds[4])
        ]

        for (name, time, id) in prayerTimes {
            guard let alertDate = calendar.date(byAdding: .minute, value: -15, to: time) else { continue }
            var components = calendar.dateComponents([.hour, .minute], from: alertDate)
            components.timeZone = day.timeZone

            let content = UNMutableNotificationContent()
            content.title = greeting
            content.body = "\(name.displayName) in 15 minutes."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func timeComponents(from seconds: Double) -> DateComponents {
        let totalSeconds = max(0, Int(seconds))
        let hour = totalSeconds / 3600
        let minute = (totalSeconds % 3600) / 60
        return DateComponents(hour: hour, minute: minute)
    }
}
