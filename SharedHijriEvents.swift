//
//  SharedHijriEvents.swift
//  Mawqit
//
//  Shared Hijri events for app + widgets
//

import Foundation

/// Helper to convert any Hijri (Umm-al-Qura) date → absolute ordinal
private func hijriOrdinal(year: Int, month: Int, day: Int) -> Int {
    let cal = Calendar(identifier: .islamicUmmAlQura)
    var comps = DateComponents()
    comps.year  = year
    comps.month = month
    comps.day   = day
    guard let date = cal.date(from: comps) else { return .max }
    return cal.ordinality(of: .day, in: .year, for: date) ?? .max
}

struct HijriEvent: Identifiable, Hashable {
    let id: String
    let monthIndex: Int        // 1 = Muharram … 12 = Dhu al-Hijjah
    let day: Int
    let title: String
    let info: String           // short description

    // cached during init for fast compare
    let ordinal: Int

    init(monthIndex: Int, day: Int, title: String, info: String, year: Int) {
        self.monthIndex = monthIndex
        self.day   = day
        self.title = title
        self.info  = info
        self.id = "\(monthIndex)-\(day)-\(title)"
        self.ordinal = hijriOrdinal(year: year, month: monthIndex, day: day)
    }

    /// Display “10 Muharram”
    var displayDate: String {
        let name = Calendar(identifier: .islamicUmmAlQura)
            .monthSymbols[monthIndex - 1]
        return "\(day) \(name)"
    }
}

/// Major dates for the current Hijri year
enum HijriEvents1447 {
    static var currentYear: Int {
        let cal = Calendar(identifier: .islamicUmmAlQura)
        return cal.component(.year, from: Date())
    }

    static var yearLabel: String {
        "\(currentYear) AH"
    }

    static var list: [HijriEvent] {
        let year = currentYear
        return [
            .init(monthIndex: 1,  day: 10, title: "ʿĀshūrāʾ",
                  info: "Commemoration of Prophet Musa’s deliverance", year: year),
            .init(monthIndex: 3,  day: 12, title: "Mawlid (Sunni)",
                  info: "Prophet Muhammad’s birthday", year: year),
            .init(monthIndex: 4,  day: 17, title: "Mawlid (Shia)",
                  info: "Alternate Mawlid date", year: year),
            .init(monthIndex: 7,  day: 27, title: "Isrāʾ & Miʿrāj",
                  info: "Night-Journey & Ascension", year: year),
            .init(monthIndex: 8,  day: 15, title: "Mid-Shaʿbān",
                  info: "Night of forgiveness (Shab-e-Barat)", year: year),
            .init(monthIndex: 9,  day: 1,  title: "Start of Ramadan",
                  info: "First day of fasting", year: year),
            .init(monthIndex: 9,  day: 17, title: "Badr Anniversary",
                  info: "Battle of Badr (2 AH)", year: year),
            .init(monthIndex: 9,  day: 27, title: "Laylat al-Qadr (obs.)",
                  info: "Likely Night of Power", year: year),
            .init(monthIndex: 10, day: 1,  title: "Eid al-Fiṭr",
                  info: "Festival after Ramadan", year: year),
            .init(monthIndex: 11, day: 8,  title: "Hajj Begins",
                  info: "Pilgrims arrive in Makkah", year: year),
            .init(monthIndex: 12, day: 8,  title: "Tarwiyah",
                  info: "Pilgrims leave to Mina", year: year),
            .init(monthIndex: 12, day: 9,  title: "ʿArafah",
                  info: "Standing at Mount ʿArafāt", year: year),
            .init(monthIndex: 12, day: 10, title: "Eid al-Aḍḥā",
                  info: "Festival of Sacrifice", year: year),
            .init(monthIndex: 12, day: 11, title: "Tashrīq 1",
                  info: "Stoning ritual continues", year: year),
            .init(monthIndex: 12, day: 13, title: "Tashrīq 3 / Hajj Ends",
                  info: "Final day of stoning", year: year)
        ]
    }

    static func upcomingEvents(from date: Date, limit: Int) -> [(HijriEvent, Int)] {
        let cal = Calendar(identifier: .islamicUmmAlQura)
        let todayOrdinal = cal.ordinality(of: .day, in: .year, for: date) ?? 0
        let yearLength = cal.range(of: .day, in: .year, for: date)?.count ?? 354

        let sorted = list.sorted { $0.ordinal < $1.ordinal }
        let upcoming = sorted.filter { $0.ordinal >= todayOrdinal }

        let candidates = upcoming.isEmpty ? sorted : upcoming
        let count = min(max(1, limit), candidates.count)

        return Array(candidates.prefix(count)).map { event in
            let delta = event.ordinal >= todayOrdinal
                ? event.ordinal - todayOrdinal
                : (yearLength - todayOrdinal) + event.ordinal
            return (event, delta)
        }
    }
}
