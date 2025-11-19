# Xcode Build Phase Setup - Content Hash Generation

## The Problem

Xcode's build sandbox blocks scripts from accessing project files unless explicitly declared via Input/Output Files.

## The Solution

Use a **simpler approach** that works within sandbox constraints:

### Option A: Disable Sandbox for This Phase (Recommended - Simplest)

1. Open `TKDojang.xcodeproj` in Xcode
2. Select **TKDojang** target → **Build Phases**
3. Find/Create "Generate Content Hashes" Run Script Phase
4. Drag it **above** "Compile Sources"
5. **Check** ✅ "For install builds only" (THIS IS THE KEY - disables sandbox)
6. Paste this script:

```bash
#!/bin/bash
set -e

OUTPUT_FILE="$SRCROOT/TKDojang/Sources/Core/Data/ContentVersion.swift"

calc_hash() {
    local pattern="$1"
    local files=$(find "$SRCROOT/TKDojang" -name "$pattern" 2>/dev/null | sort)
    [ -z "$files" ] && echo "00000000" && return
    cat $files | shasum -a 256 | cut -d' ' -f1
}

TERM_KEUP=$(calc_hash "*_keup_*.json")
TERM_DAN=$(calc_hash "*_dan_*.json")
TERMINOLOGY_HASH=$(echo "${TERM_KEUP}${TERM_DAN}" | shasum -a 256 | cut -d' ' -f1)

PATTERNS_HASH=$(calc_hash "*_patterns.json")

STEP=$(calc_hash "*_step.json")
SEMI=$(calc_hash "*semi_free*.json")
STEP_SPARRING_HASH=$(echo "${STEP}${SEMI}" | shasum -a 256 | cut -d' ' -f1)

BELT_SYSTEM_HASH=$(calc_hash "belt_system.json")
LINE_WORK_HASH=$(calc_hash "*_linework.json")
THEORY_HASH=$(calc_hash "*_theory.json")

BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$OUTPUT_FILE" << 'EOF'
// ContentVersion.swift
// Auto-generated - DO NOT EDIT
import Foundation
struct ContentVersion {
    static let terminologyHash = "TERM"
    static let patternsHash = "PAT"
    static let stepSparringHash = "STEP"
    static let beltSystemHash = "BELT"
    static let lineWorkHash = "LINE"
    static let theoryHash = "THEORY"
    static let generatedAt = "TIME"
}
EOF

sed -i '' "s/TERM/$TERMINOLOGY_HASH/" "$OUTPUT_FILE"
sed -i '' "s/PAT/$PATTERNS_HASH/" "$OUTPUT_FILE"
sed -i '' "s/STEP/$STEP_SPARRING_HASH/" "$OUTPUT_FILE"
sed -i '' "s/BELT/$BELT_SYSTEM_HASH/" "$OUTPUT_FILE"
sed -i '' "s/LINE/$LINE_WORK_HASH/" "$OUTPUT_FILE"
sed -i '' "s/THEORY/$THEORY_HASH/" "$OUTPUT_FILE"
sed -i '' "s/TIME/$BUILD_TIME/" "$OUTPUT_FILE"

echo "✅ Hashes: Term=${TERMINOLOGY_HASH:0:8}..."
```

7. Build (Cmd+B)

**Why this works:** "For install builds only" actually DISABLES the sandbox for development builds, which is what you need.

---

### Option B: Declare Input/Output Files (More Complex)

If Option A doesn't work, use Input/Output Files:

1. In Build Phase settings, add **Output Files:**
   ```
   $(SRCROOT)/TKDojang/Sources/Core/Data/ContentVersion.swift
   ```

2. Add **Input Files:** (add each JSON file pattern - tedious)
   ```
   $(SRCROOT)/TKDojang/**/*.json
   ```

This is more complex and may not work with wildcards.

---

### Option C: Pre-Generate Hash File (Fallback)

If sandbox issues persist, pre-generate the file once:

```bash
cd /Users/craig/TKDojang
bash Scripts/generate-content-hashes.sh
```

Then **commit** `ContentVersion.swift` to git.

**Pros:** No build phase needed, works immediately
**Cons:** Manual regeneration when content changes

---

## Recommended Approach

**Use Option A** - It's the simplest and works for 99% of projects. The "For install builds only" checkbox is counterintuitive but disables sandbox for development builds.

## Verification

After setup:
```bash
# Clean build
xcodebuild clean build -scheme TKDojang

# Should see in build log:
# ✅ Hashes: Term=13e5e800...
# ** BUILD SUCCEEDED **
```

## Why This Is Hard

Apple's Xcode sandbox is **very strict** by design for security. Build scripts need explicit permission to:
- Read project files (`find` command)
- Write generated files (`ContentVersion.swift`)
- Access directories outside build folder

The "For install builds only" workaround disables sandbox during development, which is acceptable for content hash generation (it's not executing untrusted code).
