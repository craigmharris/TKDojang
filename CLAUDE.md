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
- **Comprehensive Testing**: 260/260 tests passing (100% test success rate)
- **Feature-Based Organization**: Modular structure supporting independent feature development
- **SwiftData Optimization**: Proven patterns preventing relationship performance issues
- **WCAG 2.2 Compliant**: Full accessibility support with comprehensive testing

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

## Test Architecture Principles (MANDATORY)

### Data Source Hierarchy

Tests MUST follow this strict hierarchy for data sources:

1. **PRIMARY: Production JSON Files** (`Sources/Core/Data/Content/`)
   - ✅ Component tests testing features with JSON data
   - ✅ System tests validating JSON loading
   - ✅ Integration tests with real content
   - **WHY**: Tests should catch real data quality issues that users will encounter

2. **SECONDARY: TestDataFactory** (ONLY when justified)
   - ✅ Testing data loading failure scenarios
   - ✅ Unit testing the TestDataFactory itself
   - ✅ New features where JSON doesn't exist yet (temporary)
   - ❌ NEVER as default "because it's easier"
   - ❌ NEVER to work around insufficient JSON data (fix the JSON instead)

### Pre-Work Validation (REQUIRED)

**Before starting ANY test work, Claude MUST:**

1. **Check for existing JSON data**:
   ```bash
   ls -la TKDojang/Sources/Core/Data/Content/[FeatureName]/
   ```

2. **Present Data Source Analysis**:
   ```
   Feature: [name]
   JSON Data Available: [Yes/No - list files]
   Current Test Approach: [Synthetic/JSON/Mixed]
   CLAUDE.md Compliance: [Yes/No with reasoning]
   Proposed Approach: [what I plan to use and WHY]

   Proceed? (Requires approval)
   ```

3. **Get explicit approval** before writing test code

### Red Flags That MUST Trigger Challenge

If you encounter ANY of these, STOP and challenge the approach:

- ❌ Component test with `createBasicTestData()` but JSON files exist
- ❌ "Fixing" failing tests by increasing synthetic data counts
- ❌ Hardcoded expected counts (`XCTAssertEqual(count, 5)`) instead of dynamic discovery
- ❌ Tests passing with TestDataFactory but would fail with real JSON
- ❌ Test file with 0 JSON loading occurrences when feature has JSON data
- ❌ Comment saying "uses real JSON" but `grep "Bundle.main" TestFile.swift` returns nothing

### Required Self-Review Questions

Before marking ANY test work complete, Claude MUST answer:

1. **Data Source Validation**:
   - Does production JSON exist for this feature?
   - If yes, am I using it? If no, why not?
   - If using TestDataFactory, what's the documented justification?

2. **Property-Based Testing Validation**:
   - Are there hardcoded expected counts?
   - Do tests adapt to available data dynamically?
   - Would changing JSON content break these tests inappropriately?

3. **JSON-Driven Validation**:
   - Do tests load from actual JSON in `Sources/Core/Data/Content/`?
   - Would these tests catch data quality issues in JSON files?
   - Run: `grep -c "TestDataFactory\|createBasicTestData" TestFile.swift` - should be 0

4. **Architecture Compliance**:
   - Re-read CLAUDE.md testing section
   - Does this follow stated architecture principles?
   - Am I applying "Senior Engineering Advisor" role to my OWN work?

### Validation Commands

```bash
# Check test data source (should return 0 for Component tests with JSON available)
grep -c "createBasicTestData\|TestDataFactory" YourTest.swift

# Check JSON usage (should be > 0 for features with JSON data)
grep -c "Bundle.main.url.*json\|JSONDecoder" YourTest.swift

# Verify no hardcoded counts
grep -n "XCTAssertEqual.*count.*[0-9]" YourTest.swift  # Should return nothing

# Check dynamic discovery
grep -n "for.*in.*jsonFiles\|\.count" YourTest.swift  # Should find dynamic patterns
```

### Enforcement Pattern

When completing test work, Claude MUST provide:

```markdown
## Test Architecture Compliance Report

### Data Source Used
- [X] Production JSON files from Sources/Core/Data/Content/
- [ ] TestDataFactory (Justification: ________________)

### Validation Results
- JSON files available: [Yes/No - list files]
- grep "TestDataFactory" count: [number]
- grep "Bundle.main.url.*json" count: [number]
- Hardcoded counts found: [Yes/No - list if yes]

### Self-Review Checklist
- [ ] Re-read CLAUDE.md testing principles
- [ ] Verified JSON data usage where available
- [ ] Tests adapt dynamically to content
- [ ] Would catch real production JSON bugs
- [ ] Documented any TestDataFactory usage justification

### Compliance Status
[COMPLIANT / NON-COMPLIANT with explanation]
```

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

### 1. SwiftData: "Fetch All → Filter In-Memory" Pattern

**Context:** SwiftData predicate relationship navigation causes model invalidation crashes

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

**WHY:** SwiftData has bugs with predicate relationship navigation. The fetch-filter pattern eliminates crashes.

**WHEN TO USE:** Always, when accessing @Model relationships in queries

### 2. SwiftData: Persistent Storage for Tests

**Context:** In-memory storage crashes with 3+ level @Model hierarchies loaded from JSON

```swift
// ❌ WRONG - Causes bugs with nested @Model + JSON
let configuration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: true
)

// ✅ CORRECT - Matches production, catches real bugs
let testDatabaseURL = URL(filePath: NSTemporaryDirectory())
    .appending(path: "TKDojangTest_\(UUID().uuidString).sqlite")

let configuration = ModelConfiguration(
    schema: schema,
    url: testDatabaseURL,
    cloudKitDatabase: .none
)
```

**WHY:** In-memory storage uses different SwiftData code paths with bugs for complex relationships. Persistent storage:
- Matches production environment exactly
- Uses same SwiftData code paths as production
- Catches SQLite-specific bugs
- UUID ensures test isolation
- System auto-cleanup via NSTemporaryDirectory()

**WHEN TO USE:** All tests loading multi-level @Model hierarchies from JSON

### 3. SwiftData: Exact Production Replication for JSON Loading

**Rule:** When JSON-loading multi-level @Model hierarchies, match production code line-by-line.

**Key Requirements:**
1. **Field mappings must be exact** - No "equivalent" interpretations
2. **Object graph construction order** - Build complete graph in memory before insertion
3. **Explicit insertion of all levels** - Don't rely on cascading alone
4. **Persistent storage** - Required for nested relationships + JSON

**Example (StepSparring - 3 levels):**
```swift
// PHASE 1: Build complete object graph in memory
var allSequences: [StepSparringSequence] = []
for jsonData in jsonFiles {
    let sequence = StepSparringSequence(...)
    sequence.applicableBeltLevelIds = jsonData.applicable_belt_levels

    var steps: [StepSparringStep] = []
    for stepJSON in jsonData.steps {
        // Field mapping MUST match production exactly
        let attackAction = StepSparringAction(
            technique: stepJSON.attack.technique,
            koreanName: stepJSON.attack.korean_name,
            execution: "\(stepJSON.attack.hand) \(stepJSON.attack.stance) to \(stepJSON.attack.target)",  // ← EXACT
            actionDescription: stepJSON.attack.description  // ← EXACT
        )
        // ... similar for defense and counter

        let step = StepSparringStep(
            sequence: sequence,
            attackAction: attackAction,
            defenseAction: defenseAction,
            ...
        )
        steps.append(step)
    }

    sequence.steps = steps
    allSequences.append(sequence)
}

// PHASE 2: Explicit insertion of ALL @Model levels
for sequence in allSequences {
    testContext.insert(sequence)
    for step in sequence.steps {
        testContext.insert(step.attackAction)
        testContext.insert(step.defenseAction)
        if let counter = step.counterAction {
            testContext.insert(counter)
        }
        testContext.insert(step)
    }
}

// PHASE 3: Save once
try testContext.save()
```

### 4. Property-Based Testing Pattern

**Context:** Tests should validate behaviors that hold for ANY valid input, not specific scenarios

```swift
// ✅ CORRECT - Property-based
func testCardCount_PropertyBased() {
    let randomCount = Int.random(in: 5...50)
    let randomBelt = allBelts.randomElement()!
    let config = FlashcardConfiguration(numberOfTerms: randomCount)
    // PROPERTY: Count MUST match for ANY valid N
    XCTAssertEqual(cards.count, randomCount)
}

// ❌ WRONG - Hardcoded value
func testCardCount_23Cards() {
    let config = FlashcardConfiguration(numberOfTerms: 23)
    XCTAssertEqual(cards.count, 23)  // Tests ONE scenario only
}
```

**WHY:**
- Tests adapt when JSON content changes (no maintenance)
- Random inputs discover edge cases automatically
- One property test replaces dozens of hardcoded tests
- Actually found critical flashcard count bug on first run

**WHEN TO USE:**
- Configuration settings (random modes, counts, belts)
- Navigation indices (random session sizes)
- Calculations (accuracy, progress, scores)
- Data flow validation (config → session → results)
- Any behavior that should hold for ALL valid inputs

**WHEN NOT TO USE:**
- Specific UI rendering (use ViewInspector)
- Animation testing (use XCUITest)
- Image display validation (use XCUITest or snapshots)

### 5. JSON-Driven Testing Validation

**Checklist before marking test complete:**

```bash
# Build succeeds
xcodebuild -project TKDojang.xcodeproj -scheme TKDojang build  # Must pass

# No hardcoded counts
grep -n "XCTAssertEqual.*count.*[0-9]" TestFile.swift  # Must return NO results

# Dynamic discovery present
grep -n "for.*in.*jsonFiles" TestFile.swift  # Must find dynamic patterns
```

**Quality Gates:**
- [ ] Build succeeds with zero compilation errors
- [ ] Tests load from production JSON (`Sources/Core/Data/Content/`)
- [ ] TestDataFactory usage justified (if any)
- [ ] No hardcoded counts
- [ ] Dynamic discovery patterns present
- [ ] Persistent storage configured (if multi-level @Model hierarchy)
- [ ] Field mappings match production exactly
- [ ] All tests pass
- [ ] Tests would catch real JSON bugs

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
├── TKDojangTests/              # 22 comprehensive test files (260 tests)
├── CLAUDE.md                   # This file - development workflow
├── README.md                   # Developer guide - architecture & how-to
├── ROADMAP.md                  # Future development plans
└── HISTORY.md                  # Complete development history
```

## Notes for Claude Code

- **This project emphasizes education and explanation** - always explain WHY architectural decisions are made
- **Comprehensive documentation is critical** - users are learning iOS development patterns
- **Best practices should be highlighted** throughout the codebase
- **Consider long-term maintainability** and scalability of all code changes
- **JSON-driven testing is the standard** - all content testing should use actual JSON files as source of truth
- **Completion requires proof** - never mark complete without successful execution evidence
- **Property-based testing** - validate behaviors, not hardcoded values
- **SwiftData safety** - always use "Fetch All → Filter In-Memory" for relationships
