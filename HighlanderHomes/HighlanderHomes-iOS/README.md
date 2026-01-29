# Highlander Homes iOS App

A high-retention, "TikTok-style" property management iOS app built with SwiftUI and SwiftData.

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

### Creating the Xcode Project

1. Open Xcode and create a new project
2. Select "App" under iOS
3. Configure:
   - Product Name: `HighlanderHomes`
   - Team: Your development team
   - Organization Identifier: `com.yourcompany`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: SwiftData
   - Uncheck "Include Tests" (add later)

4. After project creation, delete the default `ContentView.swift` and `HighlanderHomesApp.swift`

5. Drag the contents of this `HighlanderHomes-iOS` folder into your Xcode project

6. Make sure "Copy items if needed" is checked

7. Add all files to the main target

### Running the App

1. Select an iOS 17+ simulator or device
2. Build and run (⌘R)
3. Sample data will be auto-populated on first launch

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
