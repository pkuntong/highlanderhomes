import SwiftUI

/// Tinder-style swipe cards for maintenance triage
/// Swipe RIGHT = Assign | Swipe LEFT = Dismiss | Swipe UP = Escalate
struct SwipeActionCard<Content: View>: View {
    let content: Content
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onSwipeUp: () -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var actionState: SwipeAction = .none

    private let swipeThreshold: CGFloat = 120
    private let rotationMultiplier: Double = 0.02

    enum SwipeAction {
        case none
        case assign // Right
        case dismiss // Left
        case escalate // Up

        var color: Color {
            switch self {
            case .none: return .clear
            case .assign: return Theme.Colors.emerald
            case .dismiss: return Theme.Colors.slate500
            case .escalate: return Theme.Colors.alertRed
            }
        }

        var icon: String {
            switch self {
            case .none: return ""
            case .assign: return "person.badge.plus"
            case .dismiss: return "xmark.circle"
            case .escalate: return "exclamationmark.triangle"
            }
        }

        var label: String {
            switch self {
            case .none: return ""
            case .assign: return "ASSIGN"
            case .dismiss: return "DISMISS"
            case .escalate: return "ESCALATE"
            }
        }
    }

    init(
        @ViewBuilder content: () -> Content,
        onSwipeLeft: @escaping () -> Void = {},
        onSwipeRight: @escaping () -> Void = {},
        onSwipeUp: @escaping () -> Void = {}
    ) {
        self.content = content()
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.onSwipeUp = onSwipeUp
    }

    var body: some View {
        ZStack {
            // Action indicator overlay
            if actionState != .none {
                actionOverlay
            }

            // Card content
            content
                .overlay(alignment: .topTrailing) {
                    if actionState != .none {
                        actionBadge
                            .padding()
                    }
                }
        }
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(dragGesture)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: offset)
    }

    private var actionOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .stroke(actionState.color, lineWidth: 4)
            .background(actionState.color.opacity(0.1).clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card)))
    }

    private var actionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: actionState.icon)
                .font(.system(size: 14, weight: .bold))
            Text(actionState.label)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(actionState.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(actionState.color.opacity(0.2))
                .overlay {
                    Capsule()
                        .stroke(actionState.color, lineWidth: 2)
                }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                rotation = Double(value.translation.width) * rotationMultiplier

                // Determine action state based on drag direction
                withAnimation(.easeOut(duration: 0.1)) {
                    if abs(value.translation.width) > abs(value.translation.height) {
                        // Horizontal swipe
                        if value.translation.width > swipeThreshold * 0.5 {
                            actionState = .assign
                            HapticManager.shared.selection()
                        } else if value.translation.width < -swipeThreshold * 0.5 {
                            actionState = .dismiss
                            HapticManager.shared.selection()
                        } else {
                            actionState = .none
                        }
                    } else if value.translation.height < -swipeThreshold * 0.5 {
                        // Vertical swipe up
                        actionState = .escalate
                        HapticManager.shared.selection()
                    } else {
                        actionState = .none
                    }
                }
            }
            .onEnded { value in
                let shouldComplete: Bool

                if abs(value.translation.width) > abs(value.translation.height) {
                    // Horizontal gesture
                    if value.translation.width > swipeThreshold {
                        // Swipe right - Assign
                        HapticManager.shared.impact(.heavy)
                        performAction(.assign)
                        onSwipeRight()
                        shouldComplete = true
                    } else if value.translation.width < -swipeThreshold {
                        // Swipe left - Dismiss
                        HapticManager.shared.impact(.medium)
                        performAction(.dismiss)
                        onSwipeLeft()
                        shouldComplete = true
                    } else {
                        shouldComplete = false
                    }
                } else if value.translation.height < -swipeThreshold {
                    // Swipe up - Escalate
                    HapticManager.shared.urgentPulse()
                    performAction(.escalate)
                    onSwipeUp()
                    shouldComplete = true
                } else {
                    shouldComplete = false
                }

                if !shouldComplete {
                    // Reset position
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        offset = .zero
                        rotation = 0
                        actionState = .none
                    }
                }
            }
    }

    private func performAction(_ action: SwipeAction) {
        // Animate card off screen
        withAnimation(.easeOut(duration: 0.3)) {
            switch action {
            case .assign:
                offset = CGSize(width: 500, height: 0)
            case .dismiss:
                offset = CGSize(width: -500, height: 0)
            case .escalate:
                offset = CGSize(width: 0, height: -500)
            case .none:
                break
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        SwipeActionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kitchen Sink Leak")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("Unit 2B - Water pooling under sink")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        } onSwipeLeft: {
            print("Dismissed")
        } onSwipeRight: {
            print("Assigned")
        } onSwipeUp: {
            print("Escalated")
        }
        .padding()
    }
}
