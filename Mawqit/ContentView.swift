//
//  ContentView.swift
//  Mawqit
//
//  Dark-theme redesign — 14 Jul 2025
//

import SwiftUI
import UIKit
import CoreLocation

// ─────────────────────────── Color Palette (hard-coded)
private let primaryGreen   = Color(red: 0.10, green: 0.55, blue: 0.44)   // #198C71
private let glass          = Color.white.opacity(0.05)                  // subtle card
private let glassStroke    = Color.white.opacity(0.10)

struct ContentView: View {
    @State private var hijri = HijriDate.current()
    @State private var fact  = FunFacts.random(for: HijriDate.current().hijriMonth)
    @AppStorage("hadithIndex") private var hadithIndex = 0
    @State private var dailyDua = ReminderContent.dailyDua(for: Date())
    @State private var dailyReminder = ReminderContent.dailyReminder(for: Date())
    @State private var showSettings = false
    @StateObject private var prayerService = PrayerTimesService()
    @StateObject private var qiblaService = QiblaService()
    @AppStorage("selectedDhikrIndex") private var selectedDhikrIndex = -1
    @AppStorage("userName") private var userName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    GreetingCard(name: userName)
                    DateCard(hijri: hijri)
                    PrayerTimesCard(service: prayerService)
                    QiblaCard(service: qiblaService)
                    HadithCard(hadith: ReminderContent.hadith(at: hadithIndex),
                               index: hadithIndex,
                               total: ReminderContent.hadithCount,
                               onNext: advanceHadith,
                               onPrevious: previousHadith)
                    DailyReminderCard(reminder: dailyReminder, dua: dailyDua)
                    DhikrCounterCard(dhikrs: ReminderContent.dhikrOptions,
                                     selectedIndex: $selectedDhikrIndex,
                                     fallbackIndex: ReminderContent.dailyDhikrIndex(for: Date()))
                    RemindersCard(openSettings: { showSettings = true })
                    FactCard(text: fact)
                    SecondaryInfo(hijri: hijri)
                    YearTimeline(today: hijri)
                    
                    Footer()
                }
                .padding(.top, 40)
                .padding(.horizontal)
                .frame(maxWidth: 600)
            }
            .background(Color.black.ignoresSafeArea())      // pure dark bg
            .scrollIndicators(.hidden)
            .refreshable { refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(primaryGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(primaryGreen)
                }
            }
            .navigationTitle("Mawqit")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)   // force dark on devices in Light
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            prayerService.requestIfNeeded()
            qiblaService.requestIfNeeded()
        }
    }

    private func refresh() {
        hijri = HijriDate.current()
        fact  = FunFacts.random(for: hijri.hijriMonth)
        let now = Date()
        dailyDua = ReminderContent.dailyDua(for: now)
        dailyReminder = ReminderContent.dailyReminder(for: now)
        prayerService.refresh()
        qiblaService.refresh()
        Haptics.impact(.light)
    }

    private func advanceHadith() {
        let total = ReminderContent.hadithCount
        guard total > 0 else { return }
        if hadithIndex < total - 1 {
            hadithIndex += 1
            Haptics.selection()
        } else {
            Haptics.impact(.light)
        }
    }

    private func previousHadith() {
        if hadithIndex > 0 {
            hadithIndex -= 1
            Haptics.selection()
        } else {
            Haptics.impact(.light)
        }
    }
}

 //──────────────────────────── Date Card
private struct DateCard: View {
    let hijri: HijriDate
    var body: some View {
        VStack(spacing: 6) {
            Text(hijri.hijriDay)
                .font(.system(size: 96, weight: .black, design: .serif))
                .minimumScaleFactor(0.5)
                .foregroundColor(.white)

            Text(hijri.hijriMonth)
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundColor(primaryGreen)

            Text(hijri.gregorianDate)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(glass, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }
}

// ─────────────────────────── Greeting
private struct GreetingCard: View {
    let name: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("May your day be filled with barakah.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("🌙")
                .font(.system(size: 28))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var greetingText: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Salam Alaykum"
        }
        return "Salam Alaykum, \(trimmed)"
    }
}

 //──────────────────────────── Fun-Fact Card
private struct FactCard: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(primaryGreen)
            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }
}

// ─────────────────────────── Hadith Card
private struct HadithCard: View {
    let hadith: Hadith
    let index: Int
    let total: Int
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Hadith of the Day", systemImage: "book.closed")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                Text("No. \(displayIndex) of \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ScrollView(.vertical) {
                Text(hadith.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 180)
            .scrollIndicators(.visible)
            .clipped()

            Text(hadith.source)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button {
                    onPrevious()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )
                }
                .disabled(isAtStart)
                .opacity(isAtStart ? 0.5 : 1)

                Button {
                    onNext()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(primaryGreen)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isAtEnd)
                .opacity(isAtEnd ? 0.6 : 1)
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var displayIndex: Int {
        guard total > 0 else { return 0 }
        let safe = min(max(index, 0), total - 1)
        return safe + 1
    }

    private var isAtStart: Bool {
        total == 0 || index <= 0
    }

    private var isAtEnd: Bool {
        total == 0 || index >= total - 1
    }
}

// ─────────────────────────── Daily Reminder
private struct DailyReminderCard: View {
    let reminder: IslamicReminder
    let dua: Dua

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Daily Reminder", systemImage: "sunrise.fill")
                .foregroundColor(primaryGreen)
                .font(.headline)

            Text(reminder.text)
                .font(.body)
                .foregroundColor(.white)

            Divider().background(glassStroke)

            Text("Dua of the Day")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Text(dua.text)
                .font(.footnote)
                .foregroundColor(.secondary)

            Text(dua.source)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }
}

// ─────────────────────────── Dhikr Counter
private struct DhikrCounterCard: View {
    let dhikrs: [Dhikr]
    @Binding var selectedIndex: Int
    let fallbackIndex: Int
    @AppStorage("dhikrCount") private var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dhikr Counter", systemImage: "circle.grid.cross")
                .foregroundColor(primaryGreen)
                .font(.headline)

            HStack {
                Text("Dhikr")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Dhikr", selection: selectionBinding) {
                    ForEach(Array(dhikrs.enumerated()), id: \.offset) { index, dhikr in
                        Text(dhikr.text).tag(index)
                    }
                }
                .pickerStyle(.menu)
                .tint(primaryGreen)
                .onChange(of: selectionBinding.wrappedValue) { _ in
                    Haptics.selection()
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentDhikr.text)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    Text("Recommended: \(currentDhikr.count)x • \(currentDhikr.source)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(count)")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundColor(.white)
            }

            HStack(spacing: 10) {
                Button {
                    count += 1
                    Haptics.selection()
                } label: {
                    Text("Tap +1")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(primaryGreen)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    count = 0
                    Haptics.impact(.light)
                } label: {
                    Text("Reset")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(glass)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(glassStroke, lineWidth: 1)
                        )
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

    private var selectionBinding: Binding<Int> {
        Binding(
            get: { resolvedIndex },
            set: { selectedIndex = $0 }
        )
    }

    private var resolvedIndex: Int {
        guard !dhikrs.isEmpty else { return 0 }
        if selectedIndex < 0 || selectedIndex >= dhikrs.count {
            let safeFallback = ((fallbackIndex % dhikrs.count) + dhikrs.count) % dhikrs.count
            return safeFallback
        }
        return selectedIndex
    }

    private var currentDhikr: Dhikr {
        guard !dhikrs.isEmpty else {
            return Dhikr(text: "Dhikr", count: 0, source: "")
        }
        return dhikrs[resolvedIndex]
    }
}

// ─────────────────────────── Reminders Quick Card
private struct RemindersCard: View {
    let openSettings: () -> Void
    @AppStorage("reminderHadithEnabled") private var hadithEnabled = false
    @AppStorage("reminderDhikrEnabled") private var dhikrEnabled = false
    @AppStorage("reminderJumuahEnabled") private var jumuahEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Reminders", systemImage: "bell.badge")
                .foregroundColor(primaryGreen)
                .font(.headline)

            Text(summaryText)
                .font(.footnote)
                .foregroundColor(.secondary)

            Button {
                Haptics.selection()
                openSettings()
            } label: {
                Text("Manage Notifications")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var summaryText: String {
        let active = [
            hadithEnabled ? "Hadith" : nil,
            dhikrEnabled ? "Dhikr" : nil,
            jumuahEnabled ? "Jumu'ah" : nil
        ].compactMap { $0 }
        if active.isEmpty {
            return "No reminders enabled yet. Set a schedule to stay consistent."
        }
        return "Active: " + active.joined(separator: " • ")
    }
}

// ─────────────────────────── Prayer Times
private struct PrayerTimesCard: View {
    @ObservedObject var service: PrayerTimesService
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Prayer Times", systemImage: "clock")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                if service.isLoading {
                    ProgressView()
                        .tint(primaryGreen)
                }
            }

            Text(service.locationName)
                .font(.caption)
                .foregroundColor(.secondary)

            content
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch service.status {
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Text("Enable location to see prayer times.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        case .notDetermined:
            VStack(alignment: .leading, spacing: 8) {
                Text("Allow location to calculate accurate prayer times.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Enable Location") {
                    service.requestLocation()
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        default:
            if let times = service.times {
                PrayerTimesList(times: times)
            } else if let errorMessage = service.errorMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        service.refresh()
                    }
                    .font(.headline)
                    .tint(primaryGreen)
                }
            } else {
                Text("Fetching prayer times...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct PrayerTimesList: View {
    let times: PrayerTimesDay

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            let next = times.nextPrayer(after: context.date)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(next.0.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(countdownString(to: next.1, now: context.date))
                        .font(.headline)
                        .foregroundColor(primaryGreen)
                }

                VStack(spacing: 6) {
                    ForEach(times.ordered, id: \.0) { item in
                        PrayerTimeRow(name: item.0.displayName,
                                      time: formatTime(item.1, timeZone: times.timeZone),
                                      isNext: item.0 == next.0)
                    }
                }
            }
        }
    }

    private func formatTime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    private func countdownString(to date: Date, now: Date) -> String {
        let interval = max(0, Int(date.timeIntervalSince(now)))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}

// ─────────────────────────── Qibla
private struct QiblaCard: View {
    @ObservedObject var service: QiblaService
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Qibla", systemImage: "location.north")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                if !service.isHeadingAvailable {
                    Text("Compass unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(service.locationName)
                .font(.caption)
                .foregroundColor(.secondary)

            content
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch service.status {
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Text("Enable location to use the Qibla compass.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        case .notDetermined:
            VStack(alignment: .leading, spacing: 8) {
                Text("Allow location to calculate the Qibla direction.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Enable Location") {
                    service.requestLocation()
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        default:
            if !service.isHeadingAvailable, let bearing = service.qiblaBearing {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Compass not available on this device.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("Qibla bearing: \(Int(bearing.rounded()))° from north")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else if let relative = service.relativeAngle {
                QiblaCompass(angle: relative,
                             bearing: service.qiblaBearing,
                             heading: service.heading)
            } else if let error = service.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Text("Calibrating compass...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct QiblaCompass: View {
    let angle: Double
    let bearing: Double?
    let heading: Double?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(glassStroke, lineWidth: 2)
                    .frame(width: 160, height: 160)

                ForEach(0..<4) { idx in
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 2, height: 10)
                        .offset(y: -80)
                        .rotationEffect(.degrees(Double(idx) * 90))
                }

                Image(systemName: "arrow.up")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(primaryGreen)
                    .rotationEffect(.degrees(angle))
                    .animation(.easeInOut(duration: 0.3), value: angle)

                Text("🕋")
                    .font(.system(size: 24))
                    .offset(y: -56)
            }

            HStack {
                if let bearing = bearing {
                    Text("Qibla \(Int(bearing.rounded()))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let heading = heading {
                    Text("Heading \(Int(heading.rounded()))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct PrayerTimeRow: View {
    let name: String
    let time: String
    let isNext: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .foregroundColor(isNext ? .white : .secondary)
            Spacer()
            Text(time)
                .font(.subheadline.weight(isNext ? .semibold : .regular))
                .foregroundColor(isNext ? primaryGreen : .secondary)
        }
    }
}

 //──────────────────────────── Secondary Info
private struct SecondaryInfo: View {
    let hijri: HijriDate
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Hijri Year", systemImage: "calendar")
                .foregroundColor(primaryGreen)
                .font(.headline)

            Text(hijri.hijriYear)
                .font(.title)
                .foregroundColor(.white)
                .padding(.leading, 28)

            Divider().background(glassStroke)

            Label("Coming Soon", systemImage: "clock.badge")
                .foregroundColor(primaryGreen)
                .font(.headline)

            Text("Ramadan tools and more insights are coming soon.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }
}

 //──────────────────────────── Year Timeline
struct YearTimeline: View {
    let today: HijriDate
    private let events: [HijriEvent]
    private let todayOrdinal: Int

    init(today: HijriDate) {
        self.today  = today
        self.events = HijriEvents1447.list.sorted { $0.ordinal < $1.ordinal }
        let cal = Calendar(identifier: .islamicUmmAlQura)
        self.todayOrdinal = cal.ordinality(of: .day, in: .year, for: Date()) ?? 0
    }

    enum Status { case past, current, future }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Timeline \(HijriEvents1447.yearLabel)")
                .font(.headline)
                .foregroundColor(primaryGreen)
                .padding(.bottom, 8)

            ForEach(events) { event in
                TimelineRow(event: event,
                            status: status(for: event),
                            daysDelta: event.ordinal - todayOrdinal)
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private func status(for event: HijriEvent) -> Status {
        if event.ordinal <  todayOrdinal { return .past }
        if event.ordinal == todayOrdinal { return .current }
        return .future
    }
}



private struct TimelineRow: View {
    let event: HijriEvent
    let status: YearTimeline.Status
    let daysDelta: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // marker
            VStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(glassStroke)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            // text
            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayDate)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)

                Text(event.title)
                    .font(.body)
                    .foregroundColor(.white)
                    .strikethrough(status == .past, color: .secondary)

                Text(distanceString)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .opacity(status == .past ? 0.45 : 1)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    private var markerColor: Color {
        switch status {
        case .past:    return .secondary
        case .current: return primaryGreen
        case .future:  return Color(.tertiaryLabel)
        }
    }

    private var distanceString: String {
        switch daysDelta {
        case 0:  return "Today"
        case let x where x > 0:
            return "in \(x) day" + (x == 1 ? "" : "s")
        default:
            let ago = abs(daysDelta)
            return "\(ago) day" + (ago == 1 ? "" : "s") + " ago"
        }
    }
}

// ─────────────────────────── Footer
private struct Footer: View {
    var body: some View {
        VStack(spacing: 4) {
            // top line: “Made with ❤️ by Anas”
            HStack(spacing: 4) {
                Text("Made with")
                    .foregroundColor(.secondary)

                Image(systemName: "heart.fill")
                    .foregroundColor(primaryGreen)

                Text("by")
                    .foregroundColor(.secondary)

                Link("Anas",
                     destination: URL(string: "https://www.linkedin.com/in/muhammadanas0716/")!)
                    .foregroundColor(primaryGreen)
            }
            .font(.footnote)

            // bottom line: “Privacy Policy • Terms & Conditions”
            HStack(spacing: 8) {
                Link("Privacy Policy",
                     destination: URL(string: "https://yourdomain.com/privacy")!)

                Text("•")
                    .foregroundColor(.secondary)

                Link("Terms & Conditions",
                     destination: URL(string: "https://yourdomain.com/terms")!)
            }
            .font(.footnote)
            .foregroundColor(primaryGreen)
        }
        .multilineTextAlignment(.center)          // centers both lines
        .padding(.vertical, 8)                     // tweak as desired
    }
}



 //──────────────────────────── Fun-Facts Store
enum FunFacts {
    private static let data: [String: [String]] = [
        // ❶ Muharram
        "Muharram": [
            "Muharram is one of the four sacred months in Islam.",
            "10 Muharram (Ashura) marks the deliverance of Prophet Musa and his people from Pharaoh.",
            "The word “Muharram” literally means “forbidden,” hinting that warfare paused in this month.",
            "Many Muslims fast on the 9th and 10th (or 10th and 11th) for extra reward.",
            "The Hijri calendar’s year-count began just before 1 Muharram, 17 years after the hijrah."
        ],
        // ❷ Safar
        "Safar": [
            "“Safar” may refer to empty homes when Arabs left for trade journeys.",
            "Early Muslims spoke against pre-Islamic superstitions tied to Safar.",
            "Giving charity in Safar is encouraged by scholars as a positive practice.",
            "The Battle of Khaybar occurred in Safar, 7 AH.",
            "Some linguists link Safar to the root ṣ-f-r, evoking a whistling wind over empty dwellings."
        ],
        // ❸ Rabiʿ al-Awwal
        "Rabi al-Awwal": [
            "Prophet Muhammad ﷺ was born in Rabiʿ al-Awwal, most reports say on the 12th.",
            "The Hijrah to Madinah concluded in Rabiʿ al-Awwal 1 AH with arrival at Qubaʾ.",
            "The first Friday prayer (Jumuʿah) in Islam was held in this month.",
            "Prophet Muhammad ﷺ passed away on 12 Rabiʿ al-Awwal, 11 AH.",
            "“Rabiʿ” means “spring”; Arabs named it during a season of mild weather and grazing."
        ],
        // ❹ Rabiʿ al-Thani
        "Rabi al-Thani": [
            "Also called Rabiʿ al-Akhir (“the latter spring”).",
            "Caliph ʿUmar ibn ʿAbd al-ʿAziz was born in Rabiʿ al-Thani, 63 AH.",
            "Many early Islamic conquests, including parts of Persia, advanced in this month.",
            "It often hosts regional Mawlid celebrations in some cultures, though practices vary.",
            "The name reflects ancient Arabian seasonal cycles rather than modern springtime."
        ],
        // ❺ Jumada al-Ula
        "Jumada al-Ula": [
            "“Jumada” stems from “jamad” (dry/frozen), hinting at scarce water in old Arabian winters.",
            "The Battle of Muʾtah, Islam’s first major engagement with Byzantium, began in Jumada al-Ula 8 AH.",
            "ʿUthman ibn ʿAffan became caliph in Jumada al-Ula 24 AH.",
            "Many scholars completed winter study circles (riyāḍ) during this month.",
            "Historical sources record unusually cold weather across Arabia in several Jumada winters."
        ],
        // ❻ Jumada al-Thaniyah
        "Jumada al-Thaniyah": [
            "Also called Jumada al-Akhirah (“the latter dry month”).",
            "Fatimah al-Zahraʾ, daughter of Prophet Muhammad ﷺ, passed away in Jumada al-Thaniyah 11 AH.",
            "Caliph ʿUmar ibn al-Khattab organized the administrative diwan system this month, 15 AH.",
            "Some early jurists preferred concluding annual zakat audits before Rajab begins.",
            "Classical poets noted the contrast of lingering cold mornings and warming afternoons in this period."
        ],
        // ❼ Rajab
        "Rajab": [
            "Rajab is a sacred month; fighting was traditionally prohibited.",
            "The Isra ʾ and Miʿraj (Night Journey and Ascension) are widely commemorated on 27 Rajab.",
            "Its name comes from “tarjīb” (to respect or magnify).",
            "Umrah performed in Rajab carries extra historical significance for many Muslims.",
            "Older Arabs called it Rajab Muḍar, confirming its fixed position regardless of calendar drift."
        ],
        // ❽ Shaʿban
        "Shaaban": [
            "Prophet Muhammad ﷺ fasted more in Shaʿban than any month outside Ramadan.",
            "15 Shaʿban (Laylat al-Baraʾah) is observed in many cultures for night worship.",
            "The Qiblah direction changed from Jerusalem to Makkah in Shaʿban 2 AH.",
            "Its name points to tribes “dispersing” (shaʿaba) to seek water and booty.",
            "Annual deeds are said to ascend in this month, encouraging extra good works."
        ],
        // ❾ Ramadan
        "Ramadan": [
            "Fasting in Ramadan is the fourth pillar of Islam.",
            "The Qurʾan was first revealed on Laylat al-Qadr within Ramadan.",
            "Breaking the fast with dates and water follows the Sunnah.",
            "The Battle of Badr occurred on 17 Ramadan, 2 AH.",
            "“Ramadan” relates to intense heat, reflecting the blazing ground of early summer."
        ],
        // ❿ Shawwal
        "Shawwal": [
            "Eid al-Fitr opens Shawwal with celebration after a month of fasting.",
            "Marrying in Shawwal was encouraged by Prophet Muhammad ﷺ, refuting old taboos.",
            "Six voluntary fasts in Shawwal grant the reward of fasting the whole year.",
            "The Treaty of Hudaybiyyah was signed in Shawwal 6 AH.",
            "“Shawwal” hints at raised tails of camels (shaala) during breeding season."
        ],
        // ⓫ Dhu al-Qiʿdah
        "Dhu al-Qidah": [
            "A sacred month when warfare was traditionally suspended.",
            "Most of the Treaty of Hudaybiyyah’s pilgrimage rituals happened in Dhu al-Qiʿdah.",
            "The Prophet ﷺ performed three Umrahs in Dhu al-Qiʿdah.",
            "Its name means “the month of sitting,” as Arabs paused campaigns and travel.",
            "Many caravans staged supplies in this lull before Hajj crowds gathered."
        ],
        // ⓬ Dhu al-Hijjah
        "Dhu al-Hijjah": [
            "The month of Hajj; its first ten days are highly virtuous.",
            "Eid al-Adha falls on 10 Dhu al-Hijjah, marking the sacrifice tradition of Ibrahim.",
            "Standing at ʿArafah on 9 Dhu al-Hijjah is the pinnacle of Hajj rituals.",
            "Prophet Muhammad ﷺ delivered his Farewell Sermon in Dhu al-Hijjah 10 AH.",
            "Pilgrims perform rituals at Mina, Muzdalifah, and Mecca during this month."
        ]
    ]

    static func random(for month: String) -> String {
        data[month]?.randomElement() ?? "Welcome to the Hijri calendar!"
    }
}
