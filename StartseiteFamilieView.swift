import SwiftUI

struct StartseiteFamilieView: View {
    @Binding var mode: AppMode
    @Binding var selectedTab: TabItem
    @EnvironmentObject var store: DataStore

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
                        Text("Familien-Übersicht").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        StatusDot(color: AppTheme.accentPurple)
                        StatusDot(color: AppTheme.accentBlue)
                    }
                }
                .padding(.top, 8)

                // Shared appointments
                sharedAppointments

                // Reminders + Shopping
                HStack(alignment: .top, spacing: 14) {
                    sharedReminders
                    shoppingPreview
                }

                // Shared notes
                sharedNotes

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var sharedAppointments: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Gemeinsame Termine")
            if store.familyEvents.isEmpty {
                Text("Noch keine Termine").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.familyEvents.prefix(3)) { event in
                        HStack(spacing: 12) {
                            Rectangle().fill(AppTheme.accentPurple).frame(width: 3, height: 38).clipShape(Capsule())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                                Text(eventLabel(event.date)).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                    }
                }
            }
        }
        .glassCard()
        .onTapGesture { withAnimation { selectedTab = .kalender } }
    }

    private var sharedReminders: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Erinnerungen")
            let open = store.familyReminders.filter { !$0.isCompleted }
            if open.isEmpty {
                Text("Alles erledigt").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 4)
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

    private var shoppingPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Einkauf")
            let open = store.shoppingItems.filter { !$0.isChecked }
            if open.isEmpty {
                Text("Liste leer").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(open.prefix(3)) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "circle").font(.system(size: 14)).foregroundColor(AppTheme.textTertiary)
                            Text(item.name).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            if !item.quantity.isEmpty {
                                Text(item.quantity).font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .glassCard().frame(maxWidth: .infinity)
        .onTapGesture { withAnimation { selectedTab = .tracker } }
    }

    private var sharedNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Gemeinsame Notizen")
            if store.familyNotes.isEmpty {
                Text("Noch keine Notizen").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
            } else {
                HStack(spacing: 12) {
                    ForEach(store.familyNotes.prefix(2)) { note in
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

    private func eventLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Heute" }
        if Calendar.current.isDateInTomorrow(date) { return "Morgen" }
        let f = DateFormatter(); f.locale = Locale(identifier: "de_AT"); f.dateFormat = "EE, d. MMM"
        return f.string(from: date)
    }
}
