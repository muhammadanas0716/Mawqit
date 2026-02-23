//
//  ContentView.swift
//  Mawqit
//
//  Dark-theme redesign — 14 Jul 2025
//

import SwiftUI
import UIKit
import CoreLocation

// ─────────────────────────── Color Palette (hard-coded)
private let primaryGreen   = Color(red: 0.10, green: 0.55, blue: 0.44)   // #198C71
private let glass          = Color.white.opacity(0.05)                  // subtle card
private let glassStroke    = Color.white.opacity(0.10)

private struct HadithReadRecord: Codable, Hashable {
    let bookRawValue: String
    let number: Int

    init(book: HadithBook, number: Int) {
        self.bookRawValue = book.rawValue
        self.number = number
    }

    var book: HadithBook {
        HadithBook(rawValue: bookRawValue) ?? .selectedCollection
    }
}

private struct HadithBookmarkRecord: Codable, Hashable, Identifiable {
    let bookRawValue: String
    let number: Int
    let createdAt: TimeInterval

    init(book: HadithBook, number: Int, createdAt: TimeInterval = Date().timeIntervalSince1970) {
        self.bookRawValue = book.rawValue
        self.number = number
        self.createdAt = createdAt
    }

    var book: HadithBook {
        HadithBook(rawValue: bookRawValue) ?? .selectedCollection
    }

    var id: String {
        "\(bookRawValue)-\(number)"
    }
}

private enum HadithReadLogStore {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func decode(_ raw: String) -> [String: [HadithReadRecord]] {
        guard !raw.isEmpty else { return [:] }
        guard let data = raw.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: [HadithReadRecord]].self, from: data)) ?? [:]
    }

    static func encode(_ log: [String: [HadithReadRecord]]) -> String {
        guard let data = try? JSONEncoder().encode(log),
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }
        return value
    }

    static func decodeBookmarks(_ raw: String) -> [HadithBookmarkRecord] {
        guard !raw.isEmpty else { return [] }
        guard let data = raw.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([HadithBookmarkRecord].self, from: data)) ?? []
    }

    static func encodeBookmarks(_ bookmarks: [HadithBookmarkRecord]) -> String {
        guard let data = try? JSONEncoder().encode(bookmarks),
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }
        return value
    }
}

struct ContentView: View {
    @State private var hijri = HijriDate.current()
    @State private var fact  = FunFacts.random(for: HijriDate.current().hijriMonth)
    @AppStorage("quranSelectedSurah") private var quranSelectedSurah = 1
    @AppStorage("quranSelectedPage") private var quranSelectedPage = 1
    @AppStorage("hadithIndex") private var hadithIndex = 0
    @AppStorage("selectedHadithBook") private var selectedHadithBookRaw = HadithBook.riyadAsSalihin.rawValue
    @AppStorage("hadithReadLog") private var hadithReadLogStorage = ""
    @AppStorage("hadithBookmarks") private var hadithBookmarksStorage = ""
    @State private var dailyDua = ReminderContent.dailyDua(for: Date())
    @State private var dailyReminder = ReminderContent.dailyReminder(for: Date())
    @State private var showSettings = false
    @State private var showQuranReader = false
    @State private var showHadithBookmarks = false
    @StateObject private var quranService = QuranService()
    @StateObject private var prayerService = PrayerTimesService()
    @StateObject private var qiblaService = QiblaService()
    @AppStorage("selectedDhikrIndex") private var selectedDhikrIndex = -1
    @AppStorage("userName") private var userName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    GreetingCard(name: userName)
                    DateCard(hijri: hijri)
                    PrayerTimesCard(service: prayerService)
                    QiblaCard(service: qiblaService)
                    QuranCard(service: quranService,
                              selectedSurah: $quranSelectedSurah,
                              onOpenReader: { showQuranReader = true })
                    HadithCard(hadith: currentHadith,
                               index: hadithIndex,
                               total: currentHadithTotal,
                               books: availableHadithBooks,
                               selectedBook: selectedHadithBook,
                               isReadToday: isReadToday,
                               isBookmarked: isBookmarked,
                               onSelectBook: selectHadithBook,
                               onRead: markCurrentHadithRead,
                               onToggleBookmark: toggleCurrentHadithBookmark,
                               onCopy: copyCurrentHadith,
                               onShowBookmarks: { showHadithBookmarks = true },
                               onNext: advanceHadith,
                               onPrevious: previousHadith)
                    HadithReadCalendarCard(selectedBook: selectedHadithBook, log: hadithReadLog)
                    DailyReminderCard(reminder: dailyReminder, dua: dailyDua)
                    DhikrCounterCard(dhikrs: ReminderContent.dhikrOptions,
                                     selectedIndex: $selectedDhikrIndex,
                                     fallbackIndex: ReminderContent.dailyDhikrIndex(for: Date()))
                    RemindersCard(openSettings: { showSettings = true })
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.selection()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(primaryGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(primaryGreen)
                }
            }
            .navigationTitle("Mawqit")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)   // force dark on devices in Light
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showQuranReader) {
            QuranMushafView(service: quranService, selectedPage: $quranSelectedPage)
        }
        .sheet(isPresented: $showHadithBookmarks) {
            HadithBookmarksView(
                bookmarks: sortedBookmarks,
                onSelect: jumpToBookmark,
                onDelete: deleteBookmark
            )
        }
        .task {
            normalizeHadithBookSelection()
            normalizeHadithIndex()
            let safeSurah = normalizedSurah(quranSelectedSurah)
            let safePage = normalizedPage(quranSelectedPage)
            if safeSurah != quranSelectedSurah {
                quranSelectedSurah = safeSurah
            }
            if safePage != quranSelectedPage {
                quranSelectedPage = safePage
            }
            prayerService.requestIfNeeded()
            qiblaService.requestIfNeeded()
            await quranService.loadIfNeeded(initialSurah: safeSurah)
            await quranService.loadPageIfNeeded(initialPage: safePage)
        }
        .onChange(of: quranSelectedSurah) { _, newValue in
            let safeSurah = normalizedSurah(newValue)
            if safeSurah != quranSelectedSurah {
                quranSelectedSurah = safeSurah
                return
            }
            Task {
                await quranService.loadSurah(number: safeSurah)
            }
        }
        .onChange(of: quranSelectedPage) { _, newValue in
            let safePage = normalizedPage(newValue)
            if safePage != quranSelectedPage {
                quranSelectedPage = safePage
                return
            }
            Task {
                await quranService.loadPage(number: safePage)
            }
        }
        .onChange(of: selectedHadithBookRaw) { _, _ in
            normalizeHadithBookSelection()
            normalizeHadithIndex()
        }
    }

    private func refresh() {
        hijri = HijriDate.current()
        fact  = FunFacts.random(for: hijri.hijriMonth)
        let now = Date()
        dailyDua = ReminderContent.dailyDua(for: now)
        dailyReminder = ReminderContent.dailyReminder(for: now)
        prayerService.refresh()
        qiblaService.refresh()
        Task {
            await quranService.loadSurah(number: normalizedSurah(quranSelectedSurah), forceRefresh: true)
            await quranService.loadPage(number: normalizedPage(quranSelectedPage), forceRefresh: true)
        }
        Haptics.impact(.light)
    }

    private func advanceHadith() {
        let total = currentHadithTotal
        guard total > 0 else { return }
        if hadithIndex < total - 1 {
            hadithIndex += 1
            Haptics.selection()
        } else {
            Haptics.impact(.light)
        }
    }

    private func previousHadith() {
        if hadithIndex > 0 {
            hadithIndex -= 1
            Haptics.selection()
        } else {
            Haptics.impact(.light)
        }
    }

    private var availableHadithBooks: [HadithBook] {
        let available = ReminderContent.hadithBooks
        return available.isEmpty ? [ReminderContent.defaultHadithBook] : available
    }

    private var selectedHadithBook: HadithBook {
        let preferred = HadithBook(rawValue: selectedHadithBookRaw) ?? ReminderContent.defaultHadithBook
        if ReminderContent.hadithCount(in: preferred) > 0 {
            return preferred
        }
        return ReminderContent.defaultHadithBook
    }

    private var currentHadithTotal: Int {
        ReminderContent.hadithCount(in: selectedHadithBook)
    }

    private var currentHadith: Hadith {
        ReminderContent.hadith(at: hadithIndex, in: selectedHadithBook)
    }

    private var hadithReadLog: [String: [HadithReadRecord]] {
        HadithReadLogStore.decode(hadithReadLogStorage)
    }

    private var hadithBookmarks: [HadithBookmarkRecord] {
        HadithReadLogStore.decodeBookmarks(hadithBookmarksStorage)
    }

    private var sortedBookmarks: [HadithBookmarkRecord] {
        hadithBookmarks.sorted {
            if $0.createdAt == $1.createdAt {
                if $0.bookRawValue == $1.bookRawValue {
                    return $0.number < $1.number
                }
                return $0.bookRawValue < $1.bookRawValue
            }
            return $0.createdAt > $1.createdAt
        }
    }

    private var isReadToday: Bool {
        let todayKey = HadithReadLogStore.dayKey(for: Date())
        let records = hadithReadLog[todayKey] ?? []
        return records.contains(where: { $0.book == currentHadith.book && $0.number == currentHadith.number })
    }

    private var isBookmarked: Bool {
        hadithBookmarks.contains(where: { $0.book == currentHadith.book && $0.number == currentHadith.number })
    }

    private func selectHadithBook(_ book: HadithBook) {
        selectedHadithBookRaw = book.rawValue
        hadithIndex = 0
        Haptics.selection()
    }

    private func normalizeHadithBookSelection() {
        let resolved = selectedHadithBook
        if selectedHadithBookRaw != resolved.rawValue {
            selectedHadithBookRaw = resolved.rawValue
        }
    }

    private func normalizeHadithIndex() {
        let total = currentHadithTotal
        guard total > 0 else {
            hadithIndex = 0
            return
        }
        hadithIndex = min(max(hadithIndex, 0), total - 1)
    }

    private func markCurrentHadithRead() {
        guard currentHadith.number > 0 else { return }
        let key = HadithReadLogStore.dayKey(for: Date())
        var log = hadithReadLog
        var records = log[key] ?? []
        let record = HadithReadRecord(book: currentHadith.book, number: currentHadith.number)

        if records.contains(record) {
            Haptics.selection()
            return
        }

        records.append(record)
        records.sort {
            if $0.bookRawValue == $1.bookRawValue {
                return $0.number < $1.number
            }
            return $0.bookRawValue < $1.bookRawValue
        }
        log[key] = records
        hadithReadLogStorage = HadithReadLogStore.encode(log)
        Haptics.impact(.light)
    }

    private func toggleCurrentHadithBookmark() {
        guard currentHadith.number > 0 else { return }
        var bookmarks = hadithBookmarks
        if let existingIndex = bookmarks.firstIndex(where: { $0.book == currentHadith.book && $0.number == currentHadith.number }) {
            bookmarks.remove(at: existingIndex)
            hadithBookmarksStorage = HadithReadLogStore.encodeBookmarks(bookmarks)
            Haptics.selection()
            return
        }
        bookmarks.append(HadithBookmarkRecord(book: currentHadith.book, number: currentHadith.number))
        hadithBookmarksStorage = HadithReadLogStore.encodeBookmarks(bookmarks)
        Haptics.impact(.light)
    }

    private func jumpToBookmark(_ record: HadithBookmarkRecord) {
        guard let index = ReminderContent.hadithIndex(number: record.number, in: record.book) else { return }
        selectedHadithBookRaw = record.book.rawValue
        hadithIndex = index
        showHadithBookmarks = false
        Haptics.selection()
    }

    private func deleteBookmark(_ record: HadithBookmarkRecord) {
        var bookmarks = hadithBookmarks
        bookmarks.removeAll(where: { $0.book == record.book && $0.number == record.number })
        hadithBookmarksStorage = HadithReadLogStore.encodeBookmarks(bookmarks)
    }

    private func copyCurrentHadith() {
        guard !currentHadith.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let header = "\(currentHadith.book.displayName) • No. \(currentHadith.number)"
        let source = currentHadith.source.trimmingCharacters(in: .whitespacesAndNewlines)
        let value: String
        if source.isEmpty {
            value = "\(header)\n\n\(currentHadith.text)"
        } else {
            value = "\(header)\n\n\(currentHadith.text)\n\nSource: \(source)"
        }
        UIPasteboard.general.string = value
        Haptics.impact(.light)
    }

    private func normalizedSurah(_ value: Int) -> Int {
        min(max(value, 1), 114)
    }

    private func normalizedPage(_ value: Int) -> Int {
        min(max(value, 1), 604)
    }
}

private struct QuranSurahSummary: Codable, Hashable, Identifiable {
    let number: Int
    let name: String
    let englishName: String

    var id: Int { number }
}

private struct QuranAyah: Codable, Hashable, Identifiable {
    let numberInSurah: Int
    let text: String

    var id: Int { numberInSurah }
}

private struct QuranSurahContent: Codable, Hashable {
    let number: Int
    let name: String
    let englishName: String
    let revelationType: String
    let ayahs: [QuranAyah]
}

private struct QuranPageSurahRef: Codable, Hashable {
    let number: Int
    let name: String
    let englishName: String
}

private struct QuranPageAyah: Codable, Hashable, Identifiable {
    let number: Int
    let numberInSurah: Int
    let text: String
    let surah: QuranPageSurahRef

    var id: String {
        "\(number)-\(surah.number)-\(numberInSurah)"
    }
}

private struct QuranPageData: Codable, Hashable {
    let number: Int
    let ayahs: [QuranPageAyah]
}

private struct QuranResponse<T: Decodable>: Decodable {
    let data: T
}

@MainActor
private final class QuranService: ObservableObject {
    @Published var surahs: [QuranSurahSummary] = []
    @Published var currentSurah: QuranSurahContent?
    @Published var currentPage: QuranPageData?
    @Published var isLoading = false
    @Published var isPageLoading = false
    @Published var errorMessage: String?
    @Published var pageErrorMessage: String?
    @Published var isUsingOfflineData = false

    private var cache: [Int: QuranSurahContent] = [:]
    private var pageCache: [Int: QuranPageData] = [:]
    private var didLoadSurahList = false

    func loadIfNeeded(initialSurah: Int) async {
        let safeSurah = min(max(initialSurah, 1), 114)
        if surahs.isEmpty, let cachedList = QuranLocalStore.loadSurahList() {
            surahs = cachedList
            didLoadSurahList = true
            isUsingOfflineData = true
        }
        if !didLoadSurahList {
            await loadSurahList()
        }
        if currentSurah?.number != safeSurah {
            await loadSurah(number: safeSurah)
        }
    }

    func loadSurah(number: Int, forceRefresh: Bool = false) async {
        let safeSurah = min(max(number, 1), 114)
        if !didLoadSurahList {
            await loadSurahList()
        }

        if !forceRefresh, let cached = cache[safeSurah] {
            currentSurah = cached
            errorMessage = nil
            return
        }

        if !forceRefresh,
           let cachedOnDisk = QuranLocalStore.loadSurah(number: safeSurah) {
            cache[safeSurah] = cachedOnDisk
            currentSurah = cachedOnDisk
            errorMessage = nil
            isUsingOfflineData = true
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let surah = try await QuranAPI.fetchSurah(number: safeSurah)
            cache[safeSurah] = surah
            currentSurah = surah
            isUsingOfflineData = false
            QuranLocalStore.saveSurah(surah)
        } catch {
            if let cachedOnDisk = QuranLocalStore.loadSurah(number: safeSurah) {
                cache[safeSurah] = cachedOnDisk
                currentSurah = cachedOnDisk
                isUsingOfflineData = true
                errorMessage = nil
            } else {
                errorMessage = "Unable to load Quran right now."
            }
        }
        isLoading = false
    }

    func loadPageIfNeeded(initialPage: Int) async {
        let safePage = min(max(initialPage, 1), 604)
        if currentPage?.number != safePage {
            await loadPage(number: safePage)
        }
    }

    func loadPage(number: Int, forceRefresh: Bool = false) async {
        let safePage = min(max(number, 1), 604)

        if !forceRefresh, let cached = pageCache[safePage] {
            currentPage = cached
            pageErrorMessage = nil
            return
        }

        if !forceRefresh, let disk = QuranLocalStore.loadPage(number: safePage) {
            pageCache[safePage] = disk
            currentPage = disk
            pageErrorMessage = nil
            isUsingOfflineData = true
            return
        }

        isPageLoading = true
        pageErrorMessage = nil
        do {
            let page = try await QuranAPI.fetchPage(number: safePage)
            pageCache[safePage] = page
            currentPage = page
            isUsingOfflineData = false
            QuranLocalStore.savePage(page)
        } catch {
            if let disk = QuranLocalStore.loadPage(number: safePage) {
                pageCache[safePage] = disk
                currentPage = disk
                pageErrorMessage = nil
                isUsingOfflineData = true
            } else {
                pageErrorMessage = "Unable to load Quran page right now."
            }
        }
        isPageLoading = false
    }

    private func loadSurahList() async {
        if surahs.isEmpty, let cached = QuranLocalStore.loadSurahList() {
            surahs = cached
            didLoadSurahList = true
            isUsingOfflineData = true
        }

        do {
            surahs = try await QuranAPI.fetchSurahList()
            didLoadSurahList = true
            isUsingOfflineData = false
            QuranLocalStore.saveSurahList(surahs)
        } catch {
            if let cached = QuranLocalStore.loadSurahList(), !cached.isEmpty {
                surahs = cached
                didLoadSurahList = true
                isUsingOfflineData = true
            } else {
                surahs = []
                didLoadSurahList = false
            }
        }
    }
}

private enum QuranLocalStore {
    private static let fileManager = FileManager.default
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private static var directoryURL: URL? {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("QuranCache", isDirectory: true)
    }

    private static var surahListURL: URL? {
        directoryURL?.appendingPathComponent("surah-list.json")
    }

    private static func surahURL(number: Int) -> URL? {
        directoryURL?.appendingPathComponent("surah-\(number).json")
    }

    private static func pageURL(number: Int) -> URL? {
        directoryURL?.appendingPathComponent("page-\(number).json")
    }

    static func saveSurahList(_ surahs: [QuranSurahSummary]) {
        guard let url = surahListURL else { return }
        do {
            try ensureDirectory()
            let data = try encoder.encode(surahs)
            try data.write(to: url, options: Data.WritingOptions.atomic)
        } catch {
            return
        }
    }

    static func loadSurahList() -> [QuranSurahSummary]? {
        guard let url = surahListURL,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decoder.decode([QuranSurahSummary].self, from: data)
    }

    static func saveSurah(_ surah: QuranSurahContent) {
        guard let url = surahURL(number: surah.number) else { return }
        do {
            try ensureDirectory()
            let data = try encoder.encode(surah)
            try data.write(to: url, options: Data.WritingOptions.atomic)
        } catch {
            return
        }
    }

    static func loadSurah(number: Int) -> QuranSurahContent? {
        guard let url = surahURL(number: number),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decoder.decode(QuranSurahContent.self, from: data)
    }

    static func savePage(_ page: QuranPageData) {
        guard let url = pageURL(number: page.number) else { return }
        do {
            try ensureDirectory()
            let data = try encoder.encode(page)
            try data.write(to: url, options: Data.WritingOptions.atomic)
        } catch {
            return
        }
    }

    static func loadPage(number: Int) -> QuranPageData? {
        guard let url = pageURL(number: number),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decoder.decode(QuranPageData.self, from: data)
    }

    private static func ensureDirectory() throws {
        guard let directoryURL else { return }
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}

private enum QuranAPI {
    static func fetchSurahList() async throws -> [QuranSurahSummary] {
        guard let url = URL(string: "https://api.alquran.cloud/v1/surah") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(QuranResponse<[QuranSurahSummary]>.self, from: data)
        return decoded.data
    }

    static func fetchSurah(number: Int) async throws -> QuranSurahContent {
        guard let url = URL(string: "https://api.alquran.cloud/v1/surah/\(number)/quran-uthmani") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(QuranResponse<QuranSurahContent>.self, from: data)
        return decoded.data
    }

    static func fetchPage(number: Int) async throws -> QuranPageData {
        guard let url = URL(string: "https://api.alquran.cloud/v1/page/\(number)/quran-uthmani") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(QuranResponse<QuranPageData>.self, from: data)
        return decoded.data
    }
}

private struct QuranCard: View {
    @ObservedObject var service: QuranService
    @Binding var selectedSurah: Int
    let onOpenReader: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Label("Digital Quran", systemImage: "book.pages")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                if service.isUsingOfflineData {
                    Text("Offline")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(primaryGreen)
                }
                if service.isLoading {
                    ProgressView()
                        .tint(primaryGreen)
                }
            }

            Text(headerTitle)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text("Surah \(selectedSurah)")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                onOpenReader()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                    Text("Open Full Page Mushaf")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(primaryGreen.opacity(0.2))
                .foregroundColor(primaryGreen)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(primaryGreen.opacity(0.65), lineWidth: 1)
                )
            }

            HStack(spacing: 10) {
                Button {
                    selectedSurah = max(1, selectedSurah - 1)
                    Haptics.selection()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(glass)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(glassStroke, lineWidth: 1)
                        )
                }
                .disabled(selectedSurah <= 1)
                .opacity(selectedSurah <= 1 ? 0.5 : 1)

                Menu {
                    ForEach(menuSurahs) { surah in
                        Button {
                            selectedSurah = surah.number
                            Haptics.selection()
                        } label: {
                            if surah.number == selectedSurah {
                                Label("\(surah.number). \(surah.name)", systemImage: "checkmark")
                            } else {
                                Text("\(surah.number). \(surah.name)")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Jump to Surah")
                            .font(.headline)
                        Image(systemName: "chevron.down")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )
                }

                Button {
                    selectedSurah = min(114, selectedSurah + 1)
                    Haptics.selection()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(glass)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(glassStroke, lineWidth: 1)
                        )
                }
                .disabled(selectedSurah >= 114)
                .opacity(selectedSurah >= 114 ? 0.5 : 1)
            }

            quranContent
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var quranContent: some View {
        if let errorMessage = service.errorMessage {
            VStack(alignment: .leading, spacing: 8) {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Retry") {
                    Task {
                        await service.loadSurah(number: selectedSurah, forceRefresh: true)
                    }
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        } else if let surah = service.currentSurah {
            ScrollView(.vertical) {
                VStack(alignment: .trailing, spacing: 14) {
                    ForEach(surah.ayahs) { ayah in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(ayah.numberInSurah)")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(primaryGreen)
                                .padding(7)
                                .background(glass, in: Circle())

                            Text(ayah.text)
                                .font(.system(size: 22, weight: .regular, design: .serif))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .environment(\.layoutDirection, .rightToLeft)
                    }
                }
            }
            .frame(height: 260)
            .scrollIndicators(.visible)
        } else {
            Text("Loading Quran...")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var headerTitle: String {
        if let current = service.currentSurah, current.number == selectedSurah {
            return current.name
        }
        if let surah = service.surahs.first(where: { $0.number == selectedSurah }) {
            return surah.name
        }
        return "القرآن الكريم"
    }

    private var menuSurahs: [QuranSurahSummary] {
        if service.surahs.isEmpty {
            return (1...114).map { QuranSurahSummary(number: $0, name: "سورة \($0)", englishName: "") }
        }
        return service.surahs
    }
}

private struct QuranMushafView: View {
    @ObservedObject var service: QuranService
    @Binding var selectedPage: Int
    @Environment(\.dismiss) private var dismiss
    @State private var sliderPage: Double = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.92, blue: 0.84)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    header
                    controls
                    pageContainer
                }
                .padding()
            }
            .navigationTitle("القرآن الكريم")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brown)
                }
            }
        }
        .preferredColorScheme(.light)
        .task {
            sliderPage = Double(selectedPage)
            await service.loadPageIfNeeded(initialPage: selectedPage)
        }
        .onChange(of: selectedPage) { _, newValue in
            sliderPage = Double(newValue)
        }
    }

    private var header: some View {
        HStack {
            if service.isUsingOfflineData {
                Label("Offline", systemImage: "wifi.slash")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.brown)
            }
            Spacer()
            Text("Page \(selectedPage) / 604")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.brown)
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    selectedPage = max(1, selectedPage - 1)
                    Haptics.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Prev")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.7))
                    .foregroundColor(.brown)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.brown.opacity(0.2), lineWidth: 1)
                    )
                }
                .disabled(selectedPage <= 1)
                .opacity(selectedPage <= 1 ? 0.5 : 1)

                Button {
                    selectedPage = min(604, selectedPage + 1)
                    Haptics.selection()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.7))
                    .foregroundColor(.brown)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.brown.opacity(0.2), lineWidth: 1)
                    )
                }
                .disabled(selectedPage >= 604)
                .opacity(selectedPage >= 604 ? 0.5 : 1)
            }

            Slider(
                value: $sliderPage,
                in: 1...604,
                step: 1
            ) { isEditing in
                if !isEditing {
                    let rounded = Int(sliderPage.rounded())
                    if rounded != selectedPage {
                        selectedPage = rounded
                        Haptics.selection()
                    }
                }
            }
            .tint(.brown)
        }
    }

    @ViewBuilder
    private var pageContainer: some View {
        if let error = service.pageErrorMessage {
            VStack(alignment: .leading, spacing: 10) {
                Text(error)
                    .foregroundColor(.brown)
                Button("Retry Page") {
                    Task {
                        await service.loadPage(number: selectedPage, forceRefresh: true)
                    }
                }
                .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else if let page = service.currentPage, page.number == selectedPage {
            ScrollView(.vertical) {
                VStack(alignment: .trailing, spacing: 16) {
                    Text(surahTitle(for: page))
                        .font(.custom("Geeza Pro", size: 22))
                        .foregroundColor(.brown)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(mushafText(for: page))
                        .font(.custom("Geeza Pro", size: 31))
                        .lineSpacing(15)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.black.opacity(0.88))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 0.99, green: 0.97, blue: 0.91))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.brown.opacity(0.25), lineWidth: 1)
            )
        } else {
            VStack(spacing: 10) {
                if service.isPageLoading {
                    ProgressView()
                        .tint(.brown)
                }
                Text("Loading page...")
                    .font(.footnote)
                    .foregroundColor(.brown)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func surahTitle(for page: QuranPageData) -> String {
        var names: [String] = []
        for ayah in page.ayahs {
            if names.last != ayah.surah.name {
                names.append(ayah.surah.name)
            }
        }
        return names.joined(separator: " • ")
    }

    private func mushafText(for page: QuranPageData) -> String {
        var chunks: [String] = []
        var currentSurah = -1

        for ayah in page.ayahs {
            if ayah.surah.number != currentSurah {
                currentSurah = ayah.surah.number
                chunks.append("\n\n۞ \(ayah.surah.name) ۞\n")
            }
            chunks.append("\(ayah.text) ﴿\(arabicDigits(ayah.numberInSurah))﴾")
        }

        return chunks.joined(separator: " ")
    }

    private func arabicDigits(_ value: Int) -> String {
        let map: [Character: Character] = [
            "0": "٠", "1": "١", "2": "٢", "3": "٣", "4": "٤",
            "5": "٥", "6": "٦", "7": "٧", "8": "٨", "9": "٩"
        ]
        return String(String(value).map { map[$0] ?? $0 })
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

// ─────────────────────────── Greeting
private struct GreetingCard: View {
    let name: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("May your day be filled with barakah.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("🌙")
                .font(.system(size: 28))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var greetingText: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Salam Alaykum"
        }
        return "Salam Alaykum, \(trimmed)"
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

// ─────────────────────────── Hadith Card
private struct HadithCard: View {
    let hadith: Hadith
    let index: Int
    let total: Int
    let books: [HadithBook]
    let selectedBook: HadithBook
    let isReadToday: Bool
    let isBookmarked: Bool
    let onSelectBook: (HadithBook) -> Void
    let onRead: () -> Void
    let onToggleBookmark: () -> Void
    let onCopy: () -> Void
    let onShowBookmarks: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Label("Hadith of the Day", systemImage: "book.closed")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                bookPicker
            }

            HStack(alignment: .firstTextBaseline) {
                Text(selectedBook.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("No. \(displayIndex) of \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ScrollView(.vertical) {
                Text(hadith.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 180)
            .scrollIndicators(.visible)
            .clipped()

            Text(hadith.source)
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                onRead()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isReadToday ? "checkmark.circle.fill" : "checkmark.circle")
                    Text(isReadToday ? "Read Today" : "Read")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isReadToday ? primaryGreen.opacity(0.16) : glass)
                .foregroundColor(isReadToday ? primaryGreen : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isReadToday ? primaryGreen : glassStroke, lineWidth: 1)
                )
            }
            .disabled(total == 0)

            HStack(spacing: 10) {
                Button {
                    onToggleBookmark()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        Text(isBookmarked ? "Bookmarked" : "Bookmark")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(isBookmarked ? primaryGreen : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isBookmarked ? primaryGreen : glassStroke, lineWidth: 1)
                    )
                }
                .disabled(total == 0)

                Button {
                    onCopy()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )
                }
            }

            HStack(spacing: 10) {
                Button {
                    onShowBookmarks()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark.circle")
                        Text("View Bookmarks")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )
                }
            }

            HStack(spacing: 10) {
                Button {
                    onPrevious()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )
                }
                .disabled(isAtStart)
                .opacity(isAtStart ? 0.5 : 1)

                Button {
                    onNext()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(primaryGreen)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isAtEnd)
                .opacity(isAtEnd ? 0.6 : 1)
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var displayIndex: Int {
        if hadith.number > 0 {
            return hadith.number
        }
        guard total > 0 else { return 0 }
        let safe = min(max(index, 0), total - 1)
        return safe + 1
    }

    private var isAtStart: Bool {
        total == 0 || index <= 0
    }

    private var isAtEnd: Bool {
        total == 0 || index >= total - 1
    }

    @ViewBuilder
    private var bookPicker: some View {
        if books.count <= 1 {
            EmptyView()
        } else {
            Menu {
                ForEach(books) { book in
                    Button {
                        onSelectBook(book)
                    } label: {
                        if book == selectedBook {
                            Label(book.displayName, systemImage: "checkmark")
                        } else {
                            Text(book.displayName)
                        }
                    }
                }
            } label: {
                Label("Book", systemImage: "books.vertical")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(primaryGreen)
            }
        }
    }
}

private struct HadithBookmarksView: View {
    let bookmarks: [HadithBookmarkRecord]
    let onSelect: (HadithBookmarkRecord) -> Void
    let onDelete: (HadithBookmarkRecord) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks Yet",
                        systemImage: "bookmark.slash",
                        description: Text("Bookmark hadiths and they will appear here.")
                    )
                } else {
                    List {
                        ForEach(bookmarks) { bookmark in
                            Button {
                                onSelect(bookmark)
                            } label: {
                                bookmarkRow(bookmark)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Hadith Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmark: HadithBookmarkRecord) -> some View {
        let hadith = ReminderContent.hadith(number: bookmark.number, in: bookmark.book)
        VStack(alignment: .leading, spacing: 4) {
            Text("\(bookmark.book.displayName) • No. \(bookmark.number)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Text(hadith?.text ?? "Hadith text unavailable.")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            onDelete(bookmarks[index])
        }
    }
}

private struct HadithReadCalendarCard: View {
    let selectedBook: HadithBook
    let log: [String: [HadithReadRecord]]

    @State private var monthAnchor = Date()
    @State private var selectedDate = Date()

    private let calendar = Calendar.current

    private var monthTitle: String {
        Self.monthFormatter.string(from: monthAnchor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Read Calendar", systemImage: "calendar.badge.checkmark")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                Text(selectedBook.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(glass, in: Circle())
                }

                Spacer()
                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()

                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(glass, in: Circle())
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthSlots.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(for: date)
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.clear)
                            .frame(height: 44)
                    }
                }
            }

            Divider()
                .background(glassStroke)

            VStack(alignment: .leading, spacing: 4) {
                Text(Self.daySummaryFormatter.string(from: selectedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(selectionSummary)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let numbers = numbersRead(on: date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        Button {
            selectedDate = date
            Haptics.selection()
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? .black : .white)
                if let first = numbers.first {
                    Text(numbersBadge(first: first, count: numbers.count))
                        .font(.caption2)
                        .foregroundColor(isSelected ? .black.opacity(0.85) : primaryGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(" ")
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(backgroundColor(isSelected: isSelected, isToday: isToday))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(borderColor(isSelected: isSelected, hasReads: !numbers.isEmpty), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var monthSlots: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthAnchor)),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        var slots = Array<Date?>(repeating: nil, count: leading)

        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                slots.append(date)
            }
        }
        return slots
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = max(0, calendar.firstWeekday - 1)
        let head = Array(symbols[start...])
        let tail = Array(symbols[..<start])
        return head + tail
    }

    private func shiftMonth(by value: Int) {
        guard let shifted = calendar.date(byAdding: .month, value: value, to: monthAnchor) else {
            return
        }
        monthAnchor = shifted
        if !calendar.isDate(selectedDate, equalTo: shifted, toGranularity: .month) {
            selectedDate = shifted
        }
        Haptics.selection()
    }

    private func numbersRead(on date: Date) -> [Int] {
        let key = HadithReadLogStore.dayKey(for: date)
        let records = log[key] ?? []
        return Array(Set(records.filter { $0.book == selectedBook }.map(\.number))).sorted()
    }

    private var selectionSummary: String {
        let numbers = numbersRead(on: selectedDate)
        if numbers.isEmpty {
            return "No Hadith marked as read for this date."
        }
        let values = numbers.map(String.init).joined(separator: ", ")
        return "Read Hadith numbers: \(values)"
    }

    private func numbersBadge(first: Int, count: Int) -> String {
        if count <= 1 {
            return "#\(first)"
        }
        return "#\(first) +\(count - 1)"
    }

    private func backgroundColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected {
            return primaryGreen
        }
        if isToday {
            return glass.opacity(1.25)
        }
        return glass.opacity(0.3)
    }

    private func borderColor(isSelected: Bool, hasReads: Bool) -> Color {
        if isSelected {
            return primaryGreen
        }
        if hasReads {
            return primaryGreen.opacity(0.8)
        }
        return glassStroke
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private static let daySummaryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// ─────────────────────────── Daily Reminder
private struct DailyReminderCard: View {
    let reminder: IslamicReminder
    let dua: Dua

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Daily Reminder", systemImage: "sunrise.fill")
                .foregroundColor(primaryGreen)
                .font(.headline)

            Text(reminder.text)
                .font(.body)
                .foregroundColor(.white)

            Divider().background(glassStroke)

            Text("Dua of the Day")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Text(dua.text)
                .font(.footnote)
                .foregroundColor(.secondary)

            Text(dua.source)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }
}

// ─────────────────────────── Dhikr Counter
private struct DhikrCounterCard: View {
    let dhikrs: [Dhikr]
    @Binding var selectedIndex: Int
    let fallbackIndex: Int
    @AppStorage("dhikrCount") private var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dhikr Counter", systemImage: "circle.grid.cross")
                .foregroundColor(primaryGreen)
                .font(.headline)

            HStack {
                Text("Dhikr")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Dhikr", selection: selectionBinding) {
                    ForEach(Array(dhikrs.enumerated()), id: \.offset) { index, dhikr in
                        Text(dhikr.text).tag(index)
                    }
                }
                .pickerStyle(.menu)
                .tint(primaryGreen)
                .onChange(of: selectionBinding.wrappedValue) { _ in
                    Haptics.selection()
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentDhikr.text)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    Text("Recommended: \(currentDhikr.count)x • \(currentDhikr.source)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(count)")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundColor(.white)
            }

            HStack(spacing: 10) {
                Button {
                    count += 1
                    Haptics.selection()
                } label: {
                    Text("Tap +1")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(primaryGreen)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    count = 0
                    Haptics.impact(.light)
                } label: {
                    Text("Reset")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(glass)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(glassStroke, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var selectionBinding: Binding<Int> {
        Binding(
            get: { resolvedIndex },
            set: { selectedIndex = $0 }
        )
    }

    private var resolvedIndex: Int {
        guard !dhikrs.isEmpty else { return 0 }
        if selectedIndex < 0 || selectedIndex >= dhikrs.count {
            let safeFallback = ((fallbackIndex % dhikrs.count) + dhikrs.count) % dhikrs.count
            return safeFallback
        }
        return selectedIndex
    }

    private var currentDhikr: Dhikr {
        guard !dhikrs.isEmpty else {
            return Dhikr(text: "Dhikr", count: 0, source: "")
        }
        return dhikrs[resolvedIndex]
    }
}

// ─────────────────────────── Reminders Quick Card
private struct RemindersCard: View {
    let openSettings: () -> Void
    @AppStorage("reminderHadithEnabled") private var hadithEnabled = false
    @AppStorage("reminderDhikrEnabled") private var dhikrEnabled = false
    @AppStorage("reminderJumuahEnabled") private var jumuahEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Reminders", systemImage: "bell.badge")
                .foregroundColor(primaryGreen)
                .font(.headline)

            Text(summaryText)
                .font(.footnote)
                .foregroundColor(.secondary)

            Button {
                Haptics.selection()
                openSettings()
            } label: {
                Text("Manage Notifications")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(glass)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(glassStroke, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    private var summaryText: String {
        let active = [
            hadithEnabled ? "Hadith" : nil,
            dhikrEnabled ? "Dhikr" : nil,
            jumuahEnabled ? "Jumu'ah" : nil
        ].compactMap { $0 }
        if active.isEmpty {
            return "No reminders enabled yet. Set a schedule to stay consistent."
        }
        return "Active: " + active.joined(separator: " • ")
    }
}

// ─────────────────────────── Prayer Times
private struct PrayerTimesCard: View {
    @ObservedObject var service: PrayerTimesService
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Prayer Times", systemImage: "clock")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                if service.isLoading {
                    ProgressView()
                        .tint(primaryGreen)
                }
            }

            Text(service.locationName)
                .font(.caption)
                .foregroundColor(.secondary)

            content
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch service.status {
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Text("Enable location to see prayer times.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        case .notDetermined:
            VStack(alignment: .leading, spacing: 8) {
                Text("Allow location to calculate accurate prayer times.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Enable Location") {
                    service.requestLocation()
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        default:
            if let times = service.times {
                PrayerTimesList(times: times)
            } else if let errorMessage = service.errorMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        service.refresh()
                    }
                    .font(.headline)
                    .tint(primaryGreen)
                }
            } else {
                Text("Fetching prayer times...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct PrayerTimesList: View {
    let times: PrayerTimesDay

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            let next = times.nextPrayer(after: context.date)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(next.0.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(countdownString(to: next.1, now: context.date))
                        .font(.headline)
                        .foregroundColor(primaryGreen)
                }

                VStack(spacing: 6) {
                    ForEach(times.ordered, id: \.0) { item in
                        PrayerTimeRow(name: item.0.displayName,
                                      time: formatTime(item.1, timeZone: times.timeZone),
                                      isNext: item.0 == next.0)
                    }
                }
            }
        }
    }

    private func formatTime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    private func countdownString(to date: Date, now: Date) -> String {
        let interval = max(0, Int(date.timeIntervalSince(now)))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}

// ─────────────────────────── Qibla
private struct QiblaCard: View {
    @ObservedObject var service: QiblaService
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Qibla", systemImage: "location.north")
                    .foregroundColor(primaryGreen)
                    .font(.headline)
                Spacer()
                if !service.isHeadingAvailable {
                    Text("Compass unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(service.locationName)
                .font(.caption)
                .foregroundColor(.secondary)

            content
        }
        .padding()
        .background(glass, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(glassStroke, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch service.status {
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Text("Enable location to use the Qibla compass.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        case .notDetermined:
            VStack(alignment: .leading, spacing: 8) {
                Text("Allow location to calculate the Qibla direction.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Enable Location") {
                    service.requestLocation()
                }
                .font(.headline)
                .tint(primaryGreen)
            }
        default:
            if !service.isHeadingAvailable, let bearing = service.qiblaBearing {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Compass not available on this device.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("Qibla bearing: \(Int(bearing.rounded()))° from north")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else if let relative = service.relativeAngle {
                QiblaCompass(angle: relative,
                             bearing: service.qiblaBearing,
                             heading: service.heading)
            } else if let error = service.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Text("Calibrating compass...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct QiblaCompass: View {
    let angle: Double
    let bearing: Double?
    let heading: Double?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(glassStroke, lineWidth: 2)
                    .frame(width: 160, height: 160)

                ForEach(0..<4) { idx in
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 2, height: 10)
                        .offset(y: -80)
                        .rotationEffect(.degrees(Double(idx) * 90))
                }

                Image(systemName: "arrow.up")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(primaryGreen)
                    .rotationEffect(.degrees(angle))
                    .animation(.easeInOut(duration: 0.3), value: angle)

                Text("🕋")
                    .font(.system(size: 24))
                    .offset(y: -56)
            }

            HStack {
                if let bearing = bearing {
                    Text("Qibla \(Int(bearing.rounded()))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let heading = heading {
                    Text("Heading \(Int(heading.rounded()))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct PrayerTimeRow: View {
    let name: String
    let time: String
    let isNext: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .foregroundColor(isNext ? .white : .secondary)
            Spacer()
            Text(time)
                .font(.subheadline.weight(isNext ? .semibold : .regular))
                .foregroundColor(isNext ? primaryGreen : .secondary)
        }
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

            Text("Ramadan tools and more insights are coming soon.")
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
            Text("Timeline \(HijriEvents1447.yearLabel)")
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
