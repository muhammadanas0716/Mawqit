//
//  SharedHijriDate.swift
//  Mawqit
//
//  Created by Muhammad Anas on 14/07/2025.
//

import Foundation

struct HijriDate {
    let hijriDay: String
    let hijriMonth: String
    let hijriYear: String
    let gregorianDate: String

    static func current() -> HijriDate {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        let today = Date()
        let components = calendar.dateComponents([.day, .month, .year], from: today)

        let hijriDay = "\(components.day ?? 0)"
        let hijriMonth = calendar.monthSymbols[(components.month ?? 1) - 1]
        let hijriYear = "\(components.year ?? 0)"

        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "en_US")
        let gregorianDate = formatter.string(from: today)

        return HijriDate(
            hijriDay: hijriDay,
            hijriMonth: hijriMonth,
            hijriYear: hijriYear,
            gregorianDate: gregorianDate
        )
    }
}
