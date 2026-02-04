import SwiftUI
import Combine
import AVFoundation

/// Shake your phone to instantly create a maintenance request
/// This is the "magic" feature that makes users go "wow"
struct ShakeDetectorModifier: ViewModifier {
    let onShake: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                onShake()
            }
    }
}

// Custom notification for shake
extension NSNotification.Name {
    static let deviceDidShake = NSNotification.Name("deviceDidShakeNotification")
}

// UIWindow extension to detect shake
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(ShakeDetectorModifier(onShake: action))
    }
}

// MARK: - Quick Report Sheet
struct QuickReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var title = ""
    @State private var description = ""
    @State private var selectedProperty: Property?
    @State private var selectedPriority: MaintenanceRequest.Priority = .normal
    @State private var selectedCategory: MaintenanceRequest.MaintenanceCategory = .other
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var audioURL: URL?
    @State private var showCamera = false
    @State private var capturedImages: [UIImage] = []

    @FocusState private var titleFocused: Bool

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header with shake icon
                        VStack(spacing: Theme.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.warningAmber.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .font(.system(size: 36))
                                    .foregroundColor(Theme.Colors.warningAmber)
                            }

                            Text("Quick Report")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text("Describe the issue - we'll handle the rest")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.top)

                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("What's the issue?", systemImage: "exclamationmark.bubble")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)

                            TextField("e.g., Leaky faucet in kitchen", text: $title)
                                .font(.system(size: 17))
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                        .fill(Theme.Colors.slate800)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                                .stroke(titleFocused ? Theme.Colors.emerald : Theme.Colors.slate700, lineWidth: 1)
                                        }
                                }
                                .focused($titleFocused)
                        }
                        .padding(.horizontal)

                        // Voice Note
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Or describe by voice", systemImage: "waveform")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)

                            VoiceRecordButton(
                                isRecording: $isRecording,
                                recordingTime: $recordingTime,
                                onRecordingComplete: { url in
                                    audioURL = url
                                }
                            )
                        }
                        .padding(.horizontal)

                        // Photo capture
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Add photos", systemImage: "camera")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Add photo button
                                    Button {
                                        showCamera = true
                                        HapticManager.shared.impact(.medium)
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 24))
                                            Text("Take Photo")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(Theme.Colors.emerald)
                                        .frame(width: 100, height: 100)
                                        .background {
                                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                                .fill(Theme.Colors.emerald.opacity(0.1))
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                                        .stroke(Theme.Colors.emerald.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                                }
                                        }
                                    }

                                    // Captured images
                                    ForEach(capturedImages.indices, id: \.self) { index in
                                        Image(uiImage: capturedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                                            .overlay(alignment: .topTrailing) {
                                                Button {
                                                    capturedImages.remove(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.white)
                                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Quick category selection
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Category", systemImage: "tag")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach([
                                        MaintenanceRequest.MaintenanceCategory.plumbing,
                                        .electrical,
                                        .hvac,
                                        .appliance,
                                        .other
                                    ], id: \.self) { category in
                                        CategoryChip(
                                            category: category,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                            HapticManager.shared.selection()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Priority selection
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Priority", systemImage: "flag")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)

                            HStack(spacing: 10) {
                                ForEach([
                                    MaintenanceRequest.Priority.low,
                                    .normal,
                                    .high,
                                    .urgent
                                ], id: \.self) { priority in
                                    PriorityChip(
                                        priority: priority,
                                        isSelected: selectedPriority == priority
                                    ) {
                                        selectedPriority = priority
                                        HapticManager.shared.selection()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 100)
                }

                // Submit button (floating)
                VStack {
                    Spacer()

                    Button {
                        submitReport()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Submit Report")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Gradients.emeraldGlow)
                        }
                        .shadow(color: Theme.Colors.emerald.opacity(0.4), radius: 12, y: 4)
                    }
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.6 : 1)
                    .padding()
                    .background {
                        LinearGradient(
                            colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
            }
        }
        .onAppear {
            titleFocused = true
        }
    }

    private func submitReport() {
        HapticManager.shared.success()

        let request = ConvexMaintenanceRequestInput(
            propertyId: selectedProperty?.convexId ?? "",
            tenantId: nil,
            title: title,
            descriptionText: description,
            category: selectedCategory.rawValue.lowercased(),
            priority: selectedPriority.rawValue.lowercased()
        )

        Task {
            do {
                _ = try await dataService.createMaintenanceRequest(request)
            } catch {
                print("Error creating maintenance request: \(error)")
            }
        }

        dismiss()
    }
}

// MARK: - Voice Record Button
struct VoiceRecordButton: View {
    @Binding var isRecording: Bool
    @Binding var recordingTime: TimeInterval
    let onRecordingComplete: (URL?) -> Void

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button {
            toggleRecording()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Theme.Colors.alertRed : Theme.Colors.emerald)
                        .frame(width: 44, height: 44)
                        .scaleEffect(scale)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isRecording ? "Recording..." : "Tap to record")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)

                    if isRecording {
                        Text(formatTime(recordingTime))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Theme.Colors.alertRed)
                    } else {
                        Text("Describe the issue in your own words")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                if isRecording {
                    // Recording waveform
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.Colors.alertRed)
                                .frame(width: 4, height: CGFloat.random(in: 8...24))
                        }
                    }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(isRecording ? Theme.Colors.alertRed.opacity(0.1) : Theme.Colors.slate800)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .stroke(isRecording ? Theme.Colors.alertRed : Theme.Colors.slate700, lineWidth: 1)
                    }
            }
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    scale = 1.2
                }
            } else {
                withAnimation(.spring()) {
                    scale = 1.0
                }
            }
        }
    }

    private func toggleRecording() {
        isRecording.toggle()
        HapticManager.shared.impact(isRecording ? .heavy : .medium)

        if !isRecording {
            // Recording stopped - would normally save audio file here
            onRecordingComplete(nil)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: MaintenanceRequest.MaintenanceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(isSelected ? Theme.Colors.emerald : Theme.Colors.slate800)
            }
        }
    }
}

// MARK: - Priority Chip
struct PriorityChip: View {
    let priority: MaintenanceRequest.Priority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(priority.label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(isSelected ? priorityColor : Theme.Colors.slate800)
                }
        }
    }

    private var priorityColor: Color {
        switch priority {
        case .low: return Theme.Colors.slate500
        case .normal: return Theme.Colors.infoBlue
        case .high: return Theme.Colors.warningAmber
        case .urgent, .emergency: return Theme.Colors.alertRed
        }
    }
}

#Preview {
    QuickReportSheet()
        .environmentObject(ConvexDataService.shared)
}
