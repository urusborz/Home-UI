import SwiftUI

struct ErinnerungenView: View {
    let mode: AppMode
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false
    @State private var editing: Reminder? = nil
    @State private var reading: Reminder? = nil

    private var list: [Reminder] {
        mode == .persoenlich ? store.personalReminders : store.familyReminders
    }
    private var open: [Reminder]   { store.sortedReminders(list.filter { !$0.isCompleted }) }
    private var done: [Reminder]   { list.filter { $0.isCompleted } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .persoenlich ? "Aufgaben" : "Gemeinsame Aufgaben")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("\(open.count) offen · \(done.count) erledigt")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    if !done.isEmpty {
                        Button { store.deleteCompletedReminders(isFamily: mode == .familie) } label: {
                            Text("Erledigt löschen")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(AppTheme.controlBackground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    AddButton { showingAdd = true }
                }
                .padding(.top, 8)

                if !open.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Offen")
                        reminderList(open)
                    }
                }

                if !done.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Erledigt")
                        reminderList(done)
                    }
                }

                if list.isEmpty {
                    EmptyStateView(icon: "bell", text: "Noch keine Aufgaben", actionTitle: "Aufgabe anlegen") {
                        showingAdd = true
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingAdd) {
            ReminderSheet(mode: mode, existing: nil, isPresented: $showingAdd)
                .environmentObject(store)
        }
        .sheet(item: $editing) { reminder in
            ReminderSheet(mode: mode, existing: reminder, isPresented: Binding(
                get: { editing != nil },
                set: { if !$0 { editing = nil } }
            ))
            .environmentObject(store)
        }
        .sheet(item: $reading) { reminder in
            ReminderDetailSheet(
                reminder: reminder,
                onEdit: {
                    reading = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { editing = reminder }
                },
                onDelete: {
                    store.deleteReminder(id: reminder.id)
                    reading = nil
                },
                isPresented: Binding(get: { reading != nil }, set: { if !$0 { reading = nil } })
            )
            .environmentObject(store)
        }
    }

    private func reminderList(_ items: [Reminder]) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { reminder in
                SwipeToDeleteRow(onDelete: { store.deleteReminder(id: reminder.id) }) {
                    ReminderRow(reminder: reminder).environmentObject(store)
                }
                .onTapGesture { reading = reminder }
                .itemContextMenu(onEdit: { editing = reminder },
                                 onDelete: { store.deleteReminder(id: reminder.id) })
            }
        }
    }
}

// MARK: - Reminder Row

struct ReminderRow: View {
    let reminder: Reminder
    @EnvironmentObject var store: DataStore

    private var isOverdue: Bool {
        guard let due = reminder.dueDate, !reminder.isCompleted else { return false }
        return due < Date()
    }

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleReminder(id: reminder.id) } label: {
                ZStack {
                    Circle()
                        .stroke(reminder.isCompleted ? AppTheme.accentGreen : AppTheme.ringTrack, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if reminder.isCompleted {
                        Circle().fill(AppTheme.accentGreen).frame(width: 22, height: 22)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.onAccent)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(reminder.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                    .strikethrough(reminder.isCompleted, color: AppTheme.textTertiary)
                if let due = reminder.dueDate {
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar").font(.system(size: 10))
                            Text(dueLabel(due)).font(.system(size: 11, weight: isOverdue ? .semibold : .regular))
                        }
                        .foregroundColor(isOverdue ? AppTheme.accentAmber : AppTheme.textTertiary)
                        if reminder.recurrence != .none {
                            HStack(spacing: 3) {
                                Image(systemName: "repeat").font(.system(size: 9))
                                Text(reminder.recurrence.short).font(.system(size: 11))
                            }
                            .foregroundColor(AppTheme.accentBlue)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func dueLabel(_ date: Date) -> String {
        let day = date.deWeekdayDayMonth
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        if (comps.hour ?? 0) == 0 && (comps.minute ?? 0) == 0 {
            return isOverdue ? "Überfällig · \(day)" : day
        }
        return (isOverdue ? "Überfällig · " : "") + "\(day), \(date.deTime)"
    }
}

// MARK: - Reminder Detail

struct ReminderDetailSheet: View {
    let reminder: Reminder
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.controlBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.onAccent)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.accent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.accentAmber)
                            .frame(width: 34, height: 34)
                            .background(AppTheme.controlBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        StatusPill(text: reminder.isFamily ? "Familie" : "Persönlich", color: reminder.isFamily ? AppTheme.accentPurple : AppTheme.accent)
                        StatusPill(text: reminder.isCompleted ? "Erledigt" : "Offen", color: reminder.isCompleted ? AppTheme.accentGreen : AppTheme.accentAmber)
                        if reminder.recurrence != .none {
                            StatusPill(text: reminder.recurrence.short, color: AppTheme.accentSecondary)
                        }
                    }
                    Text(reminder.title)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let due = reminder.dueDate {
                        Label(dueLine(due), systemImage: "calendar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Button {
                        store.toggleReminder(id: reminder.id)
                        isPresented = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: reminder.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                            Text(reminder.isCompleted ? "Wieder öffnen" : "Als erledigt markieren")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(reminder.isCompleted ? AppTheme.accentSecondary : AppTheme.accentGreen)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .glassCard()

                Spacer()
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func dueLine(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        if (c.hour ?? 0) == 0 && (c.minute ?? 0) == 0 {
            return date.deWeekdayDayMonth
        }
        return "\(date.deWeekdayDayMonth), \(date.deTime) Uhr"
    }
}

// MARK: - Reminder Sheet (Add + Edit)

struct ReminderSheet: View {
    let mode: AppMode
    let existing: Reminder?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore

    @State private var title: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var recurrence: Recurrence
    @State private var isFamily: Bool

    init(mode: AppMode, existing: Reminder?, isPresented: Binding<Bool>) {
        self.mode = mode
        self.existing = existing
        self._isPresented = isPresented
        _title = State(initialValue: existing?.title ?? "")
        _hasDueDate = State(initialValue: existing?.dueDate != nil)
        _dueDate = State(initialValue: existing?.dueDate ?? Date())
        _recurrence = State(initialValue: existing?.recurrence ?? .none)
        _isFamily = State(initialValue: existing?.isFamily ?? mode == .familie)
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Neue Aufgabe" : "Aufgabe bearbeiten",
                  isPresented: $isPresented, detents: [.medium, .large]) {
            VStack(spacing: 14) {
                DarkTextField(placeholder: "Aufgabe eingeben...", text: $title)
                ScopePicker(isFamily: $isFamily)
                DarkToggleRow(title: "Fälligkeitsdatum", isOn: $hasDueDate.animation())
                if hasDueDate {
                    DatePicker("Fällig am", selection: $dueDate)
                        .datePickerStyle(.compact)
                        .colorScheme(AppTheme.appearance.preferredColorScheme)
                        .tint(AppTheme.accentBlue)
                        .padding(.horizontal, 4)
                    RecurrencePicker(selection: $recurrence)
                }
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var r = existing ?? Reminder(title: "", isFamily: mode == .familie)
            r.title = title
            r.isFamily = isFamily
            r.dueDate = hasDueDate ? dueDate : nil
            r.recurrence = hasDueDate ? recurrence : .none
            if existing == nil { store.addReminder(r) } else { store.updateReminder(r) }
            isPresented = false
        }
    }
}
