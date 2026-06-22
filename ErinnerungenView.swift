import SwiftUI

struct ErinnerungenView: View {
    let mode: AppMode
    @EnvironmentObject var store: DataStore
    @State private var showingAdd = false
    @State private var newTitle = ""

    private var list: [Reminder] {
        mode == .persoenlich ? store.personalReminders : store.familyReminders
    }
    private var open: [Reminder]   { list.filter { !$0.isCompleted } }
    private var done: [Reminder]   { list.filter { $0.isCompleted } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .persoenlich ? "Erinnerungen" : "Gemeinsame Erinnerungen")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("\(open.count) offen · \(done.count) erledigt")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    AddButton { showingAdd = true }
                }
                .padding(.top, 8)

                // Open
                if !open.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Offen")
                        reminderList(open)
                    }
                }

                // Done
                if !done.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Erledigt")
                        reminderList(done)
                    }
                }

                if list.isEmpty {
                    EmptyStateView(icon: "bell", text: "Noch keine Erinnerungen")
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingAdd) {
            AddReminderSheet(mode: mode, isPresented: $showingAdd)
                .environmentObject(store)
        }
    }

    private func reminderList(_ items: [Reminder]) -> some View {
        VStack(spacing: 1) {
            ForEach(items) { reminder in
                ReminderRow(reminder: reminder)
                    .environmentObject(store)
            }
        }
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}

// MARK: - Reminder Row

struct ReminderRow: View {
    let reminder: Reminder
    @EnvironmentObject var store: DataStore

    var body: some View {
        HStack(spacing: 14) {
            Button { store.toggleReminder(id: reminder.id) } label: {
                ZStack {
                    Circle()
                        .stroke(reminder.isCompleted ? AppTheme.accentGreen : Color.white.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if reminder.isCompleted {
                        Circle().fill(AppTheme.accentGreen).frame(width: 22, height: 22)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(reminder.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(reminder.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                .strikethrough(reminder.isCompleted, color: AppTheme.textTertiary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(Divider().background(AppTheme.separator).padding(.leading, 52), alignment: .bottom)
    }
}

// MARK: - Add Reminder Sheet

struct AddReminderSheet: View {
    let mode: AppMode
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title = ""

    var body: some View {
        DarkSheet(title: "Neue Erinnerung", isPresented: $isPresented) {
            DarkTextField(placeholder: "Erinnerung eingeben...", text: $title)
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            store.addReminder(Reminder(title: title, isFamily: mode == .familie))
            isPresented = false
        }
    }
}
