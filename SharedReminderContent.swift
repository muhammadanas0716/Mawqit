//
//  SharedReminderContent.swift
//  Mawqit
//
//  Shared daily reminders for app + widgets
//

import Foundation

enum HadithBook: String, CaseIterable, Hashable, Identifiable {
    case riyadAsSalihin = "riyad_as_salihin"
    case selectedCollection = "selected_collection"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .riyadAsSalihin:
            return "Riyad as-Salihin"
        case .selectedCollection:
            return "Selected Hadith"
        }
    }
}

struct Hadith: Hashable {
    let text: String
    let source: String
    let book: HadithBook
    let number: Int
}

struct Dua: Hashable {
    let text: String
    let source: String
}

struct Dhikr: Hashable {
    let text: String
    let count: Int
    let source: String
}

struct IslamicReminder: Hashable {
    let text: String
    let source: String
}

struct DailyContent: Hashable {
    let hadith: Hadith
    let dua: Dua
    let dhikr: Dhikr
    let reminder: IslamicReminder

    static func forDate(_ date: Date) -> DailyContent {
        DailyContent(
            hadith: ReminderContent.dailyHadith(for: date),
            dua: ReminderContent.dailyDua(for: date),
            dhikr: ReminderContent.dailyDhikr(for: date),
            reminder: ReminderContent.dailyReminder(for: date)
        )
    }
}

enum ReminderContent {
    private static let hadithsByBook: [HadithBook: [Hadith]] = {
        let riyad = HadithLoader.loadRiyadHadiths() ?? []
        return [
            .riyadAsSalihin: riyad,
            .selectedCollection: fallbackHadiths
        ]
    }()

    static var hadithBooks: [HadithBook] {
        HadithBook.allCases.filter { !hadiths(for: $0).isEmpty }
    }

    static var defaultHadithBook: HadithBook {
        if !(hadithsByBook[.riyadAsSalihin] ?? []).isEmpty {
            return .riyadAsSalihin
        }
        return .selectedCollection
    }

    private static let fallbackHadiths: [Hadith] = [
        Hadith(text: "Actions are judged by intentions.", source: "Sahih al-Bukhari & Sahih Muslim", book: .selectedCollection, number: 1),
        Hadith(text: "The best among you are those who learn the Quran and teach it.", source: "Sahih al-Bukhari", book: .selectedCollection, number: 2),
        Hadith(text: "Allah does not look at your bodies or wealth, but at your hearts and deeds.", source: "Sahih Muslim", book: .selectedCollection, number: 3),
        Hadith(text: "None of you truly believes until he loves for his brother what he loves for himself.", source: "Sahih al-Bukhari & Sahih Muslim", book: .selectedCollection, number: 4),
        Hadith(text: "Whoever believes in Allah and the Last Day should speak good or remain silent.", source: "Sahih al-Bukhari & Sahih Muslim", book: .selectedCollection, number: 5),
        Hadith(text: "Smiling in your brother's face is charity.", source: "Jami` at-Tirmidhi", book: .selectedCollection, number: 6)
    ]

    static let duas: [Dua] = [
        Dua(text: "O Allah, help me remember You, thank You, and worship You well.", source: "Sunan Abi Dawud"),
        Dua(text: "Our Lord, grant us good in this world and good in the Hereafter and protect us from the punishment of the Fire.", source: "Quran 2:201"),
        Dua(text: "O Allah, I seek Your forgiveness and well-being in this world and the next.", source: "Sunan Abi Dawud")
    ]

    static let dhikrs: [Dhikr] = [
        Dhikr(text: "SubhanAllah", count: 33, source: "Bukhari & Muslim"),
        Dhikr(text: "Alhamdulillah", count: 33, source: "Bukhari & Muslim"),
        Dhikr(text: "Allahu Akbar", count: 34, source: "Bukhari & Muslim"),
        Dhikr(text: "Astaghfirullah", count: 100, source: "Sahih Muslim"),
        Dhikr(text: "La ilaha illa Allah, wahdahu la sharika lah", count: 10, source: "Sahih al-Bukhari" )
    ]

    static let reminders: [IslamicReminder] = [
        IslamicReminder(text: "Renew your intention before your actions.", source: ""),
        IslamicReminder(text: "Guard the five daily prayers; they anchor the day.", source: ""),
        IslamicReminder(text: "Send blessings upon the Prophet today.", source: ""),
        IslamicReminder(text: "Give a small charity, even a smile.", source: ""),
        IslamicReminder(text: "Seek forgiveness often: say 'Astaghfirullah'.", source: ""),
        IslamicReminder(text: "Recite a few verses of the Quran with reflection.", source: ""),
        IslamicReminder(text: "Make dua for someone who cannot ask you.", source: ""),
        IslamicReminder(text: "Be gentle in speech, even when correcting.", source: ""),
        IslamicReminder(text: "Keep wudu when possible to stay mindful.", source: ""),
        IslamicReminder(text: "Pray two rak'ahs of gratitude if you can.", source: ""),
        IslamicReminder(text: "Say Bismillah before tasks.", source: ""),
        IslamicReminder(text: "End the day with Istighfar.", source: ""),
        IslamicReminder(text: "Check on parents or elders today.", source: ""),
        IslamicReminder(text: "Feed someone or share a meal.", source: ""),
        IslamicReminder(text: "Give water to anyone in need.", source: ""),
        IslamicReminder(text: "Lower the gaze and guard modesty.", source: ""),
        IslamicReminder(text: "Replace a complaint with gratitude.", source: ""),
        IslamicReminder(text: "Make a brief plan around prayer times.", source: ""),
        IslamicReminder(text: "Read one hadith and act on it.", source: ""),
        IslamicReminder(text: "Smile at a stranger.", source: ""),
        IslamicReminder(text: "Avoid gossip and backbiting.", source: ""),
        IslamicReminder(text: "Forgive someone for Allah's sake.", source: ""),
        IslamicReminder(text: "Send salawat when you hear the Prophet's name.", source: ""),
        IslamicReminder(text: "Keep your promise, even in small things.", source: ""),
        IslamicReminder(text: "Choose patience at the first moment of anger.", source: ""),
        IslamicReminder(text: "Clean a shared space as a quiet charity.", source: ""),
        IslamicReminder(text: "Make tawbah after mistakes.", source: ""),
        IslamicReminder(text: "Visit the masjid if you can.", source: ""),
        IslamicReminder(text: "Read morning and evening adhkar.", source: ""),
        IslamicReminder(text: "Give a small sadaqah today.", source: ""),
        IslamicReminder(text: "Make dua for the Ummah.", source: ""),
        IslamicReminder(text: "Be kind to neighbors.", source: ""),
        IslamicReminder(text: "Keep a light tongue with dhikr.", source: ""),
        IslamicReminder(text: "Share beneficial knowledge.", source: ""),
        IslamicReminder(text: "Renew sincerity before each prayer.", source: ""),
        IslamicReminder(text: "Eat with the right hand and say Alhamdulillah.", source: ""),
        IslamicReminder(text: "Avoid wasting time; use moments for dhikr.", source: ""),
        IslamicReminder(text: "Seek knowledge for 10 minutes.", source: ""),
        IslamicReminder(text: "Reconcile between two people if possible.", source: ""),
        IslamicReminder(text: "Help someone with a task today.", source: ""),
        IslamicReminder(text: "Speak truthfully, even when hard.", source: ""),
        IslamicReminder(text: "Recite Ayat al-Kursi after prayers.", source: ""),
        IslamicReminder(text: "Pray Witr before sleeping.", source: ""),
        IslamicReminder(text: "Give thanks for one specific blessing.", source: ""),
        IslamicReminder(text: "Control anger with silence and wudu.", source: ""),
        IslamicReminder(text: "Make istighfar 100 times today.", source: ""),
        IslamicReminder(text: "Send a message of kindness to a friend.", source: ""),
        IslamicReminder(text: "Maintain ties of kinship.", source: ""),
        IslamicReminder(text: "Avoid envy by making dua for others.", source: ""),
        IslamicReminder(text: "Read a page of Quran before sleep.", source: ""),
        IslamicReminder(text: "Protect the tongue from harsh words.", source: ""),
        IslamicReminder(text: "Make dua when entering and leaving home.", source: ""),
        IslamicReminder(text: "Give a sincere compliment.", source: ""),
        IslamicReminder(text: "Take a short walk and reflect on Allah's creation.", source: ""),
        IslamicReminder(text: "End the day with Surah Al-Ikhlas, Al-Falaq, and An-Nas.", source: "")
    ]

    static func hadiths(for book: HadithBook) -> [Hadith] {
        hadithsByBook[book] ?? []
    }

    static func dailyHadith(for date: Date, in book: HadithBook? = nil) -> Hadith {
        let resolvedBook = resolved(book)
        return hadith(at: dailyHadithIndex(for: date, in: resolvedBook), in: resolvedBook)
    }

    static func dailyDua(for date: Date) -> Dua {
        pick(from: duas, date: date, salt: 7)
    }

    static func dailyDhikr(for date: Date) -> Dhikr {
        let index = dailyDhikrIndex(for: date)
        return dhikrs[index]
    }

    static func dailyReminder(for date: Date) -> IslamicReminder {
        pick(from: reminders, date: date, salt: 21)
    }

    static var dhikrOptions: [Dhikr] {
        dhikrs
    }

    static func dailyDhikrIndex(for date: Date) -> Int {
        dailyIndex(for: dhikrs.count, date: date, salt: 13)
    }

    static func dailyHadithIndex(for date: Date, in book: HadithBook? = nil) -> Int {
        let list = hadiths(for: resolved(book))
        return dailyIndex(for: list.count, date: date, salt: 0)
    }

    static var hadithCount: Int {
        hadithCount(in: defaultHadithBook)
    }

    static func hadithCount(in book: HadithBook) -> Int {
        hadiths(for: book).count
    }

    static func hadith(at index: Int, in book: HadithBook? = nil) -> Hadith {
        let list = hadiths(for: resolved(book))
        guard !list.isEmpty else {
            return Hadith(text: "Welcome to Mawqit.", source: "", book: resolved(book), number: 0)
        }
        let safeIndex = min(max(index, 0), list.count - 1)
        return list[safeIndex]
    }

    static func hadithIndex(number: Int, in book: HadithBook) -> Int? {
        guard number > 0 else { return nil }
        return hadiths(for: book).firstIndex(where: { $0.number == number })
    }

    static func hadith(number: Int, in book: HadithBook) -> Hadith? {
        guard let index = hadithIndex(number: number, in: book) else { return nil }
        return hadiths(for: book)[index]
    }

    private static func pick<T>(from list: [T], date: Date, salt: Int) -> T {
        guard !list.isEmpty else {
            fatalError("ReminderContent list is empty")
        }
        let index = dailyIndex(for: list.count, date: date, salt: salt)
        return list[index]
    }

    private static func dailyIndex(for count: Int, date: Date, salt: Int) -> Int {
        let safeCount = max(1, count)
        let ordinal = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return (ordinal + salt) % safeCount
    }

    private static func resolved(_ book: HadithBook?) -> HadithBook {
        if let book, !hadiths(for: book).isEmpty {
            return book
        }
        return defaultHadithBook
    }
}

private enum HadithLoader {
    static func loadRiyadHadiths() -> [Hadith]? {
        guard let url = Bundle.main.url(forResource: "riyad_assalihin", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(RiyadRoot.self, from: data)
            let mapped = decoded.hadiths.enumerated().compactMap { offset, hadith -> Hadith? in
                let text = normalize(hadith.english.text)
                guard !text.isEmpty else { return nil }
                let narrator = normalize(hadith.english.narrator)
                var source = "Riyad as-Salihin"
                if !narrator.isEmpty {
                    source += " • \(narrator)"
                }
                let number = hadith.idInBook ?? hadith.id ?? (offset + 1)
                return Hadith(text: text, source: source, book: .riyadAsSalihin, number: number)
            }
            return mapped.isEmpty ? nil : mapped
        } catch {
            return nil
        }
    }

    private static func normalize(_ value: String) -> String {
        let replaced = value.replacingOccurrences(of: "\n", with: " ")
        return replaced.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct RiyadRoot: Decodable {
        let hadiths: [RiyadHadith]
    }

    private struct RiyadHadith: Decodable {
        let id: Int?
        let idInBook: Int?
        let english: English
    }

    private struct English: Decodable {
        let narrator: String
        let text: String
    }
}
