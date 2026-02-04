//
//  MawqitReminderWidget.swift
//  MawqitWidget
//

import WidgetKit
import SwiftUI

struct MawqitReminderEntry: TimelineEntry {
    let date: Date
    let daily: DailyContent
}

struct MawqitReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> MawqitReminderEntry {
        MawqitReminderEntry(date: Date(), daily: DailyContent.forDate(Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (MawqitReminderEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MawqitReminderEntry>) -> Void) {
        let now = Date()
        let nextMidnight = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        let entry = MawqitReminderEntry(date: now, daily: DailyContent.forDate(now))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct MawqitReminderWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MawqitReminderProvider.Entry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("Hadith ready")
                .containerBackground(for: .widget) { Color.clear }

        case .accessoryCircular:
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                VStack(spacing: 2) {
                    Text("Dhikr")
                        .font(.caption2)
                    Text("\(entry.daily.dhikr.count)x")
                        .font(.caption2.weight(.bold))
                }
            }
            .containerBackground(for: .widget) { Color.clear }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Hadith of the Day")
                    .font(.caption2.weight(.semibold))
                Text(entry.daily.hadith.text)
                    .font(.caption2)
                    .lineLimit(2)
            }
            .containerBackground(for: .widget) { Color.clear }

        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                Text("Hadith of the Day")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.gray)
                Text(entry.daily.hadith.text)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .lineLimit(4)
                Text(entry.daily.hadith.source)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(red: 20/255, green: 40/255, blue: 25/255)
            }

        case .systemMedium:
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hadith of the Day")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gray)
                    Text(entry.daily.hadith.text)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .lineLimit(3)
                    Text(entry.daily.hadith.source)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Reminder")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gray)
                    Text(entry.daily.reminder.text)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(3)
                }
            }
            .padding()
            .containerBackground(for: .widget) {
                Color(red: 20/255, green: 40/255, blue: 25/255)
            }

        case .systemLarge, .systemExtraLarge:
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily Inspiration")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.gray)

                Text(entry.daily.hadith.text)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(3)

                Text(entry.daily.hadith.source)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider().background(Color.white.opacity(0.2))

                Text("Dua of the Day")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.gray)

                Text(entry.daily.dua.text)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .lineLimit(3)

                HStack {
                    Text(entry.daily.dua.source)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Dhikr: \(entry.daily.dhikr.text) \(entry.daily.dhikr.count)x")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
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
}

struct MawqitReminderWidget: Widget {
    let kind = "MawqitReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MawqitReminderProvider()) { entry in
            MawqitReminderWidgetView(entry: entry)
        }
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .configurationDisplayName("Daily Inspiration")
        .description("Hadith, dua, and reminders for the day.")
    }
}
