//
//  HijriEvents.swift
//  Mawqit
//
//  Created by Muhammad Anas on 14/07/2025.
//

import Foundation

/// One-off helper to convert any Hijri (Umm-al-Qura) date → absolute ordinal
private func hijriOrdinal(year: Int, month: Int, day: Int) -> Int {
    let cal = Calendar(identifier: .islamicUmmAlQura)
    var comps = DateComponents()
    comps.year  = year
    comps.month = month
    comps.day   = day
    guard let date = cal.date(from: comps) else { return .max }
    // days since 1 Muharram of same year
    return cal.ordinality(of: .day, in: .year, for: date) ?? .max
}

struct HijriEvent: Identifiable {
    let id = UUID()
    let monthIndex: Int        // 1 = Muharram … 12 = Dhu al-Hijjah
    let day: Int
    let title: String
    let info: String           // short description

    // cached during init for fast compare
    let ordinal: Int

    init(monthIndex: Int, day: Int, title: String, info: String) {
        self.monthIndex = monthIndex
        self.day   = day
        self.title = title
        self.info  = info
        // 1447 AH hard-coded; adapt if you load next year
        self.ordinal = hijriOrdinal(year: 1447,
                                    month: monthIndex,
                                    day: day)
    }

    /// Display “10 Muharram”
    var displayDate: String {
        let name = Calendar(identifier: .islamicUmmAlQura)
            .monthSymbols[monthIndex - 1]
        return "\(day) \(name)"
    }
}

/// 15 major dates for 1447 AH
enum HijriEvents1447 {
    static let list: [HijriEvent] = [
        .init(monthIndex: 1,  day: 10, title: "ʿĀshūrāʾ",
              info: "Commemoration of Prophet Musa’s deliverance"),
        .init(monthIndex: 3,  day: 12, title: "Mawlid (Sunni)",
              info: "Prophet Muhammad’s birthday"),
        .init(monthIndex: 4,  day: 17, title: "Mawlid (Shia)",
              info: "Alternate Mawlid date"),
        .init(monthIndex: 7,  day: 27, title: "Isrāʾ & Miʿrāj",
              info: "Night-Journey & Ascension"),
        .init(monthIndex: 8,  day: 15, title: "Mid-Shaʿbān",
              info: "Night of forgiveness (Shab-e-Barat)"),
        .init(monthIndex: 9,  day: 1,  title: "Start of Ramadan",
              info: "First day of fasting"),
        .init(monthIndex: 9,  day: 17, title: "Badr Anniversary",
              info: "Battle of Badr (2 AH)"),
        .init(monthIndex: 9,  day: 27, title: "Laylat al-Qadr (obs.)",
              info: "Likely Night of Power"),
        .init(monthIndex: 10, day: 1,  title: "Eid al-Fiṭr",
              info: "Festival after Ramadan"),
        .init(monthIndex: 11, day: 8,  title: "Hajj Begins",
              info: "Pilgrims arrive in Makkah"),
        .init(monthIndex: 12, day: 8,  title: "Tarwiyah",
              info: "Pilgrims leave to Mina"),
        .init(monthIndex: 12, day: 9,  title: "ʿArafah",
              info: "Standing at Mount ʿArafāt"),
        .init(monthIndex: 12, day: 10, title: "Eid al-Aḍḥā",
              info: "Festival of Sacrifice"),
        .init(monthIndex: 12, day: 11, title: "Tashrīq 1",
              info: "Stoning ritual continues"),
        .init(monthIndex: 12, day: 13, title: "Tashrīq 3 / Hajj Ends",
              info: "Final day of stoning")
    ]
}

