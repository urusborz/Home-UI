import SwiftUI

// MARK: - Design System

enum AppAppearance: String, CaseIterable, Codable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return "Dunkel"
        case .light: return "Hell"
        }
    }

    var preferredColorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}

enum AppAccentTheme: String, CaseIterable, Codable, Identifiable {
    case klar
    case azur
    case rubin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .klar: return "Klar"
        case .azur: return "Azur"
        case .rubin: return "Rubin"
        }
    }

    var primary: Color {
        switch self {
        case .klar: return Color(red: 0.16, green: 0.28, blue: 0.40)
        case .azur: return Color(red: 0.18, green: 0.47, blue: 1.0)
        case .rubin: return Color(red: 0.87, green: 0.16, blue: 0.38)
        }
    }

    var secondary: Color {
        switch self {
        case .klar: return Color(red: 0.08, green: 0.68, blue: 0.62)
        case .azur: return Color(red: 0.02, green: 0.72, blue: 0.96)
        case .rubin: return Color(red: 0.60, green: 0.26, blue: 0.95)
        }
    }

    var tertiary: Color {
        switch self {
        case .klar: return Color(red: 0.58, green: 0.64, blue: 0.72)
        case .azur: return Color(red: 0.38, green: 0.36, blue: 1.0)
        case .rubin: return Color(red: 1.0, green: 0.50, blue: 0.30)
        }
    }

    static func storedValue(_ rawValue: String?) -> AppAccentTheme {
        switch rawValue {
        case "klar": return .klar
        case "azur", "ocean": return .azur
        case "rubin", "sunset": return .rubin
        case "emerald": return .klar
        default: return .klar
        }
    }
}

struct AppTheme {
    static var appearance: AppAppearance {
        AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .dark
    }

    static var accentTheme: AppAccentTheme {
        AppAccentTheme.storedValue(UserDefaults.standard.string(forKey: "appAccentTheme"))
    }

    static var isLight: Bool { appearance == .light }

    // Backgrounds
    static var backgroundPrimary: Color {
        if isLight {
            switch accentTheme {
            case .klar: return Color(red: 0.955, green: 0.966, blue: 0.978)
            case .azur: return Color(red: 0.940, green: 0.965, blue: 0.995)
            case .rubin: return Color(red: 0.990, green: 0.948, blue: 0.965)
            }
        }
        switch accentTheme {
        case .klar: return Color(red: 0.025, green: 0.029, blue: 0.036)
        case .azur: return Color(red: 0.012, green: 0.030, blue: 0.060)
        case .rubin: return Color(red: 0.052, green: 0.018, blue: 0.034)
        }
    }
    static var backgroundSecondary: Color {
        if isLight {
            switch accentTheme {
            case .klar: return Color(red: 0.914, green: 0.936, blue: 0.956)
            case .azur: return Color(red: 0.872, green: 0.930, blue: 0.990)
            case .rubin: return Color(red: 0.974, green: 0.900, blue: 0.934)
            }
        }
        switch accentTheme {
        case .klar: return Color(red: 0.058, green: 0.065, blue: 0.078)
        case .azur: return Color(red: 0.030, green: 0.070, blue: 0.125)
        case .rubin: return Color(red: 0.110, green: 0.036, blue: 0.074)
        }
    }
    static var backgroundTertiary: Color {
        isLight ? Color(red: 0.995, green: 0.997, blue: 1.0) : Color(red: 0.085, green: 0.090, blue: 0.105)
    }
    static var cardSolid: Color {
        isLight ? Color(red: 0.995, green: 0.997, blue: 1.0) : Color(red: 0.092, green: 0.097, blue: 0.112)
    }

    // Glass card
    static var glassBackground: Color { isLight ? Color(red: 0.995, green: 0.997, blue: 1.0).opacity(0.92) : Color(red: 0.105, green: 0.110, blue: 0.128).opacity(0.94) }
    static var glassBorder: Color { isLight ? Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.08) : Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.09) }
    static var glassHighlight: Color { isLight ? Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.96) : Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.11) }
    static var controlBackground: Color { isLight ? Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.060) : Color(red: 0.16, green: 0.17, blue: 0.20).opacity(0.92) }
    static var selectedControlBackground: Color { isLight ? accentTheme.primary.opacity(0.14) : accentTheme.primary.opacity(0.28) }
    static var ringTrack: Color { isLight ? Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.12) : Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.14) }
    static var shadow: Color { isLight ? Color(red: 0.05, green: 0.07, blue: 0.10).opacity(0.14) : Color.black.opacity(0.42) }
    static var onAccent: Color { Color.white }

    // Text
    static var textPrimary: Color { isLight ? Color(red: 0.075, green: 0.085, blue: 0.110) : Color(red: 0.955, green: 0.960, blue: 0.975) }
    static var textSecondary: Color { isLight ? Color(red: 0.32, green: 0.35, blue: 0.42) : Color(red: 0.70, green: 0.72, blue: 0.78) }
    static var textTertiary: Color { isLight ? Color(red: 0.55, green: 0.58, blue: 0.66) : Color(red: 0.48, green: 0.50, blue: 0.57) }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundPrimary, backgroundSecondary, backgroundPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentTheme.primary, accentTheme.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var softAccentGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentTheme.primary.opacity(isLight ? 0.16 : 0.24),
                accentTheme.secondary.opacity(isLight ? 0.10 : 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Accent colors (used sparingly)
    static var accentBlue: Color { accentTheme.primary }
    static var accentGreen: Color { accentTheme.secondary }
    static var accentAmber: Color {
        switch accentTheme {
        case .klar, .azur: return Color(red: 1.0, green: 0.70, blue: 0.23)
        case .rubin: return Color(red: 1.0, green: 0.58, blue: 0.24)
        }
    }
    static var accentPurple: Color { accentTheme.tertiary }

    // Separators
    static var separator: Color { isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.06) }

    // Corner radii
    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 22
    static let radiusXL: CGFloat = 28

    static let phoneScreenPadding: CGFloat = 14
    static let compactPhoneScreenPadding: CGFloat = 12

    static func screenPadding(for width: CGFloat) -> CGFloat {
        width <= 390 ? compactPhoneScreenPadding : phoneScreenPadding
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLarge)
                    .stroke(AppTheme.glassBorder, lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }
}

// MARK: - Section Header Style

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}
