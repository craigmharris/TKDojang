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
- **Belt Design System**: Concentric belt borders with Primary-Secondary-Primary tag stripes
- **Progress Tracking**: User statistics, mastery levels, study streaks
- **Content Management**: Complete terminology system with 88+ entries across multiple belt levels
- **Navigation**: Coordinator-based navigation with smooth animations
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

#### 📁 **Complete Terminology System Overhaul:**
1. **Organized Folder Structure**: Created clean separation with Terminology/ and Patterns/ folders
2. **Enhanced CSV Tool**: Updated to output belt-prefixed filenames (10th_keup_basics.json) to single directory
3. **Complete Data Population**: Filled in 88+ missing entries with:
   - Authentic Korean Hangul characters (차렷, 막기, 경례, etc.)
   - Proper IPA phonetic pronunciations (/tʃʰa.ɾjət/, /mak.k͈i/, etc.)
   - Clear, educational definitions for all techniques and terminology

#### 🔧 **Technical Infrastructure:**
4. **Enhanced ModularContentLoader**: Added multi-location resource loading with comprehensive debug logging
5. **Bundle Resource Management**: Fixed file discovery across organized folder structure
6. **Backward Compatibility**: Maintained support for existing belt system while adding new features
7. **Quality Assurance**: Verified app builds and loads terminology correctly

### ✅ **Verified Working:**
- All 13 terminology files properly organized and loading
- Flashcard system working with complete Korean terminology
- CSV import tool updated for new structure
- Belt design system with proper theming
- Comprehensive debug logging for troubleshooting

### 📝 **Tomorrow's Immediate Tasks:**
1. Add remaining 5th_keup to 1st_keup terminology files
2. Create automated testing framework
3. Build multiple choice assessment system
4. Start Chon-Ji pattern implementation

## Notes for Claude Code

- This project emphasizes **education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation** is critical - users are learning iOS development
- **Best practices** should be highlighted and explained throughout the codebase
- When suggesting changes, explain the benefits and trade-offs
- Consider the long-term maintainability and scalability of all code changes