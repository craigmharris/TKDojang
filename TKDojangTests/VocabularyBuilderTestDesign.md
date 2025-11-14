# Vocabulary Builder Test Design

## Overview

Comprehensive test strategy for Vocabulary Builder feature covering all 4 game modes:
1. **Phrase Decoder** - Word reordering with real techniques
2. **Template Filler** - Fill-in-the-blank with real techniques
3. **Memory Match** - Card matching game
4. **Slot Builder** - Phrase construction

## Test Architecture

### Test Categories

1. **Component Tests** (ViewInspector)
   - Individual UI component testing
   - User interaction validation
   - State management verification
   - ~50ms execution time

2. **Service Integration Tests** (XCTest)
   - Service layer testing with real JSON data
   - Session generation validation
   - Validation logic correctness
   - ~100-200ms execution time

3. **System Tests** (XCTest + ViewInspector)
   - Complete user workflows
   - End-to-end feature validation
   - Integration between components
   - ~500ms-1s execution time

## Test Files to Create

### 1. PhraseDecoderComponentTests.swift

**Test Coverage:**

```swift
// MARK: - Configuration View Tests
func testPhraseDecoderConfig_LoadsTechniques() throws
func testPhraseDecoderConfig_DisplaysAvailableTechniques() throws
func testPhraseDecoderConfig_PhraseLengthPicker_PropertyBased() throws
func testPhraseDecoderConfig_SessionCountPicker_PropertyBased() throws
func testPhraseDecoderConfig_SessionPreview_CalculatesCorrectly() throws
func testPhraseDecoderConfig_StartButton_DisabledDuringLoad() throws
func testPhraseDecoderConfig_ErrorHandling_ShowsMessage() throws

// MARK: - Game View Tests
func testPhraseDecoderGame_InitializesWithScrambledWords() throws
func testPhraseDecoderGame_LanguageSelector_SwitchesLanguages() throws
func testPhraseDecoderGame_ReferencePhrase_ShowsAlternateLanguage() throws
func testPhraseDecoderGame_DragAndDrop_ReordersWords() throws
func testPhraseDecoderGame_DragAndDrop_SynchronizesBothLanguages() throws
func testPhraseDecoderGame_Validation_IdentifiesCorrectOrder() throws
func testPhraseDecoderGame_Validation_ShowsPartialFeedback() throws
func testPhraseDecoderGame_SelectionIndicator_ShowsOnFlippedCard() throws
func testPhraseDecoderGame_Continue_AdvancesToNextChallenge() throws
func testPhraseDecoderGame_Completion_ShowsResults() throws

// MARK: - Service Tests
func testPhraseDecoderService_LoadsTechniquesFromJSON() throws
func testPhraseDecoderService_FiltersByWordCount() throws
func testPhraseDecoderService_GeneratesSession_WithSufficientTechniques() throws
func testPhraseDecoderService_GeneratesSession_ThrowsWhenInsufficient() throws
func testPhraseDecoderService_ScramblesTechniques_DifferentFromOriginal() throws
func testPhraseDecoderService_ScramblesBothLanguages() throws
func testPhraseDecoderService_ValidatesCorrectOrder() throws
func testPhraseDecoderService_ValidatesPartialCorrectness() throws
func testPhraseDecoderService_CalculatesMetrics_PropertyBased() throws

// MARK: - Data Model Tests
func testTechniquePhraseLoader_LoadsAllTechniques() throws
func testTechniquePhraseLoader_LoadsFromBlocks() throws
func testTechniquePhraseLoader_LoadsFromKicks() throws
func testTechniquePhraseLoader_LoadsFromStrikes() throws
func testTechniquePhraseLoader_LoadsFromHandTechniques() throws
func testTechniquePhraseLoader_WordArrays_SplitCorrectly() throws
func testTechniquePhraseLoader_WordCount_CalculatesCorrectly() throws
```

**Key Test Scenarios:**

1. **Real Technique Loading**
   ```swift
   // Verify all 4 JSON files load
   let phrases = try TechniquePhraseLoader.loadAllTechniques()
   XCTAssertGreaterThan(phrases.count, 50, "Should load 50+ techniques")

   // Verify word splitting
   let technique = phrases.first!
   XCTAssertGreaterThan(technique.englishWords.count, 0)
   XCTAssertEqual(technique.englishWords.count, technique.koreanWords.count)
   ```

2. **Bilingual Display Validation**
   ```swift
   // English mode shows Korean reference
   let gameView = PhraseDecoderGameView(...)
   gameView.selectedLanguage = .english
   // Assert: Korean phrase visible, English has blanks

   // Korean mode shows English reference
   gameView.selectedLanguage = .korean
   // Assert: English phrase visible, Korean has blanks
   ```

3. **Drag-Drop Synchronization**
   ```swift
   // Moving word in English should move corresponding Korean word
   gameView.handleDrop(fromIndex: 0, toIndex: 2)
   XCTAssertEqual(gameView.currentEnglishWords[2], "Block")
   XCTAssertEqual(gameView.currentKoreanWords[2], "Makgi")
   ```

### 2. TemplateFillerComponentTests.swift

**Test Coverage:**

```swift
// MARK: - Configuration View Tests
func testTemplateFillerConfig_LoadsTechniques() throws
func testTemplateFillerConfig_PhraseLengthPicker_PropertyBased() throws
func testTemplateFillerConfig_SessionPreview_ShowsBlankCount() throws

// MARK: - Game View Tests
func testTemplateFillerGame_ShowsFullKoreanReference() throws
func testTemplateFillerGame_ShowsEnglishWithBlanks() throws
func testTemplateFillerGame_BlankSelector_ShowsChoices() throws
func testTemplateFillerGame_BlankSelector_HighlightsSelected() throws
func testTemplateFillerGame_MultipleBlankSupport_1To3Blanks() throws
func testTemplateFillerGame_Validation_AllBlanksCorrect() throws
func testTemplateFillerGame_Validation_PartialCorrect() throws

// MARK: - Service Tests
func testTemplateFillerService_LoadsTechniquesFromJSON() throws
func testTemplateFillerService_GeneratesChallenge_WithMultipleBlanks() throws
func testTemplateFillerService_PositionalDistractors_SamePosition() throws
func testTemplateFillerService_PositionalDistractors_AdaptiveCount() throws
func testTemplateFillerService_Validation_ChecksAllBlanks() throws
```

**Key Test Scenarios:**

1. **Full Korean Reference Display**
   ```swift
   let gameView = TemplateFillerGameView(...)
   let challenge = session.currentChallenge!

   // Korean phrase shown complete (no blanks)
   let koreanText = try inspection.find(text: challenge.correctKoreanPhrase)
   XCTAssertNotNil(koreanText, "Korean reference should be complete")

   // English has blanks
   XCTAssertTrue(challenge.blanks.count > 0, "English should have blanks")
   ```

2. **Multiple Blank Support**
   ```swift
   // 2-word phrases: 1 blank
   let session2 = service.generateSession(wordCount: 2, phraseCount: 10)
   XCTAssertEqual(session2.challenges[0].blanks.count, 1)

   // 4-word phrases: 2 blanks
   let session4 = service.generateSession(wordCount: 4, phraseCount: 10)
   XCTAssertEqual(session4.challenges[0].blanks.count, 2)

   // 5-word phrases: 3 blanks
   let session5 = service.generateSession(wordCount: 5, phraseCount: 10)
   XCTAssertLessThanOrEqual(session5.challenges[0].blanks.count, 3)
   ```

3. **Positional Distractor Generation**
   ```swift
   // Verify distractors come from same position in other techniques
   let challenge = service.generateChallenge(technique: technique, challengeNumber: 1)
   let blank = challenge.blanks[0]

   // All choices should be valid for this position
   for choice in blank.choices {
       // Verify choice appears at this position in some technique
       let valid = techniques.contains {
           $0.wordCount == challenge.technique.wordCount &&
           $0.englishWords[blank.position] == choice
       }
       XCTAssertTrue(valid, "\(choice) should be a valid word for position \(blank.position)")
   }
   ```

### 3. MemoryMatchComponentTests.swift

**Test Coverage:**

```swift
// MARK: - Configuration View Tests
func testMemoryMatchConfig_LoadsVocabulary() throws
func testMemoryMatchConfig_PairCountPicker_PropertyBased() throws

// MARK: - Game View Tests
func testMemoryMatchGame_GridLayout_CorrectColumns() throws
func testMemoryMatchGame_CardFlip_Animation() throws
func testMemoryMatchGame_SelectionIndicator_ShowsOnFirstCard() throws
func testMemoryMatchGame_SelectionIndicator_HidesOnSecondCard() throws
func testMemoryMatchGame_MatchDetection_SameWord() throws
func testMemoryMatchGame_TapToReset_UnmatchedCards() throws
func testMemoryMatchGame_TapToReset_InstructionChanges() throws
func testMemoryMatchGame_CardBack_ShowsHangul() throws
func testMemoryMatchGame_CardBack_ShowsBeltColor() throws
func testMemoryMatchGame_MoveCounter_Increments() throws
func testMemoryMatchGame_MatchedPairs_StayFlipped() throws

// MARK: - Service Tests
func testMemoryMatchService_GeneratesCards_EvenCount() throws
func testMemoryMatchService_GeneratesPairs_EnglishAndKorean() throws
func testMemoryMatchService_ShufflesCards() throws
func testMemoryMatchService_ValidatesMatch_SameWord() throws
func testMemoryMatchService_ValidatesNoMatch_DifferentWord() throws
```

**Key Test Scenarios:**

1. **Selection Indicator**
   ```swift
   // First card flipped shows orange glow
   gameView.handleCardTap(card1)
   XCTAssertTrue(card1.isFlipped)
   let cardView1 = MemoryCardView(card: card1, isProcessing: false, isOnlyFlipped: true)
   // Verify orange stroke visible

   // Second card flipped removes glow from first
   gameView.handleCardTap(card2)
   let cardView1Updated = MemoryCardView(card: card1, isProcessing: false, isOnlyFlipped: false)
   // Verify no orange stroke
   ```

2. **Tap to Reset**
   ```swift
   // Flip two unmatched cards
   gameView.handleCardTap(card1)
   gameView.handleCardTap(card2)
   XCTAssertTrue(gameView.isProcessing)

   // Verify instruction changes
   let instruction = try inspection.find(text: "Tap anywhere to continue")
   XCTAssertNotNil(instruction)

   // Tap screen to reset
   gameView.resetUnmatchedCards()
   XCTAssertFalse(card1.isFlipped)
   XCTAssertFalse(card2.isFlipped)
   XCTAssertFalse(gameView.isProcessing)
   ```

3. **Card Back Design**
   ```swift
   let cardView = MemoryCardView(...)
   let cardBack = cardView.cardBack

   // Verify hangul text exists
   let hangulText = try cardBack.inspect().find(text: "태권도")
   XCTAssertNotNil(hangulText)

   // Verify gradient colors (blue scheme)
   let rectangle = try cardBack.inspect().find(ViewType.RoundedRectangle.self)
   // Assert gradient contains blue tones
   ```

### 4. VocabularyBuilderSystemTests.swift

**End-to-End Workflow Tests:**

```swift
// MARK: - Complete Game Flows
func testPhraseDecoder_CompleteSession_AllPhrasesCorrect() throws
func testPhraseDecoder_CompleteSession_WithRetries() throws
func testPhraseDecoder_LanguageSwitch_MidSession() throws

func testTemplateFiller_CompleteSession_AllCorrect() throws
func testTemplateFiller_CompleteSession_MixedResults() throws

func testMemoryMatch_CompleteSession_AllPairsFound() throws
func testMemoryMatch_CompleteSession_WithResets() throws

// MARK: - Integration Tests
func testVocabularyBuilder_NavigatesToPhraseDecoder() throws
func testVocabularyBuilder_NavigatesToTemplateFiller() throws
func testVocabularyBuilder_NavigatesToMemoryMatch() throws
func testVocabularyBuilder_HelpSheet_Displays() throws

// MARK: - Data Persistence Tests
func testPhraseDecoder_ResultsSaved_ToProfile() throws
func testTemplateFiller_ResultsSaved_ToProfile() throws
func testMemoryMatch_ResultsSaved_ToProfile() throws
```

**Property-Based Test Examples:**

```swift
func testPhraseDecoder_SessionGeneration_PropertyBased() throws {
    // Test with random valid configurations
    for _ in 0..<10 {
        let wordCount = Int.random(in: 2...5)
        let phraseCount = Int.random(in: 5...15)

        let session = try service.generateSession(
            wordCount: wordCount,
            phraseCount: phraseCount
        )

        // Properties that must hold for ANY valid configuration
        XCTAssertEqual(session.wordCount, wordCount)
        XCTAssertEqual(session.totalChallenges, phraseCount)
        XCTAssertEqual(session.challenges.count, phraseCount)

        for challenge in session.challenges {
            XCTAssertEqual(challenge.correctEnglish.count, wordCount)
            XCTAssertEqual(challenge.correctKorean.count, wordCount)
            XCTAssertEqual(challenge.scrambledEnglish.count, wordCount)
            XCTAssertEqual(challenge.scrambledKorean.count, wordCount)
        }
    }
}

func testTemplateFiller_BlankGeneration_PropertyBased() throws {
    // Verify blank count adapts to phrase length
    for wordCount in 2...5 {
        let session = try service.generateSession(wordCount: wordCount, phraseCount: 10)

        for challenge in session.challenges {
            let expectedMinBlanks = 1
            let expectedMaxBlanks = min(3, wordCount - 1)

            XCTAssertGreaterThanOrEqual(challenge.blanks.count, expectedMinBlanks)
            XCTAssertLessThanOrEqual(challenge.blanks.count, expectedMaxBlanks)

            // Blanks should not be adjacent
            if challenge.blanks.count > 1 {
                let positions = challenge.blanks.map { $0.position }.sorted()
                for i in 0..<positions.count-1 {
                    XCTAssertGreaterThan(positions[i+1] - positions[i], 1,
                        "Blanks should not be adjacent")
                }
            }
        }
    }
}
```

## Test Execution Strategy

### Phase 1: Component Tests (Quick Feedback)
Run during development for immediate feedback.
```bash
xcodebuild test-without-building \
  -only-testing:TKDojangTests/PhraseDecoderComponentTests \
  -only-testing:TKDojangTests/TemplateFillerComponentTests \
  -only-testing:TKDojangTests/MemoryMatchComponentTests
```

### Phase 2: Service Integration Tests
Run before commit to validate business logic.
```bash
xcodebuild test-without-building \
  -only-testing:TKDojangTests/VocabularyBuilderSystemTests
```

### Phase 3: Full Test Suite
Run before merge to main branch.
```bash
xcodebuild test -scheme TKDojang
```

## Test Data Strategy

### Using Real JSON Data

All vocabulary builder tests should use production JSON files:

```swift
func loadRealTechniques() throws -> [TechniquePhrase] {
    // Load from actual production files
    return try TechniquePhraseLoader.loadAllTechniques()
}

func testWithRealTechniques() throws {
    let techniques = try loadRealTechniques()

    // Filter by word count for specific tests
    let threeWordTechniques = techniques.filter { $0.wordCount == 3 }

    // Use real data for test scenarios
    let service = PhraseDecoderService(modelContext: testContext)
    try service.loadTechniques()

    let session = try service.generateSession(wordCount: 3, phraseCount: 10)

    // Validate session uses real technique names
    for challenge in session.challenges {
        let matchesRealTechnique = techniques.contains {
            $0.english == challenge.technique.english
        }
        XCTAssertTrue(matchesRealTechnique,
            "Challenge should use real technique: \(challenge.technique.english)")
    }
}
```

## Accessibility Testing

### WCAG 2.2 Compliance

```swift
func testPhraseDecoder_Accessibility_Labels() throws
func testPhraseDecoder_Accessibility_Hints() throws
func testPhraseDecoder_Accessibility_Identifiers() throws

func testMemoryMatch_Accessibility_CardStates() throws
func testMemoryMatch_Accessibility_SelectionIndicator() throws

func testTemplateFiller_Accessibility_BlankSelectors() throws
func testTemplateFiller_Accessibility_KoreanReference() throws
```

## Performance Benchmarks

```swift
func testPhraseDecoder_LoadTime_Under100ms() throws
func testTemplateFiller_SessionGeneration_Under50ms() throws
func testMemoryMatch_CardShuffle_Under10ms() throws
```

## Edge Cases

```swift
// Insufficient techniques for session
func testPhraseDecoder_ThrowsWhenInsufficientTechniques() throws

// Single word techniques (if any exist)
func testTemplateFiller_HandlesMinimumWordCount() throws

// Maximum session size
func testMemoryMatch_HandlesMaximumPairCount() throws

// Empty vocabulary (should not crash)
func testVocabularyBuilder_HandlesEmptyVocabulary() throws
```

## Test Coverage Goals

- **Line Coverage**: >80%
- **Branch Coverage**: >75%
- **Function Coverage**: >90%
- **Critical Path Coverage**: 100%

## Implementation Priority

1. **High Priority** (Week 1)
   - Service integration tests with real JSON
   - Basic component tests
   - Session generation validation

2. **Medium Priority** (Week 2)
   - Complete component test coverage
   - System workflow tests
   - Property-based tests

3. **Low Priority** (Week 3)
   - Performance benchmarks
   - Edge case validation
   - Accessibility compliance

## Continuous Integration

Add to CI pipeline:
```yaml
- name: Run Vocabulary Builder Tests
  run: |
    xcodebuild test \
      -scheme TKDojang \
      -only-testing:TKDojangTests/PhraseDecoderComponentTests \
      -only-testing:TKDojangTests/TemplateFillerComponentTests \
      -only-testing:TKDojangTests/MemoryMatchComponentTests \
      -only-testing:TKDojangTests/VocabularyBuilderSystemTests
```

## Maintenance

- Review test coverage monthly
- Update tests when features change
- Add regression tests for bugs
- Keep test data synchronized with production JSON

## Success Metrics

- All tests pass before merge
- No regression bugs in vocabulary builder
- Test execution time < 5 seconds total
- Code coverage maintained > 80%
