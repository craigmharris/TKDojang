# TKDojang - Developer Guide

**A production-ready Taekwondo learning iOS app built with SwiftUI and MVVM-C architecture**

[![Tests](https://img.shields.io/badge/tests-260%2F260%20passing-brightgreen)]()
[![Build](https://img.shields.io/badge/build-passing-brightgreen)]()
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)]()
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)]()
[![WCAG](https://img.shields.io/badge/WCAG-2.2%20Level%20AA-blue)]()

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Getting Started](#getting-started)
3. [Architecture](#architecture)
4. [Project Structure](#project-structure)
5. [Adding Content](#adding-content)
6. [Adding Features](#adding-features)
7. [Testing Strategy](#testing-strategy)
8. [Image Management](#image-management)
9. [Documentation](#documentation)

---

## Project Overview

### Current State

**Status:** Production-ready
**Version:** 1.0
**Test Coverage:** 260/260 tests passing (100%)
**Build Status:** Zero compilation errors
**Accessibility:** WCAG 2.2 Level AA compliant

### Core Features

**Multi-Profile System (6 profiles)**
- Device-local profiles with complete data isolation
- Individual progress tracking per profile
- Personalized avatars, belt levels, color themes

**Learning Content (5 types)**
- **Terminology**: 88+ Korean terms with Leitner spaced repetition
- **Patterns**: 11 ITF patterns (Chon-Ji → Choong-Moo, 320 moves)
- **Step Sparring**: 7 sequences (8th keup → 1st keup)
- **Line Work**: 10 belt levels of exercises
- **Theory & Techniques**: 67+ techniques, belt-specific theory

**Study Systems**
- Flashcard system with spaced repetition
- Multiple choice testing with smart distractor selection
- Pattern practice with move-by-move guidance
- Comprehensive progress analytics

### Technical Highlights

- **Architecture**: MVVM-C + Services pattern
- **Data**: SwiftData with proven performance patterns
- **Content**: 100% JSON-driven (zero hardcoded data)
- **Testing**: Property-based testing with 260 comprehensive tests
- **Accessibility**: Full VoiceOver, Dynamic Type, keyboard navigation
- **Performance**: <2s startup, <200MB memory usage

---

## Getting Started

### Prerequisites

- **Xcode 15.0+**
- **iOS 17.0+ SDK**
- **macOS 14.0+ (Sonoma)**
- **CocoaPods or Swift Package Manager**

### Clone & Build

```bash
# Clone repository
git clone https://github.com/yourusername/TKDojang.git
cd TKDojang

# Open project
open TKDojang.xcodeproj

# Build and run
# Press Cmd+R in Xcode
# Or use xcodebuild:
xcodebuild -project TKDojang.xcodeproj -scheme TKDojang build
```

### Running Tests

```bash
# Source test configuration
source .claude/test-config.sh

# Run all tests
xcodebuild test -project TKDojang.xcodeproj -scheme TKDojang \
  -destination "platform=iOS Simulator,id=${TEST_DEVICE_ID}"

# Run specific test file
xcodebuild test-without-building -project TKDojang.xcodeproj \
  -scheme TKDojang \
  -destination "platform=iOS Simulator,id=${TEST_DEVICE_ID}" \
  -only-testing:TKDojangTests/FlashcardComponentTests
```

### Configuration

**Test Device:** iPhone 16 (iOS 18.6) Simulator
**Device ID:** `0A227615-B123-4282-BB13-2CD2EFB0A434`

**Environment Variables:**
```bash
export TEST_DEVICE_ID="0A227615-B123-4282-BB13-2CD2EFB0A434"
export TEST_DESTINATION="platform=iOS Simulator,id=${TEST_DEVICE_ID}"
```

---

## Architecture

### MVVM-C + Services Pattern

**WHY:** Clean separation of concerns, testability, SwiftData performance optimization

```
┌─────────────────────────────────────────────┐
│              View (SwiftUI)                 │
│  - Declarative UI                           │
│  - @ObservedObject ViewModels               │
│  - No direct data access                    │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│            ViewModel                        │
│  - @Published state                         │
│  - Business logic                           │
│  - Calls Services                           │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│          Coordinator                        │
│  - Navigation logic                         │
│  - Screen flow management                   │
│  - Creates ViewModels                       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│            Services                         │
│  - Data access layer                        │
│  - SwiftData operations                     │
│  - JSON content loading                     │
│  - Business rules                           │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│      SwiftData + JSON Content               │
│  - @Model classes                           │
│  - JSON files (Sources/Core/Data/Content)   │
│  - Persistence layer                        │
└─────────────────────────────────────────────┘
```

### Key Architectural Principles

**1. Service Layer for Data Access**
```swift
// ✅ CORRECT - Use Services
class FlashcardViewModel: ObservableObject {
    private let terminologyService: TerminologyDataService

    func loadFlashcards() {
        let terms = terminologyService.getTermsFor(belt: currentBelt)
        // ...
    }
}

// ❌ WRONG - Direct SwiftData in Views
@Query var terms: [TerminologyEntry]  // Never in ViewModels/Views
```

**2. "Fetch All → Filter In-Memory" Pattern**
```swift
// ✅ SAFE - Avoids SwiftData predicate relationship bugs
let allSessions = try modelContext.fetch(FetchDescriptor<StudySession>())
return allSessions.filter { $0.userProfile.id == profileId }

// ❌ DANGEROUS - Predicate relationship navigation
let predicate = #Predicate<StudySession> { session in
    session.userProfile.id == profileId  // Causes model invalidation
}
```

**3. JSON-Driven Content**
- All learning content loaded from JSON files
- No hardcoded data in Swift code
- Content updates don't require recompilation
- Tests validate against production JSON

**4. Coordinator-Based Navigation**
- Centralized navigation logic
- Type-safe screen transitions
- Deep linking support
- State restoration

---

## Project Structure

```
TKDojang/
├── TKDojang/
│   └── Sources/
│       ├── App/
│       │   ├── TKDojangApp.swift           # App entry point
│       │   ├── ContentView.swift           # Root coordinator
│       │   └── LoadingView.swift           # Startup screen
│       │
│       ├── Features/                       # Feature modules
│       │   ├── Dashboard/                  # Home screen, stats
│       │   ├── Learning/                   # Flashcards, testing
│       │   ├── Patterns/                   # Pattern practice
│       │   ├── StepSparring/              # Step sparring sequences
│       │   ├── LineWork/                   # Line work exercises
│       │   ├── Theory/                     # Theory content
│       │   ├── Techniques/                 # Technique library
│       │   ├── Profile/                    # Profile management
│       │   └── Testing/                    # Multiple choice tests
│       │
│       └── Core/
│           ├── Data/
│           │   ├── Content/               # JSON files
│           │   │   ├── Patterns/          # Pattern JSON files
│           │   │   ├── StepSparring/      # Step sparring JSON
│           │   │   ├── LineWork/          # Line work JSON
│           │   │   ├── Theory/            # Theory JSON
│           │   │   └── Techniques/        # Technique JSON
│           │   │
│           │   ├── Models/                # SwiftData @Model classes
│           │   │   ├── UserProfile.swift
│           │   │   ├── StudySession.swift
│           │   │   ├── TerminologyEntry.swift
│           │   │   └── ...
│           │   │
│           │   └── Services/              # Data access layer
│           │       ├── ProfileService.swift
│           │       ├── TerminologyDataService.swift
│           │       ├── PatternDataService.swift
│           │       └── ...
│           │
│           ├── Coordinators/              # Navigation management
│           │   ├── MainTabCoordinator.swift
│           │   ├── LearningCoordinator.swift
│           │   └── ...
│           │
│           └── Utils/
│               ├── BeltTheme.swift        # Belt color themes
│               ├── DebugLogger.swift      # Conditional logging
│               └── Extensions/            # Swift extensions
│
├── TKDojangTests/                         # 260 comprehensive tests
│   ├── ComponentTests/                    # Component tests (153)
│   ├── IntegrationTests/                  # Integration tests (19)
│   ├── TestHelpers/                       # Test utilities
│   └── ...
│
├── TKDojangUITests/                       # E2E UI tests
│   └── CriticalUserJourneysUITests.swift
│
├── CLAUDE.md                              # Development workflow guide
├── README.md                              # This file
├── ROADMAP.md                             # Future development plans
└── HISTORY.md                             # Complete development history
```

### Feature Module Structure

Each feature follows consistent organization:

```
Features/[FeatureName]/
├── [FeatureName]Coordinator.swift         # Navigation logic
├── [FeatureName]View.swift                # Main feature view
├── [FeatureName]ViewModel.swift           # View state & logic
├── [FeatureName]Models.swift              # Feature-specific models
└── Components/                             # Reusable sub-views
    ├── [Component]View.swift
    └── ...
```

---

## Adding Content

### Content Management Overview

All learning content is JSON-driven and located in `TKDojang/Sources/Core/Data/Content/`.

### 1. Adding Terminology

**File:** `Sources/Core/Data/Content/Terminology/terminology.json`

```json
{
  "terminology": [
    {
      "id": "new_term_id",
      "korean": "새로운 용어",
      "korean_romanized": "saeroun yongeo",
      "english": "New Term",
      "definition": "Detailed explanation of the term",
      "category": "blocks",
      "belt_level_ids": ["9th_keup", "8th_keup"],
      "difficulty": "beginner",
      "related_terms": ["related_term_id"]
    }
  ]
}
```

**Steps:**
1. Add term to JSON file
2. Assign unique `id`
3. Specify `belt_level_ids` (determines when unlocked)
4. Set `category` (counting, stances, blocks, strikes, kicks, commands)
5. Run tests to validate: `xcodebuild test -only-testing:TKDojangTests/TerminologySystemTests`

### 2. Adding Patterns

**Directory:** `Sources/Core/Data/Content/Patterns/`
**File naming:** `[belt_level]_patterns.json` (e.g., `9th_keup_patterns.json`)

```json
{
  "patterns": [
    {
      "id": "new_pattern",
      "name": "New Pattern Name",
      "korean_name": "새 패턴",
      "move_count": 20,
      "belt_level_ids": ["5th_keup"],
      "meaning": "Meaning of the pattern name",
      "diagram_image_url": "new-pattern-diagram",
      "moves": [
        {
          "sequence_number": 1,
          "technique": "Walking Stance Low Block",
          "korean_technique": "걷기 서기 아래 막기",
          "direction": "Turn left",
          "hand_foot": "Left hand",
          "image_url": "new-pattern-1",
          "description": "Detailed move description",
          "key_points": ["Point 1", "Point 2"]
        }
      ]
    }
  ]
}
```

**Steps:**
1. Create JSON file in `Patterns/` subdirectory
2. Define pattern metadata (id, name, move_count, belt_level)
3. Add all moves with sequence numbers
4. Reference image assets (see [Image Management](#image-management))
5. Run tests: `xcodebuild test -only-testing:TKDojangTests/PatternPracticeComponentTests`

### 3. Adding Step Sparring Sequences

**Directory:** `Sources/Core/Data/Content/StepSparring/`
**File naming:** `[type]_sequences.json` (e.g., `three_step_sequences.json`)

```json
{
  "sequences": [
    {
      "id": "new_sequence",
      "name": "New Three-Step Sparring",
      "sequence_type": "three_step",
      "belt_level_ids": ["7th_keup"],
      "steps": [
        {
          "step_number": 1,
          "attack": {
            "technique": "Walking Stance Obverse Punch",
            "korean_name": "걷기 서기 바로 지르기",
            "hand": "Right",
            "stance": "Right Walking Stance",
            "target": "Middle Section",
            "description": "Attack description"
          },
          "defense": {
            "technique": "Walking Stance Outer Forearm Block",
            "korean_name": "걷기 서기 바깥 팔목 막기",
            "hand": "Left",
            "stance": "Left Walking Stance",
            "target": "Middle Section",
            "description": "Defense description"
          },
          "counter_attack": {
            "technique": "Walking Stance Obverse Punch",
            "korean_name": "걷기 서기 바로 지르기",
            "hand": "Right",
            "stance": "Left Walking Stance",
            "target": "Middle Section",
            "description": "Counter description"
          }
        }
      ]
    }
  ]
}
```

**Steps:**
1. Create JSON file in `StepSparring/` subdirectory
2. Define sequence metadata
3. Add steps with attack/defense/counter structure
4. Run tests: `xcodebuild test -only-testing:TKDojangTests/StepSparringComponentTests`

### 4. Adding Theory Content

**Directory:** `Sources/Core/Data/Content/Theory/`
**File naming:** `[belt_level]_theory.json` (e.g., `9th_keup_theory.json`)

```json
{
  "belt_level": "9th_keup",
  "sections": [
    {
      "id": "new_section",
      "title": "New Theory Section",
      "category": "history",
      "questions": [
        {
          "id": "new_question",
          "question_text": "What is the meaning of Taekwondo?",
          "answer": "The way of the hand and foot"
        }
      ]
    }
  ]
}
```

### 5. Adding Techniques

**File:** `Sources/Core/Data/Content/Techniques/techniques.json`

```json
{
  "categories": [
    {
      "id": "new_category",
      "name": "New Category",
      "file": "new_category.json"
    }
  ]
}
```

**Category File:** `Sources/Core/Data/Content/Techniques/new_category.json`

```json
{
  "techniques": [
    {
      "id": "new_technique",
      "name": "New Technique",
      "korean_name": "새 기술",
      "korean_romanized": "sae gisul",
      "category": "new_category",
      "description": "Detailed description",
      "belt_levels": ["9th_keup", "8th_keup"],
      "difficulty": "beginner",
      "key_points": ["Point 1", "Point 2"],
      "applications": ["Application 1"]
    }
  ]
}
```

### Content Validation

**After adding content, always:**

1. **Validate JSON syntax**
   ```bash
   python3 -m json.tool your_file.json > /dev/null
   ```

2. **Run relevant tests**
   ```bash
   xcodebuild test -only-testing:TKDojangTests/ContentLoadingTests
   ```

3. **Test in app**
   - Build and run app
   - Navigate to new content
   - Verify display and functionality

---

## Adding Features

### Feature Development Workflow

**1. Plan Architecture**
- Determine if new feature or enhancement
- Identify required models, services, views
- Review CLAUDE.md for architectural patterns

**2. Create Feature Module**

```
Sources/Features/NewFeature/
├── NewFeatureCoordinator.swift
├── NewFeatureView.swift
├── NewFeatureViewModel.swift
└── NewFeatureModels.swift
```

**3. Implement Service Layer (if needed)**

```swift
// Sources/Core/Data/Services/NewFeatureService.swift

final class NewFeatureService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // ✅ Use "Fetch All → Filter In-Memory" pattern
    func getData(for profileId: UUID) throws -> [DataModel] {
        let allData = try modelContext.fetch(FetchDescriptor<DataModel>())
        return allData.filter { $0.profileId == profileId }
    }
}
```

**4. Create SwiftData Models (if needed)**

```swift
// Sources/Core/Data/Models/NewFeatureModel.swift

import SwiftData
import Foundation

@Model
final class NewFeatureModel {
    var id: UUID
    var name: String
    var createdAt: Date

    // ⚠️ Relationships require careful handling
    @Relationship(deleteRule: .cascade)
    var relatedItems: [RelatedItem]

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.relatedItems = []
    }
}
```

**5. Write Tests FIRST**

```swift
// TKDojangTests/NewFeatureComponentTests.swift

import XCTest
@testable import TKDojang

final class NewFeatureComponentTests: XCTestCase {
    // ✅ Use JSON-driven tests when possible
    func testFeatureLoadsFromJSON() throws {
        let jsonURL = Bundle.main.url(forResource: "new_feature", withExtension: "json")
        XCTAssertNotNil(jsonURL)

        let data = try Data(contentsOf: jsonURL!)
        let decoded = try JSONDecoder().decode([NewFeatureModel].self, from: data)

        XCTAssertGreaterThan(decoded.count, 0)
    }

    // ✅ Use property-based tests for behaviors
    func testFeature_PropertyBased_BehaviorHoldsForAnyInput() throws {
        let randomValue = Int.random(in: 1...100)
        let result = service.processValue(randomValue)

        // Property: result MUST be positive for ANY input
        XCTAssertGreaterThan(result, 0)
    }
}
```

**6. Implement Feature**
- Follow MVVM-C pattern
- Use Services for data access
- Keep Views declarative
- Add accessibility identifiers

**7. Run Tests**
```bash
xcodebuild test -only-testing:TKDojangTests/NewFeatureComponentTests
```

**8. Integration**
- Add navigation in Coordinator
- Update MainTabCoordinator if needed
- Add to appropriate feature area

### Best Practices

**DO:**
- ✅ Follow MVVM-C + Services pattern
- ✅ Use JSON for content, not hardcoded data
- ✅ Write tests before implementation (TDD)
- ✅ Use "Fetch All → Filter In-Memory" for SwiftData queries
- ✅ Add accessibility identifiers (`feature-component-action`)
- ✅ Use DebugLogger, not print()
- ✅ Document WHY, not just what

**DON'T:**
- ❌ Access SwiftData directly in Views/ViewModels
- ❌ Use SwiftData predicates with relationship navigation
- ❌ Hardcode content in Swift code
- ❌ Skip tests
- ❌ Use `print()` for logging

---

## Testing Strategy

### Test Pyramid

```
         E2E (12)
       /         \
  Integration (23)
 /                 \
Component Tests (153)
```

**Total: 260 tests (260/260 passing)**

### 1. Component Tests (ViewInspector + Property-Based)

**Purpose:** Test individual components in isolation

```swift
func testFlashcard_PropertyBased_CardCountMatchesRequest() throws {
    // Property-based: test with RANDOM inputs
    let randomCount = Int.random(in: 5...50)
    let config = FlashcardConfiguration(numberOfTerms: randomCount)

    let cards = service.createFlashcards(config)

    // Property: MUST hold for ANY valid count
    XCTAssertEqual(cards.count, randomCount)
}
```

### 2. Integration Tests (Service Orchestration)

**Purpose:** Test service coordination and multi-service workflows

```swift
func testFlashcardWorkflow_ServiceOrchestration() throws {
    // Test: EnhancedTerminologyService → FlashcardService → ProfileService

    // 1. Get terms from terminology service
    let terms = terminologyService.getTerms(for: profile.beltLevel)

    // 2. Create flashcard session
    let session = flashcardService.createSession(terms: terms)

    // 3. Complete session and record to profile
    flashcardService.completeSession(session)
    profileService.recordStudySession(session, for: profile)

    // 4. Verify profile stats updated
    let updatedProfile = profileService.getProfile(id: profile.id)
    XCTAssertGreaterThan(updatedProfile.totalFlashcardsSeen, 0)
}
```

### 3. E2E Tests (XCUITest)

**Purpose:** Validate complete user journeys

```swift
func testFlashcardCompleteWorkflow() throws {
    let app = XCUIApplication()
    app.launch()

    // Navigate: Dashboard → Flashcards → Config
    app.tabBars.buttons["navigation-tab-learn"].tap()
    app.buttons["learn-flashcards-button"].tap()

    // Configure session
    let cardCount = Int.random(in: 10...50)
    // ... configure ...

    // Study cards
    // ... mark correct/skip ...

    // Verify results
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Accuracy'")).element.exists)

    // Return to dashboard, verify metrics updated
    app.buttons["return-dashboard"].tap()
    // ... verify ...
}
```

### Test Execution

```bash
# Fast component tests
xcodebuild test -only-testing:TKDojangTests/ComponentTests

# Integration tests
xcodebuild test -only-testing:TKDojangTests/IntegrationTests

# E2E tests
xcodebuild test -only-testing:TKDojangUITests

# All tests
xcodebuild test -project TKDojang.xcodeproj -scheme TKDojang
```

See [CLAUDE.md](CLAUDE.md) for detailed testing workflow and patterns.

---

## Image Management

### Image Asset Structure

Images stored in `TKDojang.xcassets/`:

```
TKDojang.xcassets/
├── AppIcon.appiconset/
├── Patterns/
│   ├── Diagrams/
│   └── Moves/
├── StepSparring/
└── Branding/
```

### Adding Images

**1. Prepare Image**

- **Format:** PNG with transparency
- **Resolution:** 2x and 3x for iOS (e.g., 600x800@2x, 900x1200@3x)
- **File Size:** <300KB for moves, <200KB for diagrams
- **Aspect Ratio:**
  - Patterns: 3:4 (portrait)
  - Diagrams: 4:3 (landscape)
  - Icons: 1:1 (square)

**2. Batch Resize Script**

```bash
#!/bin/bash
# Scripts/resize-images.sh

INPUT_DIR="$1"
OUTPUT_DIR="$2"
TARGET_WIDTH="$3"  # e.g., 600 for @2x

for img in "$INPUT_DIR"/*.{jpg,jpeg,png}; do
    filename=$(basename "$img")
    name="${filename%.*}"

    # Resize maintaining aspect ratio
    sips -Z "$TARGET_WIDTH" "$img" --out "$OUTPUT_DIR/${name}@2x.png"

    # Generate @3x (1.5x the @2x size)
    TARGET_WIDTH_3X=$((TARGET_WIDTH * 3 / 2))
    sips -Z "$TARGET_WIDTH_3X" "$img" --out "$OUTPUT_DIR/${name}@3x.png"

    # Optimize file size
    pngquant --quality=85-95 "$OUTPUT_DIR/${name}@2x.png" --force --output "$OUTPUT_DIR/${name}@2x.png"
    pngquant --quality=85-95 "$OUTPUT_DIR/${name}@3x.png" --force --output "$OUTPUT_DIR/${name}@3x.png"

    echo "Processed: $filename"
done
```

**Usage:**
```bash
./Scripts/resize-images.sh ./input-images ./TKDojang.xcassets/Patterns/Moves/ 600
```

**3. Add to Asset Catalog**

```bash
# Create imageset directory
mkdir TKDojang.xcassets/Patterns/Moves/new-pattern-1.imageset

# Copy images
cp new-pattern-1@2x.png TKDojang.xcassets/Patterns/Moves/new-pattern-1.imageset/
cp new-pattern-1@3x.png TKDojang.xcassets/Patterns/Moves/new-pattern-1.imageset/

# Create Contents.json
cat > TKDojang.xcassets/Patterns/Moves/new-pattern-1.imageset/Contents.json <<EOF
{
  "images" : [
    {
      "filename" : "new-pattern-1@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "new-pattern-1@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
```

**4. Reference in JSON**

```json
{
  "image_url": "new-pattern-1"  // Asset name without @2x/@3x or file extension
}
```

**5. Verify in App**

- Build and run
- Navigate to content using image
- Verify image loads correctly at all scale factors

### Image Optimization Tips

- Use **PNG** for transparency, **JPEG** for photos without transparency
- Run `pngquant` or `ImageOptim` to reduce file size
- Test on actual devices (2x and 3x displays)
- Lazy load images (AsyncImage handles this automatically)
- Implement image caching if needed

---

## Documentation

### Documentation Structure

| File | Purpose | Audience |
|------|---------|----------|
| **CLAUDE.md** | Development workflow, testing patterns, critical technical patterns | AI assistant & developers |
| **README.md** | Architecture guide, getting started, content management | Developers (you are here) |
| **ROADMAP.md** | Future development plans, priorities 1-7 | Product planning |
| **HISTORY.md** | Complete development history, decisions, lessons learned | Historical reference |

### Key Resources

- **Testing Workflow:** See CLAUDE.md "Testing Workflow" section
- **SwiftData Patterns:** See CLAUDE.md "Critical Technical Patterns"
- **Future Plans:** See ROADMAP.md for priorities and timelines
- **Development History:** See HISTORY.md for context on decisions

---

## Contributing

### Commit Message Format

```
type(scope): brief description

Longer description if needed.

Why this change was made.
```

**Types:** `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`

**Example:**
```
feat(flashcards): add vocabulary builder feature

Implements word-by-word phrase building to help users learn complex
5-6 word Korean terminology phrases progressively.

Addresses user feedback about difficulty with complex phrases.
```

### Pull Request Process

1. Create feature branch: `git checkout -b feature/your-feature-name`
2. Implement feature with tests
3. Run full test suite: `xcodebuild test`
4. Update documentation if needed
5. Commit with descriptive messages
6. Push and create PR
7. Ensure CI passes (all tests green)
8. Request review

---

## License

[Your License Here]

---

## Support & Contact

- **Issues:** [GitHub Issues](https://github.com/yourusername/TKDojang/issues)
- **Documentation:** See `CLAUDE.md`, `ROADMAP.md`, `HISTORY.md`
- **Email:** [Your Email]

---

**Built with SwiftUI, SwiftData, and passion for martial arts education.**
