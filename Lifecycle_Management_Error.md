# SwiftUI View Lifecycle Management Error

**Date:** September 2, 2025  
**Status:** CRITICAL - App experiencing continuous view recreation causing instability  
**Commit:** a3f35ac (clean baseline after seeding logic removal)

## Problem Summary

The TKDojang iOS app is experiencing **massive SwiftUI view recreation loops** during normal app operation, causing:
- ProfileSwitcher instances proliferating uncontrollably (12+ instances during startup)
- Continuous WindowGroup rebuilding (`🏗️ Building WindowGroup scene...` every few seconds)
- SwiftData model invalidation crashes (p28/p32) when orphaned objects held by dying views
- App instability during navigation and profile switching

## Critical Evidence from DEBUG Logs

### 1. WindowGroup Recreation Pattern
```
🏗️ Building WindowGroup scene... - 15:34:53
🏗️ Building WindowGroup scene... - 15:34:54  
🏗️ Building WindowGroup scene... - 15:35:20 [26 seconds later!]
🏗️ Building WindowGroup scene... - 15:35:29 [9 seconds later!]
```
**ABNORMAL:** WindowGroup should only build once at app launch, not continuously.

### 2. ProfileSwitcher Instance Proliferation
```
🔄 ProfileSwitcher: Rendering menu [Instance: 726873F0]
🔄 ProfileSwitcher: Rendering menu [Instance: 5CD612BF] 
🔄 ProfileSwitcher: Rendering menu [Instance: DD6A9B11]
🔄 ProfileSwitcher: Rendering menu [Instance: 7FB9A466]
🔄 ProfileSwitcher: Rendering menu [Instance: E5A6F6DA]
🔄 ProfileSwitcher: Rendering menu [Instance: E7E2F3F9]
🔄 ProfileSwitcher: Rendering menu [Instance: 847224DE]
... [12+ unique instances during single app session]
```
**ABNORMAL:** Should have 1-2 instances max (one per tab), not 12+.

### 3. Profile Count Cycling Pattern
```
🔄 ProfileSwitcher: Rendering menu with 0 profiles, active: none [Instance: 5CD612BF]
🎬 ProfileSwitcher: onAppear triggered [Instance: 5CD612BF]
🔍 ProfileSwitcher: loadProfiles() called [Instance: 5CD612BF]
🔄 ProfileSwitcher: Loaded 6 profiles, active: Craig [Instance: 5CD612BF]
🔄 ProfileSwitcher: Rendering menu with 6 profiles, active: Craig [Instance: 5CD612BF]
🔄 ProfileSwitcher: Rendering menu with 0 profiles, active: none [Instance: DD6A9B11]  // NEW INSTANCE!
```
**ROOT CAUSE:** Each new instance starts with empty state (`0 profiles`) before loading data.

## Architecture Impact

### Affected Components
- **ProfileSwitcher.swift** - 12+ instances created/destroyed continuously
- **MainTabCoordinatorView.swift** - Rebuilding causing tab state loss
- **DataServices** - Repeated initialization triggering objectWillChange storms
- **SwiftData Context** - Model objects invalidated when holding views destroyed

### SwiftData Corruption Connection
The p28/p32 crashes are **secondary symptoms** of this view lifecycle issue:
1. Views holding UserPatternProgress objects get destroyed unexpectedly
2. SwiftData objects become orphaned/invalidated
3. When new views try to access these objects → fatal crashes
4. Corrupted pattern relationships (p28/p32) amplify the problem

## Current Feature State

### ✅ Working (Baseline Features)
- Basic app navigation (when stable)
- Pattern and Step Sparring content loading
- Profile display and basic switching
- Content synchronization from JSON

### ❌ Disabled to Prevent Crashes
```swift
// ProfileService.swift:93,146,209,304 - Auto-backup disabled
// exportService?.autoBackupProfile(profile)

// ProfileService.swift:408,484 - Queries return empty arrays  
func getStudySessions(for profile: UserProfile) throws -> [StudySession] {
    return [] // TEMPORARY: Return empty array to prevent freezes
}

func getGradingHistory(for profile: UserProfile) throws -> [GradingRecord] {
    return [] // TEMPORARY: Return empty array to prevent freezes  
}

// ProfileExportService.swift:411 - Step sparring export disabled
stepSparringProgress: [], // TEMPORARILY EMPTY: Skip step sparring to prevent SwiftData crashes
```

## Investigation Plan

### Phase 1: Identify WindowGroup Recreation Source
**PRIORITY:** Find what's causing `🏗️ Building WindowGroup scene...` to trigger repeatedly
- Check App struct lifecycle
- Investigate AppCoordinator state changes
- Review DataServices initialization timing
- Look for @Published property storms

### Phase 2: Fix View Lifecycle Management  
- Prevent continuous view recreation
- Stabilize ProfileSwitcher instance count
- Ensure single DataServices instance throughout app lifecycle

### Phase 3: Re-enable Features Systematically
Only after view lifecycle is stable:
1. **Auto-backup functionality** (4 locations in ProfileService)
2. **Study sessions query** (ProfileService.getStudySessions)
3. **Grading history query** (ProfileService.getGradingHistory)  
4. **Step sparring export** (ProfileExportService)

## Code State

### Last Stable Commit
```bash
git checkout a3f35ac  # Clean baseline with seeding logic removed
```

### Enhanced Debugging Added
- ProfileSwitcher instances now log unique IDs
- All trigger sources identified (onAppear, objectWillChange, manual switch)
- Call sequences tracked for root cause analysis

## Key Files to Investigate

1. **TKDojangApp.swift** - App struct and WindowGroup definition
2. **AppCoordinator.swift** - Navigation flow state management
3. **AppInitializationView.swift** - App startup sequence
4. **DataServices.swift** - Service layer initialization and @Published properties
5. **ProfileSwitcher.swift** - Multiple instance management

## Success Criteria

✅ **Phase 1 Complete:** WindowGroup builds only once at app startup  
✅ **Phase 2 Complete:** ProfileSwitcher has 1-2 stable instances max  
✅ **Phase 3 Complete:** All disabled features re-enabled without crashes

## Notes for Future Claude Instance

- **DO NOT** apply defensive SwiftData fixes until view lifecycle is stable
- **Focus on WindowGroup recreation** as the root cause, not SwiftData queries
- **The p28/p32 crashes are symptoms** of view lifecycle issues, not the disease
- **Test view stability first** before re-enabling any disabled features
- **Use the enhanced ProfileSwitcher DEBUG logs** to track instance behavior

**Remember:** Fix the architecture, not the symptoms.