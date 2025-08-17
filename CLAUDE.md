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

## Current State (Updated: August 17, 2025)

### ✅ **WORKING FEATURES - Production Ready:**
- **Xcode Project**: Complete working iOS project (TKDojang.xcodeproj)
- **Architecture**: Full MVVM-C implementation with coordinator pattern
- **UI Screens**: Authentication (sign-in/register), Onboarding, Loading, Main Tab structure
- **Flashcard System**: Working Korean terminology learning with Leitner spaced repetition
- **Multiple Choice Testing**: Complete testing system with question generation, smart distractors, and detailed results
- **Practice Menu**: 2x2 grid interface with 4 main practice sections (Patterns/Tul, Step Sparring, Line Work, Technique How-To)
- **Belt Design System**: Concentric belt borders with Primary-Secondary-Primary tag stripes
- **Progress Tracking**: User statistics, mastery levels, study streaks, test performance analytics
- **Content Management**: Complete terminology system with 88+ entries across multiple belt levels
- **Navigation**: Coordinator-based navigation with smooth animations and proper NavigationStack implementation
- **GitHub Repository**: Private repo at https://github.com/craigmharris/TKDojang
- **Documentation**: Comprehensive README.md and CLAUDE.md files
- **CSV Import Tool**: Enhanced Scripts/csv-to-terminology.swift for bulk content creation
- **Organized Data Structure**: Clean folder organization with Terminology/ and Patterns/ separation

### 🔧 **Known Issues:**
- Authentication service (2-second simulation, no real auth backend)
- User data persistence (uses @AppStorage for basic preferences only)
- Need automated testing framework

### 📁 **Project Structure:**
```
TKDojang/
├── TKDojang.xcodeproj/           # Working Xcode project
├── TKDojang/Sources/
│   ├── App/                      # App lifecycle and root views
│   ├── Core/
│   │   ├── Data/Content/
│   │   │   ├── Terminology/      # 13 belt-level terminology files
│   │   │   └── Patterns/         # Pattern definitions (separated)
│   │   ├── Coordinators/         # Navigation management
│   │   └── Utils/                # Shared utilities and theming
│   └── Features/
│       ├── Authentication/       # Sign-in/register UI
│       ├── Learning/             # Flashcard system
│       └── Profile/             # User settings and preferences
├── Scripts/
│   └── csv-to-terminology.swift # Enhanced CSV import tool
├── README.md                    # Project overview and architecture
└── CLAUDE.md                    # Development context (this file)
```

## Next Development Session (Tomorrow's Tasks):

### 📝 **Phase 1: Content Completion & Validation**
1. **Add remaining terminology files** for 5th_keup to 1st_keup (all theory coverage)
2. **Cursory testing** to ensure database loading works correctly across all belt levels
3. **Validate flashcard system** with complete terminology set

### 🧪 **Phase 2: Automated Testing Framework**
1. **Database loading tests** - verify all terminology loads correctly
2. **Flashcard functionality tests** - ensure spaced repetition system works
3. **UI tests** for critical user workflows
4. **Performance tests** for large terminology datasets

### 📊 **Phase 3: Assessment & Metrics System**
1. **Multiple choice testing system** to verify user knowledge
2. **Performance tracking** - user progress across belts and categories  
3. **Visible metrics** - confidence building through performance visualization
4. **Progress analytics** - streaks, mastery levels, improvement trends

### 🥋 **Phase 4: Pattern Training Foundation**
1. **First pattern implementation**: Chon-Ji pattern
2. **New data model** for patterns containing:
   - Pattern meaning and significance
   - Number of moves in sequence
   - Step-by-step move details (position, technique, stance)
   - Move descriptions for guided training
3. **Pattern UI foundation** for step-by-step instruction

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

## Session Summary (August 17, 2025)

### 🎯 **Major Accomplishments This Session:**

#### ✅ **Complete Multiple Choice Testing System:**
1. **Fixed All String Interpolation Issues**: Resolved escaped characters showing variable names instead of values
2. **Enhanced Test Results**: Proper score display, performance breakdown, and targeted study recommendations
3. **Targeted Flashcard Review**: "Review with Flashcards" now shows only incorrect terms from tests
4. **Fixed Learning Mode Logic**: Progression mode now correctly shows only current belt level terms
5. **Improved Navigation**: Full NavigationStack implementation with proper test flow
6. **UI Refinements**: Center-aligned question text, consistent styling, proper button behavior

#### 🎨 **Complete Practice Menu System:**
7. **2x2 Grid Layout**: Four main sections with color-coded cards and intuitive navigation
8. **Practice Sections**: Patterns/Tul (Blue), Step Sparring (Orange), Line Work (Green), Technique How-To (Purple)
9. **Placeholder Views**: Clean, consistent placeholder screens for each practice section
10. **Reusable Components**: PracticeMenuCard component for scalable menu system

#### 🔧 **Technical Infrastructure:**
11. **String Interpolation Fixes**: Corrected \\( to \( across TestTakingView, TestingService, TestResultsView
12. **SwiftData Compatibility**: Fixed array storage issues with string-based computed properties
13. **Navigation Architecture**: Migrated entire app from NavigationView to NavigationStack
14. **Git Workflow**: Created feature branch 'feature/patterns-tul' for next development phase

### ✅ **Verified Working:**
- Complete multiple choice testing with smart distractors and detailed analytics
- Practice menu with all four main sections accessible
- Targeted flashcard review for test errors
- Proper belt-level filtering in Progression mode
- Clean navigation flow throughout app

### 📝 **Next Development Phase - Patterns/Tul Implementation:**
Ready to begin designing the pattern data model and implementing the first Taekwondo form (Chon-Ji) with step-by-step guidance, move descriptions, and technique breakdowns.

## Notes for Claude Code

- This project emphasizes **education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation** is critical - users are learning iOS development
- **Best practices** should be highlighted and explained throughout the codebase
- When suggesting changes, explain the benefits and trade-offs
- Consider the long-term maintainability and scalability of all code changes