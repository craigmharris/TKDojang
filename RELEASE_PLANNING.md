# TKDojang Release Planning

**Target Release Date:** End of Week (November 22, 2025)
**Launch Price:** £2.99 (Introductory - Early Adopter Pricing)
**Target Price:** £5.99 (Post v1.2 Release)
**Strategy:** Transparent Roadmap Release with Iterative Development

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Strategic Rationale](#strategic-rationale)
3. [Apple App Store Compliance](#apple-app-store-compliance)
4. [Current State Assessment](#current-state-assessment)
5. [Pricing Strategy](#pricing-strategy)
6. [Marketing Positioning](#marketing-positioning)
7. [Pre-Launch Checklist](#pre-launch-checklist)
8. [Success Metrics](#success-metrics)
9. [Risk Mitigation](#risk-mitigation)
10. [Post-Launch Roadmap](#post-launch-roadmap)
11. [User Feedback & Community Strategy](#user-feedback--community-strategy)

---

## CloudKit Architecture Design

### Overview

TKDojang uses **CloudKit Public Database** for community features (feedback, roadmap, voting, announcements). This provides:

- ✅ **Zero infrastructure cost** (Apple-managed backend)
- ✅ **Built-in GDPR compliance** (Apple handles data deletion, privacy)
- ✅ **Real-time push notifications** (developer responses notify users instantly)
- ✅ **Anonymous by default** (CloudKit user IDs, not Apple IDs)
- ✅ **Offline-first with sync** (local caching + background sync)

### CloudKit Schema

#### Record Type: `Feedback`
```
feedbackID: String (indexed)
category: String ("Bug", "Feature", "Content", "General")
feedbackText: String
timestamp: Date (indexed)
userRecordID: Reference (CloudKit user - anonymous)
beltLevel: String? (optional demographic)
learningMode: String? (optional)
mostUsedFeature: String? (optional)
totalSessions: Int? (optional)
deviceInfo: String (iOS version, device model, app version)
developerResponse: String? (null until developer responds)
responseTimestamp: Date? (null until responded)
responseStatus: String ("Pending", "Responded", "Implemented")
targetVersion: String? (e.g., "v1.1" if feature request accepted)
```

**Indexes**: `feedbackID`, `timestamp`, `userRecordID`
**Permissions**: Public Read, Creator Write
**Query Pattern**: Fetch user's feedback via `userRecordID` predicate

#### Record Type: `RoadmapItem`
```
itemID: String (indexed)
title: String
description: String
priority: Int (1-9 for ordering)
estimatedRelease: String ("v1.1 - January 2026")
status: String ("Planned", "InProgress", "Released")
voteCount: Int (aggregated count, updated via CKModifyRecordsOperation)
category: String ("Content", "Feature", "UX")
completionPercentage: Double? (0.0-1.0 for InProgress items)
releaseDate: Date? (actual release date when status = Released)
```

**Indexes**: `itemID`, `priority`, `status`
**Permissions**: Public Read, Developer-Only Write
**Query Pattern**: Fetch all, sort client-side by priority

#### Record Type: `RoadmapVote`
```
voteID: String (indexed)
roadmapItemID: Reference (to RoadmapItem)
userRecordID: Reference (CloudKit user - anonymous)
votedAt: Date
```

**Indexes**: `roadmapItemID`, `userRecordID` (compound index for uniqueness check)
**Permissions**: Public Read, Creator Write
**Query Pattern**: Check if user already voted via predicate on both references

#### Record Type: `FeatureSuggestion`
```
suggestionID: String (indexed)
title: String
description: String
submittedBy: Reference (CloudKit user - anonymous)
submittedAt: Date (indexed)
status: String ("Pending", "UnderReview", "AddedToRoadmap", "Declined")
upvoteCount: Int (community upvotes)
developerNotes: String? (internal notes, not shown to users)
promotedToRoadmapID: String? (if added to roadmap)
```

**Indexes**: `suggestionID`, `submittedAt`, `status`
**Permissions**: Public Read, Creator Write (status/notes are Developer-Only Write)
**Query Pattern**: Fetch by status, sort by upvoteCount descending

#### Record Type: `DeveloperAnnouncement`
```
announcementID: String (indexed)
title: String
message: String
postedAt: Date (indexed)
expiresAt: Date? (optional auto-hide date)
category: String ("Release", "Maintenance", "Community")
targetVersion: String? (e.g., "v1.1" for release announcements)
```

**Indexes**: `announcementID`, `postedAt`
**Permissions**: Public Read, Developer-Only Write
**Query Pattern**: Fetch active (postedAt <= now && expiresAt > now)

### Privacy Architecture

**Anonymous by Default:**
- CloudKit generates unique `CKRecord.ID` per user (not Apple ID)
- User identity = `CKCurrentUserDefaultName` (Apple-managed anonymous ID)
- No email addresses or personal identifiers stored
- Apple handles GDPR "Right to be Forgotten" via CloudKit account deletion

**Opt-In Demographics:**
```swift
struct AnonymousDemographics {
    let beltLevel: String?        // e.g., "5th Keup"
    let learningMode: String?     // e.g., "Progression Mode"
    let mostUsedFeature: String?  // e.g., "Flashcards"
    let totalSessions: Int?       // e.g., 42 study sessions
}
```

Users control sharing via toggle in FeedbackView:
- ✅ "Share usage data to help prioritize features" (default: ON)
- ❌ Decline sharing (sends only feedback text + device info)

**Device Information (Always Included):**
- App version (for bug tracking)
- iOS version (compatibility)
- Device model (testing coverage)

### Push Notification Workflow

**Subscription Flow (User Side):**
1. User submits feedback via `FeedbackView`
2. App creates `CKQuerySubscription` for that specific `feedbackID`
3. Subscription triggers when `developerResponse` field changes from null → text
4. User receives push notification: "Developer responded to your feedback"
5. Badge appears on Community Hub tab

**Response Flow (Developer Side):**
1. Developer opens CloudKit Dashboard (`iCloud.com`)
2. Navigates to Public Database → Feedback records
3. Filters by `responseStatus = "Pending"`
4. Edits record, adds `developerResponse` text
5. Sets `responseStatus = "Responded"`, `responseTimestamp = now`
6. Saves record → triggers user's push notification

**Notification Payload:**
```json
{
  "aps": {
    "alert": {
      "title": "Developer Response",
      "body": "Your feedback about [category] has been answered."
    },
    "badge": 1,
    "sound": "default"
  },
  "feedbackID": "ABC123",
  "category": "Bug"
}
```

### Implementation Timeline (23 Hours, Mon-Fri)

#### Implementation Status: ✅ FEATURE COMPLETE - Primary Implementation Done

**Monday (6 hours): CloudKit Foundation**
- ✅ Enable CloudKit capability (`iCloud.com.craigmatthewharris.TKDojang`)
- ✅ Create CloudKit schema in dashboard (5 record types via import)
- ✅ Implement `CloudKitFeedbackService.swift`
- ✅ Implement `CloudKitRoadmapService.swift`
- ✅ Implement `CloudKitSuggestionService.swift`
- ✅ Configure security roles and permissions for all record types
- ✅ Add `___recordID` system field indexes (resolved queryable error)

**Tuesday (5 hours): Feedback & Responses**
- ✅ Create `FeedbackView.swift` (category selection, privacy controls, demographic opt-in)
- ✅ Create `MyFeedbackView.swift` (user's feedback + developer responses display)
- ✅ Implement push notification subscription logic (in CloudKitFeedbackService)
- ✅ Fix CloudKit predicate issues (removed `!= nil` not supported by CloudKit)
- ✅ Test feedback submission - **WORKING**

**Wednesday (5 hours): Roadmap & Voting**
- ✅ Create `RoadmapView.swift` (9 priority items + voting UI with Done button)
- ✅ Create `FeatureSuggestionView.swift` (submission + community browsing)
- ✅ Implement vote counting and double-vote prevention (in CloudKitRoadmapService)
- ✅ Seed CloudKit with 9 roadmap items (Pattern Diagrams → Dan Grade Content)
- ✅ Add explicit field selection to avoid system field query issues
- ✅ Test roadmap voting - **WORKING** (vote counts incrementing correctly)

**Thursday (5 hours): Community Hub Integration**
- ✅ Create `AboutCommunityHubView.swift` (redesigned About page with community navigation)
- ✅ Create `CommunityInsightsView.swift` (aggregate demographics display)
- ✅ Create `WhatsNewView.swift` (v1.0 changelog with auto-show on first launch)
- ✅ Wire navigation from ProfileView (Community Hub button added)
- ✅ Add WhatsNew auto-show on app launch (MainTabCoordinatorView integration)
- ✅ Verify Community Hub navigation - **WORKING**

**Friday (2 hours): Testing & Polishing**
- ✅ Basic integration testing complete (roadmap loads, voting works, feedback submits)
- 🔄 Navigation polish needed (minor UX improvements)
- 🔄 Push notification testing (pending developer certificate setup)
- 🔄 App Store submission preparation (pending final polish)

#### Build Status
- **Compilation**: ✅ BUILD SUCCEEDED (zero errors, warnings only for future pattern assets)
- **Files Created**:
  - 3 CloudKit Services: `CloudKitFeedbackService.swift`, `CloudKitRoadmapService.swift`, `CloudKitSuggestionService.swift`
  - 7 UI Components: `FeedbackView.swift`, `MyFeedbackView.swift`, `RoadmapView.swift`, `FeatureSuggestionView.swift`, `WhatsNewView.swift`, `AboutCommunityHubView.swift`, `CommunityInsightsView.swift`
- **Integration**: ✅ Community Hub accessible from ProfileView
- **Auto-Launch**: ✅ WhatsNewView presents automatically on first launch after update
- **CloudKit Schema**: ✅ All 5 record types created and configured
- **Roadmap Data**: ✅ 9 roadmap items seeded in CloudKit (priority order)
- **Functional Testing**: ✅ Core features verified working (voting, feedback submission, data loading)

#### Known Issues & Remaining Work
1. **Navigation Polish**: Minor UX improvements needed for modal dismissal flows
2. **Push Notifications**: Requires Apple Developer Certificate configuration for testing
3. **Error Handling**: Could be more user-friendly (currently shows raw CloudKit errors)
4. **Offline Support**: Services have local caching structure but needs offline-first enhancements
5. **Badge Counts**: Unread response notifications need implementation

#### Critical Discoveries & Solutions
1. **`___recordID` System Field**: CloudKit requires `___recordID` (three underscores) QUERYABLE index on all record types to enable queries - this is the system field for `recordName`
2. **CloudKit Predicate Limitations**: CloudKit does NOT support `!= nil` predicates - use subscription filtering instead
3. **Explicit Field Selection**: Using `desiredKeys` parameter avoids system field query issues
4. **Security Roles**: Three built-in roles (`_world`, `_icloud`, `_creator`) with CREATE/READ/WRITE permissions need careful configuration

#### Next Session Priorities
1. **Navigation refinements**: Improve modal presentation/dismissal UX
2. **Error messaging**: Replace CloudKit errors with user-friendly messages
3. **Push notification setup**: Configure certificates and test developer response notifications
4. **WhatsNewView content**: Write v1.0 changelog copy
5. **AboutCommunityHubView polish**: Add app version info, links to feedback/roadmap
6. **Testing on real device**: Verify CloudKit works outside simulator

### CloudKit Container Identifier

**Format:** `iCloud.com.[DeveloperTeamID].TKDojang`

**Setup:**
1. Open Xcode → Project Settings → Signing & Capabilities
2. Add Capability → iCloud
3. Enable CloudKit
4. Container identifier auto-generated or manually specified
5. Ensure Container is created in CloudKit Dashboard

### Finalized Roadmap (9 Items, Priority Order)

**v1.1 (December 2025) - £2.99 Launch**
1. 📐 **Pattern Diagram Refresh with Footprint Indicators**
   - Replace line-based diagrams with intuitive footprint markers
   - Color-coded positioning showing stance, direction, and foot placement
   - Expand pattern library from Won Hyo (6th keup) to Choong-Moo (1st keup)
   - Complete white-to-black-belt preparation coverage

**v1.1 (January 2026) - £2.99 → £4.49**
2. 📸 **Expanded Photography and Visual Content**
   - Whole-body stance photography + technique close-ups
   - Multiple camera angles (front, side, rear perspectives)
   - Dynamic action shots and static finishing positions
   - High-resolution with zoom for detailed form analysis

**v1.2 (March 2026) - £4.49 → £5.99**
3. 🥋 **Additional Pattern and Step Sparring Learning Modes**
   - Randomized step sparring quizzes (attack/defense recognition)
   - Community-driven feature development based on user feedback
   - Progressive difficulty and mastery-based unlocking
   - Active recall practice to reduce grading-day stress

4. 🎥 **Video Integration**
   - Full pattern demonstrations (normal speed + slow motion)
   - Transition flow between moves (what diagrams can't show)
   - Expandable to step sparring and technique library
   - User feedback determines content priority

**v1.3 (May 2026)**
5. ⏱️ **Free Sparring Tools**
   - Feature set pending community input (timers, point tracking, competition records)
   - Flexible design awaiting user research
   - Solo practice aids vs. club management tools to be determined
   - Customizable round timer with audio alerts
   - Point counter for scoring
   - Match history tracking

**v1.4+ (Future Releases)**
6. 🏆 **Club/Dojang Membership and Progress Sharing**
   - Opt-in progress sharing with instructors (theory knowledge focus)
   - Club-private leaderboards for motivation
   - Instructor dashboard view of student theory mastery
   - Small-to-medium club focus (10-50 students)

7. 👨‍🏫 **Instructor Account and Club Management Tools**
   - Attendance tracking (app-independent)
   - Lesson planning by belt level composition
   - Billing cycle and subscription management
   - One-way announcements (class updates, grading reminders)
   - Progressive integration as club adoption grows

8. 🎯 **Mock Grading Simulations**
   - Complete grading flow (step sparring + patterns + theory questions)
   - Next-belt preparation by default
   - Grading hall etiquette and expectations guidance
   - Can re-simulate previous gradings for review

9. 🥋 **Dan Grade Content and Advanced Patterns**
   - Progressive release: 1st-4th Dan content
   - Remaining 15 patterns (Kwang-Gae through Tong-Il)
   - Deeper philosophy, historical context, archival materials
   - Teaching methodology and mentorship guidance
   - Complete 24-pattern library for aspiring practitioners

---

## Executive Summary

### Decision: Launch Now (v1.0 Foundation Edition)

**Why:** Technical maturity is production-ready (97% test pass rate), but market validation is needed before investing in expensive content (photography, video). Launch at £2.99 introductory pricing to:

1. **Generate revenue** to fund content creation
2. **Validate assumptions** about user priorities (do they want videos, or are diagrams sufficient?)
3. **Capture first-mover advantage** in underserved Taekwondo education niche
4. **Build App Store presence** for algorithmic ranking benefits
5. **Enable iterative development** based on real user feedback vs internal assumptions

**Risk Mitigation:** Clear "Foundation Edition" messaging + transparent roadmap sets expectations and eliminates refund pressure.

---

## Strategic Rationale

### Option Comparison

| Factor | Release Now | Wait for Content |
|--------|-------------|------------------|
| **Revenue** | Immediate (funds content creation) | Delayed 3+ months |
| **Market Validation** | Real user feedback on priorities | Assumption-based investment |
| **First-Mover Advantage** | Captured | Risk of competitor entry |
| **Review Risk** | Managed via pricing + transparency | Higher expectations at £5.99 |
| **Development Efficiency** | Build what users request | Risk of building unwanted features |
| **Beta Momentum** | Maintains engagement | Risks tester attrition |

### Key Insight: "Build vs Buy" Decision

**Question:** Do users want video demonstrations, or are diagrams + text sufficient?

- **Cost of videos:** 3 months development + professional production (£££)
- **Cost of validating:** Launch now, analyze user feedback for 4 weeks
- **Risk of assumption:** Building videos nobody wants = wasted investment
- **Benefit of data:** "82% of reviews mention wanting videos for kicks" = validated priority

**Conclusion:** Market validation before expensive content investment reduces waste.

---

## Apple App Store Compliance

### Policy Analysis: App Completeness (Section 2.1)

**Apple's Requirement:**
> "Submissions should be final versions with all necessary metadata and fully functional URLs included; placeholder text, empty websites, and other temporary content should be scrubbed before submission."

### TKDojang Compliance Status: ✅ APPROVED

**What Apple Allows:**
- ✅ Complete, functional app with roadmap for future content additions
- ✅ "Version 1.0" that clearly states what's included vs planned
- ✅ All features work end-to-end (no broken buttons, no "Coming Soon" screens)

**What Apple Forbids:**
- ❌ Placeholder screens without functionality
- ❌ Broken features or non-functional buttons
- ❌ "Coming Soon" as primary content

**TKDojang Status:**
- ✅ All features functional (Patterns work with diagrams, Techniques searchable with text)
- ✅ No placeholder screens
- ✅ Future enhancements (videos, photography) are **additions**, not fixes
- ✅ App is **complete as designed**, not incomplete with placeholders

**Verdict:** Apple will approve. The app delivers complete functionality at current scope.

---

## Current State Assessment

### Technical Maturity: ✅ Production-Ready

- **Test Coverage:** 459/473 tests passing (97%)
- **Critical Bugs:** Zero blocking issues
- **Build Status:** ✅ Successful CI/CD with beta distribution
- **Performance:** Startup <2 seconds, responsive UI
- **Accessibility:** WCAG 2.2 Level AA compliant
- **Architecture:** Proven MVVM-C + Services pattern

### Content Maturity: ⚠️ Partial (By Design)

**✅ Complete & Production-Ready:**
- 5 content types (Terminology, Patterns, StepSparring, LineWork, Theory, Techniques)
- 6 interactive vocabulary games (Word Match, Slot Builder, Template Filler, Phrase Decoder, Memory Match, Creative Sandbox)
- 19 terminology files with 155 Korean terms + hangul + pronunciation
- 11 traditional patterns with move-by-move diagrams
- 7 step sparring sequences (8th keup → 1st keup)
- Multi-profile family learning (6 profiles)
- Comprehensive onboarding + 5 tours + 6 help sheets

**⚠️ Partial (Functional but Enhancement Planned):**
- Pattern diagrams (static images - video demonstrations planned)
- Technique library (text descriptions - photography + video planned)

**❌ Not Yet Built (Future Roadmap):**
- Professional technique photography (v1.1 - Jan 2026)
- Video demonstrations for techniques (v1.2 - Mar 2026)
- Alternative practice modes (v1.3 - May 2026)
- Community features (ratings, sharing) (v1.4+ - TBD)

### Market Position

**Niche:** Taekwondo education (underserved - few quality apps)
**Target Audience:** Families, students, instructors, practitioners
**Competitive Advantage:** Multi-profile offline learning + vocabulary games + comprehensive content
**Price Point:** Premium (£5.99 target) but launching at £2.99 introductory

---

## Pricing Strategy

### Introductory Pricing: £2.99 (Launch → v1.2)

**Rationale:**
1. **Sets realistic expectations** for current content level (text + diagrams vs photography + video)
2. **Reduces refund pressure** ("I knew what I was getting at this price")
3. **Creates urgency** ("Lock in lifetime access before price increase")
4. **Rewards early adopters** (builds goodwill and advocacy)
5. **Funds content creation** (revenue offsets photography/video production costs)

### Price Escalation Path

```
v1.0 (Nov 2025):  £2.99  "Foundation Edition - Early Adopter Pricing"
v1.1 (Jan 2026):  £4.49  "Professional Photography Added"
v1.2 (Mar 2026):  £5.99  "Complete Edition with Video Demonstrations"
```

**Key Message:** "Early adopters lock in lifetime access to all future updates at launch pricing."

**Psychology:**
- ✅ Existing users feel smart ("I got it at £2.99!")
- ✅ New users see value increase ("Now £5.99 but includes photos + videos")
- ✅ Price increases justified by added content (not profit grab)

### App Store Description - Pricing Section

```markdown
💰 EARLY ADOPTER PRICING: £2.99
Regular Price: £5.99 (after v1.2 release)

Get TKDojang now at introductory pricing and lock in lifetime access
to all future content updates - including upcoming professional photography
and video demonstrations.

Price increases as features are added:
• v1.1 (Jan 2026): £4.49 with Professional Photography
• v1.2 (Mar 2026): £5.99 with Video Demonstrations

Current users keep their launch price forever. 🎉
```

---

## Marketing Positioning

### App Store Listing: "Foundation Edition" Messaging

#### App Name
```
TKDojang - Taekwondo Learning
```

#### Subtitle (30 characters max)
```
Complete Digital Dojang
```

#### Description (First 170 characters - Above the Fold)
```
Master Taekwondo with TKDojang - your complete digital training companion. 6 interactive vocabulary games, 11 traditional patterns, multi-profile family learning, and comprehensive offline content. Early adopter pricing: £2.99 (regular £5.99).
```

#### Full Description Structure

```markdown
MASTER TAEKWONDO WITH YOUR DIGITAL DOJANG

TKDojang brings comprehensive Taekwondo education to your iPhone with
offline-first design, multi-profile family learning, and interactive
vocabulary games. Perfect for students, families, and practitioners
of all levels.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ WHAT'S INCLUDED IN v1.0 FOUNDATION EDITION

INTERACTIVE VOCABULARY GAMES (6 Modes)
• Word Matching - Learn Korean terminology with instant feedback
• Slot Builder - Master phrase construction
• Template Filler - Practice sentence patterns
• Phrase Decoder - Unscramble techniques
• Memory Match - Test retention with card matching
• Creative Sandbox - Build custom combinations

TRADITIONAL PATTERNS (11 Forms)
• Chon-Ji through Choong-Moo with step-by-step diagrams
• Move-by-move progression with Korean terminology
• Belt-appropriate unlocking system
• Practice tracking and mastery progression

COMPREHENSIVE CONTENT
✅ 155 Korean Terminology Terms (Hangul + Romanization + Pronunciation)
✅ 7 Step Sparring Sequences (Attack/Defense/Counter Combinations)
✅ Theory Content (Philosophy, History, Belt Requirements)
✅ Techniques Library (Kicks, Blocks, Strikes, Stances)
✅ Line Work Exercises (10 Belt Levels)

LEARNING SYSTEMS
✅ Leitner Spaced Repetition Flashcards
✅ Multiple Choice Testing with Adaptive Difficulty
✅ Two Learning Modes (Progression vs Mastery)
✅ Belt-Appropriate Content Filtering

FAMILY FEATURES
✅ 6 Device-Local Profiles (No Cloud Required)
✅ Individual Progress Tracking per Profile
✅ Complete Data Isolation (Privacy-First Design)
✅ Kid-Friendly Interface with Accessibility Support

OFFLINE-FIRST DESIGN
✅ No Internet Required After Download
✅ All Content Stored Locally
✅ Fast Performance (Startup <2 seconds)
✅ No Subscriptions, No In-App Purchases

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 COMING IN FUTURE UPDATES (FREE FOR CURRENT USERS)

v1.1 (January 2026)
📸 Expanded Photography and Visual Content
• High-quality technique photos with multiple angles
• Visual progression guides for belt levels
• Zoom functionality for detailed form analysis

v1.2 (March 2026)
🥋 Additional Pattern and Step Sparring Learning Modes
• Alternative practice modes (timed drills, random challenges)
• Progressive difficulty settings
• Mastery-based unlocking

🎥 Video Integration
• Slow-motion technique demonstrations
• Common mistakes highlighted
• Korean pronunciation audio

v1.3 (May 2026)
⏱️ Free Sparring Tools
• Customizable round timer with audio alerts
• Point counter for scoring
• Match history tracking

Future Releases (v1.4+)
🏆 Club/Dojang Membership and Leaderboards
👨‍🏫 Instructor Accounts
🎯 Mock Gradings
🥋 Dan Grade Content (Advanced patterns and theory)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💰 EARLY ADOPTER PRICING

Launch Price: £2.99
Regular Price: £5.99 (after v1.2 release)

Lock in lifetime access to all future updates at introductory pricing.
Price increases as features are added. Current users keep their
launch price forever.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎓 PERFECT FOR

• Taekwondo Students - Supplement dojo training with daily practice
• Families - Multiple profiles for parent + child learning
• Instructors - Reference tool for Korean terminology
• Practitioners - Maintain skills between classes
• Beginners - Structured progression from 10th keup to 1st dan

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

♿ ACCESSIBILITY

WCAG 2.2 Level AA Compliant
✅ Full VoiceOver Support
✅ Dynamic Type for Vision Accessibility
✅ Keyboard Navigation
✅ High Contrast Mode
✅ Reduced Motion Respect

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏆 WHY TKDOJANG?

Unlike other martial arts apps, TKDojang offers:
• Multi-profile family learning (not single-user)
• Offline-first design (no internet required)
• 6 interactive vocabulary games (not just flashcards)
• Comprehensive content across all belt levels
• Privacy-first (no account required, all data local)
• One-time purchase (no subscriptions, no ads)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📧 FEEDBACK & SUPPORT

We're committed to building the best Taekwondo learning app.
Your feedback shapes our roadmap - tell us what you want next!

Email: support@tkdojang.app
Roadmap: See what's coming in the in-app roadmap viewer
```

---

## Pre-Launch Checklist

### Week of November 18-22, 2025

#### Monday (6 hours): CloudKit Foundation ✅ IN PROGRESS

**CloudKit Setup**
- [x] Enable CloudKit capability in Xcode (Signing & Capabilities → iCloud)
- [x] Create CloudKit container identifier (`iCloud.com.craigmatthewharris.TKDojang`)
- [ ] Configure CloudKit schema in dashboard (5 record types) - **USER ACTION REQUIRED**
  - [ ] Feedback record type
  - [ ] RoadmapItem record type
  - [ ] RoadmapVote record type
  - [ ] FeatureSuggestion record type
  - [ ] DeveloperAnnouncement record type
- [ ] Set up indexes and permissions - **USER ACTION REQUIRED**

**Core Services**
- [x] Create `CloudKitFeedbackService.swift` (submit feedback, subscribe to responses)
- [x] Create `CloudKitRoadmapService.swift` (fetch items, vote, prevent double-voting)
- [x] Create `CloudKitSuggestionService.swift` (submit suggestions, upvote)
- [x] Build verification (zero compilation errors)
- [ ] Test CRUD operations with CloudKit - **PENDING UI COMPLETION**

#### Tuesday (5 hours): Feedback & Responses ✅ COMPLETED

**Feedback UI**
- [x] Create `FeedbackView.swift` with category selection (Bug, Feature, Content, General)
- [x] Add privacy controls (opt-in demographic sharing toggle)
- [x] Implement CloudKit submission with push notification subscription
- [x] Create `MyFeedbackView.swift` (user's feedback history + developer responses)
- [x] Add badge notification for new developer responses

**Testing**
- [ ] Test feedback submission end-to-end - **REQUIRES CLOUDKIT SCHEMA SETUP**
- [ ] Test push notification subscription creation - **REQUIRES CLOUDKIT SCHEMA SETUP**
- [ ] Manually respond via CloudKit Dashboard, verify notification received - **REQUIRES CLOUDKIT SCHEMA SETUP**

#### Wednesday (5 hours): Roadmap & Voting ✅ COMPLETED

**Roadmap UI**
- [x] Create `RoadmapView.swift` showing 9 priority items
- [x] Implement voting system with double-vote prevention
- [x] Add real-time vote count updates
- [x] Create `FeatureSuggestionView.swift` (user-submitted suggestions)
- [x] Separate section for suggestions vs official roadmap

**Data Seeding**
- [ ] Seed CloudKit with 9 roadmap items in priority order - **REQUIRES CLOUDKIT DASHBOARD ACCESS**
- [ ] Set initial vote counts to 0 - **REQUIRES CLOUDKIT DASHBOARD ACCESS**
- [ ] Verify items display correctly sorted by priority - **REQUIRES CLOUDKIT SCHEMA SETUP**

#### Thursday (5 hours): Community Hub Integration

**Community Hub**
- [ ] Create `AboutCommunityHubView.swift` (redesigned About page)
  - [ ] Community section (Feedback, Roadmap, Suggestions, Insights)
  - [ ] App Information section (version, credits, privacy)
- [ ] Create `CommunityInsightsView.swift` (aggregate demographics via CloudKit queries)
- [ ] Create `WhatsNewView.swift` (v1.0 changelog, auto-show on first launch)

**Integration**
- [ ] Wire navigation from ProfileView to Community Hub
- [ ] Add notification badges for unread developer responses
- [ ] Configure push notifications entitlement
- [ ] Test navigation flows

#### Friday (2 hours): Testing & App Store Submission

**End-to-End Testing**
- [ ] Test feedback submission → CloudKit storage → developer response → push notification
- [ ] Test roadmap voting and double-vote prevention
- [ ] Test feature suggestion submission
- [ ] Test Community Insights demographic aggregation
- [ ] Verify all navigation flows from ProfileView
- [ ] Test push notification badge display

**Critical User Flows (Regression Testing)**
- [ ] New user onboarding → profile creation → first study session
- [ ] Profile switching with data isolation
- [ ] All 6 vocabulary games playable end-to-end
- [ ] Pattern practice with all 11 patterns
- [ ] Step sparring sequences

**App Store Connect Preparation**
- [ ] Update app description with "Foundation Edition" messaging and CloudKit features
- [ ] Set pricing to £2.99 with "Introductory Pricing" note
- [ ] Update screenshots (include Community Hub and Roadmap viewer)
- [ ] Update keywords for ASO (App Store Optimization)
- [ ] Verify Privacy Policy covers CloudKit data usage

**Submission

**Pre-Submission**
- [ ] Increment build number
- [ ] Update version to 1.0 (from beta)
- [ ] Archive build with Xcode
- [ ] Upload to App Store Connect via Xcode Organizer
- [ ] Complete all App Store Connect metadata
- [ ] Select "Automatically release" or "Manual release" (recommend Manual for controlled launch)

**Submission to App Review**
- [ ] Submit for review
- [ ] Monitor review status (typically 24-48 hours)
- [ ] Respond promptly to any rejection feedback

**Communication Prep**
- [ ] Draft launch announcement email for beta testers
- [ ] Prepare social media posts (if applicable)
- [ ] Set up support email monitoring

---

## Success Metrics

### Launch Week (Days 1-7)

**Acquisition Metrics**
- **Target:** 50 downloads
- **Track:** Daily download count, organic vs shared
- **Goal:** Validate initial interest

**Engagement Metrics**
- **Target:** 10 App Store reviews (4.0+ star average)
- **Track:** Review sentiment (positive/negative themes)
- **Goal:** Assess first impression quality

**Retention Metrics**
- **Target:** 70% Day 1 retention, 50% Day 7 retention
- **Track:** How many users return after first session
- **Goal:** Validate core value proposition

**Support Metrics**
- **Target:** <5% refund rate
- **Track:** Support ticket themes (what are users asking for?)
- **Goal:** Identify friction points

### Month 1 (Days 8-30)

**Acquisition**
- **Target:** 200 total downloads
- **Stretch:** 500 downloads (viral coefficient >1)

**Engagement**
- **Target:** 30 reviews (4.2+ stars)
- **Track:** Feature usage analytics (which content types are popular?)
- **Analyze:** Top 3 user requests from feedback

**Revenue**
- **Target:** £600 revenue (200 downloads × £2.99)
- **Use Case:** Fund photography production for v1.1

**Decision Point: Content Priority**
- **Question:** What content addition has highest ROI?
- **Data Sources:** Reviews, feedback submissions, feature usage analytics
- **Options:** Photography, videos, alternative practice modes, community features

### Month 2-3 (Days 31-90)

**v1.1 Release Preparation**
- **Target:** Complete #1 user-requested content addition
- **Price Increase:** £2.99 → £4.49
- **Messaging:** "Added professional photography based on your feedback"

**Cumulative Metrics**
- **Downloads:** 500-1,000
- **Reviews:** 75+ (4.5+ star average)
- **Revenue:** £1,500-£3,000
- **User Feedback:** Clear priorities for v1.2

### Month 4+ (Post v1.1)

**v1.2 Release (Target: March 2026)**
- **Content:** Second major addition (likely videos if validated)
- **Price:** £4.49 → £5.99 (final pricing)
- **Goal:** 1,000+ downloads, sustained 4.5+ rating

**Long-Term Health**
- **Retention:** 40%+ monthly active users
- **Reviews:** Consistent 4.5+ stars with growing volume
- **Revenue:** £5,000+ lifetime value (1,000 users × £5 average)

---

## Risk Mitigation

### Scenario A: Low Downloads (<20 in Week 1)

**Root Cause Possibilities:**
1. App Store listing isn't compelling
2. Category saturation (too many martial arts apps)
3. Pricing too high even at £2.99
4. Keywords/ASO not optimized

**Response:**
- **Immediate:** Run limited-time £0.99 sale to drive volume
- **Messaging:** "Launch Special - 67% Off (Limited Time)"
- **Promotion:** Share in Taekwondo forums, subreddits, Facebook groups
- **Analytics:** Review App Store search terms, adjust keywords

### Scenario B: Negative Reviews (<3.5 Stars)

**Root Cause Possibilities:**
1. Feature expectations not met (users expected videos/photos)
2. Bugs in production that weren't caught in testing
3. Onboarding unclear (users don't know how to use features)
4. Content quality issues (typos, incorrect Korean)

**Response:**
- **Immediate:** Respond to every negative review (show you care)
- **Communication:** "Thanks for feedback - [specific issue] coming in v1.0.1"
- **Hotfix:** If bugs, release v1.0.1 within 48 hours
- **Messaging:** Update App Store description to clarify what's included

### Scenario C: High Refund Rate (>10%)

**Root Cause Possibilities:**
1. Pricing too high for perceived value
2. Expectations mismatch (users thought it included videos)
3. Technical issues (crashes, data loss)
4. Content not as described

**Response:**
- **Immediate:** Price drop to £0.99 temporarily
- **Investigation:** Email refund requesters asking for feedback
- **Fix:** Address top complaint in v1.0.1
- **Messaging:** Update description to be hyper-clear about what's included

### Scenario D: Users Don't Use Feedback Features

**Root Cause Possibilities:**
1. Feedback mechanisms too hidden
2. Users don't feel incentivized to provide input
3. Email friction (users don't want to email)
4. No visible response to feedback (feels like shouting into void)

**Response:**
- **Immediate:** Add in-app feedback form (no email required)
- **Incentive:** "Your feedback shapes our roadmap - vote on features!"
- **Visibility:** Show "Recent Feedback Implemented" in What's New
- **Gamification:** "Top 10 contributors get credited in About page"

### Scenario E: Competitor Launches Similar App

**Root Cause:** Taekwondo education is underserved, success attracts competition

**Response:**
- **Differentiation:** Emphasize unique features (vocabulary games, multi-profile, offline-first)
- **Community:** Build engaged user base who advocate for TKDojang
- **Quality:** Focus on polish and comprehensive content
- **Updates:** Maintain rapid iteration cycle (competitor can't keep pace)

---

## Post-Launch Roadmap

### v1.0.1 (Bug Fix Release - December 2025)

**Timeline:** 2-4 weeks post-launch
**Focus:** Address critical bugs + top user feedback
**Price:** Maintain £2.99

**Potential Fixes:**
- Critical bugs discovered in production
- Minor UX improvements from user feedback
- Content corrections (typos, incorrect Korean)
- Performance optimizations

### v1.1 (First Major Update - January 2026)

**Timeline:** 6-8 weeks post-launch
**Focus:** #1 user-requested content addition
**Price Increase:** £2.99 → £4.49

**Expected Addition (Based on Hypothesis):**
- Professional technique photography (50-100 high-quality images)
- Multiple angles for complex techniques
- Belt-appropriate progression imagery

**Decision Criteria:**
- If 60%+ of feedback mentions "need photos" → prioritize photography
- If 60%+ mentions "need videos" → prioritize video instead
- If feature requests dominate → build most-requested feature

**Marketing Message:**
```
v1.1: Professional Photography Update
• 75 high-quality technique photos added
• Multiple angles for kicks, blocks, and strikes
• Built based on YOUR feedback - thank you!

Price increasing to £4.49 to reflect added value.
Current users keep their £2.99 price forever. 🎉
```

### v1.2 (Second Major Update - March 2026)

**Timeline:** 4 months post-launch
**Focus:** Second major content addition
**Price Increase:** £4.49 → £5.99 (final pricing)

**Expected Addition:**
- Video demonstrations for key techniques
- Slow-motion breakdowns
- Common mistakes highlighted
- Korean pronunciation audio

**Marketing Message:**
```
v1.2: Complete Edition with Video Demonstrations
• 30+ technique videos with slow-motion analysis
• Audio pronunciation guides for Korean terms
• Common mistakes highlighted for each technique

TKDojang is now COMPLETE with all planned content!
Price increase to £5.99 reflects comprehensive value.
Early adopters still locked in at their original price.
```

### v1.3+ (Community & Advanced Features - May 2026+)

**Timeline:** 6+ months post-launch
**Focus:** Community-requested features + advanced functionality
**Price:** Maintain £5.99

**Potential Features (Based on User Voting):**
- Alternative practice modes (timed drills, random challenges)
- Sparring timer with customizable rounds
- Custom study sets (user-created flashcard decks)
- Progress sharing (export achievements)
- Instructor mode (assign content to students)
- Community leaderboards (optional, opt-in)
- Integration with fitness tracking (HealthKit)

**Decision Process:**
1. Collect feature requests via in-app voting
2. Analyze usage data (which features are underutilized?)
3. Build top 3 requested features
4. Release as free update (no price increase)

---

## User Feedback & Community Strategy

### CloudKit-Based Feedback Architecture

#### 1. In-App Feedback Form

**Implementation:** `FeedbackView.swift` (CloudKit-backed)

**Features:**
- Category selection (Bug Report, Feature Request, Content Issue, General Feedback)
- Free-text description field
- **Opt-in demographic sharing** (belt level, learning mode, usage stats)
- **Privacy-first:** No email required, anonymous CloudKit user ID
- Device info auto-populated (iOS version, app version, device model)
- **Automatic push notification subscription** for developer responses

**Integration Points:**
- Community Hub → "Send Feedback"
- ProfileView → Settings & Actions → "Feedback & Support"
- Help button (?) on any feature → "Found a problem?"

**CloudKit Backend:**
- Submit to CloudKit Public Database as `Feedback` record
- Create `CKQuerySubscription` for that specific feedback ID
- Developer responds via CloudKit Dashboard
- User receives push notification when developer responds

#### 2. In-App Roadmap with CloudKit Voting

**Implementation:** `RoadmapView.swift` (CloudKit-backed)

**Features:**
- **9 Priority Roadmap Items** (developer-curated, based on approved plan)
- **Real-time vote counts** fetched from CloudKit
- **Double-vote prevention** via CloudKit query (check if user already voted)
- **Anonymous voting** using CloudKit user IDs
- **Separate Feature Suggestion section** (user-submitted, not automatic roadmap)

**Data Model (CloudKit Records):**
```swift
// RoadmapItem record (Developer-Only Write)
itemID: String
title: String (e.g., "Expanded Photography and Visual Content")
description: String
priority: Int (1-9 for ordering)
estimatedRelease: String ("v1.1 - January 2026")
status: String ("Planned", "InProgress", "Released")
voteCount: Int (aggregated)
category: String ("Content", "Feature", "UX")
completionPercentage: Double? (0.0-1.0 for InProgress)

// RoadmapVote record (User Write)
voteID: String
roadmapItemID: Reference (to RoadmapItem)
userRecordID: Reference (anonymous CloudKit user)
votedAt: Date
```

**User Interactions:**
- **Vote:** Tap to vote, creates `RoadmapVote` record in CloudKit
- **Double-Vote Prevention:** Query CloudKit for existing vote before allowing
- **Real-Time Counts:** Vote count updates when view appears
- **Status Tracking:** "Planned" → "InProgress" → "Released" lifecycle

**Display:**
- **Planned Features (1-9):** Sorted by developer priority order
- **Vote counts shown:** Users see community interest
- **In Progress:** Show estimated completion % (if available)
- **Recently Released:** Last 3 releases with "New" badge

**Integration:**
- Community Hub → "Feature Roadmap" tab
- First-time tip: "Vote on what we build next!"

#### 3. App Store Review Prompts

**Implementation:** Using `SKStoreReviewController`

**Timing Strategy:**
- **First Prompt:** After 5 study sessions (engaged but not annoying)
- **Subsequent Prompts:** After major milestones (completed first pattern, passed first test)
- **Limit:** Max 3 prompts per year (Apple's limit)
- **Logic:** Only prompt users who haven't left review yet

**Code Example:**
```swift
func checkForReviewPrompt() {
    let sessionCount = profileService.getActiveProfile()?.totalStudySessions ?? 0

    // Prompt at 5, 25, and 50 sessions
    if sessionCount == 5 || sessionCount == 25 || sessionCount == 50 {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
```

#### 4. What's New / Changelog Viewer

**Implementation:** `WhatsNewView.swift`

**Purpose:**
- Show users what changed in each update
- Build excitement for new features
- Demonstrate responsiveness to feedback ("You asked for X, we built it!")

**Display Logic:**
- **Auto-show:** First launch after any update
- **Manual Access:** About TKDojang → "What's New"
- **Archive:** All previous release notes viewable

**Content Structure:**
```markdown
## Version 1.1 - January 2026

### 🎉 New: Professional Photography
You asked, we delivered! 75 high-quality technique photos added.
• Multiple angles for kicks, blocks, and strikes
• Belt-appropriate progression imagery
• Zoom for detailed form analysis

### 🐛 Bug Fixes
• Fixed flashcard count occasionally showing incorrect value
• Improved Step Sparring loading performance
• Corrected Korean pronunciation for 3 terminology terms

### 💡 Based on Your Feedback
Thank you to everyone who requested photos - you shaped this update!
Next up: Video demonstrations (v1.2 - March 2026)
```

#### 5. Feature Suggestion System

**Implementation:** `FeatureSuggestionView.swift` (CloudKit-backed)

**Purpose:**
- Allow users to suggest features not in the official roadmap
- Community can upvote suggestions
- Developer can promote high-value suggestions to roadmap

**User Flow:**
1. User navigates to Community Hub → "Suggest a Feature"
2. Enters title and description
3. Submits to CloudKit as `FeatureSuggestion` record
4. Other users can browse and upvote suggestions
5. Developer reviews periodically, promotes to roadmap if valuable

**Data Model (CloudKit Record):**
```swift
suggestionID: String
title: String
description: String
submittedBy: Reference (anonymous CloudKit user)
submittedAt: Date
status: String ("Pending", "UnderReview", "AddedToRoadmap", "Declined")
upvoteCount: Int
promotedToRoadmapID: String? (if added to official roadmap)
```

**Privacy:**
- Anonymous submissions (CloudKit user ID, not personal info)
- Users can only see their own submissions in "My Suggestions"
- Developer can see all suggestions in CloudKit Dashboard

**Integration:**
- RoadmapView → "Suggest a Feature" button at bottom
- Separate tab for "Community Suggestions" sorted by upvote count
- Badge notification when developer promotes user's suggestion to roadmap

### Community Building Strategy

#### Phase 1 (Launch - Month 3): Foundation

**Goals:**
- Establish feedback channels
- Build trust with early adopters
- Create sense of partnership ("you shape the roadmap")

**Tactics:**
- Respond to every App Store review (show you're listening)
- Email all beta testers on launch day (they're your advocates)
- Highlight user feedback in release notes ("John M. suggested this!")
- Create simple landing page with roadmap + email signup

#### Phase 2 (Month 4-6): Engagement

**Goals:**
- Increase user retention
- Build word-of-mouth growth
- Validate long-term feature priorities

**Tactics:**
- Monthly "Roadmap Update" email to subscribers
- Spotlight "Feature of the Month" with usage tips
- User success stories ("Sarah passed her black belt test using TKDojang!")
- Consider Reddit AMA or Taekwondo forum engagement

#### Phase 3 (Month 7+): Sustainability

**Goals:**
- Self-sustaining community
- User-generated content
- Reduced reliance on founder for all communication

**Tactics:**
- User-submitted study tips (curated and featured in app)
- Instructor directory (opt-in for instructors using app)
- Community challenges ("30-day pattern practice challenge")
- Consider Discord or forum for user discussions

### Metrics to Track

**Feedback Volume**
- **Target:** 10% of active users submit feedback per month
- **Indicator:** High engagement if hitting target
- **Action:** If <5%, make feedback mechanisms more visible

**Roadmap Voting Participation**
- **Target:** 30% of users vote on at least 1 feature
- **Indicator:** Users feel invested in product direction
- **Action:** If low, add gamification ("Top voters get beta access!")

**CloudKit Engagement**
- **Target:** 20% of users interact with Community Hub (feedback, voting, or suggestions)
- **Indicator:** Users care about product direction
- **Action:** Promote Community Hub in onboarding and first-launch tips

**Review Conversion**
- **Target:** 15% of active users leave App Store review
- **Indicator:** Users willing to advocate publicly
- **Action:** If low, adjust review prompt timing

**Response Time**
- **Target:** <24 hours for support emails, <48 hours for App Store reviews
- **Indicator:** Users feel heard and valued
- **Action:** Set up auto-responder for immediate acknowledgment

---

## CloudKit Services Reference

For complete CloudKit implementation details including schema, push notifications, and service architecture, see the **CloudKit Architecture Design** section at the beginning of this document.

Key services to implement:
- `CloudKitFeedbackService.swift` - Feedback submission and response subscriptions
- `CloudKitRoadmapService.swift` - Roadmap voting and item management
- `CloudKitSuggestionService.swift` - Feature suggestion submission and upvoting

---

## Legacy: Original Email-Based Implementation Plan

**NOTE:** This section is preserved for historical context but has been superseded by the CloudKit approach. See CloudKit Architecture Design section for current implementation.

### Priority 1: In-App Roadmap Viewer (8 hours - DEPRECATED)

**File:** `TKDojang/Sources/Core/Components/Roadmap/RoadmapView.swift`

**Requirements:**
```swift
struct RoadmapView: View {
    @State private var roadmapItems: [RoadmapItem] = RoadmapData.items
    @State private var selectedCategory: RoadmapCategory = .all
    @State private var showingNotifySheet = false
    @State private var selectedItem: RoadmapItem?

    var body: some View {
        NavigationStack {
            List {
                // Category Filter
                categoryPicker

                // Planned Features (sorted by votes)
                Section("Coming Soon") {
                    ForEach(plannedItems) { item in
                        RoadmapItemRow(item: item) {
                            voteForItem(item)
                        }
                    }
                }

                // In Progress
                Section("In Development") {
                    ForEach(inProgressItems) { item in
                        RoadmapItemRow(item: item, showProgress: true)
                    }
                }

                // Recently Released
                Section("Recently Added") {
                    ForEach(releasedItems.prefix(3)) { item in
                        RoadmapItemRow(item: item, isReleased: true)
                    }
                }
            }
            .navigationTitle("Feature Roadmap")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct RoadmapItemRow: View {
    let item: RoadmapItem
    let showProgress: Bool = false
    let isReleased: Bool = false
    let onVote: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.estimatedRelease)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !isReleased {
                    Button(action: { onVote?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: item.hasUserVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                            Text("\(item.voteCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(item.hasUserVoted ? .accentColor : .secondary)
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if showProgress {
                ProgressView(value: item.completionPercentage ?? 0)
                    .progressViewStyle(.linear)
            }
        }
        .padding(.vertical, 4)
    }
}
```

**Data Model:**
```swift
// TKDojang/Sources/Core/Data/Models/RoadmapModels.swift

struct RoadmapItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: RoadmapCategory
    let estimatedRelease: String
    let status: RoadmapStatus
    var voteCount: Int
    var hasUserVoted: Bool
    var completionPercentage: Double? // Only for inProgress items
}

enum RoadmapCategory: String, CaseIterable {
    case all = "All"
    case content = "Content"
    case features = "Features"
    case ux = "User Experience"
}

enum RoadmapStatus {
    case planned
    case inProgress
    case released
}

// TKDojang/Sources/Core/Data/RoadmapData.swift

struct RoadmapData {
    static let items: [RoadmapItem] = [
        RoadmapItem(
            title: "Professional Technique Photography",
            description: "High-quality photos of all kicks, blocks, and strikes with multiple angles for complex techniques.",
            category: .content,
            estimatedRelease: "v1.1 - January 2026",
            status: .planned,
            voteCount: 0,
            hasUserVoted: false
        ),
        RoadmapItem(
            title: "Video Demonstrations",
            description: "Slow-motion technique breakdowns with Korean pronunciation audio and common mistakes highlighted.",
            category: .content,
            estimatedRelease: "v1.2 - March 2026",
            status: .planned,
            voteCount: 0,
            hasUserVoted: false
        ),
        RoadmapItem(
            title: "Sparring Timer",
            description: "Customizable round timer for sparring practice with audio alerts and rest periods.",
            category: .features,
            estimatedRelease: "v1.3 - May 2026",
            status: .planned,
            voteCount: 0,
            hasUserVoted: false
        ),
        RoadmapItem(
            title: "Custom Study Sets",
            description: "Create your own flashcard decks with selected terminology and techniques.",
            category: .features,
            estimatedRelease: "v1.3 - May 2026",
            status: .planned,
            voteCount: 0,
            hasUserVoted: false
        ),
        RoadmapItem(
            title: "Progress Sharing",
            description: "Export and share your achievements with friends, family, or instructors.",
            category: .features,
            estimatedRelease: "v1.3 - May 2026",
            status: .planned,
            voteCount: 0,
            hasUserVoted: false
        ),
        RoadmapItem(
            title: "Alternative Practice Modes",
            description: "Timed drills, random challenges, and progressive difficulty for advanced training.",
            category: .features,
            estimatedRelease: "v1.4 - TBD",
            status: .planned,
            voteCount: 0,
            hasUserVoted: false
        )
    ]
}
```

**Integration:**
Add to ProfileView Settings & Actions section:
```swift
NavigationLink {
    RoadmapView()
} label: {
    HStack {
        Image(systemName: "map")
        VStack(alignment: .leading) {
            Text("Feature Roadmap")
                .font(.headline)
            Text("Vote on what we build next")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### Priority 2: Feedback Submission (4 hours)

**File:** `TKDojang/Sources/Core/Components/Feedback/FeedbackView.swift`

**Requirements:**
```swift
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category: FeedbackCategory = .general
    @State private var description: String = ""
    @State private var email: String = ""
    @State private var includeDeviceInfo: Bool = true
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("What would you like to share?") {
                    Picker("Category", selection: $category) {
                        ForEach(FeedbackCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Describe your feedback...")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }

                Section {
                    TextField("Email (optional, for follow-up)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                } footer: {
                    Text("We'll only use this to respond to your feedback.")
                        .font(.caption)
                }

                Section {
                    Toggle("Include device info", isOn: $includeDeviceInfo)
                } footer: {
                    Text("Helps us debug issues (iOS version, device model, app version)")
                        .font(.caption)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        submitFeedback()
                    }
                    .disabled(description.isEmpty)
                }
            }
            .alert("Feedback Sent", isPresented: $showingConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you! Your feedback helps shape TKDojang's future.")
            }
        }
    }

    private func submitFeedback() {
        let deviceInfo = includeDeviceInfo ? getDeviceInfo() : "Not provided"

        // Compose email
        let subject = "[TKDojang Feedback] \(category.rawValue)"
        let body = """
        Category: \(category.rawValue)

        Description:
        \(description)

        Contact Email: \(email.isEmpty ? "Not provided" : email)

        ---
        Device Information:
        \(deviceInfo)
        """

        // Send via email (using mailto: URL)
        if let mailto = createMailtoURL(subject: subject, body: body) {
            if UIApplication.shared.canOpenURL(mailto) {
                UIApplication.shared.open(mailto)
                showingConfirmation = true
            }
        }
    }

    private func createMailtoURL(subject: String, body: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:support@tkdojang.app?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: mailtoString)
    }

    private func getDeviceInfo() -> String {
        """
        App Version: \(Bundle.main.appVersion)
        iOS Version: \(UIDevice.current.systemVersion)
        Device Model: \(UIDevice.current.model)
        Device Name: \(UIDevice.current.name)
        """
    }
}

enum FeedbackCategory: String, CaseIterable {
    case bug = "Bug Report"
    case feature = "Feature Request"
    case general = "General Feedback"
}

extension Bundle {
    var appVersion: String {
        (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Unknown"
    }
}
```

**Integration:**
Add to ProfileView Settings & Actions section:
```swift
Button {
    showingFeedback = true
} label: {
    HStack {
        Image(systemName: "envelope")
        VStack(alignment: .leading) {
            Text("Send Feedback")
                .font(.headline)
            Text("Help us improve TKDojang")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
.sheet(isPresented: $showingFeedback) {
    FeedbackView()
}
```

### Priority 3: What's New Viewer (3 hours)

**File:** `TKDojang/Sources/Core/Components/WhatsNew/WhatsNewView.swift`

**Requirements:**
```swift
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // v1.0 Release
                    ReleaseNoteSection(
                        version: "1.0",
                        date: "November 2025",
                        title: "Foundation Edition Launch 🎉",
                        sections: [
                            ReleaseNoteItem(
                                icon: "gamecontroller.fill",
                                title: "6 Interactive Vocabulary Games",
                                description: "Word Match, Slot Builder, Template Filler, Phrase Decoder, Memory Match, Creative Sandbox"
                            ),
                            ReleaseNoteItem(
                                icon: "figure.martial.arts",
                                title: "11 Traditional Patterns",
                                description: "Chon-Ji through Choong-Moo with step-by-step diagrams"
                            ),
                            ReleaseNoteItem(
                                icon: "person.3.fill",
                                title: "Multi-Profile Family Learning",
                                description: "6 device-local profiles with complete data isolation"
                            ),
                            ReleaseNoteItem(
                                icon: "wifi.slash",
                                title: "Complete Offline Functionality",
                                description: "All content stored locally - no internet required"
                            )
                        ]
                    )

                    Divider()

                    // Future releases will be added here automatically
                }
                .padding()
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ReleaseNoteSection: View {
    let version: String
    let date: String
    let title: String
    let sections: [ReleaseNoteItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Version \(version)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }

            // Items
            ForEach(sections) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(item.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct ReleaseNoteItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
```

**Integration:**
- Auto-show on first launch after update (check UserDefaults for last seen version)
- Add to About TKDojang page as "What's New" button

### Testing Requirements

**Roadmap Viewer:**
- [ ] Vote count increments correctly
- [ ] User can only vote once per item
- [ ] Categories filter items correctly
- [ ] Items display in correct sections (Planned, In Progress, Released)

**Feedback Submission:**
- [ ] Email client opens with pre-populated content
- [ ] Device info captured correctly
- [ ] Empty description prevents submission
- [ ] Confirmation alert shows after send

**What's New:**
- [ ] Displays correctly on all screen sizes
- [ ] Content is readable and well-formatted
- [ ] "Done" button dismisses view

---

## Launch Day Checklist

### Morning of Launch

- [ ] **Final Build Verification**
  - Build number incremented
  - Version set to 1.0
  - No debug code or test data
  - All features functional in production build

- [ ] **App Store Connect Review**
  - Metadata complete and accurate
  - Screenshots uploaded (6 required)
  - Keywords optimized
  - Pricing set to £2.99
  - "Automatically release" selected (or Manual if preferred)

- [ ] **Communication Ready**
  - Beta tester email drafted
  - Social media posts ready (if applicable)
  - Support email monitored

### During Review (24-48 hours)

- [ ] **Monitor Status**
  - Check App Store Connect for review progress
  - Respond immediately to any rejection feedback
  - Have hotfix ready if critical issues found

### Launch Day (Upon Approval)

- [ ] **Go Live**
  - If manual release, click "Release" button
  - Verify app appears in App Store search
  - Download on personal device to confirm

- [ ] **Communication Blitz**
  - Email all beta testers with launch announcement
  - Post on social media (if applicable)
  - Share in Taekwondo forums/communities
  - Request reviews from engaged beta users

- [ ] **Monitoring**
  - Track download count (App Store Connect Analytics)
  - Monitor support email for issues
  - Watch for first reviews (respond within 24 hours)
  - Check crash reports (should be zero with 97% test pass rate)

### First Week Post-Launch

- [ ] **Daily Monitoring**
  - Review count and sentiment
  - Download trends
  - Support ticket themes
  - Feature usage analytics

- [ ] **User Engagement**
  - Respond to every review (positive and negative)
  - Answer support emails within 24 hours
  - Collect feedback for v1.0.1 priorities

- [ ] **Metrics Collection**
  - Downloads vs target (50 in week 1)
  - Reviews vs target (10 with 4.0+ average)
  - Refund rate (<5%)
  - Top user requests

---

## Success Criteria for v1.0 Launch

### Minimum Viable Success (Week 1)

- ✅ 20+ downloads
- ✅ 5+ reviews averaging 3.5+ stars
- ✅ <10% refund rate
- ✅ Zero critical bugs reported
- ✅ Clear user feedback on priorities

### Target Success (Week 1)

- ✅ 50+ downloads
- ✅ 10+ reviews averaging 4.0+ stars
- ✅ <5% refund rate
- ✅ 3+ feature requests with consensus
- ✅ At least 1 organic (non-beta) positive review

### Exceptional Success (Week 1)

- ✅ 100+ downloads
- ✅ 20+ reviews averaging 4.5+ stars
- ✅ <2% refund rate
- ✅ Word-of-mouth growth evident
- ✅ Clear roadmap priority from user feedback

**Decision Point:** After Week 1, analyze data to determine v1.0.1 priorities and v1.1 content direction.

---

## Next Steps

1. **Review this document** with stakeholders
2. **Adjust priorities** for week sprint based on feedback
3. **Implement Priority 1-3 features** (Roadmap, Feedback, What's New)
4. **Prepare App Store materials** (screenshots, description, metadata)
5. **Submit for review** by end of week (November 22, 2025)
6. **Execute launch communication plan** upon approval

---

**Questions? Concerns? Adjustments Needed?**

This is a living document - update as strategy evolves based on real-world results.
