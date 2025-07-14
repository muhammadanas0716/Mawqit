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

