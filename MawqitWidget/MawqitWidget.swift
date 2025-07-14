//
//  MawqitWidget.swift
//  MawqitWidget
//
//  Created by Muhammad Anas on 14/07/2025.
//

import WidgetKit
import SwiftUI

struct MawqitEntry: TimelineEntry {
    let date: Date
    let hijriDate: HijriDate
}

struct MawqitProvider: TimelineProvider {
    func placeholder(in context: Context) -> MawqitEntry {
        MawqitEntry(date: Date(), hijriDate: HijriDate.current())
    }

    func getSnapshot(in context: Context, completion: @escaping (MawqitEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MawqitEntry>) -> Void) {
        let now = Date()
        let nextMidnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        let entry = MawqitEntry(date: now, hijriDate: HijriDate.current())
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Widget View
struct MawqitWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MawqitProvider.Entry

    var body: some View {
        switch family {

        // ───────── Lock-Screen • Inline ─────────
        case .accessoryInline:
            Text("🌙 \(entry.hijriDate.hijriDay) \(entry.hijriDate.hijriMonth)")
                .containerBackground(for: .widget) { Color.clear }

        // ──────── Lock-Screen • Rectangular ─────
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(entry.hijriDate.hijriDay) \(entry.hijriDate.hijriMonth)")
                    Text("🌙")
                }
                .font(.headline)
                Text("\(entry.hijriDate.hijriYear) AH")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .containerBackground(for: .widget) { Color.clear }

        // ───────── Home-Screen • 2×2 (Small) ────
        case .systemSmall:
            VStack(spacing: 4) {
                Text(entry.hijriDate.hijriDay)
                    .font(.system(size: 44, weight: .black, design: .serif))
                Text(entry.hijriDate.hijriMonth)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(entry.hijriDate.hijriYear)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                Color(red: 20/255, green: 40/255, blue: 25/255)
            }

        // ─────── Home-Screen • 2-row (Medium) ───
        case .systemMedium:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.hijriDate.hijriMonth)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("\(entry.hijriDate.hijriYear) AH")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(entry.hijriDate.gregorianDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(entry.hijriDate.hijriDay)
                    .font(.system(size: 56, weight: .black, design: .serif))
                    .foregroundColor(.white)
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(red: 20/255, green: 40/255, blue: 25/255)
            }

        // ─────────── Fallback ───────────
        default:
            EmptyView()
        }
    }
}

// MARK: - Widget Definition
struct MawqitWidget: Widget {
    let kind = "MawqitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MawqitProvider()) { entry in
            MawqitWidgetEntryView(entry: entry)
        }
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline
        ])
        .configurationDisplayName("Hijri Date")
        .description("Shows today's Hijri date with a moon icon.")
    }
}

