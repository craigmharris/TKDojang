# Build Scripts

## Content Hash Generation (Xcode Build Phase)

**Purpose:** Automatically generates content version hashes at build time to detect when JSON content changes.

### Setup Instructions (IMPORTANT)

Due to Xcode sandbox restrictions, you need to **paste the script directly** into the Build Phase (not reference an external file).

1. Open `TKDojang.xcodeproj` in Xcode
2. Select the **TKDojang** target
3. Go to **Build Phases** tab
4. Click **+** → **New Run Script Phase**
5. Name it: **Generate Content Hashes**
6. Drag it **above** the "Compile Sources" phase
7. **Open `Scripts/XCODE_BUILD_PHASE.sh` and copy the ENTIRE script**
8. **Paste the script into the Build Phase text box**
9. Uncheck "Show environment variables in build log" (optional)

### What It Does

- Calculates SHA-256 hash of all content JSON files:
  - Terminology files (`*_keup_*.json`, `*_dan_*.json`)
  - Pattern files (`*_patterns.json`)
  - Step sparring files (`*_step.json`, `*semi_free*.json`)
  - Belt system (`belt_system.json`)
  - Line work (`*_linework.json`)
  - Theory (`*_theory.json`)

- Generates `ContentVersion.swift` with current hashes
- Runs on **every build**
- Zero runtime cost - hashes are compile-time constants

### How Content Sync Works

1. **Build time:** Script generates `ContentVersion.swift` with hashes
2. **App launch:** `DataManager.setupInitialData()` compares hashes
3. **If hash changed:** Automatic content reload
4. **If hash unchanged:** Skip reload, use cached data

### Benefits

- ✅ **Automatic:** No manual version bumps needed
- ✅ **Precise:** Detects actual content changes, not app version
- ✅ **Fast:** Only reloads when content actually changed
- ✅ **Dev-friendly:** Works during development, catches manual JSON edits
- ✅ **Production-ready:** Ensures users get latest content on app updates

### Verification

After adding the build phase, build the project and check:

```bash
# Check generated file exists
ls -la TKDojang/Sources/Core/Data/ContentVersion.swift

# View current hashes
cat TKDojang/Sources/Core/Data/ContentVersion.swift
```

You should see output like:
```swift
struct ContentVersion {
    static let terminologyHash = "13e5e800589c0a7b..."
    static let patternsHash = "3306ba8acb061203..."
    ...
}
```
