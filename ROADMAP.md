# TKDojang Development Roadmap

**Last Updated:** November 19, 2025
**Current Status:** Production-ready (260/260 tests passing, WCAG 2.2 compliant)

---

## Current State Assessment

### ✅ Production Ready
- Complete multi-profile system (6 profiles)
- Comprehensive onboarding & help system (5 tours + 6 help sheets, 100% feature coverage)
- 5 content types fully implemented (Terminology, Patterns, StepSparring, LineWork, Theory, Techniques)
- **Vocabulary Builder**: 6 interactive game modes (Word Matching, Slot Builder, Template Filler, Phrase Decoder, Memory Match, Creative Sandbox)
- **Hash-Based Content Sync**: Automatic content updates without App Store releases or database migrations
- Comprehensive testing infrastructure (260/260 tests passing - 100%)
- Advanced SwiftData architecture with proven performance patterns
- Full offline functionality with local data storage
- WCAG 2.2 Level AA accessibility compliance

### 📊 Technical Health
- **✅ Zero Critical Bugs**: No blocking issues in primary user flows
- **✅ Strong Test Coverage**: 260/260 tests passing (100% - all tests stable)
- **✅ Clean Build**: Zero compilation errors, production-ready codebase
- **✅ Performance Optimized**: Startup time <2 seconds, responsive UI
- **✅ Architecture Mature**: MVVM-C + Services pattern proven at scale
- **✅ Accessibility Excellence**: VoiceOver, Dynamic Type, keyboard navigation support
- **✅ Content Pipeline**: Zero-maintenance hash-based sync enables rapid iteration on user feedback
- **✅ CI/CD Pipeline**: Xcode Cloud builds passing (pre-commit hook automation)

---


## Priority 1: E2E Testing Completion

**Status:** In Progress (1/12 tests complete)
**Timeline:** 2-3 weeks
**Priority:** HIGH - Testing foundation critical for confident development

### Current Status
- **Phase 1 (Component Tests):** ✅ 153/153 complete (100%)
- **Phase 2 (Integration Tests):** ✅ 19/23 complete (83% - functionally complete)
- **Phase 3 (E2E Tests):** 🔄 1/12 complete (8% - in progress)
- **Overall:** 173/196 tests (88%)

### Remaining E2E User Journey Tests (11 tests)

**Test File:** `TKDojangUITests/CriticalUserJourneysUITests.swift`

#### Test 1: New User Onboarding ⬜
**Flow:** Welcome → Profile Creation → Dashboard → First Action
- Verify welcome screen displays
- Complete profile creation wizard
- Navigate to dashboard
- Trigger first feature (flashcards/patterns/test)
- Validate initial data setup

#### Test 2: Flashcard Complete Workflow 🔄
**Flow:** Dashboard → Configure (23 cards, Korean) → Study → Mark Correct/Skip → Results → Dashboard
- Navigate from dashboard to flashcards
- Configure session (random card count 10-50, random mode)
- Study cards with randomized correct/skip actions
- Verify results accuracy calculation
- Confirm dashboard metrics updated
- **Status:** Created, needs iteration with actual UI

#### Test 3: Multiple Choice Complete Workflow ⬜
**Flow:** Dashboard → Configure (20 questions, 7th keup) → Answer → Review → Results → Dashboard
- Navigate to multiple choice testing
- Configure test (random question count, random belt)
- Answer questions (mix of correct/incorrect)
- Review answers and explanations
- Verify result analytics
- Confirm profile stats updated

#### Test 4: Pattern Practice Complete Workflow ⬜
**Flow:** Dashboard → Select Pattern → Practice (all 19 moves) → Complete → Results → Dashboard
- Navigate to pattern practice
- Select random pattern
- Navigate through all moves
- Complete pattern session
- Verify progress tracking
- Confirm dashboard updated

#### Test 5: Step Sparring Workflow ⬜
**Flow:** Dashboard → Select Sequence → Practice → Complete → Dashboard
- Navigate to step sparring
- Select random sequence
- Practice attack/defense/counter
- Complete sequence
- Verify mastery level update

#### Test 6: Profile Switching Workflow ⬜
**Flow:** Dashboard (Profile A) → Switch to Profile B → Verify isolated data → Switch back → Verify data restored
- Create two profiles with different belts
- Complete study session as Profile A
- Switch to Profile B
- Verify Profile B sees different content (belt-appropriate)
- Verify Profile B has no Profile A sessions
- Switch back to Profile A
- Verify Profile A data intact

#### Test 7: Theory Learning Workflow ⬜
**Flow:** Dashboard → Theory → Read content → Return → Verify progress tracked
- Navigate to theory section
- Browse belt-specific content
- Read theory sections
- Return to dashboard
- Verify reading time tracked (if applicable)

#### Test 8: Dashboard Statistics Accuracy ⬜
**Flow:** Complete flashcard session → Dashboard → Verify counts/charts update correctly
- Baseline dashboard stats
- Complete flashcard session
- Return to dashboard
- Verify flashcard count incremented
- Verify total study time updated
- Verify streak calculation correct
- Verify charts reflect new data

#### Test 9: Belt Progression Validation ⬜
**Flow:** Verify content filters correctly across belt levels
- Create profiles at different belt levels (9th keup, 5th keup, 1st keup)
- Verify each sees belt-appropriate content:
  - Terminology count increases with belt level
  - Patterns unlock progressively
  - Step sparring sequences available correctly
  - Line work exercises match belt

#### Test 10: Search Functionality ⬜
**Flow:** Search terminology/techniques → Verify results → Select → Verify detail view
- Navigate to techniques/terminology search
- Enter search query (random technique name)
- Verify search results accuracy
- Select search result
- Verify detail view displays correctly
- Test Korean and English search

#### Test 11: Navigation Resilience ⬜
**Flow:** Navigate forward 10 levels deep → Back button → Verify no crashes/state loss
- Start at dashboard
- Navigate through: Dashboard → Learning → Flashcards → Config → Session → Results → Dashboard → Profile → Edit → ... (10+ screens)
- Use back button to navigate backward
- Verify no crashes
- Verify no state loss
- Verify navigation stack integrity

#### Test 12: Multi-Session Workflow ⬜
**Flow:** Flashcards → Patterns → Test → Dashboard → Verify all sessions logged
- Complete flashcard session
- Complete pattern practice
- Complete multiple choice test
- Return to dashboard
- Verify all 3 sessions appear in history
- Verify aggregated stats correct
- Verify streak calculation considers all sessions

### Test Implementation Approach

**Key Learnings Applied:**
- ✅ Use explicit waits (`waitForExistence`) not sleeps
- ✅ Validate data-layer properties, not UI element counts
- ✅ Support multiple label variations for robustness
- ✅ Use randomization for input values (counts, modes, selections)
- ✅ Sanity check accuracy percentages and calculations

**Data Layer Validation Principle:**
For isolation tests, validate **what profiles HAVE** (belt levels, settings, progress), not **what the UI RENDERS** (card counts, list items). SwiftUI caches views aggressively.

### Success Metrics
- [ ] All 12 E2E tests passing consistently (5+ runs)
- [ ] Test execution time <30s per test (<6 minutes total)
- [ ] Zero flaky tests (100% pass rate across 20 runs)
- [ ] Critical user journeys validated end-to-end

---

## Priority 2: User Testing Feedback

**Status:** Ready to Execute
**Timeline:** 2-4 weeks (ongoing)
**Priority:** MEDIUM - Address remaining user-reported issues
**Infrastructure:** ✅ Hash-based content sync system enables rapid iteration

### Feedback Collection & Prioritization
- Collect user feedback from testing sessions
- Categorize by severity (Critical/High/Medium/Low)
- Prioritize based on frequency and impact
- Track resolution status
- **Content updates deploy automatically via hash sync** (no App Store update required)

### Categories

**UI/UX Improvements:**
- Navigation clarity enhancements
- Visual feedback improvements
- Button/control placement optimization
- Color contrast adjustments

**Feature Enhancements:**
- Requested feature variations
- Workflow optimizations
- Performance improvements
- Content additions

**Bug Fixes:**
- Edge case handling
- Error message clarity
- Data validation improvements
- Recovery mechanisms

### Process
1. **Collect:** Gather feedback from users
2. **Triage:** Categorize and prioritize
3. **Validate:** Reproduce and understand issue
4. **Implement:** Fix or enhance
5. **Test:** Validate resolution
6. **Deploy:** Release to users
7. **Verify:** Confirm issue resolved

---

## Priority 3: Image Generation & Integration

**Status:** Planned
**Timeline:** 4-6 weeks
**Priority:** MEDIUM - Transforms text-based to visually rich learning

### Overview
Transform app from text-heavy to visually rich learning experience with 300+ professional-quality martial arts images.

### Image Requirements

**Total Images:** 322
- **App Icons:** 18 sizes (1024×1024 to 20×20)
- **Pattern Diagrams:** 9 images (one per pattern)
- **Pattern Moves:** 258 images (moves across 11 patterns)
- **Step Sparring:** 54 images (attack/defense/counter sequences)
- **Branding:** 1 launch logo

### Asset Structure (Already Created)
```
TKDojang.xcassets/
├── AppIcon.appiconset/          # 18 icon sizes
├── Patterns/
│   ├── Diagrams/                # 9 pattern diagrams
│   └── Moves/                   # 258 pattern moves
├── StepSparring/                # 54 sparring images
└── Branding/                    # Launch logo
```

### Implementation Tasks

#### 1. Image Resizing & Optimization
**Batch Processing Script:**
```bash
# Resize images for 2x/3x iOS displays
# Optimize file sizes (<300KB for moves, <200KB for diagrams)
# Convert to PNG with proper transparency
# Validate aspect ratios (3:4 portrait, 4:3 landscape, 1:1 square)
```

**Quality Requirements:**
- Resolution: Meets 2x/3x specifications
- Format: PNG with transparency
- File Size: <300KB for moves, <200KB for diagrams
- Aspect Ratio: Correct for category

#### 2. JSON File Updates
**Update all pattern/step sparring JSON files:**
```json
// Before: URL references
{"image_url": "https://example.com/moves/chon-ji-1.jpg"}

// After: Asset catalog names
{"image_url": "chon-ji-1"}
```

#### 3. AsyncImage Integration
- Update all image loading to use asset catalog names
- Implement fallback for missing images
- Add loading states and error handling
- Performance testing (ensure no startup impact)

#### 4. Visual Consistency Validation
- Character consistency across pattern sets
- Belt color accuracy for each keup level
- Lighting and background uniformity
- Cultural authenticity review

### Success Metrics
- [ ] All 322 images integrated successfully
- [ ] No impact on app startup time (<2 seconds maintained)
- [ ] Memory usage within limits (<200MB for image loading)
- [ ] User feedback: "Images help learning" rating >4.5/5

---

## Priority 4: Video Content Support

**Status:** Planned
**Timeline:** 4-6 weeks
**Priority:** LOW - Enhancement for advanced learning

### Feature Requirements

#### 1. Video Infrastructure
- **Video Player Integration**: AVPlayer for inline video playback
- **Video Storage**: Local video files in app bundle or downloaded content
- **Streaming Support**: Optional streaming for larger video library
- **Offline Access**: Downloaded videos available offline

#### 2. Video Content Types

**Pattern Demonstrations:**
- Full pattern performance (real-time speed)
- Slow-motion breakdowns
- Move-by-move instruction
- Multiple camera angles

**Technique Tutorials:**
- Proper form demonstrations
- Common mistakes highlighted
- Application examples
- Training drills

**Step Sparring Sequences:**
- Attack/defense/counter demonstrations
- Partner interaction videos
- Timing and rhythm instruction

#### 3. Video Controls
- Play/Pause
- Seek bar with preview thumbnails
- Playback speed control (0.5x, 1x, 2x)
- Loop/repeat options
- Fullscreen mode

#### 4. Integration Points
- **Pattern Practice:** "Watch Demonstration" button
- **Techniques Library:** Video alongside written description
- **Step Sparring:** "See Example" for each sequence
- **Theory:** Instructional videos for concepts

### Technical Considerations
- **File Size Management**: Optimize video compression
- **Download System**: Progressive download, resume capability
- **Storage Management**: User control over downloaded videos
- **Performance**: Hardware acceleration, efficient buffering

### Success Metrics
- [ ] Video playback smooth on target devices
- [ ] Download/streaming reliable
- [ ] Storage impact acceptable (<500MB for core videos)
- [ ] User feedback: "Videos improve understanding" >4/5

---

## Priority 5: Additional Features & Enhancements

**Status:** Planned
**Timeline:** Ongoing
**Priority:** LOW - Nice-to-have enhancements

### iCloud Backup & Sync

**Requirements:**
- Profile data backup to iCloud
- Progress sync across devices
- Conflict resolution for multi-device use
- Privacy-first approach (user controls sync)

**Implementation:**
- CloudKit integration
- Selective sync (profiles, progress, settings)
- Offline-first with sync when available
- Clear sync status indicators

### Additional Enhancements

**Widget Support:**
- Home screen widgets for quick stats
- Study streak widget
- Daily goal progress widget
- Quick launch to specific features

**Shortcuts Integration:**
- Siri shortcuts for common actions
- "Start flashcard session"
- "Practice today's pattern"
- "Check my progress"

**Apple Watch Support:**
- Basic flashcard functionality
- Progress tracking
- Workout integration (pattern practice as activity)
- Glanceable stats

**iPad Optimization:**
- Enhanced layouts for larger screens
- Split view support
- Keyboard shortcuts
- External display support

### Success Metrics
- [ ] iCloud sync reliable (>99% success rate)
- [ ] Cross-device experience seamless
- [ ] Widgets provide value (daily interaction >30%)
- [ ] User adoption of extended features >40%

---

## Long-Term Vision

### Platform Expansion
- **Apple Watch App**: Standalone flashcard functionality
- **iPad Pro Optimization**: Pencil support for pattern tracing
- **macOS App**: Full-featured desktop experience
- **tvOS App**: Large-screen practice mode

### Content Expansion
- **Advanced Patterns**: Black belt patterns (Kwang-Gae through Se-Jong)
- **Multiple Styles**: ITF, WTF, ATA variations
- **International Content**: Multi-language support (Spanish, French, Korean)
- **Regional Variations**: Accommodate different teaching methodologies

### Community Features
- **Instructor Mode**: Track student progress (separate app/premium feature)
- **Dojang Integration**: School-specific content and tracking
- **Achievement Sharing**: Social sharing (privacy-controlled)
- **Leaderboards**: Optional competitive features

---

## Success Metrics Framework

### Development Quality
- **Test Coverage**: Maintain 100% test pass rate
- **Build Health**: Zero compilation errors
- **Performance**: <2s startup, responsive UI
- **Accessibility**: WCAG 2.2 Level AA compliance maintained

### User Experience
- **Onboarding Success**: >90% complete welcome flow
- **Feature Adoption**: >70% users try each major feature
- **Retention**: >60% weekly active users
- **Satisfaction**: >4/5 average rating

### Technical Excellence
- **Reliability**: <1% crash rate
- **Performance**: <200MB memory usage
- **Battery**: <5% battery drain per hour of use
- **Storage**: <500MB total app size (including videos)

---

**This roadmap balances user needs, technical excellence, and sustainable development practices. Priorities may adjust based on user feedback, technical discoveries, or market changes.**
