# Claude Code Configuration

This file provides context and instructions for Claude Code when working on this project.

## Project Overview

This is **TKDojang**, a Taekwondo learning iOS app built with SwiftUI using the MVVM-C (Model-View-ViewModel-Coordinator) architecture pattern. The app is designed to help users learn Taekwondo from beginner to advanced levels with structured lessons, technique demonstrations, and progress tracking.

## Architecture & Patterns

- **MVVM-C Architecture**: Model-View-ViewModel-Coordinator pattern for clean separation of concerns
- **Feature-based Organization**: Code is organized by features rather than file types
- **Protocol-Oriented Programming**: Heavy use of protocols for dependency injection and testability
- **Reactive Programming**: Uses Combine framework for reactive data flow
- **SwiftUI**: Modern declarative UI framework

## Key Conventions

### Code Style
- **Comprehensive Documentation**: Every public interface must include detailed documentation explaining WHY decisions were made
- **Descriptive Naming**: Use clear, self-documenting variable and function names
- **Single Responsibility**: Each file/class should have one clear purpose
- **No Magic Numbers**: Use constants from `AppConstants.swift`

### File Organization
- Features are organized in `/Sources/Features/[FeatureName]/`
- Shared code goes in `/Sources/Core/`
- Each feature should have its own coordinator for navigation
- Models and utilities are centralized in `/Sources/Core/Utils/`

### Testing
- Unit tests for business logic and utilities
- UI tests for critical user workflows
- Test files mirror the source structure
- Use dependency injection to enable mocking

## Development Guidelines

### When Adding New Features
1. Create a new directory under `/Sources/Features/`
2. Implement a coordinator for navigation management
3. Follow the established pattern of separating views, view models, and models
4. Add comprehensive unit tests
5. Update documentation

### When Modifying Architecture
1. Explain the reasoning behind architectural changes
2. Update this CLAUDE.md file with new patterns
3. Ensure changes are consistent across the entire codebase
4. Consider impact on testing and maintainability

### Documentation Standards
- Include `PURPOSE:` sections explaining why code exists
- Document architectural decisions and their benefits
- Provide usage examples for complex APIs
- Explain trade-offs and alternative approaches considered

## Current State (Updated: August 17, 2025 - Evening)

### ✅ **WORKING FEATURES - Production Ready:**
- **Xcode Project**: Complete working iOS project (TKDojang.xcodeproj)
- **Architecture**: Full MVVM-C implementation with coordinator pattern
- **UI Screens**: Authentication (sign-in/register), Onboarding, Loading, Main Tab structure
- **Flashcard System**: Working Korean terminology learning with Leitner spaced repetition
- **Multiple Choice Testing**: Complete testing system with question generation, smart distractors, and detailed results
- **Pattern System**: Complete Taekwondo forms system with 9 traditional patterns (Chon-Ji through Chung-Mu)
- **Pattern Practice Interface**: Interactive step-by-step practice with move-by-move guidance
- **Practice Menu**: 2x2 grid interface with 4 main practice sections (Patterns/Tul, Step Sparring, Line Work, Technique How-To)
- **Belt Design System**: Concentric belt borders with Primary-Secondary-Primary tag stripes
- **Progress Tracking**: User statistics, mastery levels, study streaks, test performance analytics, pattern progress
- **Content Management**: Complete terminology system with 88+ entries across multiple belt levels
- **Navigation**: Coordinator-based navigation with smooth animations and proper NavigationStack implementation
- **GitHub Repository**: Private repo at https://github.com/craigmharris/TKDojang
- **Documentation**: Comprehensive README.md and CLAUDE.md files
- **CSV Import Tool**: Enhanced Scripts/csv-to-terminology.swift for bulk content creation
- **Database Management**: Robust reset and reload system with pattern seeding

### 🔧 **Known Issues:**
- Authentication service (2-second simulation, no real auth backend)
- User data persistence (uses @AppStorage for basic preferences only)
- Pattern image/video URLs are placeholder (need real content)
- Need automated testing framework
- Need multi-device sync capabilities

### 📁 **Complete Project Structure:**
```
TKDojang/
├── TKDojang.xcodeproj/           # Working Xcode project
├── TKDojang/Sources/
│   ├── App/                      # App lifecycle and root views
│   │   ├── TKDojangApp.swift     # Main entry point (@main)
│   │   ├── ContentView.swift     # Root navigation container
│   │   └── LoadingView.swift     # Loading screen
│   ├── Core/
│   │   ├── Data/
│   │   │   ├── Content/
│   │   │   │   └── Terminology/  # 13 belt-level terminology files (JSON)
│   │   │   ├── Models/           # SwiftData models
│   │   │   │   ├── TerminologyModels.swift
│   │   │   │   ├── PatternModels.swift      # NEW: Complete pattern system
│   │   │   │   ├── TestingModels.swift
│   │   │   │   └── UserModels.swift
│   │   │   └── Services/         # Data service layer
│   │   │       ├── TerminologyDataService.swift
│   │   │       ├── PatternDataService.swift  # NEW: Pattern management
│   │   │       └── TestingService.swift
│   │   ├── Coordinators/         # Navigation management
│   │   │   └── AppCoordinator.swift
│   │   └── Utils/                # Shared utilities and theming
│   │       └── BeltTheme.swift
│   └── Features/
│       ├── Authentication/       # Sign-in/register UI
│       ├── Dashboard/            # Main tab navigation
│       │   └── MainTabCoordinatorView.swift
│       ├── Learning/             # Flashcard system
│       │   └── FlashcardView.swift
│       ├── Patterns/             # NEW: Pattern practice system
│       │   └── PatternPracticeView.swift
│       ├── Profile/              # User settings and preferences
│       │   └── UserSettingsView.swift
│       └── Testing/              # Multiple choice testing
│           ├── TestSelectionView.swift
│           ├── TestTakingView.swift
│           └── TestResultsView.swift
├── Scripts/
│   └── csv-to-terminology.swift # Enhanced CSV import tool
├── README.md                    # Project overview and architecture
└── CLAUDE.md                    # Development context (this file)
```

## Content Management & Data Updates

### Adding/Modifying Flashcard Terminology

#### 1. Using CSV Import Tool (Recommended)
```bash
# Create CSV with columns: korean, english, category, belt_level, pronunciation
swift Scripts/csv-to-terminology.swift input.csv TKDojang/Sources/Core/Data/Content/Terminology/

# CSV Format Example:
korean,english,category,belt_level,pronunciation
안녕하세요,Hello,basics,10th_keup,an-nyeong-ha-se-yo
```

#### 2. Manual JSON Editing
Edit files in `TKDojang/Sources/Core/Data/Content/Terminology/`:
```json
{
  "belt_level": "9th_keup",
  "entries": [
    {
      "korean": "천지",
      "english": "Heaven and Earth",
      "category": "patterns",
      "pronunciation": "chon-ji",
      "difficulty_level": 1
    }
  ]
}
```

### Adding/Modifying Pattern Data

#### 1. Pattern Metadata
Edit pattern creation in `PatternDataService.swift`:
```swift
private func createCustomPattern(beltLevels: [BeltLevel]) {
    let moves = createCustomPatternMoves() // Create move sequence
    
    let pattern = createPattern(
        name: "Pattern-Name",
        hangul: "한글",
        englishMeaning: "English Meaning",
        significance: "Historical significance and meaning...",
        moveCount: 24,
        diagramDescription: "Pattern shape description",
        startingStance: "Parallel ready stance",
        videoURL: "https://your-video-host.com/pattern-name.mp4",
        diagramImageURL: "https://your-image-host.com/pattern-diagram.jpg",
        beltLevels: [targetBelt],
        moves: moves
    )
}
```

#### 2. Pattern Move Sequences
```swift
private func createCustomPatternMoves() -> [PatternMove] {
    let movesData: [(Int, String, String, String, String?, String, String?, String?)] = [
        (1, "Left walking stance", "Low block", "West", "Lower section", 
         "Keep shoulders square", "Block too high", 
         "https://your-host.com/moves/pattern-1.jpg"),
        // ... additional moves
    ]
    
    return movesData.map { (moveNumber, stance, technique, direction, target, keyPoints, commonMistakes, imageURL) in
        PatternMove(
            moveNumber: moveNumber,
            stance: stance,
            technique: technique,
            direction: direction,
            target: target,
            keyPoints: keyPoints,
            commonMistakes: commonMistakes,
            executionNotes: nil,
            imageURL: imageURL
        )
    }
}
```

### Updating Media URLs (Images & Videos)

#### 1. Pattern Diagram Images
Update in pattern creation functions:
```swift
diagramImageURL: "https://your-cdn.com/diagrams/pattern-name-diagram.jpg"
```

#### 2. Individual Move Images
Update in move creation:
```swift
imageURL: "https://your-cdn.com/moves/pattern-name-move-1.jpg"
```

#### 3. Pattern Demonstration Videos
Update in pattern creation:
```swift
videoURL: "https://your-video-platform.com/patterns/pattern-name-full.mp4"
```

#### 4. Recommended Media Hosting
- **Images**: Use a CDN service (AWS CloudFront, Cloudinary, or GitHub releases)
- **Videos**: Use video hosting (Vimeo, YouTube, or dedicated video CDN)
- **File Structure**: `/patterns/{pattern-name}/diagram.jpg`, `/patterns/{pattern-name}/moves/move-{number}.jpg`

### Database Management

#### Force Database Reset (Development)
1. Delete app from simulator/device
2. Clean build folder (Cmd+Shift+K)
3. Rebuild and run - database will recreate with latest data

#### Reset Database Programmatically
```swift
// Add to DataManager for development/testing
dataManager.resetAndReloadDatabase()
```

## Testing Commands

```bash
# Build the project
# Use Xcode: Cmd+B or Product → Build

# Run unit tests
# Use Xcode: Cmd+U or Product → Test

# Run on simulator
# Use Xcode: Cmd+R or Product → Run

# Build for device
# Select device target and use Cmd+R

# Clean build
# Use Xcode: Cmd+Shift+K or Product → Clean Build Folder
```

## Session Summary (August 17, 2025 - Evening Session)

### 🎯 **MAJOR ACCOMPLISHMENTS - Pattern System Complete:**

#### ✅ **Complete Pattern Practice System Implementation:**
1. **9 Traditional Patterns**: Chon-Ji through Chung-Mu with full Korean names and historical significance
2. **Interactive Practice Interface**: Step-by-step move guidance with progress tracking
3. **Move-by-Move Breakdown**: Each move includes stance, technique, direction, key points, and common mistakes
4. **Belt Level Integration**: Patterns appear based on user's current belt level progression
5. **Practice Controls**: Start/pause, previous/next move, restart functionality
6. **Progress Persistence**: User pattern progress tracked with spaced repetition

#### 🔧 **Critical Bug Fixes:**
7. **Belt Level Filtering**: Fixed logic so 10th Keup sees no patterns, 9th Keup sees Chon-Ji only
8. **Pattern Move Data**: All patterns now have complete move sequences (not just Chon-Ji)
9. **Database Reset Issues**: Fixed pattern seeding after database reset/reload
10. **Practice Again Button**: Now functional for all patterns with proper state management

#### 🏗️ **Technical Infrastructure:**
11. **PatternDataService**: Complete service layer for pattern CRUD operations and progress tracking
12. **PatternModels**: SwiftData models with proper relationship management and computed properties
13. **Database Migration**: Robust pattern seeding and reset functionality
14. **Navigation Integration**: Seamless pattern practice flow from main interface

#### 📊 **Data Architecture:**
15. **Move Sequences**: Detailed breakdown of each pattern with 19-38 moves per pattern
16. **Progress Tracking**: Individual pattern mastery levels with spaced repetition
17. **Media Support**: Image and video URL structure ready for content integration
18. **Belt Progression**: Proper filtering and access control based on user advancement

### ✅ **Fully Working Pattern System:**
- **Belt Progression**: 10th Keup → no patterns, 9th Keup → Chon-Ji, 8th Keup → Chon-Ji + Dan-Gun, etc.
- **Practice Interface**: Complete move-by-move guidance with visual progress
- **Data Persistence**: Pattern progress saved and tracked across sessions
- **Content Management**: Easy pattern and move data updates via service layer
- **Media Ready**: Structure in place for pattern diagrams and move demonstration images/videos

### 🚀 **Next Development Priorities (Ranked by Impact):**

#### **Priority 1: Content & Media Integration** ⭐⭐⭐⭐⭐
1. **Real Pattern Media**: Replace placeholder URLs with actual pattern diagrams and move images
2. **Video Integration**: Add pattern demonstration videos with proper player controls
3. **Content Validation**: Test all patterns with real media content across different belt levels
4. **Image Optimization**: Ensure images load efficiently on various devices and network conditions

#### **Priority 2: Multi-Device Sync & Data Persistence** ⭐⭐⭐⭐
1. **CloudKit Integration**: Sync user progress across iPhone, iPad, and future platforms
2. **Offline Capability**: Ensure app works without internet after initial content download
3. **Backup & Restore**: User data export/import for device migrations
4. **Cross-Platform**: Prepare architecture for potential macOS/watchOS expansion

#### **Priority 3: Automated Testing Framework** ⭐⭐⭐
1. **Unit Tests**: Test pattern loading, belt progression logic, progress tracking
2. **UI Tests**: Validate critical user workflows (flashcards, testing, pattern practice)
3. **Integration Tests**: Database operations, content loading, navigation flows
4. **Performance Tests**: Large dataset handling, memory usage, battery optimization

#### **Priority 4: Advanced Learning Features** ⭐⭐
1. **Smart Recommendations**: AI-driven suggestions for practice focus areas
2. **Advanced Analytics**: Detailed progress insights and learning pattern analysis
3. **Social Features**: Share progress, belt achievements, pattern mastery
4. **Gamification**: Achievement badges, streak rewards, progression milestones

## Notes for Claude Code

- This project emphasizes **education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation** is critical - users are learning iOS development
- **Best practices** should be highlighted and explained throughout the codebase
- When suggesting changes, explain the benefits and trade-offs
- Consider the long-term maintainability and scalability of all code changes
- **Pattern system is now complete** - focus should shift to content integration and multi-device capabilities