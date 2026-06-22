import SwiftUI

// MARK: - Design System

enum AppAppearance: String, CaseIterable, Codable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
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
    case ocean
    case emerald
    case sunset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean: return "Ocean"
        case .emerald: return "Emerald"
        case .sunset: return "Sunset"
        }
    }

    var primary: Color {
        switch self {
        case .ocean: return Color(red: 0.28, green: 0.55, blue: 1.0)
        case .emerald: return Color(red: 0.10, green: 0.70, blue: 0.48)
        case .sunset: return Color(red: 1.0, green: 0.45, blue: 0.25)
        }
    }

    var secondary: Color {
        switch self {
        case .ocean: return Color(red: 0.22, green: 0.85, blue: 0.55)
        case .emerald: return Color(red: 0.30, green: 0.58, blue: 1.0)
        case .sunset: return Color(red: 1.0, green: 0.72, blue: 0.25)
        }
    }

    var tertiary: Color {
        switch self {
        case .ocean: return Color(red: 0.65, green: 0.45, blue: 1.0)
        case .emerald: return Color(red: 0.74, green: 0.52, blue: 1.0)
        case .sunset: return Color(red: 0.74, green: 0.42, blue: 1.0)
        }
    }
}

struct AppTheme {
    static var appearance: AppAppearance {
        AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .dark
    }

    static var accentTheme: AppAccentTheme {
        AppAccentTheme(rawValue: UserDefaults.standard.string(forKey: "appAccentTheme") ?? "") ?? .ocean
    }

    static var isLight: Bool { appearance == .light }

    // Backgrounds
    static var backgroundPrimary: Color {
        isLight ? Color(red: 0.955, green: 0.965, blue: 0.98) : Color(red: 0.024, green: 0.027, blue: 0.035)
    }
    static var backgroundSecondary: Color {
        isLight ? Color(red: 0.91, green: 0.93, blue: 0.955) : Color(red: 0.047, green: 0.051, blue: 0.063)
    }
    static var backgroundTertiary: Color {
        isLight ? Color.white : Color(red: 0.07, green: 0.075, blue: 0.09)
    }
    static var cardSolid: Color {
        isLight ? Color.white : Color(red: 0.085, green: 0.09, blue: 0.105)
    }

    // Glass card
    static var glassBackground: Color { isLight ? Color.white.opacity(0.78) : Color.white.opacity(0.05) }
    static var glassBorder: Color { isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.08) }
    static var glassHighlight: Color { isLight ? Color.white.opacity(0.92) : Color.white.opacity(0.12) }
    static var controlBackground: Color { isLight ? Color.black.opacity(0.055) : Color.white.opacity(0.06) }
    static var selectedControlBackground: Color { isLight ? Color.black.opacity(0.085) : Color.white.opacity(0.11) }

    // Text
    static var textPrimary: Color { isLight ? Color(red: 0.09, green: 0.10, blue: 0.13) : Color.white }
    static var textSecondary: Color { isLight ? Color(red: 0.34, green: 0.36, blue: 0.42) : Color(white: 0.55) }
    static var textTertiary: Color { isLight ? Color(red: 0.56, green: 0.58, blue: 0.64) : Color(white: 0.35) }

    // Accent colors (used sparingly)
    static var accentBlue: Color { accentTheme.primary }
    static var accentGreen: Color { accentTheme.secondary }
    static var accentAmber: Color {
        switch accentTheme {
        case .ocean, .emerald: return Color(red: 1.0, green: 0.72, blue: 0.25)
        case .sunset: return Color(red: 1.0, green: 0.58, blue: 0.18)
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
