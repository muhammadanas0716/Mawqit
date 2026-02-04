//
//  SettingsView.swift
//  Mawqit
//

import SwiftUI
import UserNotifications
import UIKit

private let primaryGreen = Color(red: 0.10, green: 0.55, blue: 0.44)
private let glass = Color.white.opacity(0.05)
private let glassStroke = Color.white.opacity(0.10)

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("reminderHadithEnabled") private var hadithEnabled = false
    @AppStorage("reminderHadithTimeSeconds") private var hadithTimeSeconds: Double = 8 * 3600

    @AppStorage("reminderDhikrEnabled") private var dhikrEnabled = false
    @AppStorage("reminderDhikrTimeSeconds") private var dhikrTimeSeconds: Double = 19 * 3600

    @AppStorage("reminderJumuahEnabled") private var jumuahEnabled = false
    @AppStorage("reminderJumuahTimeSeconds") private var jumuahTimeSeconds: Double = 9 * 3600

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    statusCard
                    reminderCard(
                        title: "Hadith Reminder",
                        subtitle: "A short daily reminder to open your hadith.",
                        isOn: $hadithEnabled,
                        time: timeBinding($hadithTimeSeconds)
                    )

                    reminderCard(
                        title: "Dhikr Reminder",
                        subtitle: "Pause for dhikr and reflection.",
                        isOn: $dhikrEnabled,
                        time: timeBinding($dhikrTimeSeconds)
                    )

                    reminderCard(
                        title: "Jumu'ah Reminder",
                        subtitle: "Weekly reminder every Friday.",
                        isOn: $jumuahEnabled,
                        time: timeBinding($jumuahTimeSeconds),
                        isWeekly: true
                    )
                }
                .padding(.top, 24)
                .padding(.horizontal)
                .frame(maxWidth: 640)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(primaryGreen)
                }
            }
            .onChange(of: hadithEnabled) { _ in updateNotifications() }
            .onChange(of: dhikrEnabled) { _ in updateNotifications() }
            .onChange(of: jumuahEnabled) { _ in updateNotifications() }
            .onChange(of: hadithTimeSeconds) { _ in updateNotifications() }
            .onChange(of: dhikrTimeSeconds) { _ in updateNotifications() }
            .onChange(of: jumuahTimeSeconds) { _ in updateNotifications() }
            .task { await refreshAuthorizationStatus() }
        }
        .preferredColorScheme(.dark)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notifications", systemImage: "bell.badge")
                .foregroundColor(primaryGreen)
                .font(.headline)

            Text(statusText)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                Task {
                    if authorizationStatus == .denied {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                        return
                    }
                    _ = await NotificationManager.shared.requestAuthorization()
                    await refreshAuthorizationStatus()
                    updateNotifications()
                    Haptics.success()
                }
            } label: {
                Text(buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(primaryGreen)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(authorizationStatus == .authorized)
            .opacity(authorizationStatus == .authorized ? 0.6 : 1)
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private func reminderCard(title: String, subtitle: String, isOn: Binding<Bool>, time: Binding<Date>, isWeekly: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(primaryGreen)
            .onChange(of: isOn.wrappedValue) { _ in Haptics.selection() }

            if isOn.wrappedValue {
                HStack {
                    Label(isWeekly ? "Friday" : "Daily", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(primaryGreen)
                }
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var statusText: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled. Customize your reminder schedule below."
        case .denied:
            return "Notifications are disabled in Settings. Enable them to receive reminders."
        case .notDetermined:
            return "Enable notifications to receive daily reminders."
        @unknown default:
            return "Enable notifications to receive daily reminders."
        }
    }

    private var buttonTitle: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications Enabled"
        case .denied:
            return "Open Settings"
        case .notDetermined:
            return "Enable Notifications"
        @unknown default:
            return "Enable Notifications"
        }
    }

    private func refreshAuthorizationStatus() async {
        authorizationStatus = await NotificationManager.shared.authorizationStatus()
    }

    private func updateNotifications() {
        Task {
            let wantsNotifications = hadithEnabled || dhikrEnabled || jumuahEnabled
            if wantsNotifications {
                let granted = await NotificationManager.shared.requestAuthorization()
                if !granted {
                    await MainActor.run {
                        hadithEnabled = false
                        dhikrEnabled = false
                        jumuahEnabled = false
                    }
                    await refreshAuthorizationStatus()
                    return
                }
            }
            let settings = ReminderSettings(
                hadithEnabled: hadithEnabled,
                hadithTimeSeconds: hadithTimeSeconds,
                dhikrEnabled: dhikrEnabled,
                dhikrTimeSeconds: dhikrTimeSeconds,
                jumuahEnabled: jumuahEnabled,
                jumuahTimeSeconds: jumuahTimeSeconds
            )
            await NotificationManager.shared.apply(settings: settings)
            await refreshAuthorizationStatus()
        }
    }

    private func timeBinding(_ seconds: Binding<Double>) -> Binding<Date> {
        Binding<Date>(
            get: { dateFromSeconds(seconds.wrappedValue) },
            set: { seconds.wrappedValue = secondsFromDate($0) }
        )
    }

    private func dateFromSeconds(_ seconds: Double) -> Date {
        let calendar = Calendar.current
        let totalSeconds = max(0, Int(seconds))
        let hour = totalSeconds / 3600
        let minute = (totalSeconds % 3600) / 60
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private func secondsFromDate(_ date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        return Double(hour * 3600 + minute * 60)
    }
}
