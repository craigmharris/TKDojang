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

## Current State (Updated: August 18, 2025)

### ✅ **WORKING FEATURES - Production Ready:**
- **Xcode Project**: Complete working iOS project (TKDojang.xcodeproj)
- **Architecture**: Full MVVM-C implementation with coordinator pattern
- **Multi-Profile System**: Support for up to 6 device-local user profiles with creation, editing, deletion, and switching
- **UI Screens**: Onboarding, Loading, Main Tab structure with profile management
- **Flashcard System**: Working Korean terminology learning with Leitner spaced repetition, properly filtered by user belt level
- **Multiple Choice Testing**: Complete testing system with randomized questions and performance tracking
- **Pattern Learning**: Chon-Ji pattern implementation with step-by-step instruction
- **Belt Design System**: Concentric belt borders with Primary-Secondary-Primary tag stripes
- **Content Management**: Complete terminology system with 88+ entries across multiple belt levels
- **Navigation**: Coordinator-based navigation with smooth animations
- **GitHub Repository**: Private repo at https://github.com/craigmharris/TKDojang
- **Documentation**: Comprehensive README.md and CLAUDE.md files
- **CSV Import Tool**: Enhanced Scripts/csv-to-terminology.swift for bulk content creation
- **Organized Data Structure**: Clean folder organization with Terminology/ and Patterns/ separation

### 🔧 **Known Issues:**
- Authentication system removed (multi-profile replaces single-user auth)
- User data persistence uses SwiftData with device-local storage only
- Need automated testing framework

### ⚠️ **CRITICAL LESSONS LEARNED - Progress Tracking Pitfalls:**

**DO NOT IMPLEMENT** the following patterns when rebuilding progress tracking:

1. **SwiftData Relationship Navigation on Main Thread**:
   - Accessing `userProfile.terminologyProgress` directly causes app hangs
   - Accessing `userProfile.studySessions` synchronously freezes the UI
   - **Solution**: Use background queues for relationship fetching

2. **Complex Nested Predicates**:
   - Predicates like `progress.userProfile.id == profileId AND progress.terminologyEntry.beltLevel.id == beltId` cause compilation failures
   - **Solution**: Use separate queries and combine results programmatically

3. **Service Initialization During DataManager Init**:
   - ProfileService initialization during DataManager creation causes deadlock
   - **Solution**: Lazy initialization or dependency injection after container setup

4. **Direct SwiftData Model Access in Views**:
   - Views directly accessing SwiftData relationships block the main thread
   - **Solution**: Use ViewModels with async data fetching

**Working State Before Issues**: Commit 77485cd represents the last stable state with multi-profile system functioning correctly before progress tracking was added.

### 📁 **Project Structure:**
```
TKDojang/
├── TKDojang.xcodeproj/           # Working Xcode project
├── TKDojang/Sources/
│   ├── App/                      # App lifecycle and root views
│   ├── Core/
│   │   ├── Data/
│   │   │   ├── Content/
│   │   │   │   ├── Terminology/  # 13 belt-level terminology files
│   │   │   │   └── Patterns/     # Pattern definitions (separated)
│   │   │   ├── DataManager.swift # SwiftData model container management
│   │   │   └── Services/         # Data access services
│   │   ├── Coordinators/         # Navigation management
│   │   └── Utils/                # Shared utilities and theming
│   └── Features/
│       ├── Learning/             # Flashcard system
│       ├── Profile/              # Multi-profile management
│       ├── Testing/              # Multiple choice testing system
│       └── Patterns/             # Pattern learning (Chon-Ji)
├── Scripts/
│   └── csv-to-terminology.swift # Enhanced CSV import tool
├── README.md                    # Project overview and architecture
└── CLAUDE.md                    # Development context (this file)
```

## Next Development Session Priority Tasks:

### 🧪 **Phase 1: Automated Testing Framework**
1. **Database loading tests** - verify all terminology loads correctly across belt levels
2. **Multi-profile system tests** - ensure profile creation, switching, and data isolation works
3. **Flashcard functionality tests** - ensure spaced repetition system works correctly
4. **Multiple choice testing tests** - verify question generation and scoring
5. **UI tests** for critical user workflows
6. **Performance tests** for large terminology datasets

### 📊 **Phase 2: Progress Tracking System (REBUILD)**
**CRITICAL**: Follow the lessons learned above to avoid previous pitfalls

1. **Architecture Design**:
   - Use background queues for all SwiftData relationship access
   - Implement async ViewModels instead of direct model access in views
   - Design simple predicates that don't cross multiple relationship boundaries
   - Use dependency injection for service initialization

2. **Implementation Strategy**:
   - Create ProgressTrackingService with async methods only
   - Implement progress caching to reduce database queries
   - Use @MainActor for UI updates, background queues for data fetching
   - Test incrementally with single-relationship queries first

3. **Features to Rebuild**:
   - User study session tracking
   - Terminology mastery levels
   - Study streaks and statistics
   - Performance analytics dashboard
   - Progress visualization charts

### 📝 **Phase 3: Content Completion**
1. **Add remaining terminology files** for 5th_keup to 1st_keup (all theory coverage)
2. **Additional pattern implementations** beyond Chon-Ji
3. **Advanced testing modes** (time challenges, streak modes)

### 🔧 **Phase 4: Production Readiness**
1. **Performance optimization** - reduce app startup time
2. **Error handling** - comprehensive error states and recovery
3. **Accessibility** - VoiceOver support and dynamic type
4. **App Store preparation** - screenshots, descriptions, metadata

## Development Context Notes:
- **Current State**: Complete terminology system with organized structure ready for testing
- **Architecture Decision**: MVVM-C pattern working well, continue with this approach
- **Code Quality**: All code includes comprehensive documentation explaining WHY decisions were made
- **Testing Priority**: Need automated testing framework for reliability
- **Next Phase**: Content completion, testing, assessment system, and pattern training

## Testing Commands

The project now has a working Xcode configuration:

```bash
# Build the project
# Use Xcode: Cmd+B or Product → Build

# Run unit tests
# Use Xcode: Cmd+U or Product → Test

# Run on simulator
# Use Xcode: Cmd+R or Product → Run

# Build for device
# Select device target and use Cmd+R
```

## Environment Configuration

The app supports multiple environments through build configurations:
- `DEBUG`: Development environment with debug features enabled
- `STAGING`: Staging environment for testing
- `RELEASE`: Production environment

Environment-specific constants are managed in `AppConstants.swift` using compiler directives.

## Session Summary (August 18, 2025)

### 🎯 **Major Accomplishments This Session:**

#### 🔄 **Repository Management & Feature Integration:**
1. **Branch Analysis**: Systematically reviewed all git branches (main, develop, feature/flashcard-ui-refinements, feature/multiple-choice-testing, feature/patterns-tul)
2. **Strategic Merging**: Successfully merged flashcard UI refinements and multiple choice testing into develop branch
3. **Issue Identification**: Discovered critical app hangs in profile-dependent features (flashcards, tests, patterns, progress)
4. **Root Cause Analysis**: Identified SwiftData performance issues and service initialization deadlocks
5. **Strategic Revert**: Reverted to commit 77485cd - last stable state with working multi-profile system
6. **Repository Cleanup**: Pushed clean, working state to develop branch

#### 🐛 **Bug Fixes & Code Quality:**
7. **String Interpolation Errors**: Fixed 14+ instances of `\\(error)` vs `\(error)` across multiple files
8. **Debug Logging Cleanup**: Removed 20+ performance-impacting debug print statements
9. **Build Stability**: Ensured all merged features compile and run without crashes

#### 📚 **Documentation & Knowledge Capture:**
10. **Comprehensive Analysis**: Documented specific technical issues that caused app hangs
11. **Lessons Learned**: Captured critical pitfalls to avoid when rebuilding progress tracking
12. **Current State Documentation**: Updated project status to reflect working features vs. removed problematic code

### ✅ **Verified Working (Current Stable State):**
- Multi-profile system with up to 6 device-local profiles
- Profile creation, editing, deletion, and switching functionality
- Flashcard system properly filtering by user belt level
- Multiple choice testing system with performance tracking
- Chon-Ji pattern learning with step-by-step instruction
- All terminology loading correctly across belt levels
- Coordinator-based navigation working smoothly
- App launches and runs without hangs or crashes

### 🚫 **Removed Features (Due to Performance Issues):**
- Progress analytics dashboard
- Study session tracking
- Terminology mastery statistics
- User progress visualization charts
- Complex SwiftData relationship queries

### 🎓 **Critical Technical Lessons:**
- **SwiftData Performance**: Direct relationship access (`userProfile.terminologyProgress`) on main thread causes hangs
- **Service Architecture**: Initialization during DataManager setup creates deadlocks
- **Predicate Complexity**: Nested relationship predicates cause compilation failures
- **Threading Strategy**: Background queues essential for database relationship navigation

### 📋 **Next Session Priorities:**
1. Implement comprehensive automated testing framework
2. Rebuild progress tracking using lessons learned (background queues, simple predicates)
3. Add remaining belt-level terminology content
4. Prepare for production release

## Notes for Claude Code

- This project emphasizes **education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation** is critical - users are learning iOS development
- **Best practices** should be highlighted and explained throughout the codebase
- When suggesting changes, explain the benefits and trade-offs
- Consider the long-term maintainability and scalability of all code changes