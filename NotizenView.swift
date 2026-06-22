import SwiftUI

struct NotizenView: View {
    let mode: AppMode
    @EnvironmentObject var store: DataStore
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var selectedNote: Note? = nil

    private var list: [Note] {
        let all = mode == .persoenlich ? store.personalNotes : store.familyNotes
        guard !searchText.isEmpty else { return all }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .persoenlich ? "Notizen" : "Gemeinsame Notizen")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("\(list.count) Einträge")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    AddButton { showingAdd = true }
                }
                .padding(.top, 8)

                SearchBarView(text: $searchText)

                if list.isEmpty {
                    EmptyStateView(icon: "note.text", text: searchText.isEmpty ? "Noch keine Notizen" : "Keine Ergebnisse")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(list) { note in
                            NoteCard(note: note)
                                .onTapGesture { selectedNote = note }
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingAdd) {
            AddNoteSheet(mode: mode, isPresented: $showingAdd)
                .environmentObject(store)
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note, isPresented: .constant(true))
                .environmentObject(store)
        }
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
            Text(note.body)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(3)
            Spacer()
            Text(note.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}

// MARK: - Add Note Sheet

struct AddNoteSheet: View {
    let mode: AppMode
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore
    @State private var title = ""
    @State private var body_ = ""

    var body: some View {
        DarkSheet(title: "Neue Notiz", isPresented: $isPresented) {
            VStack(spacing: 12) {
                DarkTextField(placeholder: "Titel", text: $title)
                DarkTextEditor(placeholder: "Notiz schreiben...", text: $body_)
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            store.addNote(Note(title: title, body: body_, isFamily: mode == .familie))
            isPresented = false
        }
    }
}

// MARK: - Note Detail Sheet

struct NoteDetailSheet: View {
    let note: Note
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(note.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Button {
                            store.deleteNotes(IndexSet(integer: 0), from: [note])
                            isPresented = false
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                    }
                    Text(note.date.formatted(date: .long, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textTertiary)
                    Divider().background(AppTheme.separator)
                    Text(note.body)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textTertiary)
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Notizen durchsuchen").foregroundColor(AppTheme.textTertiary)
                }
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textPrimary)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}

extension View {
    func placeholder<C: View>(when show: Bool, @ViewBuilder placeholder: () -> C) -> some View {
        ZStack(alignment: .leading) { if show { placeholder() }; self }
    }
}
