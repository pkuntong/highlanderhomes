# Highlander Homes iOS App

Property management app built with SwiftUI + SwiftData and backed by Convex.

## Overview

- Same account model as web (email/password + verification flow)
- Convex-backed data services
- SwiftData local models for responsive UI
- Dashboard, Properties, Maintenance, Finance, Contractors, Profile

## Prerequisites

- Xcode 15+
- iOS 17+
- Apple Developer account (for App Store/TestFlight workflows)

## Setup

1. Open `HighlanderHomes.xcodeproj`.
2. Select the `HighlanderHomes` target.
3. Confirm bundle identifier and signing team.
4. Build and run on simulator/device.

## Backend

- The iOS app uses Convex endpoints configured in:
  - `Services/Convex/ConvexConfig.swift`
  - `Services/Convex/ConvexClient.swift`
- Keep deployment URLs and environment variables aligned with your target deployment.

## Notes

- Legacy remote-sync stubs are no-op placeholders to keep older data-manager code paths safe.
- Current production flow uses Convex APIs.
