//
//  ContentView.swift
//  Mawqit
//
//  Dark-theme redesign — 14 Jul 2025
//

import SwiftUI

// ─────────────────────────── Color Palette (hard-coded)
private let primaryGreen   = Color(red: 0.10, green: 0.55, blue: 0.44)   // #198C71
private let glass          = Color.white.opacity(0.05)                  // subtle card
private let glassStroke    = Color.white.opacity(0.10)

struct ContentView: View {
    @State private var hijri = HijriDate.current()
    @State private var fact  = FunFacts.random(for: HijriDate.current().hijriMonth)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    DateCard(hijri: hijri)
                    FactCard(text: fact)
                    SecondaryInfo(hijri: hijri)
                    YearTimeline(today: hijri)
                }
                .padding(.top, 40)
                .padding(.horizontal)
                .frame(maxWidth: 600)
            }
            .background(Color.black.ignoresSafeArea())      // pure dark bg
            .scrollIndicators(.hidden)
            .refreshable { refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { refresh() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(primaryGreen)
                }
            }
            .navigationTitle("Mawqit")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)   // force dark on devices in Light
    }

    private func refresh() {
        hijri = HijriDate.current()
        fact  = FunFacts.random(for: hijri.hijriMonth)
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

            Text("Prayer times and significant dates will appear here.")
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
            Text("Timeline 1447 AH")
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

 //──────────────────────────── Fun-Facts Store
enum FunFacts {
    private static let data: [String: [String]] = [
        "Muharram": [
            "Muharram is one of the four sacred months in Islam.",
            "10 Muharram (Ashura) commemorates Prophet Musa’s deliverance.",
            "‘Muharram’ literally means ‘forbidden’—warfare paused.",
            "Many Muslims fast on 9–10 Muharram for extra reward.",
            "Hijri calendar numbering began just before 1 Muharram."
        ],
        "Safar": [
            "‘Safar’ may refer to empty homes during pre-Islamic travel.",
            "Early Muslims refuted superstitions tied to Safar.",
            "Charity in Safar has been encouraged by scholars.",
            "The Battle of Khaybar occurred in Safar 7 AH.",
            "Linguists link Safar to the root ‘ṣ-f-r’ (whistling wind)."
        ]
        // …add five for each remaining month…
    ]

    static func random(for month: String) -> String {
        data[month]?.randomElement() ?? "Welcome to the Hijri calendar!"
    }
}

