# UI Testing Implementation Notes

This document captures key lessons and architectural decisions for UI testing implementation in TKDojang.

---

## ✅ Completed Features

### StepSparringComponentTests (2025-10-17)
- **Status:** ✅ Complete - 25/25 tests passing
- **Approach:** JSON-driven property-based testing
- **Data Source:** 7 production JSON files (20 sequences)
- **Architecture:** CLAUDE.md compliant (zero TestDataFactory usage)
- **Achievement:** Successfully caught and fixed real data quality issue (non-cumulative belt progression)
- **Pattern:** Multi-level @Model hierarchy with persistent storage

### LineWorkComponentTests (2025-10-17)
- **Status:** ✅ Complete - 19/19 tests passing
- **Approach:** JSON-driven property-based testing
- **Data Source:** 10 production JSON files (10th_keup to 1st_keup)
- **Architecture:** CLAUDE.md compliant (zero TestDataFactory usage)
- **Achievement:** Simpler pattern (Codable structs, no SwiftData complexity)
- **Pattern:** Direct JSON loading with dynamic discovery

---

## Critical Lessons: Multi-Level @Model Hierarchies with JSON

### Issue: SwiftData In-Memory Storage Bugs

**Problem:**
SwiftData has confirmed bugs when loading 3+ level @Model hierarchies from JSON into in-memory test storage (`isStoredInMemoryOnly: true`).

**Symptoms:**
- Crashes during insertion (`EXC_BAD_INSTRUCTION`)
- Crashes during fetch operations
- Timeouts after save completes
- Only occurs with JSON-loaded data, not synthetic TestDataFactory data
- Only occurs with deeply nested @Model relationships (3+ levels)

**Root Cause:**
In-memory storage uses different SwiftData code paths than persistent SQLite storage. These paths have bugs with complex nested relationships created from JSON data.

### Solution: Persistent Storage Required

**Implementation (TestHelpers.swift - TestContainerFactory):**
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

**Why This Works:**
- Matches production environment exactly
- Uses same SwiftData code paths as production
- Catches SQLite-specific bugs
- UUID ensures test isolation (no cross-test contamination)
- System auto-cleanup via NSTemporaryDirectory()

### Critical Pattern: Exact Production Replication

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

---

## Property-Based Testing Requirements

### When to Use JSON-Driven Tests

✅ **MUST USE** when:
- Production JSON files exist for the feature
- Testing data loading and validation
- Validating component behavior with real content

❌ **ONLY USE TestDataFactory** when:
- Testing error handling for missing/corrupt data
- Feature has no JSON yet (temporary - document justification)
- Testing the TestDataFactory itself

### Test Pattern

**Key Principles:**
1. **Dynamic discovery** - No hardcoded counts
2. **Property validation** - Test behavior, not specific values
3. **Data quality validation** - Tests catch real JSON bugs
4. **Adaptation** - Tests should pass/fail based on data properties, not static expectations

**Example:**
```swift
// ✅ CORRECT - Property-based
func testSequences_ProgressiveAvailability() throws {
    let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

    for (index, beltId) in beltLevels.enumerated() {
        let filteredSequences = allSequences.filter { $0.applicableBeltLevelIds.contains(beltId) }
        let currentCount = filteredSequences.count

        if index > 0 {
            // PROPERTY: Higher belts should see >= sequences than lower belts
            XCTAssertGreaterThanOrEqual(currentCount, previousCount)
        }
        previousCount = currentCount
    }
}

// ❌ WRONG - Hardcoded values
func testSequences_Count() throws {
    let sequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
    XCTAssertEqual(sequences.count, 20)  // ← Breaks when JSON changes
}
```

---

## Validation Checklist for New JSON-Driven Tests

Before marking complete:

- [ ] Build succeeds with zero compilation errors
- [ ] Tests load from production JSON (`Sources/Core/Data/Content/`)
- [ ] TestDataFactory usage: `grep -c "TestDataFactory" TestFile.swift` = 0
- [ ] JSON usage confirmed: `grep -c "Bundle.main.url.*json" TestFile.swift` > 0
- [ ] No hardcoded counts: `grep "XCTAssertEqual.*count.*[0-9]" TestFile.swift` returns nothing
- [ ] Dynamic discovery patterns present
- [ ] Persistent storage configured (if multi-level @Model hierarchy)
- [ ] Field mappings match production exactly
- [ ] All tests pass
- [ ] Tests would catch real JSON bugs (verify with intentional data corruption)

---

## Component Test Coverage Status

### ✅ Complete - JSON-Driven Property-Based Tests

All features with production JSON files now have comprehensive component tests:

1. ✅ **PatternPracticeComponentTests** - 11 JSON files (Patterns)
2. ✅ **MultipleChoiceComponentTests** - Dynamic JSON loading
3. ✅ **StepSparringComponentTests** - 7 JSON files (25 tests)
4. ✅ **TheoryTechniquesDataTests** - 22 JSON files (12+ tests)
5. ✅ **LineWorkComponentTests** - 10 JSON files (19 tests)

### ✅ Complete - Justified TestDataFactory Usage

1. ✅ **FlashcardComponentTests** - UI component testing (ViewInspector)
2. ✅ **ProfileDataTests** - User-created data (30 property-based tests)

### Architecture Compliance: 100%

- **Zero CLAUDE.md violations**
- **All JSON-backed features tested with production data**
- **All TestDataFactory usage properly justified**
- **Property-based testing throughout (no hardcoded data dependencies)**

---

## Reference Implementations

### Multi-Level @Model Hierarchy (Complex)

**File:** `/Users/craig/TKDojang/TKDojangTests/StepSparringComponentTests.swift`

**Pattern:**
- 25 property-based tests across 6 categories
- Loads 7 production JSON files dynamically
- **Persistent storage for 3-level @Model hierarchy** (required)
- Explicit insertion of all @Model levels
- Exact field mappings matching production ContentLoader
- Zero hardcoded values
- 100% CLAUDE.md compliant

**Use as template for:** Features with nested SwiftData @Model relationships

### Codable Structs (Simple)

**File:** `/Users/craig/TKDojang/TKDojangTests/LineWorkComponentTests.swift`

**Pattern:**
- 19 property-based tests across 8 categories
- Loads 10 production JSON files dynamically
- **No SwiftData complexity** (pure Codable structs)
- Direct JSON loading with dynamic discovery
- Zero hardcoded values
- 100% CLAUDE.md compliant

**Use as template for:** Features using Codable structs without database persistence
