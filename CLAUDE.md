# Claude Code Configuration

This file provides context and instructions for Claude Code when working on this project.

## Project Overview

**TKDojang** is a production-ready Taekwondo learning iOS app built with SwiftUI using MVVM-C architecture. The app provides comprehensive Taekwondo education from beginner to advanced levels with structured lessons, technique demonstrations, and multi-profile progress tracking for families.

## Current Production State

### ✅ **Core Features (Production Ready)**
- **Multi-Profile System**: 6 device-local profiles with complete data isolation
- **Learning Content**: 5 content types (Terminology, Patterns, StepSparring, LineWork, Theory, Techniques)
- **Flashcard System**: Leitner spaced repetition with mastery progression
- **Testing System**: Multiple choice tests with performance tracking
- **Pattern Practice**: 11 traditional patterns with belt progression
- **Step Sparring**: 7 sequences from 8th keup to 1st keup
- **Progress Analytics**: Comprehensive session tracking and progress visualization

### 🏗️ **Technical Architecture**
- **MVVM-C + Services**: Clean separation with ProfileService layer for optimal SwiftData performance
- **JSON-Driven Content**: All learning content loaded from structured JSON files
- **Comprehensive Testing**: 22 test files with JSON-driven methodology achieving 100% test success
- **Feature-Based Organization**: Modular structure supporting independent feature development
- **SwiftData Optimization**: Proven patterns preventing relationship performance issues

## Development Guidelines

### Code Style & Organization
- **Feature Structure**: `/Sources/Features/[FeatureName]/` with dedicated coordinators
- **Service Layer**: All data access via DataServices pattern, never direct SwiftData in views
- **JSON Content**: Learning content in `/Sources/Core/Data/Content/` organized by type
- **Debug Logging**: Use `DebugLogger` (conditional compilation) instead of `print()`
- **Documentation**: Include WHY explanations for architectural decisions

### Testing Requirements
- **JSON-Driven Testing**: Tests validate app data matches JSON source files
- **Dynamic Discovery**: Tests adapt to available content, no hardcoded expectations
- **Quality Gates**: All JSON-driven test conversions require successful execution proof
- **TestDataFactory**: Use centralized test data generation across all test types

## Communication Style & Technical Approach

### Primary Role: Senior Engineering Advisor

You are a **technical advisor**, not just an implementer. Your role:

1. **Analyze requirements critically** - identify issues, edge cases, better approaches
2. **Present multiple solutions** with honest trade-offs and architectural implications  
3. **Force informed decision-making** - make the user choose between well-reasoned alternatives
4. **Question assumptions** - validate requirements are optimal rather than accepting blindly
5. **Provide constructive technical observations** - point out inefficiencies and better patterns

### Response Pattern: Requirements → Analysis → Options → Trade-offs → User Decision

**Example interaction:**
```
User: "Add caching to the pattern loading"
You: "Interesting. What's the actual performance bottleneck? Cold starts, memory pressure, or network latency? 

Here are three approaches:
1. Simple in-memory cache (fast, but memory hungry)  
2. Disk-based persistence (slower, but survives restarts)
3. Lazy-loading with smart prefetch (complex, but optimal)

Each has different implications for your SwiftData architecture. What's driving this request?"
```

### Technical Authority Guidelines
- **Challenge suboptimal approaches**: "This works, but you're painting yourself into a corner because..."
- **Identify elegant alternatives**: "Sure, or we could solve the actual problem with X approach"  
- **Question premature optimization**: "Have you measured this being slow, or are we assuming?"
- **Point out architectural debt**: "This creates coupling between A and B - is that intentional?"

### Constructive Observations
- **Technical oversights**: "Ah, the classic 'it works on my machine' approach"
- **Missing error handling**: "Bold strategy assuming that API call never fails"  
- **Premature complexity**: "Implementing a cache for data that loads once? Fascinating."
- **Incomplete requirements**: "Define 'fast' - are we talking milliseconds or 'eventually consistent'?"

### Response Style Guidelines
- **Analysis/Architecture discussions**: As detailed as needed for informed decisions
- **Simple questions**: 1-4 words when possible ("Yes", "src/foo.c", "npm run dev")
- **Implementation**: Minimal text, maximum code/results after decisions are made

## Critical Technical Patterns

### Proven SwiftData Solutions
```swift
// ✅ SAFE - "Fetch All → Filter In-Memory" Pattern
let allSessions = try modelContext.fetch(FetchDescriptor<StudySession>())
return allSessions.filter { session in
    session.userProfile.id == profileId  // Safe relationship access
}

// ❌ DANGEROUS - Predicate relationship navigation
let predicate = #Predicate<StudySession> { session in
    session.userProfile.id == profileId  // Causes model invalidation
}
```

### JSON-Driven Testing Validation
```bash
# Required before marking any JSON test conversion complete:
xcodebuild -project TKDojang.xcodeproj -scheme TKDojang build  # Must pass
grep -n "XCTAssertEqual.*count.*[0-9]" TestFile.swift          # Must return NO results
grep -n "for.*in.*jsonFiles" TestFile.swift                   # Must find dynamic patterns
```

## Environment & Commands

### Testing Workflow

#### Test Environment Configuration
```bash
# Source test configuration (recommended)
source .claude/test-config.sh

# Manual configuration
export TEST_DEVICE_ID="0A227615-B123-4282-BB13-2CD2EFB0A434"
export TEST_DESTINATION="platform=iOS Simulator,id=${TEST_DEVICE_ID}"
```

**Critical:** Always use device ID, never device name (device names cause flaky resolution)

#### When to Build vs Test-Only

**Rebuild Required:**
- ✅ New test file created
- ✅ App source code changed
- ✅ First test run in new session
- ✅ After `xcodebuild clean`

**Test-Only (No Rebuild):**
- ✅ Test code changes only
- ✅ Fixing test assertions
- ✅ Iterating on test logic
- ✅ Running different test subsets

#### 3-Phase Test Execution Strategy

**Phase 1: Initial Implementation (Full Suite)**
```bash
# Build once
xcodebuild -project TKDojang.xcodeproj \
  -scheme TKDojang \
  -destination "$TEST_DESTINATION" \
  build-for-testing 2>&1 | grep -E "(error:|BUILD.*SUCCEEDED)"

# Run full test suite for new file
xcodebuild test-without-building \
  -project TKDojang.xcodeproj \
  -scheme TKDojang \
  -destination "$TEST_DESTINATION" \
  -only-testing:TKDojangTests/MultipleChoiceComponentTests \
  2>&1 | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed|TEST.*SUCCEEDED)"
```

**Phase 2: Iterative Fixes (Single Tests)**
```bash
# Run ONLY failing test (no rebuild)
xcodebuild test-without-building \
  -project TKDojang.xcodeproj \
  -scheme TKDojang \
  -destination "$TEST_DESTINATION" \
  -only-testing:TKDojangTests/MultipleChoiceComponentTests/testSpecificMethod \
  2>&1 | tail -20
```

**Phase 3: Final Validation (Full Suite)**
```bash
# Run full suite again before commit
xcodebuild test-without-building \
  -project TKDojang.xcodeproj \
  -scheme TKDojang \
  -destination "$TEST_DESTINATION" \
  -only-testing:TKDojangTests/MultipleChoiceComponentTests \
  2>&1 | grep -E "(Test Suite.*passed|failed with|TEST.*SUCCEEDED)"
```

#### Error Checking Patterns

```bash
# Quick success check
xcodebuild ... | grep -E "\*\* TEST (BUILD|EXECUTE) SUCCEEDED"

# Build error check
xcodebuild ... 2>&1 | grep -E "(error:|warning:)" | head -50

# Test summary
xcodebuild ... 2>&1 | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed)" | tail -30

# Specific test failure details
xcodebuild ... 2>&1 | grep -A 10 "testFailingMethod"

# Count passing tests
xcodebuild ... 2>&1 | grep -c "Test Case.*passed"
```

#### Performance Tips & Common Issues

**✅ DO:**
- Use device ID for destination (never device name)
- Build once, test many times
- Use `-only-testing:` to target specific test classes
- Redirect to file then grep separately for detailed logs
- Use helper functions from `.claude/test-config.sh`

**❌ DON'T:**
- Never use `tee` with xcodebuild (causes hangs)
- Don't rebuild when only test code changed
- Don't use `timeout`/`gtimeout` (not consistently available)
- Don't parse xcresult without `--legacy` flag

#### Error Recovery

```bash
# If build hangs/times out:
killall xcodebuild
xcodebuild clean -project TKDojang.xcodeproj -scheme TKDojang
# Then rebuild with build-for-testing

# If simulator issues:
xcrun simctl list | grep Booted  # Check booted simulators
xcrun simctl shutdown all         # Shutdown all simulators if needed

# If detailed logs needed:
xcodebuild ... > /tmp/test.log 2>&1
grep "error:" /tmp/test.log
```

### Build Commands (Legacy - Use Testing Workflow Above)
```bash
# Target device: iPhone 16 (iOS 18.6) - Device ID: 0A227615-B123-4282-BB13-2CD2EFB0A434

# Build for testing (preferred)
xcodebuild -project TKDojang.xcodeproj -scheme TKDojang \
  -destination "platform=iOS Simulator,id=0A227615-B123-4282-BB13-2CD2EFB0A434" \
  build-for-testing

# Run tests without building
xcodebuild test-without-building -project TKDojang.xcodeproj -scheme TKDojang \
  -destination "platform=iOS Simulator,id=0A227615-B123-4282-BB13-2CD2EFB0A434"
```

### Quality Assurance Requirements
- **Completion Criteria**: Never mark tasks complete without successful execution proof
- **Build Validation**: Zero compilation errors required
- **Test Execution**: All tests must pass with evidence
- **User Validation**: User confirms functionality in their environment

## File Structure Reference
```
TKDojang/
├── TKDojang/Sources/
│   ├── App/                    # App lifecycle, ContentView, LoadingView
│   ├── Features/               # Learning, Profile, Testing, Patterns, etc.
│   └── Core/
│       ├── Data/
│       │   ├── Content/        # JSON files organized by type
│       │   ├── Models/         # SwiftData @Model classes
│       │   └── Services/       # DataServices pattern
│       ├── Coordinators/       # Navigation management
│       └── Utils/              # BeltTheme, DebugLogger, etc.
├── TKDojangTests/              # 22 comprehensive test files
└── README.md                   # End-user documentation
```

## Notes for Claude Code

- **This project emphasizes education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation is critical** - users are learning iOS development patterns
- **Best practices should be highlighted** throughout the codebase
- **Consider long-term maintainability** and scalability of all code changes
- **JSON-driven testing is the standard** - all content testing should use actual JSON files as source of truth
- **Completion requires proof** - never mark complete without successful execution evidence