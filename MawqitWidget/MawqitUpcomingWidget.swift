//
//  MawqitUpcomingWidget.swift
//  MawqitWidget
//

import WidgetKit
import SwiftUI

struct MawqitUpcomingEntry: TimelineEntry {
    let date: Date
    let hijriDate: HijriDate
    let upcoming: [UpcomingEventItem]
}

struct UpcomingEventItem: Hashable {
    let event: HijriEvent
    let days: Int
}

struct MawqitUpcomingProvider: TimelineProvider {
    func placeholder(in context: Context) -> MawqitUpcomingEntry {
        MawqitUpcomingEntry(date: Date(),
                            hijriDate: HijriDate.current(),
                            upcoming: sampleUpcoming())
    }

    func getSnapshot(in context: Context, completion: @escaping (MawqitUpcomingEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MawqitUpcomingEntry>) -> Void) {
        let now = Date()
        let entry = MawqitUpcomingEntry(date: now,
                                        hijriDate: HijriDate.current(),
                                        upcoming: loadUpcoming(from: now))
        let nextMidnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func loadUpcoming(from date: Date) -> [UpcomingEventItem] {
        HijriEvents1447.upcomingEvents(from: date, limit: 3).map { item in
            UpcomingEventItem(event: item.0, days: item.1)
        }
    }

    private func sampleUpcoming() -> [UpcomingEventItem] {
        loadUpcoming(from: Date())
    }
}

struct MawqitUpcomingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MawqitUpcomingProvider.Entry

    var body: some View {
        switch family {
        case .accessoryInline:
            if let next = entry.upcoming.first {
                Text("Next: \(next.event.title) \(distanceString(next.days))")
                    .containerBackground(for: .widget) { Color.clear }
            } else {
                Text("Upcoming dates")
                    .containerBackground(for: .widget) { Color.clear }
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Upcoming")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let next = entry.upcoming.first {
                    Text(next.event.title)
                        .font(.caption.weight(.semibold))
                    Text(distanceString(next.days))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No events")
                        .font(.caption)
                }
            }
            .containerBackground(for: .widget) { Color.clear }

        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                Text("Upcoming")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.gray)
                if let next = entry.upcoming.first {
                    Text(next.event.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text(distanceString(next.days))
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("No events")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(red: 20/255, green: 40/255, blue: 25/255)
            }

        case .systemMedium:
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Upcoming Dates")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gray)
                    Text("\(entry.hijriDate.hijriMonth) \(entry.hijriDate.hijriYear) AH")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.upcoming.prefix(2), id: \.self) { item in
                        HStack {
                            Text(item.event.title)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                            Text(distanceString(item.days))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(red: 20/255, green: 40/255, blue: 25/255)
            }

        case .systemLarge, .systemExtraLarge:
            VStack(alignment: .leading, spacing: 10) {
                Text("Upcoming Hijri Dates")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.gray)

                HStack {
                    Text("\(entry.hijriDate.hijriDay) \(entry.hijriDate.hijriMonth)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(entry.hijriDate.hijriYear) AH")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Divider().background(Color.white.opacity(0.2))

                VStack(spacing: 8) {
                    ForEach(entry.upcoming, id: \.self) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.event.displayDate)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Text(item.event.title)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(distanceString(item.days))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(red: 20/255, green: 40/255, blue: 25/255)
            }

        default:
            EmptyView()
        }
    }

    private func distanceString(_ days: Int) -> String {
        switch days {
        case 0: return "Today"
        case 1: return "in 1 day"
        default: return "in \(days) days"
        }
    }
}

struct MawqitUpcomingWidget: Widget {
    let kind = "MawqitUpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MawqitUpcomingProvider()) { entry in
            MawqitUpcomingWidgetView(entry: entry)
        }
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline
        ])
        .configurationDisplayName("Upcoming Hijri Dates")
        .description("See the next major dates in the Hijri calendar.")
    }
}
