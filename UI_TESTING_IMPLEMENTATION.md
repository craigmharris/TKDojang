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

## Next Features for JSON-Driven Property-Based Tests

### Remaining Component Tests to Implement

1. **LineWorkComponentTests** (if JSON exists)
2. **TheoryComponentTests** (if JSON exists)
3. **TechniquesComponentTests** (if JSON exists)

### Investigation Required

For each feature:
1. Check for production JSON files: `ls Sources/Core/Data/Content/[Feature]/`
2. If JSON exists → implement JSON-driven property-based tests
3. If no JSON → document justification for TestDataFactory usage
4. Follow StepSparringComponentTests as reference implementation

---

## Reference Implementation

**File:** `/Users/craig/TKDojang/TKDojangTests/ComponentTests/StepSparringComponentTests.swift`

**Pattern:**
- 25 property-based tests across 6 categories
- Loads 7 production JSON files dynamically
- Persistent storage for 3-level @Model hierarchy
- Exact field mappings matching production ContentLoader
- Zero hardcoded values
- 100% CLAUDE.md compliant

**Use as template for future multi-level @Model + JSON test implementations.**
