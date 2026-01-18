# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run

This is an iOS SwiftUI app using Xcode. No Swift Package Manager or external dependencies.

```bash
# Open project in Xcode
open frindr.xcodeproj

# Build from command line
xcodebuild -project frindr.xcodeproj -scheme frindr -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests (once tests are added)
xcodebuild -project frindr.xcodeproj -scheme frindr -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+
- Camera permissions required for meal capture

## Project Structure

```
frindr/
├── frindrApp.swift              # App entry point
├── ContentView.swift            # Root container with tab navigation
├── Models/
│   ├── Meal.swift               # Meal data model with PrepTime enum
│   ├── FamilyMember.swift       # Family member profile model
│   └── CodableColor.swift       # Color persistence wrapper
└── Views/
    ├── Discover/
    │   └── FullscreenMealView.swift   # Full-screen meal carousel
    ├── Family/
    │   └── AddFamilyMemberSheet.swift # Add family member form
    ├── Camera/
    │   ├── CameraCaptureView.swift    # Meal capture interface
    │   └── ImagePicker.swift          # UIKit camera wrapper
    └── Shared/
        └── FlowLayout.swift           # Custom tag-style layout
```

## Architecture

**Frindr** is a family meal tracking app built with SwiftUI using MVVM-style patterns.

### Data Flow
- State is managed at the `ContentView` level using `@State` properties for `meals` and `familyMembers`
- Child views receive data via bindings (`@Binding`) or direct passing
- No persistence layer yet - data is initialized with sample data on app launch via `loadSampleData()`

### Key Models
- `Meal` - Tracks meal name, cuisine type, prep time, photo data, when eaten, and which family members ate it (via UUIDs)
- `FamilyMember` - Profile with name, role, age, activities, preferences, and favorite meal IDs
- `CodableColor` - Wrapper to make SwiftUI `Color` codable for persistence

### View Structure
- `ContentView` - Root container managing tab navigation (Discover/Activity/Family) and modal presentations
- Activity tab triggers the quick actions modal overlay rather than showing its own content
- `FullscreenMealView` - Full-screen meal carousel with card flip animations

### Design System
The app uses iOS "Liquid Glass" glassmorphic design:
- `GlassEffectContainer` groups elements with `.glassEffect()` modifier
- Dark gradient backgrounds (purple/blue)
- Spring-based animations (response: 0.3-0.6s, damping: 0.7-0.8)
- `FlowLayout` - Custom SwiftUI Layout for tag-style wrapping content

### UIKit Integration
- `ImagePicker` wraps `UIImagePickerController` via `UIViewControllerRepresentable` for camera access

## Backend API

The app syncs with a Rust REST API for multi-device support across family members.

### Technology Stack
- Rust Edition 2024 with Axum web framework
- libsql with Turso (embedded replica with periodic cloud sync)
- Cloudflare R2 for image storage
- Sentry for error tracking
- Deployed on fly.io

### Authentication
Bearer token authentication via `Authorization` header. The token is embedded in the iOS app and validated by the API.

### API Endpoints

**Meals:**
- `GET /api/v1/meals` - List meals (?cuisine=, ?limit=, ?offset=)
- `GET /api/v1/meals/:id` - Get meal
- `POST /api/v1/meals` - Create meal
- `PUT /api/v1/meals/:id` - Update meal
- `DELETE /api/v1/meals/:id` - Delete meal
- `POST /api/v1/meals/:id/eaten` - Record meal eaten

**Family Members:**
- `GET /api/v1/family-members` - List members
- `GET /api/v1/family-members/:id` - Get member
- `POST /api/v1/family-members` - Create member
- `PUT /api/v1/family-members/:id` - Update member
- `DELETE /api/v1/family-members/:id` - Delete member
- `POST /api/v1/family-members/:id/favorites/:meal_id` - Add favorite
- `DELETE /api/v1/family-members/:id/favorites/:meal_id` - Remove favorite

**Images:**
- `POST /api/v1/images/upload` - Upload image (multipart)
- `GET /api/v1/images/presigned/:key` - Get presigned upload URL
- `DELETE /api/v1/images/:key` - Delete image

### JSON Format
All API requests/responses use camelCase JSON matching Swift conventions:
```json
{
  "id": "uuid",
  "name": "Spaghetti Carbonara",
  "cuisineType": "Italian",
  "prepTime": "medium",
  "imageUrl": "https://r2.example.com/meals/uuid.jpg",
  "lastEaten": "2024-01-15T12:00:00Z",
  "timesEaten": 5,
  "eatenBy": ["uuid1", "uuid2"],
  "createdDate": "2024-01-01T10:00:00Z",
  "notes": "Family favorite"
}
```

## Data Storage Strategy

### Local-Only Data
These remain on-device and are never synced:
- **UI State** - Tab selection, modal presentation state, scroll positions
- **Temporary camera captures** - Raw `imageData: Data` before upload
- **Draft/unsaved changes** - Edits in progress before user confirms

### Remote-Only Data (API is source of truth)
These are stored exclusively on the server:
- **Meal images** - Stored in Cloudflare R2, referenced by `imageUrl`
- **Historical sync metadata** - Server tracks `updated_at` timestamps

### Synced Data (Local cache + Remote persistence)
These exist both locally and remotely:

| Data | Local Purpose | Remote Purpose |
|------|---------------|----------------|
| `Meal` | Fast UI rendering, offline viewing | Cross-device sync, family sharing |
| `FamilyMember` | Profile display, meal associations | Shared family roster |
| `favoriteMealIds` | Quick favorites access | Persisted preferences |
| `eatenBy` | Show who ate what | Family meal history |

### Sync Architecture

**On App Launch:**
1. Load cached data from local storage (UserDefaults or Core Data)
2. Display cached data immediately for fast startup
3. Fetch fresh data: `GET /api/v1/meals` and `GET /api/v1/family-members`
4. Merge remote data into local cache, remote wins on conflicts

**On Data Creation:**
```swift
// 1. Create locally with temporary state
let meal = Meal(id: UUID(), name: "New Meal", ...)

// 2. Upload image first if present
if let imageData = meal.imageData {
    let response = await POST /api/v1/images/upload (multipart: imageData)
    meal.imageUrl = response.url
    meal.imageData = nil  // Clear local binary after upload
}

// 3. Create on server
let serverMeal = await POST /api/v1/meals (body: meal)

// 4. Update local with server response (gets server timestamps)
updateLocalCache(serverMeal)
```

**On Data Update:**
```swift
// 1. Optimistic local update for responsive UI
updateLocalCache(updatedMeal)

// 2. Sync to server
await PUT /api/v1/meals/:id (body: updatedMeal)

// 3. Handle failure by reverting local state
```

**On Recording Meal Eaten:**
```swift
// Use dedicated endpoint - handles incrementing count and updating lastEaten
await POST /api/v1/meals/:id/eaten (body: { familyMemberIds: [uuid1, uuid2] })
```

### Model Field Mapping

**Meal - iOS to API:**
| iOS Field | API Field | Storage Notes |
|-----------|-----------|---------------|
| `id: UUID` | `id` | Generated locally, synced |
| `name: String` | `name` | Synced |
| `cuisineType: String` | `cuisineType` | Synced |
| `prepTime: PrepTime` | `prepTime` | Enum as string: "short", "medium", "long", "veryLong" |
| `imageData: Data?` | - | Local only, upload before sync |
| - | `imageUrl` | Remote URL after upload |
| `lastEaten: Date?` | `lastEaten` | ISO 8601 string |
| `timesEaten: Int` | `timesEaten` | Synced |
| `eatenBy: [UUID]` | `eatenBy` | Array of family member IDs |
| `createdDate: Date` | `createdDate` | ISO 8601 string |
| `notes: String?` | `notes` | Synced |

**FamilyMember - iOS to API:**
| iOS Field | API Field | Storage Notes |
|-----------|-----------|---------------|
| `id: UUID` | `id` | Generated locally, synced |
| `name: String` | `name` | Synced |
| `role: String` | `role` | Synced |
| `age: Int` | `age` | Synced |
| `icon: String` | `icon` | SF Symbol name |
| `gradientColors: [CodableColor]` | `gradientColors` | JSON array of {red, green, blue, opacity} |
| `activities: [String]` | `activities` | JSON array |
| `preferences: String` | `preferences` | Synced |
| `favoriteMealIds: [UUID]` | `favoriteMealIds` | Managed via favorites endpoints |

### API Usage Examples

**Fetching all meals with pagination:**
```swift
let url = URL(string: "\(baseURL)/api/v1/meals?limit=20&offset=0")!
var request = URLRequest(url: url)
request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
let (data, _) = try await URLSession.shared.data(for: request)
let meals = try JSONDecoder().decode([Meal].self, from: data)
```

**Creating a meal with image:**
```swift
// Step 1: Upload image
let imageURL = URL(string: "\(baseURL)/api/v1/images/upload")!
var imageRequest = URLRequest(url: imageURL)
imageRequest.httpMethod = "POST"
imageRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
// Set multipart form data with image...
let (imageData, _) = try await URLSession.shared.upload(for: imageRequest, from: formData)
let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: imageData)

// Step 2: Create meal with image URL
let mealURL = URL(string: "\(baseURL)/api/v1/meals")!
var mealRequest = URLRequest(url: mealURL)
mealRequest.httpMethod = "POST"
mealRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
mealRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
let createMeal = CreateMealRequest(
    name: "Pizza",
    cuisineType: "Italian",
    prepTime: "long",
    imageUrl: uploadResponse.url,
    notes: nil
)
mealRequest.httpBody = try JSONEncoder().encode(createMeal)
```

**Adding a meal to favorites:**
```swift
let url = URL(string: "\(baseURL)/api/v1/family-members/\(memberId)/favorites/\(mealId)")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
let (data, _) = try await URLSession.shared.data(for: request)
```

### Offline Handling
- Cache all fetched data locally for offline viewing
- Queue mutations when offline, sync when connectivity returns
- Show sync status indicator in UI
- Generate UUIDs locally to allow offline creation
