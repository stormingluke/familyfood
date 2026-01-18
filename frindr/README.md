# 🍽️ Frindr - Family Meal Tracker

A beautiful, modern iOS app for families to discover, capture, and track meals together. Built with SwiftUI and featuring stunning Liquid Glass design patterns.

![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## 📱 Overview

Frindr helps families:
- **Discover & Track Meals** - Browse and photograph family meals
- **Share Favorites** - Each family member can favorite their preferred meals
- **Meal History** - Track when meals were eaten and who enjoyed them
- **Prep Time Tracking** - Know how long each meal takes to prepare
- **Family Portal** - Manage family members and their meal preferences

## ✨ Key Features

### 🎨 Modern Design
- **Liquid Glass UI** - Beautiful glassmorphic design throughout the app
- **Smooth Animations** - Spring-based physics for natural interactions
- **Dark Gradient Backgrounds** - Elegant purple/blue gradients
- **Interactive Cards** - Touch-responsive glass effect components

### 📸 Meal Capture
- **Camera Integration** - Capture meals instantly
- **Meal Metadata** - Name, cuisine type, and prep time
- **Family Selection** - Tag which family members ate the meal
- **Photo Storage** - Images stored with meal data

### 🔍 Discover Tab
- **Meal Cards** - Browse all captured meals
- **Visual Thumbnails** - See meal photos or cuisine-based gradients
- **Quick Info** - Prep time, cuisine type, and last eaten date
- **Favorites Count** - See how many family members liked each meal
- **Full-Screen View** - Tap for detailed meal information

### 👨‍👩‍👧‍👦 Family Portal
- **Family Carousel** - Horizontal scrolling family member cards
- **Member Profiles** - Name, age, role, and preferences
- **Favorite Meals Tracking** - Each member's meal favorites count
- **Activities & Interests** - Track hobbies and preferences
- **Add Members** - Easy family member creation flow

### 🎯 Quick Actions
- 📷 **Take Photo** - Instant camera access
- ❤️ **Favorites** - View family favorites
- 📅 **Meal Plan** - Weekly meal planning
- 🔍 **Search** - Find specific meals
- 📊 **Statistics** - Eating patterns and insights
- 🍽️ **Categories** - Browse by cuisine type

### 🎴 Meal Details (Full-Screen Carousel)
- **Swipe Navigation** - Left/right to browse meals
- **Card Flip Animation** - Tap to reveal meal info
- **Three Key Metrics**:
  - ⏰ **When** - Last time eaten (relative format)
  - ❤️ **Who liked it?** - Family members who ate it
  - ⏱️ **How long?** - Prep time (Short/Medium/Long/Very Long)
- **Bottom Details** - Full meal information with family member tags

## 🏗️ Architecture

### Project Structure
```
frindr/
├── App/
│   └── frindrApp.swift                 # App entry point
├── Models/
│   ├── Meal.swift                      # Meal data model
│   ├── FamilyMember.swift              # Family member model
│   └── CodableColor.swift              # Color persistence helper
├── Views/
│   ├── ContentView.swift               # Main app container
│   ├── Discover/
│   │   ├── DiscoverView.swift          # Meal discovery feed
│   │   ├── MealCardView.swift          # Individual meal card
│   │   └── FullscreenMealView.swift    # Full-screen meal carousel
│   ├── Family/
│   │   ├── FamilyPortalView.swift      # Family management
│   │   ├── FamilyMemberCardView.swift  # Family member card
│   │   └── AddFamilyMemberSheet.swift  # Add member form
│   ├── Camera/
│   │   ├── CameraCaptureView.swift     # Meal capture interface
│   │   └── ImagePicker.swift           # Native camera integration
│   └── Shared/
│       ├── QuickActionsModal.swift     # Quick actions menu
│       └── FlowLayout.swift            # Custom flow layout
└── README.md
```

### Data Models

#### Meal
```swift
struct Meal: Identifiable, Codable {
    let id: UUID
    var name: String
    var cuisineType: String
    var prepTime: PrepTime
    var imageData: Data?
    var lastEaten: Date?
    var timesEaten: Int
    var eatenBy: [UUID]     // Family member IDs
    var createdDate: Date
    var notes: String?
}
```

#### FamilyMember
```swift
struct FamilyMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var role: String
    var age: Int
    var icon: String
    var gradientColors: [CodableColor]
    var activities: [String]
    var preferences: String
    var favoriteMealIds: [UUID]
}
```

## 🎨 Design System

### Liquid Glass Components
- `GlassEffectContainer` - Groups glass elements with proper spacing
- `.glassEffect()` - Applies glassmorphic effect to views
- `.interactive()` - Makes glass respond to touch
- Custom corner radii (12-32pt) for modern aesthetics

### Color Palette
- **Primary Gradient**: Deep purple to dark blue
- **Accent Colors**: 
  - Blue (Italian cuisine, info)
  - Purple/Pink (Asian cuisine, favorites)
  - Orange (Mexican, featured)
  - Green/Teal (Mediterranean, statistics)
  - Red (Actions, alerts)

### Typography
- **SF Pro Rounded** - Friendly, modern feel
- **Hierarchy**: 36pt headings, 16-28pt body, 12pt captions
- **Bold weights** for emphasis
- **Proper line spacing** for readability

### Animations
- **Spring physics**: Natural, bouncy feel
- **Response**: 0.3-0.6s timing
- **Damping**: 0.7-0.8 for smooth deceleration
- **Scale effects**: 1.0x → 1.1x for selected items

## 🚀 Getting Started

### Requirements
- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+
- Camera permissions for meal capture

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/frindr.git
   cd frindr
   ```

2. **Open in Xcode**
   ```bash
   open frindr.xcodeproj
   ```

3. **Configure Info.plist**
   Add camera permission:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Frindr needs camera access to capture meal photos</string>
   ```

4. **Build and Run**
   - Select target device/simulator
   - Press `Cmd + R`

### Sample Data
The app includes sample data on first launch:
- 3 family members (Emma, Jack, Sarah)
- 4 meals (Spaghetti, Stir Fry, Pizza, Salad)

## 📝 Usage

### Adding a Meal
1. Tap **Activity** tab (bell icon)
2. Select **Take Photo** from Quick Actions
3. Capture meal photo
4. Enter meal name and cuisine type
5. Select prep time (Short/Medium/Long/Very Long)
6. Choose family members who ate it
7. Tap **Save Meal**

### Viewing Meal Details
1. Navigate to **Discover** tab
2. Tap any meal card
3. Swipe left/right to navigate meals
4. Tap image to flip and see metrics
5. Scroll bottom section for full details

### Managing Family
1. Navigate to **Family** tab
2. Scroll carousel to browse members
3. Tap member to view details
4. Tap **+** button to add new member
5. View favorite meals count per member

## 🔮 Future Enhancements

### Planned Features
- [ ] **SQLite Persistence** - Local database for meal history
- [ ] **Meal Statistics** - Charts and insights
- [ ] **Search & Filter** - Find meals by name, cuisine, or date
- [ ] **Meal Planning** - Weekly meal calendar
- [ ] **Shopping Lists** - Generate from planned meals
- [ ] **Recipe Integration** - Add cooking instructions
- [ ] **Cloud Sync** - iCloud synchronization
- [ ] **Widgets** - Home Screen meal widgets
- [ ] **Export** - Share meals via PDF or images
- [ ] **Dietary Restrictions** - Tag allergens and preferences

### Technical Improvements
- [ ] Core Data integration
- [ ] Unit tests with Swift Testing
- [ ] UI tests
- [ ] Performance optimizations
- [ ] Accessibility improvements
- [ ] Localization (i18n)
- [ ] Dark mode refinements

## 🛠️ Tech Stack

### Core Technologies
- **SwiftUI** - Modern declarative UI framework
- **Swift Concurrency** - Async/await for smooth operations
- **Combine** - Reactive programming (future)
- **UIKit Integration** - Camera picker

### Design Patterns
- **MVVM** - Model-View-ViewModel architecture
- **Composition** - Reusable view components
- **State Management** - @State, @Binding, @Environment
- **Namespace** - For matched geometry effects

### Apple Frameworks
- **Foundation** - Core functionality
- **UIKit** - Camera integration
- **Photos** - Image handling
- **SwiftUI** - User interface

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused
- Write descriptive commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Luke Caradine**
- Created: January 17, 2026

## 🙏 Acknowledgments

- **Apple** - For SwiftUI and Liquid Glass design patterns
- **SF Symbols** - Beautiful icon system
- **Swift Community** - Inspiration and support

## 📧 Contact

For questions, suggestions, or feedback:
- Open an issue on GitHub
- Email: [your-email@example.com]

---

**Made with ❤️ using SwiftUI and Liquid Glass design**

⭐️ Star this repository if you find it helpful!
