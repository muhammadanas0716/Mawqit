//
//  MawqitWatchWidget.swift
//  MawqitWatchWidget
//

import WidgetKit
import SwiftUI

struct WatchHijriEntry: TimelineEntry {
    let date: Date
    let hijriDate: HijriDate
}

struct WatchHijriProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchHijriEntry {
        WatchHijriEntry(date: Date(), hijriDate: HijriDate.current())
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchHijriEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchHijriEntry>) -> Void) {
        let now = Date()
        let entry = WatchHijriEntry(date: now, hijriDate: HijriDate.current())
        let nextMidnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct WatchHijriWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchHijriProvider.Entry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.hijriDate.hijriDay) \(entry.hijriDate.hijriMonth)")
        case .accessoryCircular:
            ZStack {
                Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                VStack(spacing: 2) {
                    Text(entry.hijriDate.hijriDay)
                        .font(.headline)
                    Text("AH")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Hijri Date")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(entry.hijriDate.hijriDay) \(entry.hijriDate.hijriMonth)")
                    .font(.caption.weight(.semibold))
                Text("\(entry.hijriDate.hijriYear) AH")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        case .accessoryCorner:
            Text(entry.hijriDate.hijriDay)
        default:
            EmptyView()
        }
    }
}

struct MawqitWatchHijriWidget: Widget {
    let kind = "MawqitWatchHijriWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchHijriProvider()) { entry in
            WatchHijriWidgetView(entry: entry)
        }
        .configurationDisplayName("Hijri Date")
        .description("Current Hijri date.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}

struct WatchUpcomingEntry: TimelineEntry {
    let date: Date
    let upcoming: [UpcomingEventItem]
}

struct WatchUpcomingProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchUpcomingEntry {
        WatchUpcomingEntry(date: Date(), upcoming: loadUpcoming(from: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchUpcomingEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchUpcomingEntry>) -> Void) {
        let now = Date()
        let entry = WatchUpcomingEntry(date: now, upcoming: loadUpcoming(from: now))
        let nextMidnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func loadUpcoming(from date: Date) -> [UpcomingEventItem] {
        HijriEvents1447.upcomingEvents(from: date, limit: 3).map { item in
            UpcomingEventItem(event: item.0, days: item.1)
        }
    }
}

struct WatchUpcomingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchUpcomingProvider.Entry

    var body: some View {
        switch family {
        case .accessoryInline:
            if let first = entry.upcoming.first {
                Text("Next: \(first.event.title)")
            } else {
                Text("Upcoming")
            }
        case .accessoryCircular:
            ZStack {
                Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                VStack(spacing: 2) {
                    Text("Next")
                        .font(.caption2)
                    Text(shortDays)
                        .font(.caption2.weight(.semibold))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Upcoming")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let first = entry.upcoming.first {
                    Text(first.event.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(distanceString(first.days))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No events")
                        .font(.caption)
                }
            }
        case .accessoryCorner:
            Text(shortDays)
        default:
            EmptyView()
        }
    }

    private var shortDays: String {
        guard let first = entry.upcoming.first else { return "--" }
        return first.days == 0 ? "0d" : "\(first.days)d"
    }

    private func distanceString(_ days: Int) -> String {
        switch days {
        case 0: return "Today"
        case 1: return "in 1 day"
        default: return "in \(days) days"
        }
    }
}

struct MawqitWatchUpcomingWidget: Widget {
    let kind = "MawqitWatchUpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchUpcomingProvider()) { entry in
            WatchUpcomingWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Hijri")
        .description("Next 2-3 Hijri dates.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}
