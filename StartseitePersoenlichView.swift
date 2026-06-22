import SwiftUI

struct StartseitePersoenlichView: View {
    @Binding var mode: AppMode
    @Binding var selectedTab: TabItem
    @Binding var selectedTrackerSection: TrackerSection
    @EnvironmentObject var store: DataStore
    @State private var confettiTrigger = 0

    private var habitsAllDone: Bool {
        !store.habits.isEmpty && store.habits.allSatisfy(\.isDone)
    }

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
                        Text(greetingTitle).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        StatusDot(color: AppTheme.accentGreen)
                        StatusDot(color: AppTheme.accentAmber)
                        StatusDot(color: AppTheme.accentBlue)
                    }
                }
                .padding(.top, 8)

                // Daily overview (connects all daily trackers)
                dailyOverview

                // Prayer preview (sun arc)
                prayerPreview

                // Today timeline
                todayTimelineCard

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
            .padding(.horizontal, AppTheme.phoneScreenPadding)
            .padding(.bottom, 20)
        }
        .overlay(ConfettiView(trigger: confettiTrigger))
        .onChange(of: habitsAllDone) { _, done in
            if done { Haptics.success(); confettiTrigger += 1 }
        }
    }

    // MARK: - Daily Overview (activity rings)

    private var dailyOverview: some View {
        let slots = store.prayerSlots()
        let prayersDone = slots.filter { $0.isTrackable && $0.isDone }.count
        let habitsDone = store.habits.filter(\.isDone).count
        let habitsTotal = store.habits.count
        let longestStreak = store.withdrawalItems.map { $0.cleanDays() }.max() ?? 0
        let hasWithdrawal = !store.withdrawalItems.isEmpty

        // Tasks due today (done vs total)
        let cal = Calendar.current
        let dueToday = store.personalReminders.filter { r in
            guard let due = r.dueDate else { return false }
            return cal.isDateInToday(due)
        }
        let tasksDone = dueToday.filter(\.isCompleted).count
        let tasksTotal = dueToday.count

        let gebeteP = Double(prayersDone) / 5.0
        let habitsP = habitsTotal == 0 ? 0 : Double(habitsDone) / Double(habitsTotal)
        let tasksP = tasksTotal == 0 ? 0 : Double(tasksDone) / Double(tasksTotal)

        let totalUnits = 5 + habitsTotal + tasksTotal
        let doneUnits = prayersDone + habitsDone + tasksDone
        let overall = totalUnits == 0 ? 0 : Int(Double(doneUnits) / Double(totalUnits) * 100)

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Heute im Überblick")
            HStack(spacing: 18) {
                ActivityRings(
                    rings: [
                        (progress: gebeteP, color: AppTheme.accentAmber),
                        (progress: habitsP, color: AppTheme.accentGreen),
                        (progress: tasksP, color: AppTheme.accent)
                    ],
                    centerLabel: "\(overall)%",
                    centerSub: "erledigt"
                )
                VStack(spacing: 11) {
                    ringLegend("Gebete", "\(prayersDone)/5", AppTheme.accentAmber)
                    ringLegend("Habits", "\(habitsDone)/\(habitsTotal)", AppTheme.accentGreen)
                    ringLegend("Aufgaben", tasksTotal == 0 ? "–" : "\(tasksDone)/\(tasksTotal)", AppTheme.accent)
                    if hasWithdrawal {
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill").font(.system(size: 11)).foregroundColor(AppTheme.accentAmber)
                            Text("Entzug").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("\(longestStreak) Tage").font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private func ringLegend(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
        }
    }

    // MARK: - Today Timeline

    private var todayTimelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Heute")
            if todayEntries.isEmpty {
                Text("Heute nichts geplant").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
                    .padding(.vertical, 4)
            } else {
                TodayTimeline(entries: todayEntries, now: Date())
            }
        }
        .glassCard()
    }

    private var todayEntries: [TimelineEntry] {
        let cal = Calendar.current
        let today = Date()
        var arr: [TimelineEntry] = []

        for s in store.prayerSlots() where s.isTrackable {
            arr.append(TimelineEntry(time: s.time, title: s.name, kind: .prayer, done: s.isDone))
        }
        for occ in store.eventOccurrences(store.personalEvents, on: today) where occ.event.hasTime {
            arr.append(TimelineEntry(time: occ.date, title: occ.event.title, kind: .event))
        }
        for r in store.personalReminders {
            guard let due = r.dueDate, cal.isDateInToday(due) else { continue }
            let c = cal.dateComponents([.hour, .minute], from: due)
            guard (c.hour ?? 0) != 0 || (c.minute ?? 0) != 0 else { continue }
            arr.append(TimelineEntry(time: due, title: r.title, kind: .task, done: r.isCompleted))
        }
        return arr.sorted { $0.time < $1.time }
    }

    // MARK: - Prayer Preview (live IZW Vienna times, tap dots to mark done)

    private var prayerPreview: some View {
        let slots = store.prayerSlots()
        let next = store.nextPrayer()
        let trackable = slots.filter { $0.isTrackable }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Gebete heute", subtitle: "\(trackable.filter(\.isDone).count)/5")
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { openTracker(.gebete) }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Nächstes Gebet").font(.system(size: 11, weight: .medium)).foregroundColor(AppTheme.textTertiary)
                    Text(next.name).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    Text(next.germanName).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(next.date.deTime).font(.system(size: 28, weight: .light, design: .rounded)).foregroundColor(AppTheme.accentAmber)
                    Text("Uhr").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(16)
            .background(AppTheme.accentAmber.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.accentAmber.opacity(0.2), lineWidth: 0.5))

            PrayerSunArc(slots: slots, now: Date())
        }
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture { openTracker(.gebete) }
    }

    // MARK: - Calendar Preview

    private var calendarPreview: some View {
        let upcoming = store.upcomingEventOccurrences(store.personalEvents, from: Date(), days: 60, limit: 3)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Termine")
            if upcoming.isEmpty {
                Text("Keine Termine").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(upcoming) { occ in
                        HStack(spacing: 10) {
                            Rectangle().fill(AppTheme.accentBlue).frame(width: 3, height: 32).clipShape(Capsule())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(occ.event.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                                Text(eventLabel(occ.event, occ.date)).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .kalender } }
    }

    // MARK: - Reminders Preview (tap circle to complete)

    private var remindersPreview: some View {
        let open = store.sortedReminders(store.personalReminders.filter { !$0.isCompleted })
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Aufgaben")
            if open.isEmpty {
                Text("Alles erledigt").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(open.prefix(3)) { r in
                        HStack(spacing: 10) {
                            Button { store.toggleReminder(id: r.id) } label: {
                                Image(systemName: "circle").font(.system(size: 15)).foregroundColor(AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            Text(r.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .erinnerungen } }
    }

    // MARK: - Habits Preview (tap to toggle)

    private var habitsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Tägliche Habits", subtitle: "\(store.habits.filter(\.isDone).count)/\(store.habits.count)")
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { openTracker(.habits) }
            if store.habits.isEmpty {
                Text("Noch keine Habits").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                let done = store.habits.filter(\.isDone).count
                HStack(spacing: 14) {
                    LiquidFillCircle(
                        progress: Double(done) / Double(store.habits.count),
                        size: 60,
                        color: AppTheme.accentGreen,
                        centerLabel: "\(done)/\(store.habits.count)"
                    )
                    HStack(spacing: 8) {
                        ForEach(store.habits.prefix(3)) { habit in
                            Button { store.toggleHabit(id: habit.id) } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle().stroke(AppTheme.glassBorder, lineWidth: 3).frame(width: 44, height: 44)
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
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .glassCard()
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
                            Text(note.date.deDayMonth).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
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
        .contentShape(Rectangle())
        .onTapGesture { withAnimation { selectedTab = .notizen } }
    }

    // MARK: - Withdrawal Preview

    private var cleanTrackerPreview: some View {
        let items = store.withdrawalItems.sorted { $0.cleanHours() > $1.cleanHours() }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Entzug", subtitle: items.isEmpty ? "Noch nichts aktiv" : "\(items.count) aktiv")
            if items.isEmpty {
                Text("Lege fest, womit du aufhören willst und warum es dir wichtig ist.")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textTertiary)
            } else {
                VStack(spacing: 10) {
                    ForEach(items.prefix(3)) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.accentAmber)
                            Text(item.title).font(.system(size: 14, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            Spacer()
                            Text("\(item.cleanDays()) Tage").font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.accentAmber)
                        }
                    }
                }
            }
        }
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture { openTracker(.entzug) }
    }

    private var greetingTitle: String {
        let name = store.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? greeting : "\(greeting), \(name)"
    }

    private func openTracker(_ section: TrackerSection) {
        withAnimation {
            selectedTrackerSection = section
            selectedTab = .tracker
        }
    }

    private func eventLabel(_ event: CalendarEvent, _ date: Date) -> String {
        let day = date.deWeekdayDayMonth
        return event.hasTime ? "\(day), \(date.deTime)" : day
    }
}

struct StatusDot: View {
    let color: Color
    var body: some View { Circle().fill(color.opacity(0.7)).frame(width: 7, height: 7) }
}
