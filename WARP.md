# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Frindr is a SwiftUI iOS app for families to discover, capture, and track meals together. It features iOS 18's Liquid Glass design patterns.

**Requirements:** iOS 18.0+, Xcode 16.0+, Swift 6.0+

## Build & Run

```bash
# Open project in Xcode
open frindr.xcodeproj

# Build from command line
xcodebuild -project frindr.xcodeproj -scheme frindr -sdk iphonesimulator build

# Run tests (when added)
xcodebuild -project frindr.xcodeproj -scheme frindr -sdk iphonesimulator test
```

In Xcode: Select target device/simulator and press `Cmd + R`

## Architecture

### MVVM with SwiftUI State Management
- `@State` for local view state
- `@Binding` for child-to-parent communication
- `@Namespace` for matched geometry effects (card transitions)

### Core Data Models
- **`Meal`** (`ModelsMeal.swift`): Tracks meal name, cuisine type, prep time, image data, and which family members ate it via `eatenBy: [UUID]`
- **`FamilyMember`** (`ModelsFamilyMember.swift`): Stores name, role, age, gradient colors (via `CodableColor`), and favorite meal IDs
- **`CodableColor`** (`ModelsCodableColor.swift`): Wrapper to persist SwiftUI `Color` as Codable RGBA values

### View Organization (all in `frindr/`)
Files use prefix naming convention: `Views*`, `Models*`
- **`ContentView.swift`**: Main app container with tab navigation and state
- **Views/Shared**: `FlowLayout` (custom Layout protocol), `ImagePicker` (UIKit camera bridge)

### Key UI Patterns

**Liquid Glass Effect (iOS 18):**
```swift
.glassEffect(.regular, in: .rect(cornerRadius: 32))
```

**Spring Animations:**
```swift
withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { ... }
```

**Background Gradient:** Deep purple-to-blue (`Color(red: 0.1, green: 0.1, blue: 0.2)` → `Color(red: 0.2, green: 0.1, blue: 0.15)`)

### Tab Structure
- **Discover**: Browse meal cards with full-screen carousel detail view
- **Activity**: Triggers quick actions modal (camera, favorites, etc.)
- **Family**: Horizontal carousel of family member cards

## Code Conventions

- Use SF Symbols for icons
- Typography: SF Pro Rounded, 36pt headings, 16-28pt body
- Corner radii: 12-32pt for modern aesthetics
- Scale effects: 1.0x → 1.1x for selected items

## Camera Integration

Camera access requires Info.plist entry:
```xml
<key>NSCameraUsageDescription</key>
<string>Frindr needs camera access to capture meal photos</string>
```

`ImagePicker` wraps `UIImagePickerController` via `UIViewControllerRepresentable`.

## Sample Data

App loads sample data on first launch in `loadSampleData()`: 3 family members (Emma, Jack, Sarah) and 4 meals. Check this function when testing new features.
