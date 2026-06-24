import SwiftUI

struct AuthView: View {
    @EnvironmentObject var store: DataStore
    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 30)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lesaria")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Melde dich an, damit deine Daten automatisch synchronisiert werden.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("E-Mail")
                        DarkTextField(placeholder: "name@example.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Passwort")
                        SecureField("", text: $password)
                            .placeholder(when: password.isEmpty) {
                                Text("Mindestens 6 Zeichen").foregroundColor(AppTheme.textTertiary)
                            }
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(AppTheme.controlBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
                    }

                    Button { submit() } label: {
                        HStack(spacing: 8) {
                            if store.isAuthenticating {
                                ProgressView().tint(AppTheme.onAccent)
                            } else {
                                Image(systemName: isCreatingAccount ? "person.badge.plus.fill" : "person.crop.circle.fill")
                            }
                            Text(isCreatingAccount ? "Account erstellen" : "Anmelden")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(canSubmit ? AppTheme.accent : AppTheme.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit || store.isAuthenticating)

                    Button {
                        isCreatingAccount.toggle()
                        store.authStatusMessage = ""
                    } label: {
                        Text(isCreatingAccount ? "Ich habe schon einen Account" : "Neuen Account erstellen")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    if !store.authStatusMessage.isEmpty {
                        Text(store.authStatusMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .glassCard()

                Spacer()
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
        }
        .preferredColorScheme(store.appAppearance.preferredColorScheme)
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    private func submit() {
        if isCreatingAccount {
            store.signUp(email: email, password: password)
        } else {
            store.signIn(email: email, password: password)
        }
    }
}
