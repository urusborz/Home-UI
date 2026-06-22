import SwiftUI

class DataStore: ObservableObject {

    // MARK: - Published Data

    @Published var events: [CalendarEvent] = []
    @Published var reminders: [Reminder] = []
    @Published var notes: [Note] = []
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var cleanTasks: [CleanTask] = []
    @Published var prayers: [PrayerTime] = []
    @Published var habits: [Habit] = []

    // MARK: - Init

    init() {
        load()
        resetHabitsIfNewDay()
    }

    // MARK: - Computed: Personal / Family splits

    var personalEvents: [CalendarEvent]  { events.filter { !$0.isFamily } }
    var familyEvents: [CalendarEvent]    { events.filter { $0.isFamily } }
    var personalReminders: [Reminder]    { reminders.filter { !$0.isFamily } }
    var familyReminders: [Reminder]      { reminders.filter { $0.isFamily } }
    var personalNotes: [Note]            { notes.filter { !$0.isFamily } }
    var familyNotes: [Note]              { notes.filter { $0.isFamily } }

    // MARK: - Events

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        save()
    }

    func deleteEvents(_ offsets: IndexSet, from list: [CalendarEvent]) {
        let ids = offsets.map { list[$0].id }
        events.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Reminders

    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        save()
    }

    func toggleReminder(id: UUID) {
        if let i = reminders.firstIndex(where: { $0.id == id }) {
            reminders[i].isCompleted.toggle()
            save()
        }
    }

    func deleteReminders(_ offsets: IndexSet, from list: [Reminder]) {
        let ids = offsets.map { list[$0].id }
        reminders.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Notes

    func addNote(_ note: Note) {
        notes.insert(note, at: 0)
        save()
    }

    func deleteNotes(_ offsets: IndexSet, from list: [Note]) {
        let ids = offsets.map { list[$0].id }
        notes.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Shopping

    func addShoppingItem(_ item: ShoppingItem) {
        shoppingItems.append(item)
        save()
    }

    func toggleShoppingItem(id: UUID) {
        if let i = shoppingItems.firstIndex(where: { $0.id == id }) {
            shoppingItems[i].isChecked.toggle()
            save()
        }
    }

    func deleteShoppingItems(_ offsets: IndexSet, from list: [ShoppingItem]) {
        let ids = offsets.map { list[$0].id }
        shoppingItems.removeAll { ids.contains($0.id) }
        save()
    }

    func deleteCheckedShoppingItems() {
        shoppingItems.removeAll { $0.isChecked }
        save()
    }

    // MARK: - Clean Tasks

    func addCleanTask(_ task: CleanTask) {
        cleanTasks.append(task)
        save()
    }

    func toggleCleanTask(id: UUID) {
        if let i = cleanTasks.firstIndex(where: { $0.id == id }) {
            cleanTasks[i].isCompleted.toggle()
            if cleanTasks[i].isCompleted {
                cleanTasks[i].lastDone = Date()
            }
            save()
        }
    }

    func deleteCleanTasks(_ offsets: IndexSet, from list: [CleanTask]) {
        let ids = offsets.map { list[$0].id }
        cleanTasks.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Prayers

    func togglePrayer(id: UUID) {
        if let i = prayers.firstIndex(where: { $0.id == id }) {
            prayers[i].isDone.toggle()
            save()
        }
    }

    func resetPrayers() {
        for i in prayers.indices {
            prayers[i].isDone = false
        }
        save()
    }

    // MARK: - Habits

    func toggleHabit(id: UUID) {
        if let i = habits.firstIndex(where: { $0.id == id }) {
            let wasDone = habits[i].isDone
            habits[i].isDone.toggle()
            if !wasDone {
                habits[i].streak += 1
                habits[i].lastDoneDate = Date()
            } else {
                habits[i].streak = max(0, habits[i].streak - 1)
            }
            save()
        }
    }

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
    }

    func deleteHabits(_ offsets: IndexSet, from list: [Habit]) {
        let ids = offsets.map { list[$0].id }
        habits.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Day Reset (habits reset daily)

    private func resetHabitsIfNewDay() {
        let key = "lastHabitResetDate"
        let today = Calendar.current.startOfDay(for: Date())
        if let stored = UserDefaults.standard.object(forKey: key) as? Date {
            if stored < today {
                for i in habits.indices { habits[i].isDone = false }
                UserDefaults.standard.set(today, forKey: key)
                save()
            }
        } else {
            UserDefaults.standard.set(today, forKey: key)
        }
    }

    // MARK: - Persistence

    private func save() {
        encode(events,        key: "events")
        encode(reminders,     key: "reminders")
        encode(notes,         key: "notes")
        encode(shoppingItems, key: "shoppingItems")
        encode(cleanTasks,    key: "cleanTasks")
        encode(prayers,       key: "prayers")
        encode(habits,        key: "habits")
    }

    private func load() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunched")

        events        = decode([CalendarEvent].self, key: "events")        ?? (isFirstLaunch ? SeedData.events : [])
        reminders     = decode([Reminder].self,      key: "reminders")     ?? (isFirstLaunch ? SeedData.reminders : [])
        notes         = decode([Note].self,          key: "notes")         ?? (isFirstLaunch ? SeedData.notes : [])
        shoppingItems = decode([ShoppingItem].self,  key: "shoppingItems") ?? (isFirstLaunch ? SeedData.shoppingItems : [])
        cleanTasks    = decode([CleanTask].self,     key: "cleanTasks")    ?? (isFirstLaunch ? SeedData.cleanTasks : [])
        prayers       = decode([PrayerTime].self,    key: "prayers")       ?? SeedData.prayers
        habits        = decode([Habit].self,         key: "habits")        ?? (isFirstLaunch ? SeedData.habits : [])

        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            save()
        }
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
