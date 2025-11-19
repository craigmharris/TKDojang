#!/bin/bash
set -e

OUTPUT_FILE="$SRCROOT/TKDojang/Sources/Core/Data/ContentVersion.swift"

echo "Generating content hashes..."

calc_hash() {
    local pattern="$1"
    local files=$(find "$SRCROOT/TKDojang" -name "$pattern" 2>/dev/null | sort)
    if [ -z "$files" ]; then
        echo "00000000"
        return
    fi
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
    static let terminologyHash = "TERM_HASH"
    static let patternsHash = "PAT_HASH"
    static let stepSparringHash = "STEP_HASH"
    static let beltSystemHash = "BELT_HASH"
    static let lineWorkHash = "LINE_HASH"
    static let theoryHash = "THEORY_HASH"
    static let generatedAt = "BUILD_TIME"
}
EOF

sed -i '' "s/TERM_HASH/$TERMINOLOGY_HASH/" "$OUTPUT_FILE"
sed -i '' "s/PAT_HASH/$PATTERNS_HASH/" "$OUTPUT_FILE"
sed -i '' "s/STEP_HASH/$STEP_SPARRING_HASH/" "$OUTPUT_FILE"
sed -i '' "s/BELT_HASH/$BELT_SYSTEM_HASH/" "$OUTPUT_FILE"
sed -i '' "s/LINE_HASH/$LINE_WORK_HASH/" "$OUTPUT_FILE"
sed -i '' "s/THEORY_HASH/$THEORY_HASH/" "$OUTPUT_FILE"
sed -i '' "s/BUILD_TIME/$BUILD_TIME/" "$OUTPUT_FILE"

echo "Content hashes: Term=${TERMINOLOGY_HASH:0:8}... Pat=${PATTERNS_HASH:0:8}..."
