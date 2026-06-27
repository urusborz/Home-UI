import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 30)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lesaria")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Melde dich mit Apple an, damit deine Daten privat ueber iCloud synchronisiert werden.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privater iCloud Sync")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Deine Daten bleiben in deiner privaten CloudKit Datenbank.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        store.signInWithApple(result)
                    }
                    .signInWithAppleButtonStyle(store.appAppearance == .light ? .black : .white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
                    .disabled(store.isAuthenticating)

                    if store.isAuthenticating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Apple Anmeldung wird vorbereitet...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

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
}
