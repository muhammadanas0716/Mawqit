//
//  WatchContentView.swift
//  MawqitWatch
//

import SwiftUI

struct WatchContentView: View {
    @State private var hijri = HijriDate.current()
    @State private var upcoming = HijriEvents1447.upcomingEvents(from: Date(), limit: 2)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mawqit")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(hijri.hijriDay) \(hijri.hijriMonth)")
                        .font(.title3.weight(.semibold))
                    Text("\(hijri.hijriYear) AH")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                Text("Upcoming")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                ForEach(upcoming, id: \.0.id) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0.title)
                            .font(.subheadline)
                        Text(distanceString(item.1))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .onAppear {
            refresh()
        }
    }

    private func refresh() {
        hijri = HijriDate.current()
        upcoming = HijriEvents1447.upcomingEvents(from: Date(), limit: 2)
    }

    private func distanceString(_ days: Int) -> String {
        switch days {
        case 0: return "Today"
        case 1: return "In 1 day"
        default: return "In \(days) days"
        }
    }
}
