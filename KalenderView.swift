import SwiftUI

struct KalenderView: View {
    let mode: AppMode
    @EnvironmentObject var store: DataStore
    @State private var selectedDate = Date()
    @State private var showingAdd = false

    private var events: [CalendarEvent] {
        mode == .persoenlich ? store.personalEvents : store.familyEvents
    }
    private var accentColor: Color {
        mode == .persoenlich ? AppTheme.accentBlue : AppTheme.accentPurple
    }
    private var eventsForSelected: [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    private var upcoming: [CalendarEvent] {
        events.filter {
            !Calendar.current.isDate($0.date, inSameDayAs: selectedDate) && $0.date > selectedDate
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .persoenlich ? "Mein Kalender" : "Familienkalender")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(monthYearLabel)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    AddButton { showingAdd = true }
                }
                .padding(.top, 8)

                // Week strip
                weekStrip

                // Events for selected day
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Ausgewählter Tag", subtitle: "\(eventsForSelected.count) Termine")

                    if eventsForSelected.isEmpty {
                        EmptyStateView(icon: "calendar", text: "Kein Termin an diesem Tag")
                    } else {
                        ForEach(eventsForSelected) { event in
                            EventRow(event: event, accentColor: accentColor)
                        }
                    }
                }
                .glassCard()

                // Upcoming
                if !upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Demnächst")
                        ForEach(upcoming.prefix(5)) { event in
                            EventRow(event: event, accentColor: accentColor)
                        }
                    }
                    .glassCard()
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingAdd) {
            AddEventSheet(mode: mode, selectedDate: selectedDate, isPresented: $showingAdd)
                .environmentObject(store)
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let isToday = Calendar.current.isDateInToday(date)
                let hasEvent = events.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }

                Button { withAnimation(.spring(response: 0.3)) { selectedDate = date } } label: {
                    VStack(spacing: 5) {
                        Text(dayLetter(date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isSelected ? .white : AppTheme.textTertiary)
                        Text(dayNumber(date))
                            .font(.system(size: 16, weight: isToday ? .bold : .regular, design: .rounded))
                            .foregroundColor(isSelected ? .white : (isToday ? accentColor : AppTheme.textPrimary))
                        Circle()
                            .fill(hasEvent ? accentColor : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12).fill(accentColor.opacity(0.25))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .glassCard(padding: 0)
    }

    private var weekDays: [Date] {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private var monthYearLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate)
    }
    private func dayLetter(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "EE"
        return String(f.string(from: d).prefix(2)).uppercased()
    }
    private func dayNumber(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: d)
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: CalendarEvent
    let accentColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3, height: 44)
                .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(dateLabel(event.date))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }

    private func dateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Heute" }
        if Calendar.current.isDateInTomorrow(date) { return "Morgen" }
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "EE, d. MMM"
        return f.string(from: date)
    }
}

// MARK: - Add Event Sheet

struct AddEventSheet: View {
    let mode: AppMode
    let selectedDate: Date
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title = ""
    @State private var date: Date

    init(mode: AppMode, selectedDate: Date, isPresented: Binding<Bool>) {
        self.mode = mode
        self.selectedDate = selectedDate
        self._isPresented = isPresented
        self._date = State(initialValue: selectedDate)
    }

    var body: some View {
        DarkSheet(title: "Neuer Termin", isPresented: $isPresented) {
            VStack(spacing: 12) {
                DarkTextField(placeholder: "Titel", text: $title)
                DatePicker("Datum", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .padding(.horizontal, 4)
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            store.addEvent(CalendarEvent(title: title, date: date, isFamily: mode == .familie))
            isPresented = false
        }
    }
}

// MARK: - View Toggle Button (reused)

struct ViewToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : AppTheme.textTertiary)
                .padding(.vertical, 7).padding(.horizontal, 14)
                .background(Group { if isSelected { Capsule().fill(Color.white.opacity(0.1)).padding(3) } })
        }
        .buttonStyle(.plain)
    }
}
