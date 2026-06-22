import SwiftUI

// MARK: - App State

enum AppMode: String, CaseIterable {
    case persoenlich = "Persönlich"
    case familie = "Familie"
}

enum TabItem: Int, CaseIterable {
    case startseite
    case kalender
    case erinnerungen
    case notizen
    case tracker

    func label(for mode: AppMode) -> String {
        switch self {
        case .startseite:   return "Startseite"
        case .kalender:     return "Kalender"
        case .erinnerungen: return "Erinnerungen"
        case .notizen:      return "Notizen"
        case .tracker:      return mode == .persoenlich ? "Tracker" : "Liste"
        }
    }

    func icon(for mode: AppMode) -> String {
        switch self {
        case .startseite:   return "house.fill"
        case .kalender:     return "calendar"
        case .erinnerungen: return "bell.fill"
        case .notizen:      return "note.text"
        case .tracker:      return mode == .persoenlich ? "chart.bar.fill" : "list.bullet"
        }
    }
}

// MARK: - Data Models (all Codable for UserDefaults persistence)

struct CalendarEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var isFamily: Bool = false
}

struct Reminder: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var isFamily: Bool = false
}

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var date: Date = Date()
    var isFamily: Bool = false
}

struct ShoppingItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var quantity: String = ""
    var isChecked: Bool = false
}

struct CleanTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var lastDone: Date?
    var isCompleted: Bool = false
}

struct PrayerTime: Identifiable, Codable {
    var id = UUID()
    var name: String
    var germanName: String
    var time: String
    var isDone: Bool = false
    var isNext: Bool = false
}

struct Habit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isDone: Bool = false
    var streak: Int = 0
    var lastDoneDate: Date?
}

// MARK: - Seed Data (used only on first launch)

struct SeedData {
    static let events: [CalendarEvent] = [
        CalendarEvent(title: "Zahnarzt", date: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now),
        CalendarEvent(title: "Sport", date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now),
        CalendarEvent(title: "Familienessen", date: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now, isFamily: true)
    ]

    static let reminders: [Reminder] = [
        Reminder(title: "Medikamente nehmen"),
        Reminder(title: "Rechnung bezahlen"),
        Reminder(title: "Elternabend vorbereiten", isFamily: true)
    ]

    static let notes: [Note] = [
        Note(title: "Gedanken", body: "Heute war ein guter Tag...", date: .now),
        Note(title: "Urlaubsplanung", body: "Wohin soll die Reise gehen?", date: .now, isFamily: true)
    ]

    static let shoppingItems: [ShoppingItem] = [
        ShoppingItem(name: "Milch", quantity: "2 Liter"),
        ShoppingItem(name: "Brot", quantity: "1 Laib"),
        ShoppingItem(name: "Tomaten", quantity: "500g")
    ]

    static let cleanTasks: [CleanTask] = [
        CleanTask(title: "Badezimmer putzen", lastDone: Calendar.current.date(byAdding: .day, value: -7, to: .now)),
        CleanTask(title: "Staubsaugen", lastDone: Calendar.current.date(byAdding: .day, value: -3, to: .now)),
        CleanTask(title: "Küche wischen", lastDone: Calendar.current.date(byAdding: .day, value: -1, to: .now)),
        CleanTask(title: "Fenster putzen", lastDone: Calendar.current.date(byAdding: .day, value: -14, to: .now))
    ]

    static let prayers: [PrayerTime] = [
        PrayerTime(name: "Fajr",    germanName: "Morgengebet",        time: "04:18"),
        PrayerTime(name: "Dhuhr",   germanName: "Mittagsgebet",       time: "13:02"),
        PrayerTime(name: "Asr",     germanName: "Nachmittagsgebet",   time: "17:24", isNext: true),
        PrayerTime(name: "Maghrib", germanName: "Abendgebet",         time: "21:05"),
        PrayerTime(name: "Isha",    germanName: "Nachtgebet",         time: "22:51")
    ]

    static let habits: [Habit] = [
        Habit(title: "Sport",         streak: 0),
        Habit(title: "Quran lesen",   streak: 0),
        Habit(title: "Wasser 2L",     streak: 0),
        Habit(title: "Journaling",    streak: 0)
    ]
}
