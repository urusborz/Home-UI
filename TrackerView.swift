import SwiftUI

struct TrackerView: View {
    let mode: AppMode
    @State private var section: TrackerSection = .habits

    enum TrackerSection: String, CaseIterable {
        case habits = "Habits"
        case gebete = "Gebete"
        case cleaning = "Cleaning"
    }

    var body: some View {
        if mode == .persoenlich {
            personalTracker
        } else {
            ShoppingListView()
        }
    }

    private var personalTracker: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tracker")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TrackerSection.allCases, id: \.rawValue) { sec in
                        Button {
                            withAnimation(.spring(response: 0.3)) { section = sec }
                        } label: {
                            Text(sec.rawValue)
                                .font(.system(size: 14, weight: section == sec ? .semibold : .regular, design: .rounded))
                                .foregroundColor(section == sec ? .white : AppTheme.textTertiary)
                                .padding(.vertical, 8).padding(.horizontal, 18)
                                .background(section == sec ? AppTheme.accentBlue.opacity(0.2) : Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(section == sec ? AppTheme.accentBlue.opacity(0.4) : AppTheme.glassBorder, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    switch section {
                    case .habits:   HabitsView()
                    case .gebete:   GebeteView()
                    case .cleaning: CleanTrackerView()
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Habits View

struct HabitsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false

    private var completed: Int { store.habits.filter(\.isDone).count }
    private var progress: Double { store.habits.isEmpty ? 0 : Double(completed) / Double(store.habits.count) }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    SectionHeader(title: "Tägliche Habits", subtitle: "\(completed)/\(store.habits.count)")
                    AddButton { showingAdd = true }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4).fill(AppTheme.accentGreen).frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .glassCard()

            if store.habits.isEmpty {
                EmptyStateView(icon: "checkmark.circle", text: "Noch keine Habits")
            } else {
                VStack(spacing: 1) {
                    ForEach(store.habits) { habit in
                        HabitRow(habit: habit)
                    }
                }
                .background(AppTheme.glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddHabitSheet(isPresented: $showingAdd).environmentObject(store)
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleHabit(id: habit.id) } label: {
                ZStack {
                    Circle().stroke(habit.isDone ? AppTheme.accentGreen : Color.white.opacity(0.2), lineWidth: 1.5).frame(width: 28, height: 28)
                    if habit.isDone {
                        Circle().fill(AppTheme.accentGreen.opacity(0.2)).frame(width: 28, height: 28)
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(habit.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(habit.isDone ? AppTheme.textTertiary : AppTheme.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 11)).foregroundColor(habit.streak > 0 ? AppTheme.accentAmber : AppTheme.textTertiary)
                Text("\(habit.streak)").font(.system(size: 12, weight: .semibold)).foregroundColor(habit.streak > 0 ? AppTheme.accentAmber : AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .overlay(Divider().background(AppTheme.separator).padding(.leading, 58), alignment: .bottom)
    }
}

struct AddHabitSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title = ""

    var body: some View {
        DarkSheet(title: "Neuer Habit", isPresented: $isPresented) {
            DarkTextField(placeholder: "Habit eingeben...", text: $title)
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            store.addHabit(Habit(title: title))
            isPresented = false
        }
    }
}

// MARK: - Prayer / Gebete View

struct GebeteView: View {
    @EnvironmentObject var store: DataStore

    private var nextPrayer: PrayerTime? { store.prayers.first(where: { $0.isNext }) }

    var body: some View {
        VStack(spacing: 16) {
            if let next = nextPrayer {
                VStack(spacing: 8) {
                    Text("Nächstes Gebet").font(.system(size: 12, weight: .medium)).foregroundColor(AppTheme.accentAmber.opacity(0.8))
                    Text(next.name).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text(next.time + " Uhr").font(.system(size: 22, weight: .light, design: .rounded)).foregroundColor(AppTheme.accentAmber)
                    Text(next.germanName).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
                .background(AppTheme.accentAmber.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusXL))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusXL).stroke(AppTheme.accentAmber.opacity(0.18), lineWidth: 0.5))
            }

            VStack(spacing: 1) {
                ForEach(store.prayers) { prayer in
                    PrayerRow(prayer: prayer)
                }
            }
            .background(AppTheme.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
        }
    }
}

struct PrayerRow: View {
    let prayer: PrayerTime
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(prayer.isDone ? AppTheme.accentGreen.opacity(0.15) : (prayer.isNext ? AppTheme.accentAmber.opacity(0.15) : Color.clear)).frame(width: 36, height: 36)
                Image(systemName: prayer.isDone ? "checkmark" : (prayer.isNext ? "circle.dotted" : "moon.fill"))
                    .font(.system(size: prayer.isDone ? 13 : 15, weight: prayer.isDone ? .bold : .regular))
                    .foregroundColor(prayer.isDone ? AppTheme.accentGreen : (prayer.isNext ? AppTheme.accentAmber : AppTheme.textTertiary))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(prayer.name).font(.system(size: 16, weight: prayer.isNext ? .semibold : .medium))
                    .foregroundColor(prayer.isNext ? .white : (prayer.isDone ? AppTheme.textTertiary : AppTheme.textPrimary))
                Text(prayer.germanName).font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            Spacer()
            Text(prayer.time).font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(prayer.isNext ? AppTheme.accentAmber : AppTheme.textSecondary)
            Button { store.togglePrayer(id: prayer.id) } label: {
                Image(systemName: prayer.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(prayer.isDone ? AppTheme.accentGreen : Color.white.opacity(0.2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(prayer.isNext ? AppTheme.accentAmber.opacity(0.04) : Color.clear)
        .overlay(Divider().background(AppTheme.separator).padding(.leading, 58), alignment: .bottom)
    }
}

// MARK: - Clean Tracker

struct CleanTrackerView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false

    private var completed: Int { store.cleanTasks.filter(\.isCompleted).count }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    SectionHeader(title: "Clean Tracker", subtitle: "\(completed)/\(store.cleanTasks.count)")
                    AddButton { showingAdd = true }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4).fill(AppTheme.accentGreen)
                            .frame(width: store.cleanTasks.isEmpty ? 0 : geo.size.width * Double(completed) / Double(store.cleanTasks.count), height: 6)
                    }
                }
                .frame(height: 6)
            }
            .glassCard()

            if store.cleanTasks.isEmpty {
                EmptyStateView(icon: "sparkles", text: "Noch keine Aufgaben")
            } else {
                VStack(spacing: 1) {
                    ForEach(store.cleanTasks) { task in
                        CleanTaskRow(task: task)
                    }
                }
                .background(AppTheme.glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddCleanTaskSheet(isPresented: $showingAdd).environmentObject(store)
        }
    }
}

struct CleanTaskRow: View {
    let task: CleanTask
    @EnvironmentObject var store: DataStore

    private var lastDoneLabel: String {
        guard let date = task.lastDone else { return "Nie" }
        let days = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
        if days == 0 { return "Heute" }
        if days == 1 { return "Gestern" }
        return "Vor \(days) Tagen"
    }

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleCleanTask(id: task.id) } label: {
                ZStack {
                    Circle().stroke(task.isCompleted ? AppTheme.accentGreen : Color.white.opacity(0.2), lineWidth: 1.5).frame(width: 26, height: 26)
                    if task.isCompleted {
                        Circle().fill(AppTheme.accentGreen.opacity(0.2)).frame(width: 26, height: 26)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                    }
                }
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.system(size: 15, weight: .medium)).foregroundColor(task.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                Text("Zuletzt: " + lastDoneLabel).font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .overlay(Divider().background(AppTheme.separator).padding(.leading, 58), alignment: .bottom)
    }
}

struct AddCleanTaskSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title = ""

    var body: some View {
        DarkSheet(title: "Neue Aufgabe", isPresented: $isPresented) {
            DarkTextField(placeholder: "z.B. Badezimmer putzen", text: $title)
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            store.addCleanTask(CleanTask(title: title))
            isPresented = false
        }
    }
}

// MARK: - Shopping List

struct ShoppingListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false

    private var open: [ShoppingItem] { store.shoppingItems.filter { !$0.isChecked } }
    private var done: [ShoppingItem] { store.shoppingItems.filter { $0.isChecked } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Einkaufsliste")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("\(open.count) Artikel offen")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                if !done.isEmpty {
                    Button { store.deleteCheckedShoppingItems() } label: {
                        Text("Erledigt löschen")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                AddButton { showingAdd = true }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if store.shoppingItems.isEmpty {
                        EmptyStateView(icon: "cart", text: "Einkaufsliste ist leer")
                    } else {
                        if !open.isEmpty {
                            VStack(spacing: 1) {
                                ForEach(open) { item in ShoppingRow(item: item) }
                            }
                            .background(AppTheme.glassBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                        }
                        if !done.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionLabel("Erledigt")
                                VStack(spacing: 1) {
                                    ForEach(done) { item in ShoppingRow(item: item) }
                                }
                                .background(AppTheme.glassBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                            }
                        }
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddShoppingItemSheet(isPresented: $showingAdd).environmentObject(store)
        }
    }
}

struct ShoppingRow: View {
    let item: ShoppingItem
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleShoppingItem(id: item.id) } label: {
                ZStack {
                    Circle().stroke(item.isChecked ? AppTheme.accentGreen : Color.white.opacity(0.2), lineWidth: 1.5).frame(width: 24, height: 24)
                    if item.isChecked {
                        Circle().fill(AppTheme.accentGreen.opacity(0.15)).frame(width: 24, height: 24)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                    }
                }
            }
            .buttonStyle(.plain)
            Text(item.name).font(.system(size: 15, weight: .medium))
                .foregroundColor(item.isChecked ? AppTheme.textTertiary : AppTheme.textPrimary)
                .strikethrough(item.isChecked, color: AppTheme.textTertiary)
            Spacer()
            if !item.quantity.isEmpty {
                Text(item.quantity).font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .overlay(Divider().background(AppTheme.separator).padding(.leading, 56), alignment: .bottom)
    }
}

struct AddShoppingItemSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var name = ""
    @State private var quantity = ""

    var body: some View {
        DarkSheet(title: "Artikel hinzufügen", isPresented: $isPresented) {
            VStack(spacing: 12) {
                DarkTextField(placeholder: "Artikel (z.B. Milch)", text: $name)
                DarkTextField(placeholder: "Menge (z.B. 2 Liter)", text: $quantity)
            }
        } onSave: {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            store.addShoppingItem(ShoppingItem(name: name, quantity: quantity))
            isPresented = false
        }
    }
}
