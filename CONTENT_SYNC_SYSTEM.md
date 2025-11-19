# Automated Content Synchronization System

## Overview

TKDojang now has a **fully automated content synchronization system** that ensures users always receive the latest content from JSON files without losing any progress data. The system uses **SHA-256 content hashes** generated at build time to detect when JSON content changes.

## Problem Solved

**Before:** Users seeing old content (e.g., "jun-bi ja-sae") because terminology was loaded once and never updated.

**After:** Content automatically reloads when JSON files change, triggered by hash comparison (not manual version bumps).

## Architecture

### 1. Build-Time Hash Generation

**Script:** `.build-scripts/generate-content-hashes.sh`

- Runs on **every build** (via Xcode Build Phase)
- Calculates SHA-256 hash of all content JSON files
- Generates `ContentVersion.swift` with hashes as constants
- Zero runtime cost (hashes are compile-time constants)

**Content Types Tracked:**
- Terminology (`*_keup_*.json`, `*_dan_*.json`)
- Patterns (`*_patterns.json`)
- Step Sparring (`*_step.json`, `*semi_free*.json`)
- Belt System (`belt_system.json`)
- Line Work (`*_linework.json`)
- Theory (`*_theory.json`)

### 2. Runtime Hash Comparison

**File:** `TKDojang/Sources/Core/Data/DataManager.swift`

On every app launch, `setupInitialData()`:

1. Loads current hashes from `ContentVersion.swift` (from latest build)
2. Compares with last known hashes (stored in UserDefaults)
3. If hash changed → Triggers content reload
4. If hash unchanged → Skips reload, uses cached data
5. Saves new hashes to UserDefaults

### 3. Content Reload Strategies

#### Terminology (Full Reload)
- Deletes all `TerminologyEntry` and `TerminologyCategory` objects
- Reloads from JSON using `ModularContentLoader`
- **Safe:** Never touches `UserTerminologyProgress` (Leitner boxes intact)

#### Patterns (Dynamic Sync)
- Compares pattern names in JSON vs database
- Reloads if mismatch detected
- Already existed, now enhanced with hash detection

#### Step Sparring (Dynamic Sync)
- Compares sequence IDs in JSON vs database
- Reloads if mismatch detected
- Already existed, now enhanced with hash detection

#### Belt System (Metadata Update)
- **NEVER deletes/recreates** BeltLevel records
- Only updates metadata fields (colors, names, requirements)
- **Preserves all user foreign keys** (current belt, grading history)

## User Data Safety

### ✅ Always Preserved
- `UserProfile` - Profile data, current belt
- `StudySession` - Session tracking
- `UserTerminologyProgress` - Leitner box state
- `UserPatternProgress` - Pattern mastery
- `UserStepSparringProgress` - Step sparring progress
- `GradingRecord` - Grading history
- `TestSession` / `TestResult` - Test performance

### ⚙️ Content Models (Reloaded When Changed)
- `BeltLevel` - **Metadata only** (never deleted)
- `TerminologyEntry` - Deleted and reloaded
- `TerminologyCategory` - Deleted and reloaded
- `Pattern` - Deleted and reloaded (if mismatch)
- `StepSparringSequence` - Deleted and reloaded (if mismatch)

## How to Use

### Developer Workflow

**No manual steps needed!** The system is fully automatic:

1. Edit any JSON file in `TKDojang/Sources/Core/Data/Content/`
2. Build the app (Cmd+B)
3. Hash generation script runs automatically
4. `ContentVersion.swift` updates with new hashes
5. Launch the app
6. Content automatically reloads if hashes changed

### Testing Content Changes

```bash
# 1. View current hashes
cat TKDojang/Sources/Core/Data/ContentVersion.swift

# 2. Edit a JSON file (e.g., fix spelling in terminology)
# 3. Rebuild
xcodebuild -scheme TKDojang build

# 4. Check hashes changed
cat TKDojang/Sources/Core/Data/ContentVersion.swift
```

### App Store Updates

When you release an app update:

1. Build app for release (hashes generated automatically)
2. Submit to App Store
3. Users download update
4. Users launch app
5. Hash comparison detects changes
6. Content reloads automatically
7. **Users see updated content without manual database reset**

## File Reference

### New Files Created

1. **`.build-scripts/generate-content-hashes.sh`**
   - Build-time hash generation script
   - Run by Xcode Build Phase

2. **`.build-scripts/README.md`**
   - Instructions for setting up Build Phase
   - System documentation

3. **`TKDojang/Sources/Core/Data/ContentVersion.swift`**
   - Auto-generated file (DO NOT EDIT MANUALLY)
   - Contains SHA-256 hashes of all content
   - Updated on every build

### Modified Files

1. **`TKDojang/Sources/Core/Data/DataManager.swift`**
   - Added content hash comparison methods
   - Modified `setupInitialData()` to use hashes
   - Added `ensureBeltSystemIsSynchronized()`

2. **`TKDojang/Sources/Core/Data/Services/TerminologyDataService.swift`**
   - Added `clearAndReloadTerminology()` method

## Implementation Details

### Hash Calculation

```bash
# Example: Terminology hash
find TKDojang -name "*_keup_*.json" -o -name "*_dan_*.json" \
  | sort \
  | xargs cat \
  | shasum -a 256
```

**Why sort?** Ensures consistent hash regardless of file discovery order.

**Why combine files?** One hash represents entire content type.

### Hash Storage

**Build-time (ContentVersion.swift):**
```swift
struct ContentVersion {
    static let terminologyHash = "13e5e800589c0a7b6e16a81b02b43427..."
    static let patternsHash = "3306ba8acb0612038bd47d4cebbd21f0..."
    // ... more hashes
}
```

**Runtime (UserDefaults):**
```
TKDojang_LastTerminologyHash = "13e5e800589c0a7b6e16a81b02b43427..."
TKDojang_LastPatternsHash = "3306ba8acb0612038bd47d4cebbd21f0..."
```

### Content Reload Decision Flow

```
App Launch
  ↓
Load ContentVersion hashes (from build)
  ↓
Load last known hashes (from UserDefaults)
  ↓
Compare hashes
  ↓
┌─────────────────┬─────────────────┐
│ Hashes Match    │ Hashes Different│
│ ↓               │ ↓               │
│ Skip Reload     │ Reload Content  │
│ Use Cache       │ From JSON       │
└─────────────────┴─────────────────┘
  ↓
Save new hashes to UserDefaults
  ↓
Continue App
```

## Xcode Setup (One-Time - IMPORTANT)

Due to Xcode sandbox restrictions, you must **paste the script inline** (not reference external file):

1. Open `TKDojang.xcodeproj` in Xcode
2. Select **TKDojang** target → **Build Phases** tab
3. Click **+** → **New Run Script Phase**
4. Rename to: **Generate Content Hashes**
5. Drag phase **above "Compile Sources"**
6. **Open `Scripts/XCODE_BUILD_PHASE.sh`**
7. **Copy the ENTIRE script and paste into Build Phase text box**
8. Uncheck "Show environment variables in build log" (optional)

**Why inline?** Xcode sandbox blocks access to external scripts in hidden directories. Inline scripts work without sandbox issues.

**Verification:**
- Build the project (Cmd+B)
- Check build log for "🔨 Generating content hashes..."
- Verify `ContentVersion.swift` exists and has hashes
- Should see: "✅ Content hashes: Term=13e5e800... Pat=3306ba8a..."

## Benefits

### ✅ Automatic
- No manual version tracking
- No remembering to bump versions
- Works during development AND production

### ✅ Precise
- Detects **actual content changes**, not just app version bumps
- Won't reload if only code changed
- Will reload if only JSON changed

### ✅ Fast
- Only reloads when content actually changed
- No unnecessary database operations
- Cached data used when hashes match

### ✅ Safe
- User progress **always preserved**
- Belt level FKs **never broken**
- Leitner boxes **intact**

### ✅ Developer-Friendly
- Catches manual JSON edits immediately
- Works in debug builds
- Clear logging for debugging

## Troubleshooting

### "ContentVersion.swift not found" Error

**Cause:** Build script hasn't run yet.

**Fix:**
1. Check Build Phase is configured correctly
2. Clean build folder (Cmd+Shift+K)
3. Rebuild (Cmd+B)

### Content Not Reloading

**Cause:** Hashes match (content hasn't changed).

**Debug:**
```bash
# Check current hashes
cat TKDojang/Sources/Core/Data/ContentVersion.swift

# Force regenerate
bash .build-scripts/generate-content-hashes.sh

# Check app logs for hash comparison
# Look for: "Terminology content changed" or "unchanged"
```

### Build Script Permission Error

**Cause:** Script not executable.

**Fix:**
```bash
chmod +x .build-scripts/generate-content-hashes.sh
```

## Testing the System

### Automated Test

```bash
# Run the hash change detection test
bash /tmp/test_hash_changes.sh

# Should show:
# ✅ PASS: Hash changed when content modified
# ✅ PASS: Hash returned to original after revert
# 🎉 Content hash system working correctly!
```

### Manual Test

1. Launch app, note current terminology
2. Edit a terminology JSON file (change a spelling)
3. Rebuild app
4. Launch app again
5. Verify updated terminology appears

## Future Enhancements

- [ ] Per-file hash granularity (detect which specific file changed)
- [ ] Differential updates (only reload changed files)
- [ ] Hash verification on app launch (detect corrupted JSON)
- [ ] CloudKit sync integration (server-side content updates)

## Summary

The content sync system is now **100% automated**:
- ✅ Hash generation at build time
- ✅ Hash comparison at runtime
- ✅ Automatic content reload when changed
- ✅ User progress always preserved
- ✅ Zero manual intervention required

**Users will always see the latest content without losing progress.**
