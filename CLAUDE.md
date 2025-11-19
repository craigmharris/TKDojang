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

### 6. Component Extraction for Tour Reuse with Accessibility

**Context:** UI components need accessibility identifiers for testing AND should be reusable in tours for 75% maintenance reduction

**Pattern:** Extract components with `isDemo` parameter and comprehensive accessibility

```swift
// ✅ CORRECT - Extracted component with accessibility and demo mode
struct CardCountPickerComponent: View {
    @Binding var numberOfTerms: Int
    let availableTermsCount: Int
    let isDemo: Bool  // Enables visual-only demo mode for tours

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Number of Cards")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button(action: { if !isDemo { numberOfTerms = max(5, numberOfTerms - 5) } }) {
                    Image(systemName: "minus.circle.fill")
                }
                .disabled(isDemo || numberOfTerms <= 5)
                .accessibilityIdentifier("flashcard-decrease-count")

                Text("\(numberOfTerms)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(minWidth: 50)
                    .accessibilityIdentifier("flashcard-count-display")
                    .accessibilityLabel("\(numberOfTerms) cards selected")

                Button(action: { if !isDemo { numberOfTerms = min(availableTermsCount, numberOfTerms + 5) } }) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(isDemo || numberOfTerms >= availableTermsCount)
                .accessibilityIdentifier("flashcard-increase-count")
            }

            Text("\(availableTermsCount) available")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("\(availableTermsCount) cards available in total")
        }
    }
}

// Production usage
CardCountPickerComponent(
    numberOfTerms: $numberOfTerms,
    availableTermsCount: availableCount,
    isDemo: false  // Full functionality
)

// Tour usage (REUSES SAME COMPONENT!)
FeatureTourStep(
    icon: "number.circle",
    title: "Card Count Selection",
    description: "Choose how many terms...",
    liveComponent: AnyView(
        CardCountPickerComponent(
            numberOfTerms: .constant(20),
            availableTermsCount: 50,
            isDemo: true  // Visual-only, all actions disabled
        )
    )
)

// ❌ WRONG - Inline UI, no accessibility, not reusable
struct FlashcardConfigurationView: View {
    var body: some View {
        HStack {
            Button("-") { numberOfTerms -= 5 }  // No accessibility ID
            Text("\(numberOfTerms)")  // No accessibility label
            Button("+") { numberOfTerms += 5 }  // No accessibility ID
        }
    }
}
```

**WHY:**
- Production components update tours automatically when UI changes
- Comprehensive accessibility IDs enable UI testing
- 75% maintenance reduction (one component, two contexts)
- Ensures tour demos match production UI exactly
- `isDemo` parameter prevents state mutations in tours

**WHEN TO USE:**
- Any configurable UI component (pickers, sliders, toggles, cards)
- Components that need to appear in tours
- All interactive elements requiring accessibility testing
- When extracting from configuration views

**ACCESSIBILITY ID PATTERN:**
```
[feature]-[component]-[element]

Examples:
- flashcard-count-display
- test-type-quick-button
- belt-scope-toggle
- pattern-help-button
```

**Component Extraction Checklist:**
- [ ] Component accepts `isDemo: Bool` parameter
- [ ] All buttons/controls check `!isDemo` before state changes
- [ ] `.disabled(isDemo)` on interactive elements
- [ ] Accessibility identifiers follow `[feature]-[component]-[element]` pattern
- [ ] Accessibility labels describe current state
- [ ] Accessibility traits added where appropriate (.isHeader, .isButton, etc.)
- [ ] Component works in both production and tour contexts
- [ ] Demo mode shows visual state without functionality

### 7. SwiftUI: Version Counter for Binding Propagation

**Context:** SwiftUI doesn't detect nested struct mutations in @Binding, causing child views to display stale state

```swift
// ❌ PROBLEM - Child views don't update
struct MemoryMatchSession {
    var cards: [MemoryCard]
    var moveCount: Int = 0
}

// In parent view:
var newSession = session
newSession.cards[index].isFlipped = true
session = newSession  // SwiftUI doesn't detect this as a change!

// Child views still see old card state because SwiftUI's change
// detection doesn't deep-compare array contents
```

```swift
// ✅ SOLUTION - Add version counter
struct MemoryMatchSession {
    var cards: [MemoryCard]
    var moveCount: Int = 0
    var version: Int = 0  // Force change detection
}

// In parent view - increment version on EVERY state mutation:
private func flipCard(_ card: MemoryCard) {
    var cards = session.cards
    cards[index].isFlipped = true

    var newSession = session
    newSession.cards = cards
    newSession.version += 1  // ← This forces SwiftUI to detect change
    session = newSession
}
```

**WHY:**
- SwiftUI compares struct values for equality to detect changes
- Nested array mutations don't change struct equality (cards array has same identity)
- Version counter changes on every mutation, forcing SwiftUI to propagate update
- All child views observing @Binding receive the new struct

**WHEN TO USE:**
- Any struct with nested collections (arrays, dictionaries) passed via @Binding
- When child views aren't updating despite parent state changes
- Game states, session data, or any mutable nested structures
- Alternative to converting to ObservableObject (keeps struct value semantics)

**CRITICAL:** Increment version in ALL functions that mutate nested state:
```swift
// EVERY mutation function needs version increment:
flipCard() → version += 1
resetCards() → version += 1
markAsMatched() → version += 1
updateScore() → version += 1
```

### 8. CloudKit: System Field Indexing Requirement

**Context:** CloudKit queries fail with "Field 'recordName' is not marked queryable" error despite correct schema definition

```swift
// Query fails with system field error
let query = CKQuery(recordType: "RoadmapItem", predicate: NSPredicate(value: true))
let results = try await publicDatabase.records(matching: query)
// Error: Field 'recordName' is not marked queryable
```

**Solution:** Add `___recordID` (three underscores) QUERYABLE index in CloudKit Console:

1. Navigate to: **Schema → Indexes** (in CloudKit Dashboard)
2. Select record type (e.g., RoadmapItem)
3. Click **"+ Add Index"**
4. **Field Name**: `___recordID` (system field for recordName)
5. **Index Type**: QUERYABLE
6. **Save**

**WHY:**
- `___recordID` is CloudKit's internal system field name for `recordName`
- Schema imports don't automatically create system field indexes
- CloudKit uses system fields internally for result ordering/pagination
- Without this index, ALL queries fail (not just sorted queries)

**WHEN TO USE:** Add `___recordID` QUERYABLE index to EVERY CloudKit record type that will be queried

**Alternative:** Explicit field selection avoids system field issues:
```swift
let desiredKeys = ["itemID", "title", "description", "priority", "status"]
let results = try await publicDatabase.records(matching: query, desiredKeys: desiredKeys)
```

### 9. CloudKit: Predicate Limitations and Security Roles

**Context:** CloudKit has predicate syntax limitations and requires careful permission configuration

**Predicate Limitations:**
```swift
// ❌ NOT SUPPORTED - CloudKit rejects != nil predicates
let predicate = NSPredicate(format: "developerResponse != nil")

// ✅ CORRECT - Subscribe to all updates, filter in notification handler
let predicate = NSPredicate(format: "feedbackID == %@", feedbackID)
let subscription = CKQuerySubscription(
    recordType: "Feedback",
    predicate: predicate,
    options: [.firesOnRecordUpdate] // Only updates, not creation
)
```

**Security Roles (Built-in):**
- `_world`: Unauthenticated users (read-only public data)
- `_icloud`: Authenticated iCloud users (can CREATE records)
- `_creator`: User who created a specific record (can WRITE their own records)

**Permission Pattern for User-Generated Content:**
```
Record Type: Feedback / FeatureSuggestion / RoadmapVote

_world:
  Create: ☐
  Read: ✓
  Write: ☐

_icloud:
  Create: ✓  (any signed-in user can submit)
  Read: ✓
  Write: ☐  (can't edit others' records)

_creator:
  Create: ☐  (redundant with _icloud)
  Read: ✓
  Write: ✓  (can only edit their own records)
```

**Permission Pattern for Developer-Controlled Content:**
```
Record Type: RoadmapItem / DeveloperAnnouncement

_world:
  Create: ☐
  Read: ✓
  Write: ☐

_icloud:
  Create: ☐  (users can't create roadmap items)
  Read: ✓
  Write: ☐

_creator:
  Create: ☐  (developer creates manually)
  Read: ✓
  Write: ✓  (only creator/developer can edit)
```

**WHY:**
- CloudKit predicates don't support NULL checks with `!= nil` syntax
- Security roles use CREATE/READ/WRITE separately (not just read/write)
- `_creator` automatically grants permissions to whoever created each record
- Proper permissions prevent users from editing others' submissions

**WHEN TO USE:**
- Always configure security roles in CloudKit Dashboard before deployment
- Use `_icloud` CREATE permission for user-submitted content
- Use `_creator` WRITE permission to allow users to edit only their own records

### 10. Data Quality: Levenshtein Distance Spelling Consistency

**Context:** When managing large JSON datasets with romanized non-English terms, spelling inconsistencies accumulate over time through manual entry and multiple contributors

```python
# ✅ CORRECT - Fuzzy similarity clustering approach
import json
from collections import Counter, defaultdict

def levenshtein_distance(s1, s2):
    """Calculate edit distance between two strings."""
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)

    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row

    return previous_row[-1]

def find_spelling_clusters(words, word_frequencies):
    """Cluster similar words to identify potential misspellings."""
    similar_clusters = []
    processed = set()

    for word1 in sorted(words):
        if word1 in processed:
            continue

        cluster = [word1]
        for word2 in sorted(words):
            if word1 == word2 or word2 in processed:
                continue

            # Only compare words of similar length (±2 characters)
            if abs(len(word1) - len(word2)) > 2:
                continue

            distance = levenshtein_distance(word1.lower(), word2.lower())
            max_distance = 1 if len(word1) <= 4 else 2

            if distance <= max_distance and distance > 0:
                cluster.append(word2)
                processed.add(word2)

        if len(cluster) > 1:
            similar_clusters.append(cluster)
            processed.add(word1)

    # Sort by frequency - most common word likely correct
    similar_clusters.sort(key=lambda c: max(word_frequencies[w] for w in c), reverse=True)

    return similar_clusters
```

```python
# ❌ WRONG - Manual review or regex pattern matching
def check_spelling(word):
    # Brittle - only catches exact known typos
    typos = {"Bakuro": "Bakaero", "Anaero": "Anuro"}
    return typos.get(word, word)

# ❌ WRONG - Hardcoded pattern lists
if "Joomok" in text:  # Misses variants, doesn't scale
    text = text.replace("Joomok", "Joomuk")
```

**WHY:**
- Levenshtein distance finds ALL similar variants automatically (Joomok/Joomuk, Bakkat/Bakat, Mirro/Miro)
- Frequency analysis identifies correct spelling (common word likely correct, singleton likely typo)
- Scales to thousands of terms without manual pattern maintenance
- Catches typos that human reviewers miss (edit distance 1-2 characters)
- Provides evidence-based correction recommendations with usage counts

**WHEN TO USE:**
- After bulk content imports (CSV, external data sources)
- Before major releases to ensure data quality
- When adding 50+ new terms to vocabulary/technique databases
- After contributions from multiple sources
- Anytime you see inconsistent romanizations (Anaero vs Anuro vs Aaero)

**IMPLEMENTATION CHECKLIST:**
- [ ] Extract all romanized words from all JSON files (vocabulary + techniques + flashcards)
- [ ] Count frequency of each word across all sources
- [ ] Run Levenshtein clustering (edit distance ≤ 1 for short words, ≤ 2 for long words)
- [ ] Flag singleton words near common words (likely typos)
- [ ] Manual review of clusters (standardize to most frequent variant)
- [ ] Apply corrections across all files, verify build succeeds
- [ ] Re-run clustering to confirm zero remaining inconsistencies

**REAL-WORLD RESULTS (TKDojang Vocabulary Builder):**
- Analyzed 166 unique romanized Korean words across 70 JSON files
- Found 35 spelling inconsistency clusters
- Corrected 14 spelling variants (Joomok→Joomuk, Bakkat→Bakat, etc.)
- Zero manual regex patterns needed - algorithm found all variants automatically

### 11. Content Versioning: Hash-Based Synchronization System

**Context:** JSON content updates need to propagate to all user devices automatically without manual version tracking or developer intervention

**System Architecture:**

```swift
// ContentVersion.swift - Auto-generated by build script
struct ContentVersion {
    static let terminologyHash = "a37d7a1f7b869a13..."
    static let patternsHash = "388011ac4434957a..."
    static let stepSparringHash = "fb3b1da4f0c3222a..."
    static let beltSystemHash = "b4bcf561dd232a29..."
    static let lineWorkHash = "4c1b612d7c342cae..."
    static let theoryHash = "3e3d8c7a19b1e56b..."
    static let generatedAt = "2025-11-18T23:23:10Z"
}

// DataManager.swift - Automatic sync on startup
func setupInitialData() async {
    let terminologyChanged = hasTerminologyContentChanged()  // Compares hashes
    let patternsChanged = hasPatternsContentChanged()

    if terminologyChanged {
        await ensureTerminologyIsSynchronized(forceReload: true)  // Clears & reloads
    }

    if patternsChanged {
        await ensurePatternsAreSynchronized(forceReload: true)
    }
}
```

**Build Script (Scripts/generate-content-hashes.sh):**
```bash
# Uses shell globbing instead of find to avoid Xcode sandbox issues
hash_json_files() {
    local dir="$1"
    local pattern="$2"

    shopt -s nullglob
    local files=("$dir"/$pattern)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        echo "00000000"
        return
    fi

    cat "${files[@]}" | shasum -a 256 | cut -d' ' -f1
}

PATTERNS_HASH=$(hash_json_files "$CONTENT_BASE/Patterns" "*_patterns.json")
```

**WHY:**
- **Zero developer maintenance**: No manual version tracking, no human error in forgetting to increment versions
- **Automatic propagation**: Content updates reach all users on next app launch without App Store update
- **Granular detection**: Separate hashes for each content type (terminology, patterns, etc.) enable targeted reloads
- **Build-time generation**: Production builds (Archive/TestFlight) auto-generate hashes, ensuring they're always current

**WHEN TO USE:**
- **All JSON content additions/modifications**: Patterns, terminology, step sparring, theory, line work, techniques
- **Before every development build with JSON changes**: Run `bash Scripts/update-content-hashes-dev.sh`
- **Archive builds**: Automatic - no intervention needed

**Development Workflow:**
```bash
# After modifying JSON content:
bash Scripts/update-content-hashes-dev.sh
xcodebuild build
```

**Production Workflow:**
- Archive build automatically runs hash generation script (sandbox disabled for install builds)
- Users download update → app launches → setupInitialData() compares hashes → changed content reloads
- **No database version management needed**

**Critical Implementation Details:**
1. **Xcode Sandbox Limitation**: Development builds can't auto-generate hashes (sandbox blocks file access)
2. **"For install builds only"**: Build phase must have `runOnlyForDeploymentPostprocessing = 1`
3. **Shell globbing not find**: Avoid `find` command - use bash glob patterns to prevent sandbox violations
4. **Inline script**: Script embedded in project.pbxproj, not external file (sandbox blocks reading external scripts)
5. **Belt level preservation**: Content sync NEVER deletes BeltLevel records (preserves user progress foreign keys)

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
