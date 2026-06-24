import SwiftUI

struct StartseitePersoenlichView: View {
    @Binding var mode: AppMode
    @Binding var selectedTab: TabItem
    @Binding var selectedTrackerSection: TrackerSection
    let onQuickAction: (QuickActionTarget) -> Void
    @EnvironmentObject var store: DataStore
    @State private var confettiTrigger = 0
    @State private var overviewMotion = false

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
            VStack(spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString).font(.system(size: 12, weight: .medium)).foregroundColor(AppTheme.textSecondary)
                        Text(greetingTitle).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        StatusDot(color: AppTheme.accentGreen)
                        StatusDot(color: AppTheme.accentAmber)
                        StatusDot(color: AppTheme.accentBlue)
                    }
                }
                .padding(.top, 8)

                adaptiveOverview
                adaptiveMicroGrid

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
            .padding(.bottom, 10)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay(ConfettiView(trigger: confettiTrigger))
        .onChange(of: habitsAllDone) { _, done in
            if done { Haptics.success(); confettiTrigger += 1 }
        }
        .onAppear {
            withAnimation(.linear(duration: 13).repeatForever(autoreverses: false)) {
                overviewMotion = true
            }
        }
    }

    // MARK: - Adaptive Home Concept

    private var adaptiveOverview: some View {
        let slots = store.prayerSlots()
        let prayersDone = slots.filter { $0.isTrackable && $0.isDone }.count
        let next = store.nextPrayer()
        let habitsDone = store.habits.filter(\.isDone).count
        let habitsTotal = store.habits.count
        let todaysEvents = store.eventOccurrences(store.personalEvents, on: Date()).count

        return ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: AppTheme.heroBaseColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            AngularGradient(
                gradient: Gradient(colors: AppTheme.heroGlowColors),
                center: .center,
                angle: .degrees(210)
            )
            .blur(radius: 22)
            .scaleEffect(1.35)
            .rotationEffect(.degrees(overviewMotion ? 360 : 0))
            .opacity(0.78)

            AdaptiveGridOverlay()
                .opacity(0.24)
                .mask(
                    LinearGradient(
                        colors: [.black.opacity(0.85), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                Text("Heute im Überblick")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nächster Fokus")
                        .font(.system(size: 11, weight: .heavy))
                        .textCase(.uppercase)
                        .foregroundColor(.white.opacity(0.62))
                    Text("\(next.name) steht an")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(next.date.deTime)
                            .font(.system(size: 31, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.microPrayer)
                            .shadow(color: AppTheme.microPrayer.opacity(0.45), radius: 24)
                        Text("Uhr · \(next.germanName)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }
                .padding(.top, 15)

                Spacer(minLength: 60)
            }
            .padding(20)

            VStack {
                Spacer()
                HStack(spacing: 9) {
                    AdaptivePriorityTile(label: "Gebete", value: "\(max(5 - prayersDone, 0)) offen", delay: 0) {
                        openTracker(.gebete)
                    }
                        .frame(maxWidth: .infinity, minHeight: 52)
                    AdaptivePriorityTile(label: "Habits", value: habitsTotal == 0 ? "0 geplant" : "\(habitsDone)/\(habitsTotal)", delay: 0.9) {
                        if habitsTotal == 0 {
                            onQuickAction(.habit)
                        } else {
                            openTracker(.habits)
                        }
                    }
                        .frame(maxWidth: .infinity, minHeight: 52)
                    AdaptivePriorityTile(label: "Termine", value: todaysEvents == 0 ? "frei" : "\(todaysEvents) heute", delay: 1.8) {
                        if todaysEvents == 0 {
                            onQuickAction(.event)
                        } else {
                            withAnimation { selectedTab = .kalender }
                        }
                    }
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .frame(height: 244)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color(red: 0.082, green: 0.141, blue: 0.247).opacity(0.17), radius: 30, x: 0, y: 16)
    }

    private var adaptiveMicroGrid: some View {
        let slots = store.prayerSlots()
        let prayersDone = slots.filter { $0.isTrackable && $0.isDone }.count
        let next = store.nextPrayer()
        let habitsDone = store.habits.filter(\.isDone).count
        let habitsTotal = store.habits.count
        let openTasks = store.personalReminders.filter { !$0.isCompleted }.count
        let totalTasks = store.personalReminders.count
        let nextOpenTask = store.sortedReminders(store.personalReminders.filter { !$0.isCompleted }).first?.title
        let longestStreak = store.withdrawalItems.map { $0.cleanDays() }.max() ?? 0
        let activeWithdrawal = store.withdrawalItems.sorted { $0.cleanHours() > $1.cleanHours() }.first?.title
        let nextHabit = store.habits.first(where: { !$0.isDone })?.title

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            AdaptiveMicroCard(
                title: "Habits",
                subtitle: habitsTotal == 0 ? "noch leer" : "\(habitsDone) von \(habitsTotal) erledigt",
                detail: nextHabit.map { "Nächster Habit: \($0)" } ?? (habitsTotal == 0 ? "Lege deinen ersten Habit an" : "Alle heutigen Habits geschafft"),
                value: "\(habitsDone)/\(habitsTotal)",
                color: AppTheme.microHabit,
                delay: 0
            ) {
                if habitsTotal == 0 {
                    onQuickAction(.habit)
                } else {
                    openTracker(.habits)
                }
            }
            AdaptiveMicroCard(
                title: "Aufgaben",
                subtitle: openTasks == 0 ? "alles erledigt" : "\(openTasks) offen",
                detail: nextOpenTask.map { "Als Nächstes: \($0)" } ?? "Heute frei von offenen Aufgaben",
                value: "\(max(totalTasks - openTasks, 0))/\(totalTasks)",
                color: AppTheme.microTask,
                delay: 0.7
            ) {
                if totalTasks == 0 {
                    onQuickAction(.reminder)
                } else {
                    withAnimation { selectedTab = .erinnerungen }
                }
            }
            AdaptiveMicroCard(
                title: "Gebete",
                subtitle: "\(prayersDone) von 5 erledigt",
                detail: "\(next.name) um \(next.date.deTime) Uhr",
                value: "\(prayersDone)/5",
                color: AppTheme.microPrayer,
                delay: 1.4
            ) {
                openTracker(.gebete)
            }
            AdaptiveMicroCard(
                title: "Status",
                subtitle: longestStreak == 0 ? "stabil starten" : "Entzug Tag \(longestStreak)",
                detail: activeWithdrawal.map { "Fokus: \($0)" } ?? "Noch kein Entzug aktiv",
                value: "\(longestStreak)",
                color: AppTheme.microStatus,
                delay: 2.1
            ) {
                if store.withdrawalItems.isEmpty {
                    onQuickAction(.withdrawal)
                } else {
                    openTracker(.entzug)
                }
            }
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

struct AdaptiveGridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let step: CGFloat = 42
            Path { path in
                var x: CGFloat = 0
                while x <= geo.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    x += step
                }

                var y: CGFloat = 0
                while y <= geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += step
                }
            }
            .stroke(.white.opacity(0.34), lineWidth: 1)
        }
    }
}

struct AdaptivePriorityTile: View {
    let label: String
    let value: String
    let delay: Double
    let action: () -> Void
    @State private var isFloating = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(label)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.white.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.17), lineWidth: 1)
            )
            .offset(y: isFloating ? -2 : 0)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 4).delay(delay).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}

struct AdaptiveMicroCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let value: String
    let color: Color
    let delay: Double
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(AppTheme.isLight ? Color.white.opacity(0.72) : AppTheme.surface)

                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(color.opacity(pulse ? 0.18 : 0.12))
                    .frame(width: 108, height: 108)
                    .rotationEffect(.degrees(pulse ? 34 : 26))
                    .scaleEffect(pulse ? 1.05 : 1)
                    .offset(x: 36 + (pulse ? -6 : 0), y: 42 + (pulse ? -5 : 0))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(detail)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer()

                    HStack {
                        Spacer()
                        Text(value)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                    }
                }
                .padding(14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 102)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.isLight ? Color.white.opacity(0.76) : AppTheme.glassBorder, lineWidth: 0.8)
            )
            .shadow(color: AppTheme.shadow.opacity(AppTheme.isLight ? 0.42 : 0.30),
                    radius: 20, x: 0, y: 10)
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 5).delay(delay).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
