import SwiftUI
import UIKit

struct BackupSheet: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var exportURL: URL? = nil
    @State private var importText = ""
    @State private var message: String? = nil
    @State private var messageColor: Color = AppTheme.accentGreen
    @State private var showImportConfirm = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    HStack {
                        Text("Einstellungen")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Button { isPresented = false } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(AppTheme.controlBackground).clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 18)

                    if let message {
                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(messageColor)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(messageColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                    }

                    // Appearance
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Darstellung")

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Name")
                            DarkTextField(
                                placeholder: "Name für die Startseite",
                                text: Binding(
                                    get: { store.displayName },
                                    set: { store.setDisplayName($0) }
                                )
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Modus")
                            HStack(spacing: 10) {
                                ForEach(AppAppearance.allCases) { appearance in
                                    settingsOption(
                                        title: appearance.title,
                                        isSelected: store.appAppearance == appearance,
                                        swatch: appearance == .dark ? Color.black : Color.white
                                    ) {
                                        store.setAppearance(appearance)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Akzent")
                            HStack(spacing: 10) {
                                ForEach(AppAccentTheme.allCases) { theme in
                                    settingsOption(
                                        title: theme.title,
                                        isSelected: store.appAccentTheme == theme,
                                        swatch: theme.primary
                                    ) {
                                        store.setAccentTheme(theme)
                                    }
                                }
                            }
                        }
                    }
                    .glassCard()

                    // Export
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Exportieren")
                        Text("Sichere alle Daten (Termine, Aufgaben, Notizen, Einkauf, Tracker) als Datei. Ohne Backup gehen Daten beim Löschen der App verloren.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)

                        if let url = exportURL {
                            ShareLink(item: url) {
                                actionLabel(icon: "square.and.arrow.up", text: "Backup teilen / sichern", filled: true)
                            }
                        }
                        Button {
                            UIPasteboard.general.string = store.exportJSON()
                            flash("In Zwischenablage kopiert ✓", AppTheme.accentGreen)
                        } label: {
                            actionLabel(icon: "doc.on.doc", text: "In Zwischenablage kopieren", filled: false)
                        }
                        .buttonStyle(.plain)
                    }
                    .glassCard()

                    // Import
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Importieren")
                        Text("Backup-Text hier einfügen und importieren. Achtung: ersetzt alle aktuellen Daten.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)

                        DarkTextEditor(placeholder: "Backup-JSON hier einfügen...", text: $importText)

                        Button {
                            if let s = UIPasteboard.general.string { importText = s }
                        } label: {
                            actionLabel(icon: "doc.on.clipboard", text: "Aus Zwischenablage einfügen", filled: false)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showImportConfirm = true
                        } label: {
                            actionLabel(icon: "tray.and.arrow.down", text: "Importieren", filled: true)
                        }
                        .buttonStyle(.plain)
                        .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    }
                    .glassCard()

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, AppTheme.phoneScreenPadding)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { exportURL = store.exportFileURL() }
        .alert("Daten ersetzen?", isPresented: $showImportConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Importieren", role: .destructive) { performImport() }
        } message: {
            Text("Alle aktuellen Daten werden durch das Backup ersetzt. Das kann nicht rückgängig gemacht werden.")
        }
    }

    private func performImport() {
        if store.importJSON(importText) {
            importText = ""
            flash("Import erfolgreich ✓", AppTheme.accentGreen)
            exportURL = store.exportFileURL()
        } else {
            flash("Import fehlgeschlagen – ungültiges Backup.", AppTheme.accentAmber)
        }
    }

    private func flash(_ text: String, _ color: Color) {
        message = text
        messageColor = color
    }

    private func actionLabel(icon: String, text: String, filled: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold))
            Text(text).font(.system(size: 15, weight: .semibold))
            Spacer()
        }
        .foregroundColor(filled ? AppTheme.onAccent : AppTheme.textPrimary)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background {
            if filled {
                AppTheme.accentGradient
            } else {
                AppTheme.controlBackground
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }

    private func settingsOption(title: String, isSelected: Bool, swatch: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(swatch)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(AppTheme.glassBorder, lineWidth: 1))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? AppTheme.onAccent : AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background {
                if isSelected {
                    AppTheme.accentGradient
                } else {
                    AppTheme.controlBackground
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(isSelected ? AppTheme.accentBlue.opacity(0.35) : AppTheme.glassBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}
