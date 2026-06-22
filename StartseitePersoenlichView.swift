import SwiftUI

struct StartseitePersoenlichView: View {
    @Binding var mode: AppMode
    @Binding var selectedTab: TabItem
    @EnvironmentObject var store: DataStore

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12:  return "Guten Morgen"
        case 12..<18: return "Guten Tag"
        case 18..<22: return "Guten Abend"
        default:      return "Gute Nacht"
        }
    }

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_AT")
        f.dateFormat = "EEEE, d. MMMM"
        return f.string(from: .now)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary)
                        Text(greeting).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        StatusDot(color: AppTheme.accentGreen)
                        StatusDot(color: AppTheme.accentAmber)
                        StatusDot(color: AppTheme.accentBlue)
                    }
                }
                .padding(.top, 8)

                // Prayer preview
                prayerPreview

                // Calendar + Reminders
                HStack(alignment: .top, spacing: 14) {
                    calendarPreview
                    remindersPreview
                }

                // Habits
                habitsPreview

                // Notes
                notesPreview

                // Clean tracker
                cleanTrackerPreview

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Prayer Preview

    private var prayerPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Gebete heute")
            if let next = store.prayers.first(where: { $0.isNext }) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Nächstes Gebet").font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.textTertiary)
                        Text(next.name).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                        Text(next.germanName).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(next.time).font(.system(size: 28, weight: .light, design: .rounded)).foregroundColor(AppTheme.accentAmber)
                        Text("Uhr").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
                    }
                }
                .padding(16)
                .background(AppTheme.accentAmber.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.accentAmber.opacity(0.2), lineWidth: 0.5))
            }
            HStack(spacing: 0) {
                ForEach(store.prayers) { prayer in
                    VStack(spacing: 5) {
                        ZStack {
                            Circle().fill(prayer.isDone ? AppTheme.accentGreen.opacity(0.2) : Color.white.opacity(0.06)).frame(width: 32, height: 32)
                            Image(systemName: prayer.isDone ? "checkmark" : (prayer.isNext ? "circle.dotted" : "circle"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(prayer.isDone ? AppTheme.accentGreen : (prayer.isNext ? AppTheme.accentAmber : AppTheme.textTertiary))
                        }
                        Text(prayer.name).font(.system(size: 10, weight: .medium)).foregroundColor(prayer.isNext ? AppTheme.accentAmber : AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glassCard()
        .onTapGesture { withAnimation { selectedTab = .tracker } }
    }

    // MARK: - Calendar Preview

    private var calendarPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Termine")
            if store.personalEvents.isEmpty {
                Text("Keine Termine").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.personalEvents.prefix(3)) { event in
                        HStack(spacing: 10) {
                            Rectangle().fill(AppTheme.accentBlue).frame(width: 3, height: 32).clipShape(Capsule())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                                Text(eventLabel(event.date)).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .onTapGesture { withAnimation { selectedTab = .kalender } }
    }

    // MARK: - Reminders Preview

    private var remindersPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Erinnerungen")
            let open = store.personalReminders.filter { !$0.isCompleted }
            if open.isEmpty {
                Text("Alles erledigt").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(open.prefix(3)) { r in
                        HStack(spacing: 10) {
                            Image(systemName: "circle").font(.system(size: 14)).foregroundColor(AppTheme.textTertiary)
                            Text(r.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .onTapGesture { withAnimation { selectedTab = .erinnerungen } }
    }

    // MARK: - Habits Preview

    private var habitsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tägliche Habits", subtitle: "\(store.habits.filter(\.isDone).count)/\(store.habits.count)")
            if store.habits.isEmpty {
                Text("Noch keine Habits").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                HStack(spacing: 10) {
                    ForEach(store.habits.prefix(4)) { habit in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.1), lineWidth: 3).frame(width: 44, height: 44)
                                if habit.isDone {
                                    Circle().fill(AppTheme.accentGreen.opacity(0.2)).frame(width: 44, height: 44)
                                    Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.accentGreen)
                                } else {
                                    Text("\(habit.streak)").font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            Text(habit.title).font(.system(size: 11, weight: .medium)).foregroundColor(habit.isDone ? AppTheme.textPrimary : AppTheme.textTertiary).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .glassCard()
        .onTapGesture { withAnimation { selectedTab = .tracker } }
    }

    // MARK: - Notes Preview

    private var notesPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notizen")
            if store.personalNotes.isEmpty {
                Text("Noch keine Notizen").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                HStack(spacing: 12) {
                    ForEach(store.personalNotes.prefix(2)) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Text(note.body).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).lineLimit(2)
                            Spacer()
                            Text(note.date.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .background(AppTheme.glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
        .onTapGesture { withAnimation { selectedTab = .notizen } }
    }

    // MARK: - Clean Tracker Preview

    private var cleanTrackerPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Clean Tracker", subtitle: "\(store.cleanTasks.filter(\.isCompleted).count)/\(store.cleanTasks.count)")
            if store.cleanTasks.isEmpty {
                Text("Noch keine Aufgaben").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.cleanTasks.prefix(3)) { task in
                        HStack(spacing: 12) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16)).foregroundColor(task.isCompleted ? AppTheme.accentGreen : AppTheme.textTertiary)
                            Text(task.title).font(.system(size: 14, weight: .medium)).foregroundColor(task.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard()
        .onTapGesture { withAnimation { selectedTab = .tracker } }
    }

    private func eventLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Heute" }
        if Calendar.current.isDateInTomorrow(date) { return "Morgen" }
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "EE, d. MMM"
        return f.string(from: date)
    }
}

struct StatusDot: View {
    let color: Color
    var body: some View { Circle().fill(color.opacity(0.7)).frame(width: 7, height: 7) }
}
