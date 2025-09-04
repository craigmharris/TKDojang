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
- **Debug Logging**: Always use `DebugLogger` instead of `print()` for debug output - provides conditional compilation and zero release overhead

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
6. Use `DebugLogger.ui()`, `DebugLogger.data()`, or `DebugLogger.profile()` for debug output instead of `print()`

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

## Current State (Updated: September 4, 2025)

### 🎯 **Production-Ready Features:**

All major SwiftData relationship crashes resolved. Core functionality is stable and ready for production deployment.

#### **Complete Learning System**
- **Multi-Profile System**: 6 device-local profiles with data isolation, avatars, color themes, activity tracking
- **9 Traditional Patterns**: JSON-based pattern definitions with comprehensive 3-image system and belt filtering
- **Complete Pattern Imagery**: Multi-image carousel system (Position/Technique/Progress), diagram thumbnails, starting move guides
- **Comprehensive Content**: Terminology (88+ entries), Theory, Line Work, Step Sparring (18 sequences)
- **Profile-Aware Learning**: Flashcards, testing, and session tracking with personalized home screen
- **Progress Analytics**: Instant-loading progress cache system with charts and visualizations

#### **Technical Architecture**
- **MVVM-C Pattern**: Full coordinator-based navigation with ProfileService layer
- **SwiftData Integration**: Optimized queries using proven "Fetch All → Filter In-Memory" patterns
- **JSON Content Pipeline**: Scalable content management with internal asset catalogue integration
- **Service Layer**: Clean separation preventing direct SwiftData model access in views
- **Debug Infrastructure**: Conditional DebugLogger system with zero-overhead release builds

#### **Testing Infrastructure (Ready for Merge)**
- **Comprehensive Test Suite**: BasicFunctionalityTests, MultiProfileSystemTests, FlashcardSystemTests, PerformanceTests
- **Test Infrastructure**: TestContainerFactory, TestDataFactory, TKDojangAssertions, MockObjects

### 📁 **Project Structure:**
```
TKDojang/
├── TKDojang.xcodeproj/           # Complete iOS project
├── Sources/
│   ├── Core/Data/               # SwiftData models, services, JSON content loaders
│   └── Features/                # Learning, Profile, Testing, Patterns, StepSparring, Dashboard
├── TKDojangTests/               # Comprehensive test suite (needs merge)
└── DEVELOPMENT_HISTORY.md       # Detailed development sessions
```

## Next Development Priorities

### ✅ **RESOLVED: Complete Pattern Imagery System**
**Achievement**: Full migration from external URLs to internal asset catalogue with comprehensive image support
**Implementation**: 
- 3-image system per move (Position/Technique/Progress) with TabView carousel
- Pattern diagram thumbnails in list view with prominent 120x80 sizing
- Starting move images in detail view (diagram redundancy removed)
- Debug reload button for pattern refresh without profile data loss
- Graceful fallback for missing images using UIImage(named:) detection
- Complete DebugLogger migration for zero-overhead release builds

### 🔄 **NEXT: Testing Infrastructure Integration**
1. Merge comprehensive test suite from feature/testing-infrastructure branch
2. Validate tests pass with current pattern imagery system
3. Expand pattern content with remaining move image assets

### 📊 **Enhanced Analytics** 
Build on existing ProfileService session tracking to add progress charts, belt journey visualization, and achievement system.


## Testing Commands

### iOS Simulator Configuration
- **Default Test Target**: iPhone 16 (iOS 18.6) - always available simulator  
- **Device ID**: `0A227615-B123-4282-BB13-2CD2EFB0A434`

The project now has a working Xcode configuration:

```bash
# Build the project (CLI)
xcodebuild -project TKDojang.xcodeproj -scheme TKDojang -destination "platform=iOS Simulator,name=iPhone 16" build

# Run unit tests  
# Use Xcode: Cmd+U or Product → Test

# Run on simulator
# Use Xcode: Cmd+R or Product → Run (set to iPhone 16)

# Build for device
# Select device target and use Cmd+R
```

## Environment Configuration

The app supports multiple environments through build configurations:
- `DEBUG`: Development environment with debug features enabled
- `STAGING`: Staging environment for testing
- `RELEASE`: Production environment

Environment-specific constants are managed in `AppConstants.swift` using compiler directives.

## Development Process & History

**Important**: Session summaries and detailed development history should be maintained in `DEVELOPMENT_HISTORY.md` to prevent this document from becoming bloated. When making commits, add session summaries to the history file rather than this main context document.

## Critical SwiftData Architecture Patterns

### 🔧 **Proven SwiftData Solutions:**

#### **"Fetch All → Filter In-Memory" Pattern (Production Critical):**
```swift
// ❌ DANGEROUS - Predicate relationship navigation
let predicate = #Predicate<StudySession> { session in
    session.userProfile.id == profileId  // Causes model invalidation
}

// ✅ SAFE - In-memory filtering  
let allSessions = try modelContext.fetch(FetchDescriptor<StudySession>())
return allSessions.filter { session in
    session.userProfile.id == profileId  // Safe relationship access
}
```

#### **"Load → Convert → Discard" Pattern:**
```swift
// ✅ SAFE - Immediate conversion to primitives  
let sequences = service.getSequences(for: type, userProfile: profile)
sequenceData = sequences.map { sequence in
    StepSparringSequenceDisplay(
        id: sequence.id,           // UUID - safe primitive
        name: sequence.name,       // String - safe primitive  
        totalSteps: sequence.totalSteps // Int - safe primitive
    )
}
// SwiftData objects automatically released from memory
```

#### **Nuclear Option Database Reset:**
For critical data operations with complex state management, clean process termination (`exit(0)`) is often more reliable than sophisticated coordination.

### 🎓 **SwiftData Development Rules:**
1. **Avoid predicate relationship navigation** - causes model invalidation crashes
2. **Never store SwiftData objects in view state** - convert to primitives immediately  
3. **Use simple queries + in-memory processing** for complex analytics
4. **Background processing** for heavy operations to prevent UI blocking
5. **Nuclear options** are sometimes the most reliable solution


## Quality Assurance Requirements

### Before Marking Tasks Complete:
- **Build + Runtime Verification**: Successful compilation AND functional testing required
- **Root Cause Analysis**: Always identify WHY issues occurred, not just HOW to fix them
- **Multiple Approach Evaluation**: Present 2-3 solutions with trade-offs before implementing
- **Evidence-Based Validation**: Measure actual improvements, don't assume them

### Error Prevention Process:
- **Challenge Suboptimal Approaches**: Point out better alternatives even if current approach works
- **Question Assumptions**: Validate rather than assume requirements are optimal
- **Think Systems-Level**: Consider broader architectural implications

## Communication Guidelines

### Technical Interaction:
- **Critical Analysis First**: Identify potential issues before agreeing to approaches
- **Constructive Skepticism**: Question approaches that seem incomplete or suboptimal  
- **Evidence-Based Claims**: Support performance assertions with actual measurements
- **Educational Focus**: Prioritize understanding principles over quick solutions

### Communication Style:
- **Primary Mode**: Senior engineer providing honest critical analysis and pushback
- **Technical Authority**: Maintain professional credibility through substantive engineering feedback
- **Constructive Critique**: Challenge approaches to drive better solutions

### When Providing Critical Feedback:
- **Technical Oversights**: Point out when more elegant solutions exist
- **Premature Validation**: Question assumptions about task completion
- **Suboptimal Patterns**: Highlight when simpler approaches would be more effective
- **Process Improvements**: Suggest better workflows when current approach has issues

### Communication Boundaries:
- **Educational Moments**: Straightforward explanation for new concepts or complex decisions
- **Error Analysis**: Clear, direct communication during serious debugging
- **Technical Discussion**: Focus on engineering merit, not entertainment

## Architecture Decision Process

### Implementation Standards:
1. **Problem Definition**: Clearly articulate what problem is actually being solved
2. **Solution Evaluation**: Present multiple approaches with honest pros/cons
3. **Impact Assessment**: Consider performance, maintainability, and complexity effects
4. **Validation Strategy**: Define how success will be measured
5. **Incremental Testing**: Break changes into verifiable steps

## Notes for Claude Code

- This project emphasizes **education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation** is critical - users are learning iOS development
- **Best practices** should be highlighted and explained throughout the codebase
- When suggesting changes, explain the benefits and trade-offs
- Consider the long-term maintainability and scalability of all code changes
- **Sometimes nuclear options are the right choice** - don't over-engineer when simple solutions work better