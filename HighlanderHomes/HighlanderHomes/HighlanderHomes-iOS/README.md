# Highlander Homes iOS App

A high-retention, "TikTok-style" property management iOS app built with SwiftUI and SwiftData.

**Syncs with your existing web app** - Same Firebase backend, real-time data sync.

## What Makes This App Special (Competitor Killers)

| Feature | Why It's Addictive |
|---------|-------------------|
| **Swipe-to-Action Cards** | Tinder for maintenance - swipe right to assign, left to dismiss, up to escalate |
| **AI Daily Briefing** | "Good morning! 3 items need attention" with smart recommendations |
| **Shake to Report** | Shake your phone → instant maintenance request creation |
| **Voice Notes** | Describe issues by voice - no typing needed |
| **Celebration Animations** | Confetti when rent is received, checkmarks for completed tasks |
| **TikTok-Style Feed** | Vertical swipe through activity cards with pulse animations |
| **Haptic Everything** | Every action provides satisfying tactile feedback |
| **One-Tap Contacts** | Call/text tenants & contractors instantly |

## Design Philosophy

- **UI Inspiration**: Stessa (clean finance) meets Rocket Money (simplicity) meets TikTok (fluidity/engagement)
- **Design Language**: Large Typography, SF Symbols, high-contrast cards, smooth SwiftUI transitions
- **The "Drug" Factor**: Visual/haptic rewards for every action (closing tickets, receiving rent, confirming contractors)

## Architecture

```
HighlanderHomes-iOS/
├── App/
│   ├── HighlanderHomesApp.swift    # App entry point & SwiftData container
│   └── ContentView.swift            # Main TabView with custom tab bar
├── Core/
│   ├── Theme/
│   │   └── Theme.swift              # Color palette, typography, gradients
│   ├── Haptics/
│   │   └── HapticManager.swift      # Haptic feedback patterns
│   └── Extensions/                   # SwiftUI extensions
├── Models/                           # SwiftData models
│   ├── Property.swift
│   ├── Tenant.swift
│   ├── MaintenanceRequest.swift
│   ├── Contractor.swift
│   ├── Expense.swift
│   ├── RentPayment.swift
│   └── FeedEvent.swift
├── ViewModels/                       # MVVM view models (to be added)
├── Views/
│   ├── Feed/
│   │   └── MaintenanceFeedView.swift     # TikTok-style activity feed
│   ├── Triage/
│   │   └── TriageHubView.swift           # 3-way maintenance triage
│   ├── Dashboard/
│   │   └── CommandCenterView.swift       # Portfolio health dashboard
│   ├── Vault/
│   │   └── PropertyVaultView.swift       # Properties & tenants vault
│   ├── QuickEntry/
│   │   └── QuickEntryView.swift          # Spreadsheet-killer data entry
│   └── Components/                        # Reusable UI components
└── Services/
    ├── API/
    │   └── APIService.swift              # REST API client (placeholders)
    └── LocalStorage/
        └── SyncService.swift             # Offline-first sync
```

## Color Palette

### Modern Slate & Emerald Green

```swift
// Primary Emerald
emerald: #10B981
emeraldLight: #34D399
emeraldDark: #059669

// Slate System
slate50 - slate950 (Full grayscale range)

// Semantic Colors
alertRed: #EF4444
warningAmber: #F59E0B
infoBlue: #3B82F6
gold: #FFD700
```

## Key Features

### 1. The Feed (TikTok-Style)
- Vertical swipe navigation between activity cards
- Color-coded event types (maintenance = red, payments = gold, etc.)
- Pulse animations for urgent items
- Haptic feedback on interactions

### 2. Maintenance Triage (3-Way Communication)
- Visual workflow steps: Request → Assign → Schedule → Notify
- One-tap contractor assignment
- Real-time status updates
- Quick contact buttons (call, text, email)

### 3. Command Center Dashboard
- Animated portfolio health ring (0-100 score)
- Key metrics: Revenue, Occupancy, Pending Maintenance
- Property status grid with health indicators
- Time-range selectable charts

### 4. Property Vault
- Quick-access tenant cards with one-tap contact
- Property cards with health scores
- Contractor directory with ratings
- Search across all entities

### 5. Quick Entry (Spreadsheet Killer)
- Fast multi-row data entry
- Tab navigation between fields
- Category quick-picker
- Running total calculation
- Keyboard navigation toolbar

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- macOS Sonoma or later
- Apple Developer Account (for Apple Sign-In)

### Step 1: Create the Xcode Project

1. Open Xcode → File → New → Project
2. Select "App" under iOS
3. Configure:
   - Product Name: `HighlanderHomes`
   - Team: Your development team
   - Organization Identifier: `com.highlanderhomes`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: SwiftData
4. Delete the default `ContentView.swift` and `HighlanderHomesApp.swift`

### Step 2: Add Firebase SDK

1. File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: 11.0.0 or later
4. Add these packages to your target:
   - FirebaseAuth
   - FirebaseCore
   - FirebaseFirestore

### Step 3: Add GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `highlanderhomes-4b1f3`
3. Add iOS app with bundle ID: `com.highlanderhomes.app`
4. Download `GoogleService-Info.plist`
5. Drag it into your Xcode project root

### Step 4: Configure Apple Sign-In

1. In Xcode: Signing & Capabilities → + Capability → "Sign in with Apple"
2. In [Apple Developer Portal](https://developer.apple.com):
   - Certificates, Identifiers & Profiles → Identifiers
   - Select your App ID → Enable "Sign In with Apple"
3. In Firebase Console:
   - Authentication → Sign-in method → Apple → Enable
   - Add your Services ID

### Step 5: Import Project Files

1. Drag the contents of `HighlanderHomes-iOS` folder into Xcode
2. Check "Copy items if needed"
3. Add all files to the main target
4. Ensure folder references are correct

### Step 6: Run

1. Select an iOS 17+ simulator or device
2. Build and run (⌘R)
3. Sign in with your email or Apple ID
4. Data syncs automatically from your web app!

## Backend Integration

The `APIService.swift` is prepared with placeholder endpoints. To connect to your web API:

1. Update `baseURL` in `APIService.swift`:
```swift
self.baseURL = URL(string: "https://your-api.com/v1")!
```

2. Implement authentication:
```swift
await APIService.shared.setAuthToken("your-jwt-token")
```

3. The sync service handles offline-first data:
```swift
SyncService.shared.configure(with: modelContext)
await SyncService.shared.performSync()
```

## Haptic Patterns

The app uses custom haptic patterns for different actions:

- **Selection**: Light tap for navigation
- **Success**: Triple-tap reward pattern
- **Cash Register**: Payment confirmation
- **Urgent Pulse**: Emergency alerts

## Future Enhancements

- [ ] Push notifications for maintenance updates
- [ ] Biometric authentication
- [ ] Widget for quick property overview
- [ ] Apple Watch companion app
- [ ] Siri shortcuts for common actions
- [ ] Receipt scanning with Vision framework
- [ ] Charts framework integration for analytics

## Tech Stack

- **Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM
- **Local Storage**: SwiftData
- **Networking**: async/await URLSession
- **Charts**: Swift Charts (native)
- **Haptics**: UIKit haptic generators

---

Built with the goal of being **faster than a spreadsheet** and **as engaging as TikTok**.
