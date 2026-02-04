import SwiftUI
import Combine

/// Celebration animations for rent collection milestones and achievements
/// This creates the "dopamine hit" that keeps users engaged
struct CelebrationView: View {
    @Binding var isShowing: Bool
    let type: CelebrationType
    let amount: Double?
    let message: String

    @State private var confettiCounter = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var coinOffsets: [CGSize] = []

    enum CelebrationType {
        case rentReceived
        case maintenanceCompleted
        case fullOccupancy
        case milestone
        case streak

        var icon: String {
            switch self {
            case .rentReceived: return "dollarsign.circle.fill"
            case .maintenanceCompleted: return "checkmark.seal.fill"
            case .fullOccupancy: return "house.fill"
            case .milestone: return "star.fill"
            case .streak: return "flame.fill"
            }
        }

        var color: Color {
            switch self {
            case .rentReceived: return Theme.Colors.gold
            case .maintenanceCompleted: return Theme.Colors.emerald
            case .fullOccupancy: return Theme.Colors.infoBlue
            case .milestone: return Theme.Colors.gold
            case .streak: return Color.orange
            }
        }

        var title: String {
            switch self {
            case .rentReceived: return "Rent Received!"
            case .maintenanceCompleted: return "Issue Resolved!"
            case .fullOccupancy: return "Full Occupancy!"
            case .milestone: return "Milestone Reached!"
            case .streak: return "On a Streak!"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .opacity(opacity)
                .onTapGesture {
                    dismiss()
                }

            // Confetti effect for rent received
            if type == .rentReceived {
                ConfettiView(counter: $confettiCounter)
            }

            // Floating coins for rent
            if type == .rentReceived {
                ForEach(0..<8, id: \.self) { index in
                    CoinView()
                        .offset(coinOffsets.indices.contains(index) ? coinOffsets[index] : .zero)
                }
            }

            // Main celebration card
            VStack(spacing: Theme.Spacing.lg) {
                // Icon with pulse
                ZStack {
                    // Pulse rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(type.color.opacity(0.3 - Double(i) * 0.1), lineWidth: 3)
                            .frame(width: CGFloat(100 + i * 30), height: CGFloat(100 + i * 30))
                            .scaleEffect(scale)
                    }

                    // Icon
                    ZStack {
                        Circle()
                            .fill(type.color)
                            .frame(width: 80, height: 80)
                            .shadow(color: type.color.opacity(0.6), radius: 20, y: 4)

                        Image(systemName: type.icon)
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(scale)

                // Title
                Text(type.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                // Amount (if applicable)
                if let amount = amount {
                    Text("$\(Int(amount).formatted())")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [type.color, type.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Message
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background {
                            Capsule()
                                .fill(type.color)
                        }
                        .shadow(color: type.color.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.top, Theme.Spacing.md)
            }
            .padding(Theme.Spacing.xl)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.extraLarge)
                    .fill(Theme.Colors.slate900)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.extraLarge)
                            .stroke(type.color.opacity(0.3), lineWidth: 2)
                    }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            show()
        }
    }

    private func show() {
        // Haptic
        if type == .rentReceived {
            HapticManager.shared.cashRegister()
        } else {
            HapticManager.shared.reward()
        }

        // Initialize coin positions
        coinOffsets = (0..<8).map { _ in
            CGSize(
                width: CGFloat.random(in: -150...150),
                height: CGFloat.random(in: -200...200)
            )
        }

        // Animate in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }

        // Trigger confetti
        if type == .rentReceived {
            confettiCounter += 1
        }
    }

    private func dismiss() {
        HapticManager.shared.impact(.light)

        withAnimation(.easeIn(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = false
        }
    }
}

// MARK: - Coin View
struct CoinView: View {
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "dollarsign.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(Theme.Colors.gold)
            .shadow(color: Theme.Colors.gold.opacity(0.5), radius: 4)
            .offset(y: offset)
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .onAppear {
                withAnimation(.easeIn(duration: 2).repeatForever(autoreverses: false)) {
                    offset = 200
                }
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @Binding var counter: Int

    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                ConfettiPiece()
            }
        }
        .id(counter)
    }
}

struct ConfettiPiece: View {
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var horizontalOffset: CGFloat = CGFloat.random(in: -200...200)

    private let colors: [Color] = [
        Theme.Colors.gold,
        Theme.Colors.emerald,
        Theme.Colors.infoBlue,
        Theme.Colors.alertRed,
        Color.purple,
        Color.orange
    ]

    var body: some View {
        Rectangle()
            .fill(colors.randomElement()!)
            .frame(width: CGFloat.random(in: 8...15), height: CGFloat.random(in: 8...15))
            .offset(x: horizontalOffset, y: offset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                    offset = 600
                }
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Celebration Manager
@MainActor
class CelebrationManager: ObservableObject {
    static let shared = CelebrationManager()

    @Published var showCelebration = false
    @Published var celebrationType: CelebrationView.CelebrationType = .rentReceived
    @Published var celebrationAmount: Double?
    @Published var celebrationMessage = ""

    private init() {}

    func celebrate(
        type: CelebrationView.CelebrationType,
        amount: Double? = nil,
        message: String
    ) {
        celebrationType = type
        celebrationAmount = amount
        celebrationMessage = message
        showCelebration = true
    }

    func rentReceived(amount: Double, tenantName: String) {
        celebrate(
            type: .rentReceived,
            amount: amount,
            message: "Payment from \(tenantName) deposited"
        )
    }

    func maintenanceCompleted(title: String) {
        celebrate(
            type: .maintenanceCompleted,
            message: "\(title) has been resolved"
        )
    }

    func fullOccupancy() {
        celebrate(
            type: .fullOccupancy,
            message: "All your properties are occupied!"
        )
    }

    func milestone(message: String) {
        celebrate(
            type: .milestone,
            message: message
        )
    }
}

// MARK: - View Modifier for Easy Use
struct CelebrationModifier: ViewModifier {
    @ObservedObject var manager = CelebrationManager.shared

    func body(content: Content) -> some View {
        content
            .overlay {
                if manager.showCelebration {
                    CelebrationView(
                        isShowing: $manager.showCelebration,
                        type: manager.celebrationType,
                        amount: manager.celebrationAmount,
                        message: manager.celebrationMessage
                    )
                }
            }
    }
}

extension View {
    func withCelebrations() -> some View {
        modifier(CelebrationModifier())
    }
}

#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        CelebrationView(
            isShowing: .constant(true),
            type: .rentReceived,
            amount: 2400,
            message: "Payment from Sarah Johnson deposited"
        )
    }
}
