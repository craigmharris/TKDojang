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

## Current State (Updated: August 19, 2025)

### 🎯 **OPTIMAL DEVELOPMENT STATE:**

After comprehensive review of all branches (develop, feature/patterns-tul, feature/testing-infrastructure), the **feature/patterns-tul branch contains the most advanced and production-ready features**. This branch should be the foundation for continued development.

### ✅ **WORKING FEATURES - Production Ready:**

#### **Complete Multi-Profile System** 
- **ProfileService**: Full profile management with activation, switching, and isolation
- **Profile Components**: ProfileSwitcher, ProfileManagementView, ProfileGridView
- **Profile Features**: Up to 6 device-local profiles, avatars, color themes, custom names
- **Profile Stats**: Activity tracking, study streaks, flashcard/test counters
- **Profile Isolation**: Complete data separation between family members

#### **Advanced Pattern System**
- **9 Traditional Patterns**: Complete implementation with metadata
- **PatternService**: Pattern loading, user progress tracking, belt-level filtering  
- **Pattern Views**: PatternCard, PatternDetailView, PatternPracticeView
- **Pattern Progress**: User mastery tracking with visual indicators
- **Pattern Data**: JSON-based pattern definitions with proper structure

#### **Enhanced Learning Features**
- **Profile-Aware Flashcards**: Filtering by active profile, session tracking
- **Profile-Aware Testing**: User-specific test creation and result tracking
- **Study Session Recording**: Automatic session logging with ProfileService
- **Learning Mode Adaptation**: Mastery vs Progression mode support
- **Step Sparring System**: Complete sparring sequence learning with manual belt filtering

#### **Robust UI & Navigation**
- **Profile-Aware Toolbars**: ProfileSwitcher in all major views
- **Enhanced Profile Management**: Creation, editing, deletion, validation
- **Belt-Themed UI**: BeltTheme integration throughout the app
- **Responsive Design**: Adaptive layouts for different content types

#### **Core Technical Features**
- **Xcode Project**: Complete working iOS project (TKDojang.xcodeproj) 
- **Architecture**: Full MVVM-C implementation with coordinator pattern
- **Content Management**: 88+ terminology entries across 13 belt levels
- **Data Services**: TerminologyService, PatternService, ProfileService
- **SwiftData Integration**: Optimized model relationships and queries

### 🧪 **COMPREHENSIVE TESTING INFRASTRUCTURE (from testing-infrastructure branch):**

The testing-infrastructure branch provides essential testing coverage that should be merged:

#### **Test Coverage**
- **BasicFunctionalityTests**: Core framework validation, model creation, basic queries
- **MultiProfileSystemTests**: Profile creation, switching, data isolation, deletion, limits (up to 6)
- **FlashcardSystemTests_Simple**: Leitner box system, mastery progression, spaced repetition
- **PerformanceTests**: Database performance, memory usage, bulk operations, sorting
- **TestHelpers**: Complete test infrastructure with factories, assertions, utilities

#### **Test Infrastructure**
- **TestContainerFactory**: In-memory SwiftData containers for isolated testing
- **TestDataFactory**: Realistic test data generation (belts, categories, terminology, profiles)
- **TKDojangAssertions**: Custom validation helpers for domain objects
- **PerformanceMeasurement**: Execution time and memory usage measurement
- **MockObjects**: Service mocking for complex interaction testing

### 🔧 **Current Architecture Advantages:**

#### **Solved Previous Issues:**
- ✅ **ProfileService Pattern**: Eliminated SwiftData relationship hangs through proper service layer
- ✅ **Background Processing**: Async profile operations prevent main thread blocking  
- ✅ **Simple Queries**: Avoided complex nested predicates that caused compilation failures
- ✅ **Lazy Initialization**: ProfileService properly initialized after DataManager setup
- ✅ **Service Layer**: Views use services instead of direct SwiftData model access
- ✅ **Step Sparring "Nuclear Option"**: Completely bypassed SwiftData many-to-many relationships

#### **Technical Improvements:**
- **Session Management**: Automatic study session recording with duration and stats
- **Profile Activity**: Last active tracking, streak counting, usage statistics
- **Memory Efficiency**: Optimized loading patterns and lazy initialization
- **Error Handling**: Comprehensive error management throughout profile operations
- **Manual Belt Filtering**: Hardcoded pattern matching prevents SwiftData relationship corruption

### ⚠️ **CRITICAL LESSONS LEARNED - SwiftData Performance:**

**These patterns were successfully resolved in feature/patterns-tul:**

1. **SwiftData Relationship Navigation on Main Thread** ✅ SOLVED:
   - **Problem**: Accessing `userProfile.terminologyProgress` directly caused app hangs
   - **Solution**: ProfileService with async methods prevents direct relationship access

2. **Complex Nested Predicates** ✅ SOLVED:
   - **Problem**: Predicates crossing multiple relationships caused compilation failures
   - **Solution**: Simple queries with programmatic filtering in service layer

3. **Service Initialization During DataManager Init** ✅ SOLVED:
   - **Problem**: ProfileService initialization during DataManager creation caused deadlock
   - **Solution**: Lazy initialization pattern with proper dependency management

4. **Direct SwiftData Model Access in Views** ✅ SOLVED:
   - **Problem**: Views accessing SwiftData relationships blocked the main thread
   - **Solution**: Service layer with async methods and proper threading

5. **Step Sparring Many-to-Many Relationships** ✅ SOLVED:
   - **Problem**: SwiftData many-to-many relationships between sequences and belt levels caused object invalidation crashes
   - **Solution**: "Nuclear Option" - Completely bypass SwiftData relationships and use manual pattern matching based on sequence types and numbers

### 📁 **Updated Project Structure:**
```
TKDojang/
├── TKDojang.xcodeproj/           # Working Xcode project  
├── TKDojang/Sources/
│   ├── App/                      # App lifecycle and root views
│   ├── Core/
│   │   ├── Data/
│   │   │   ├── Content/
│   │   │   │   ├── Terminology/        # 13 belt-level terminology files
│   │   │   │   ├── Patterns/           # 9 belt-specific pattern JSON files
│   │   │   │   ├── StepSparring/       # 5 belt-specific step sparring files
│   │   │   │   ├── PatternContentLoader.swift     # Pattern JSON loader
│   │   │   │   ├── StepSparringContentLoader.swift # Step sparring JSON loader
│   │   │   │   └── ModularContentLoader.swift     # Terminology JSON loader
│   │   │   ├── DataManager.swift # SwiftData container + service orchestration
│   │   │   ├── Models/           # All SwiftData models (Patterns, Profiles, StepSparring)
│   │   │   └── Services/         # Data access services (Terminology, Pattern, Profile, StepSparring)
│   │   ├── Coordinators/         # Navigation management
│   │   └── Utils/                # Shared utilities, theming, belt design system
│   └── Features/
│       ├── Learning/             # Enhanced flashcard system with profile support
│       ├── Profile/              # Complete multi-profile management
│       ├── Testing/              # Profile-aware multiple choice testing  
│       ├── Patterns/             # Traditional pattern learning system (JSON-based)
│       ├── StepSparring/         # Step sparring training system with manual belt filtering
│       └── Dashboard/            # Main navigation with profile integration
├── TKDojangTests/               # Comprehensive test suite (needs merge from testing branch)
│   ├── BasicFunctionalityTests.swift
│   ├── MultiProfileSystemTests.swift  
│   ├── FlashcardSystemTests_Simple.swift
│   ├── PerformanceTests.swift
│   └── TestHelpers/             # Test infrastructure and utilities
├── Scripts/
│   └── csv-to-terminology.swift # Enhanced CSV import tool
├── README.md                    # Project overview and architecture
└── CLAUDE.md                    # Development context (this file)
```

## Next Development Session Priority Tasks:

### 🔄 **IMMEDIATE: Content System Integration**
1. **🔄 Pattern Content Expansion**: Add full move breakdowns for all remaining patterns (Dan-Gun through Chung-Mu)
2. **🔄 Merge Testing Infrastructure**: Copy comprehensive test suite from feature/testing-infrastructure to current branch
3. **🔄 JSON Content Validation**: Create validation tools to ensure JSON content consistency
4. **🔄 Branch Consolidation**: Merge pattern JSON structure into develop for stable foundation

### 🧪 **Phase 1: Testing Framework Integration**
**PRIORITY**: The testing infrastructure exists but needs to be merged into the primary branch

1. **Immediate Tasks**:
   - Copy test files from feature/testing-infrastructure to feature/patterns-tul
   - Verify tests run successfully with the advanced features
   - Fix any test incompatibilities with the multi-profile system
   - Validate performance tests work with the enhanced data model

2. **Test Validation**:
   - **BasicFunctionalityTests**: Verify core models and services work
   - **MultiProfileSystemTests**: Validate profile isolation and switching  
   - **FlashcardSystemTests_Simple**: Confirm spaced repetition logic
   - **PerformanceTests**: Ensure app performs well with realistic data loads

### 📊 **Phase 2: Enhanced Progress Analytics**
**FOUNDATION**: ProfileService already handles study sessions - build on this success

1. **Extend Existing Session Tracking**:
   - ProfileService.recordStudySession() already works correctly
   - Add detailed session analytics and visualization  
   - Implement progress charts using the existing session data
   - Create study streak calculations and achievement system

2. **Analytics Dashboard**:
   - Profile-specific progress visualization
   - Belt progression tracking
   - Learning efficiency metrics
   - Family progress comparison (across profiles)

### 📝 **Phase 3: Content & Feature Expansion**
1. **Complete Pattern System**: Add remaining 7 patterns beyond Chon-Ji
2. **Enhanced Testing Modes**: Time challenges, adaptive difficulty, custom test creation
3. **Advanced Learning Features**: Weak area focus, personalized study plans
4. **Community Features**: Family challenges, shared achievements

### 🔧 **Phase 4: Production Polish**
1. **Performance Optimization**: App startup time, memory usage, smooth animations
2. **Accessibility**: VoiceOver support, dynamic type, reduced motion
3. **Error Handling**: Comprehensive error states, recovery mechanisms
4. **App Store Preparation**: Screenshots, descriptions, marketing materials

## Development Context Notes:
- **Current Optimal State**: feature/patterns-tul branch with complete multi-profile system and pattern learning
- **Architecture Decision**: MVVM-C pattern with ProfileService layer proven successful
- **Code Quality**: All code includes comprehensive documentation explaining WHY decisions were made
- **Testing Priority**: Comprehensive test suite exists in testing-infrastructure branch, needs merge
- **Next Phase**: Merge testing infrastructure, then enhance analytics using existing session tracking

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

## Session Summary (August 21, 2025)

### 🎯 **Major Accomplishments This Session:**

#### 🗂️ **Pattern JSON Structure Implementation:**
1. **Fixed JSON Architecture**: Created consistent JSON structure for patterns following terminology/step sparring pattern
2. **Belt-Specific Pattern Files**: 9 JSON files covering 9th_keup through 1st_keup patterns
3. **PatternContentLoader**: New content loader matching StepSparringContentLoader pattern for consistency
4. **Complete Pattern Data**: Full pattern definitions with moves, Korean terminology, and educational content
5. **Service Integration**: Updated PatternDataService to load from JSON instead of hardcoded Swift methods

#### 📊 **Comprehensive Pattern Content:**
6. **Detailed Move Breakdowns**: Complete 19-move breakdown for Chon-Ji, structured data for all patterns
7. **Korean Integration**: Korean technique names alongside English for authentic learning
8. **Educational Content**: Key points, common mistakes, execution notes for each move
9. **Multimedia Support**: URL fields for pattern videos and individual move images
10. **Belt Level Associations**: Proper filtering based on user's current belt progression

#### 🔧 **Technical Architecture Enhancement:**
11. **MainActor Support**: Proper async/await integration for SwiftUI compatibility
12. **JSON Schema Consistency**: Unified structure across terminology, step sparring, and patterns
13. **Content Maintainability**: Easy content updates without code changes
14. **Build Integration**: All JSON files properly bundled and tested successfully

#### 🥊 **Step Sparring System (Previous Session Recap):**
15. **18 Step Sparring Sequences**: Complete 3-step and 2-step sparring with manual belt filtering
16. **Nuclear Option Success**: SwiftData relationship bypass preventing crashes
17. **Production-Ready Interface**: Step-by-step practice with progress tracking

### ✅ **Technical Architecture Success:**
- **✅ Consistent JSON Structure**: Patterns now match terminology and step sparring format
- **✅ Content Loading Pipeline**: PatternContentLoader follows established patterns
- **✅ SwiftData Integration**: Proper model insertion with belt level associations
- **✅ Build Verification**: All new JSON files compile and bundle correctly
- **✅ Educational Completeness**: Full pattern data with Korean terminology and learning aids

### 📋 **Current Feature Status:**
- **Pattern System**: JSON-based with complete Chon-Ji implementation, framework for all 24 ITF patterns
- **Step Sparring**: 18 sequences with manual belt filtering (stable, no crashes)
- **Multi-Profile System**: Complete with data isolation and activity tracking  
- **Terminology System**: 88+ entries across 13 belt levels with JSON structure
- **Testing Infrastructure**: Comprehensive test suite ready for integration

## Session Summary (August 19, 2025)

### 🎯 **Major Accomplishments This Session:**

#### 🔍 **Comprehensive Branch Analysis:**
1. **Complete Repository Review**: Systematically analyzed three key branches (develop, feature/patterns-tul, feature/testing-infrastructure)
2. **Feature Comparison**: Documented capabilities and state of each branch to identify optimal development path
3. **Testing Infrastructure Discovery**: Found comprehensive test suite with 4 test files and robust infrastructure
4. **Architecture Evolution Tracking**: Identified how ProfileService pattern solved previous SwiftData performance issues

#### 📊 **Strategic Development Planning:**
5. **Optimal Branch Identification**: Determined feature/patterns-tul as most advanced with complete multi-profile system
6. **Integration Strategy**: Created plan to merge testing infrastructure into primary development branch
7. **Technical Debt Resolution**: Documented how previous SwiftData issues were successfully resolved
8. **Priority Roadmap**: Established clear phase-based development plan

#### 📚 **Documentation Overhaul:**
9. **CLAUDE.md Complete Update**: Rewrote entire current state section to reflect actual capabilities
10. **Architecture Success Documentation**: Documented how ProfileService pattern eliminated previous performance issues
11. **Testing Infrastructure Cataloging**: Detailed the comprehensive test coverage available for integration
12. **Development Context Refinement**: Updated guidance to reflect current optimal development state

### ✅ **Verified Current Optimal State (feature/patterns-tul):**
- **Complete Multi-Profile System**: ProfileService, ProfileSwitcher, profile management UI
- **9 Traditional Patterns**: Full pattern learning system with progress tracking
- **Enhanced Learning Features**: Profile-aware flashcards and testing with session recording
- **Solved Technical Issues**: ProfileService pattern eliminated SwiftData relationship hangs
- **Robust UI**: Profile-themed navigation, belt design system, responsive layouts
- **Working Services**: TerminologyService, PatternService, ProfileService all operational

### 🧪 **Available Testing Infrastructure (feature/testing-infrastructure):**
- **BasicFunctionalityTests**: Core framework and model validation
- **MultiProfileSystemTests**: Complete profile system validation (creation, switching, isolation)
- **FlashcardSystemTests_Simple**: Spaced repetition and Leitner box system tests
- **PerformanceTests**: Database performance, memory usage, bulk operations
- **TestHelpers**: Comprehensive test infrastructure with factories and utilities

### 🎓 **Technical Architecture Success:**
- **✅ ProfileService Pattern**: Eliminated direct SwiftData relationship access issues
- **✅ Async Operations**: Proper threading prevents main thread blocking
- **✅ Service Layer**: Clean separation between UI and data access
- **✅ Session Management**: Automatic study session recording without performance issues
- **✅ Multi-Profile Isolation**: Complete data separation between family members

### 📋 **Next Session Action Plan:**
1. **Copy testing infrastructure** from feature/testing-infrastructure to feature/patterns-tul
2. **Validate test compatibility** with enhanced multi-profile system
3. **Merge consolidated branch** into develop for stable foundation
4. **Build on ProfileService success** to add enhanced analytics and visualizations

## Notes for Claude Code

- This project emphasizes **education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation** is critical - users are learning iOS development
- **Best practices** should be highlighted and explained throughout the codebase
- When suggesting changes, explain the benefits and trade-offs
- Consider the long-term maintainability and scalability of all code changes