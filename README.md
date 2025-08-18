# TKDojang

A comprehensive iOS application for learning and practicing Taekwondo, designed to guide users from beginner to advanced levels with structured lessons, technique demonstrations, and multi-profile progress tracking.

## Table of Contents

- [Current Features](#current-features)
- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Design Patterns](#design-patterns)
- [Getting Started](#getting-started)
- [Development Guidelines](#development-guidelines)
- [Known Issues & Lessons Learned](#known-issues--lessons-learned)
- [Development Roadmap](#development-roadmap)

## Current Features

### ✅ **Production-Ready Features**

#### 🔄 **Multi-Profile System**
- Support for up to 6 device-local user profiles
- Profile creation, editing, deletion, and switching
- Belt level tracking per profile (10th Keup to 1st Dan)
- Independent progress tracking for each profile
- No cloud dependency - all data stored locally on device

#### 📚 **Korean Terminology Learning**
- **Comprehensive Flashcard System**: Leitner spaced repetition algorithm
- **88+ Terminology Entries**: Authentic Korean terms with Hangul characters
- **Phonetic Pronunciation**: IPA notation for accurate pronunciation
- **Belt-Level Filtering**: Content automatically filtered by user's current belt level
- **13 Belt Levels**: Complete coverage from 10th Keup through 1st Dan
- **Educational Definitions**: Clear explanations of techniques and terminology

#### 🧪 **Multiple Choice Testing**
- **Randomized Question Generation**: Smart question creation from terminology database
- **Performance Tracking**: Score tracking and performance analytics
- **Belt-Appropriate Content**: Questions filtered by user's current belt level
- **Immediate Feedback**: Instant results with correct answer explanations

#### 🥋 **Pattern Learning**
- **Chon-Ji Pattern Implementation**: Complete step-by-step instruction
- **Move-by-Move Guidance**: Detailed breakdown of each technique
- **Pattern Significance**: Historical and philosophical context
- **24-Move Sequence**: Full Chon-Ji pattern with proper form descriptions

#### 🎨 **Visual Design System**
- **Belt Representation**: Concentric belt borders with authentic color schemes
- **Primary-Secondary-Primary Stripes**: Accurate belt progression visualization
- **SwiftUI Modern Interface**: Clean, intuitive user experience
- **Responsive Design**: Optimized for various iOS device sizes

#### 🏗️ **Technical Architecture**
- **MVVM-C Pattern**: Model-View-ViewModel-Coordinator architecture
- **SwiftData Integration**: Modern Core Data replacement for persistence
- **Coordinator Navigation**: Clean separation of navigation concerns
- **Protocol-Oriented Design**: Dependency injection and testability
- **Feature-Based Organization**: Modular code structure

### 🔧 **Development Infrastructure**
- **Working Xcode Project**: Complete iOS project setup
- **Git Repository Management**: Feature branch workflow with develop/main structure
- **Comprehensive Documentation**: Detailed code comments and architectural decisions
- **CSV Import Tools**: Bulk content creation and management utilities
- **Organized Content Structure**: Clean separation of terminology and pattern data

## Architecture Overview

This app follows a **clean, scalable architecture** designed for long-term maintainability and team collaboration:

### Core Architectural Decisions

1. **MVVM-C (Model-View-ViewModel-Coordinator)**: Separates concerns and makes navigation testable
2. **Feature-based organization**: Groups related functionality together instead of separating by file type
3. **Protocol-oriented programming**: Enables dependency injection and easy testing
4. **Reactive programming with Combine**: Provides responsive UI and data flow
5. **SwiftUI + UIKit hybrid**: Modern SwiftUI for UI with UIKit when needed

### Why These Choices?

- **Scalability**: Structure supports adding new features without creating chaos
- **Testability**: Dependency injection and separation of concerns enable comprehensive testing
- **Team collaboration**: Clear boundaries make it easier for multiple developers to work together
- **Maintainability**: Well-documented, single-responsibility components are easier to modify
- **Performance**: Reactive patterns minimize unnecessary UI updates

## Project Structure

```
TKDojang/
├── TKDojang.xcodeproj/               # Working Xcode project
├── TKDojang/Sources/
│   ├── App/                          # App lifecycle and root views
│   │   ├── TKDojangApp.swift         # Main app entry point
│   │   ├── ContentView.swift         # Root navigation container
│   │   └── LoadingView.swift         # App loading state
│   │
│   ├── Features/                     # Feature modules (business logic)
│   │   ├── Learning/                 # Flashcard system with spaced repetition
│   │   ├── Profile/                  # Multi-profile management system
│   │   ├── Testing/                  # Multiple choice testing system
│   │   └── Patterns/                 # Pattern learning (Chon-Ji)
│   │
│   ├── Core/                         # Shared utilities and services
│   │   ├── Data/                     # Data persistence and content
│   │   │   ├── Content/
│   │   │   │   ├── Terminology/      # 13 belt-level terminology files
│   │   │   │   └── Patterns/         # Pattern definitions
│   │   │   ├── DataManager.swift     # SwiftData model container management
│   │   │   └── Services/             # Data access services
│   │   ├── Coordinators/             # Navigation management
│   │   │   └── AppCoordinator.swift  # Main app navigation
│   │   └── Utils/                    # Shared utilities and theming
│   │       ├── Models.swift          # Core data models
│   │       ├── BeltLevel.swift       # Belt progression system
│   │       └── AppTheme.swift        # Design system
│   │
│   └── Resources/                    # App assets and localizations
│       ├── Assets/                   # Images, icons, colors
│       └── Preview Content/          # SwiftUI preview assets
│
├── Scripts/
│   └── csv-to-terminology.swift     # Enhanced CSV import tool
├── README.md                        # Project overview and architecture
└── CLAUDE.md                        # Development context and guidelines
```

### Key Directory Explanations

#### `/Sources/App/`
Contains the application's entry point and root-level views. These files manage the overall app lifecycle and coordinate between major application flows.

#### `/Sources/Features/`
Each subdirectory represents a major feature area of the app:
- **Learning**: Flashcard system with Leitner spaced repetition algorithm
- **Profile**: Multi-profile management supporting up to 6 device-local profiles  
- **Testing**: Multiple choice testing system with performance tracking
- **Patterns**: Pattern learning system (currently implements Chon-Ji)

This organization:
- **Reduces merge conflicts** - developers can work on different features independently
- **Improves code discoverability** - all related files are grouped together
- **Enables feature flags** - entire features can be easily enabled/disabled
- **Supports modularization** - features can potentially become separate modules

#### `/Sources/Core/`
Shared code that multiple features depend on:
- **Data**: SwiftData models, content management, and data services
- **Content**: 13 belt-level terminology files and pattern definitions
- **Coordinators**: Navigation coordinators that manage app flow between features
- **Utils**: Shared utilities, theming, belt progression system, and core models

#### `/Scripts/`
Development and content management tools:
- **csv-to-terminology.swift**: Enhanced tool for bulk content creation from CSV files

## Design Patterns

### 1. Coordinator Pattern

**Purpose**: Separates navigation logic from view controllers

```swift
// Example: AppCoordinator manages app-wide navigation
class AppCoordinator: ObservableObject {
    @Published var currentFlow: AppFlow = .loading
    
    func showMainFlow() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = .main
        }
    }
}
```

**Benefits**:
- Navigation logic is testable
- Views remain focused on display logic
- Easy to modify navigation flows
- Supports deep linking and programmatic navigation

### 2. Repository Pattern

**Purpose**: Abstracts data access and provides a consistent interface

```swift
// Example: TerminologyDataService protocol
protocol TerminologyDataServiceProtocol {
    func loadTerminology(for beltLevel: BeltLevel) async throws -> [TerminologyEntry]
    func getAllTerminology() async throws -> [TerminologyEntry]
    func getTerminologyCategories() async throws -> [TerminologyCategory]
}
```

**Benefits**:
- Enables easy testing with mock implementations
- Separates business logic from data access details
- Supports multiple data sources (JSON files, SwiftData, cache)
- Makes it easy to change data storage mechanisms

### 3. Reactive Programming with Combine

**Purpose**: Creates responsive UI that automatically updates when data changes

```swift
// Example: Reactive profile state management
profileService.currentProfile
    .receive(on: DispatchQueue.main)
    .sink { [weak self] profile in
        self?.updateUIForProfile(profile)
    }
    .store(in: &cancellables)
```

**Benefits**:
- Eliminates manual state synchronization
- Reduces bugs from outdated UI state
- Enables complex data flow with simple composition
- Provides built-in error handling and threading

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0 deployment target (required for SwiftData)
- Swift 5.9 or later
- macOS for development

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone [repository-url]
   cd TKDojang
   ```

2. **Open in Xcode**:
   ```bash
   open TKDojang.xcodeproj
   ```

3. **Build and run**:
   - Select your target device or simulator
   - Press `Cmd+R` to build and run

### Configuration

The app is designed to work out-of-the-box with no external dependencies:

- **Local Storage**: All data stored locally using SwiftData (no cloud setup required)
- **Content Loading**: Terminology and pattern data loaded from bundled JSON files
- **Profile Management**: Up to 6 device-local profiles with independent progress tracking
- **No Network Required**: App functions completely offline

## Development Guidelines

### Code Style

1. **Documentation**: Every public interface must include comprehensive documentation
   - Explain **WHY** decisions were made, not just what the code does
   - Include usage examples for complex APIs
   - Document architectural patterns and their benefits

2. **Naming Conventions**:
   - Use descriptive, self-documenting names
   - Prefer clarity over brevity
   - Follow Swift API Design Guidelines

3. **File Organization**:
   - Group related functionality together
   - Use feature-based organization
   - Keep files focused on single responsibilities

### Testing Strategy

1. **Unit Tests**: Test business logic, utilities, and data transformations
2. **Integration Tests**: Test service interactions and data flow
3. **UI Tests**: Test critical user workflows and accessibility
4. **Performance Tests**: Monitor app launch time and memory usage

### Adding New Features

1. **Create feature directory** under `/Sources/Features/`
2. **Implement coordinator** for feature navigation
3. **Add models** to appropriate Core directory
4. **Write comprehensive tests** for new functionality
5. **Update documentation** including this README

## Known Issues & Lessons Learned

### ⚠️ **Critical SwiftData Performance Lessons**

During development, we encountered significant performance issues when implementing progress tracking. These lessons are crucial for future development:

#### **1. SwiftData Relationship Navigation on Main Thread**
- **Issue**: Accessing `userProfile.terminologyProgress` directly causes app hangs
- **Cause**: SwiftData relationship loading blocks the main thread
- **Solution**: Use background queues for all relationship fetching

#### **2. Complex Nested Predicates**
- **Issue**: Predicates like `progress.userProfile.id == profileId AND progress.terminologyEntry.beltLevel.id == beltId` cause compilation failures
- **Cause**: SwiftData predicate compiler limitations with complex relationships
- **Solution**: Use separate queries and combine results programmatically

#### **3. Service Initialization During DataManager Setup**
- **Issue**: ProfileService initialization during DataManager creation causes deadlock
- **Cause**: Circular dependency during container setup
- **Solution**: Lazy initialization or dependency injection after container setup

#### **4. Direct SwiftData Model Access in Views**
- **Issue**: Views directly accessing SwiftData relationships block the main thread
- **Cause**: SwiftUI view updates happening synchronously with database queries
- **Solution**: Use ViewModels with async data fetching and @MainActor updates

### **Working State Reference**
Commit `77485cd` represents the last stable state with full multi-profile system functionality before progress tracking issues were introduced.

## Development Roadmap

### 🧪 **Phase 1: Testing Infrastructure (Next Priority)**
- [ ] Automated testing framework for all current features
- [ ] Database loading verification tests
- [ ] Multi-profile system integration tests
- [ ] UI workflow testing for critical paths
- [ ] Performance benchmarking

### 📊 **Phase 2: Progress Tracking System (Rebuild)**
Following lessons learned above:
- [ ] Background-queue-based ProgressTrackingService
- [ ] Async ViewModels for progress data
- [ ] Simple predicate design patterns
- [ ] Study session tracking
- [ ] Terminology mastery levels
- [ ] Performance analytics dashboard

### 📝 **Phase 3: Content Expansion**
- [ ] Complete remaining terminology files (5th Keup to 1st Keup)
- [ ] Additional pattern implementations beyond Chon-Ji
- [ ] Advanced testing modes (time challenges, streak modes)
- [ ] Video demonstrations integration

### 🔧 **Phase 4: Production Polish**
- [ ] Performance optimization and app startup time
- [ ] Comprehensive error handling and recovery
- [ ] Accessibility features (VoiceOver, Dynamic Type)
- [ ] App Store preparation and submission

## Contributing

1. Follow the established architecture patterns
2. Write comprehensive tests for new features
3. Update documentation for any architectural changes
4. Ensure all code includes detailed documentation
5. Test on multiple device sizes and orientations

## Architecture Benefits

This architecture provides several key advantages:

### For Developers
- **Clear separation of concerns** makes code easier to understand and modify
- **Dependency injection** enables comprehensive testing and flexible implementations
- **Feature-based organization** reduces merge conflicts and improves collaboration
- **Comprehensive documentation** accelerates onboarding and knowledge transfer

### For Users
- **Responsive UI** through reactive programming patterns
- **Consistent experience** through centralized navigation and state management
- **Reliable functionality** through comprehensive testing strategy
- **Smooth performance** through efficient data flow and caching

### For Business
- **Faster feature development** through reusable components and clear patterns
- **Easier maintenance** through well-documented, single-responsibility components
- **Better quality** through testable architecture and comprehensive test coverage
- **Future flexibility** through modular design and protocol-oriented interfaces

This architecture serves as a solid foundation for building a world-class Taekwondo learning application that can grow and evolve with user needs while maintaining high code quality and developer productivity.