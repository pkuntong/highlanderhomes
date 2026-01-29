import SwiftUI
import UIKit

// MARK: - Haptic Manager
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Selection Feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Notification Feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    // MARK: - Custom Patterns
    func success() {
        notification(.success)
    }

    func error() {
        notification(.error)
    }

    func warning() {
        notification(.warning)
    }

    // Reward pattern for completed actions
    func reward() {
        Task {
            impact(.light)
            try? await Task.sleep(nanoseconds: 100_000_000)
            impact(.medium)
            try? await Task.sleep(nanoseconds: 100_000_000)
            notification(.success)
        }
    }

    // Urgent pulse for alerts
    func urgentPulse() {
        Task {
            for _ in 0..<3 {
                impact(.heavy)
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
        }
    }

    // Cash register sound for rent received
    func cashRegister() {
        Task {
            impact(.rigid)
            try? await Task.sleep(nanoseconds: 50_000_000)
            impact(.soft)
            try? await Task.sleep(nanoseconds: 100_000_000)
            notification(.success)
        }
    }
}

// MARK: - Haptic View Modifier
struct HapticButtonStyle: ButtonStyle {
    let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.shared.impact(feedbackStyle)
                }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> HapticButtonStyle {
        HapticButtonStyle(feedbackStyle: style)
    }
}
