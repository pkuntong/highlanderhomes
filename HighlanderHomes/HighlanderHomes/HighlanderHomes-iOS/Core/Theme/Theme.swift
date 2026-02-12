import SwiftUI
import UIKit

// MARK: - Theme Namespace
enum Theme {

    // MARK: - Color Palette (Modern Slate & Emerald Green)
    enum Colors {
        private static func dynamicColor(lightHex: String, darkHex: String) -> Color {
            Color(
                UIColor { traits in
                    UIColor(hex: traits.userInterfaceStyle == .dark ? darkHex : lightHex)
                }
            )
        }

        // Primary Emerald
        static let emerald = Color(hex: "10B981")
        static let emeraldLight = Color(hex: "34D399")
        static let emeraldDark = Color(hex: "059669")
        static let emeraldMuted = Color(hex: "065F46")

        // Slate System
        // These tokens auto-adapt in Light/Dark mode (Light is intentionally inverted for a clean white/gray UI).
        static var slate50: Color { dynamicColor(lightHex: "0F172A", darkHex: "F8FAFC") }
        static var slate100: Color { dynamicColor(lightHex: "1E293B", darkHex: "F1F5F9") }
        static var slate200: Color { dynamicColor(lightHex: "334155", darkHex: "E2E8F0") }
        static var slate300: Color { dynamicColor(lightHex: "475569", darkHex: "CBD5E1") }
        static var slate400: Color { dynamicColor(lightHex: "64748B", darkHex: "94A3B8") }
        static var slate500: Color { dynamicColor(lightHex: "94A3B8", darkHex: "64748B") }
        static var slate600: Color { dynamicColor(lightHex: "CBD5E1", darkHex: "475569") }
        static var slate700: Color { dynamicColor(lightHex: "E2E8F0", darkHex: "334155") }
        static var slate800: Color { dynamicColor(lightHex: "F1F5F9", darkHex: "1E293B") }
        static var slate900: Color { dynamicColor(lightHex: "F8FAFC", darkHex: "0F172A") }
        static var slate950: Color { dynamicColor(lightHex: "FFFFFF", darkHex: "020617") }

        // Semantic Colors
        static var background: Color { slate950 }
        static var surface: Color { slate900 }
        static var surfaceElevated: Color { slate800 }
        static var cardBackground: Color { slate800.opacity(0.7) }

        // Status Colors
        static let alertRed = Color(hex: "EF4444")
        static let alertRedMuted = Color(hex: "7F1D1D")
        static let warningAmber = Color(hex: "F59E0B")
        static let warningAmberMuted = Color(hex: "78350F")
        static let successGreen = emerald
        static let infoBlue = Color(hex: "3B82F6")
        static let infoBlueMuted = Color(hex: "1E3A8A")

        // Gold for payments
        static let gold = Color(hex: "FFD700")
        static let goldMuted = Color(hex: "A16207")

        // Text
        static var textPrimary: Color { slate50 }
        static var textSecondary: Color { slate400 }
        static var textMuted: Color { slate500 }
    }

    // MARK: - Gradients
    enum Gradients {
        static let emeraldGlow = LinearGradient(
            colors: [Colors.emeraldLight, Colors.emerald, Colors.emeraldDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let goldShimmer = LinearGradient(
            colors: [Color(hex: "FBBF24"), Colors.gold, Color(hex: "F59E0B")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let alertPulse = LinearGradient(
            colors: [Color(hex: "F87171"), Colors.alertRed, Color(hex: "DC2626")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let surfaceGradient = LinearGradient(
            colors: [Colors.slate800, Colors.slate900],
            startPoint: .top,
            endPoint: .bottom
        )

        static let cardGradient = LinearGradient(
            colors: [Colors.slate800.opacity(0.8), Colors.slate900.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography
    enum Typography {
        // Hero Text
        static func hero(_ text: Text) -> some View {
            text
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(Colors.textPrimary)
        }

        // Large Title
        static func largeTitle(_ text: Text) -> some View {
            text
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(Colors.textPrimary)
        }

        // Title
        static func title(_ text: Text) -> some View {
            text
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Colors.textPrimary)
        }

        // Headline
        static func headline(_ text: Text) -> some View {
            text
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Colors.textPrimary)
        }

        // Subheadline
        static func subheadline(_ text: Text) -> some View {
            text
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Colors.textSecondary)
        }

        // Body
        static func body(_ text: Text) -> some View {
            text
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Colors.textPrimary)
        }

        // Caption
        static func caption(_ text: Text) -> some View {
            text
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Colors.textMuted)
        }

        // Mono (for numbers/data)
        static func mono(_ text: Text) -> some View {
            text
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(Colors.textPrimary)
        }

        // Big Number
        static func bigNumber(_ text: Text) -> some View {
            text
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Colors.textPrimary)
        }
    }

    // MARK: - Shadows
    enum Shadows {
        static func card() -> some View {
            Color.black.opacity(0.3)
        }

        static func glow(color: Color) -> some View {
            color.opacity(0.4)
        }
    }

    // MARK: - Corner Radii
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let card: CGFloat = 20
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Hex Extension (for dynamic colors)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle() -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Theme.Gradients.cardGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Theme.Colors.slate700.opacity(0.5), lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    func glassStyle() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Colors.slate600.opacity(0.3), lineWidth: 1)
            }
    }

    func pulseAnimation(isActive: Bool, color: Color) -> some View {
        self.overlay {
            if isActive {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(color, lineWidth: 2)
                    .opacity(0.8)
                    .scaleEffect(1.02)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isActive
                    )
            }
        }
    }
}
