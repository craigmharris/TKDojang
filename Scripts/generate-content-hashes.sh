#!/bin/bash
# generate-content-hashes.sh
# PURPOSE: Generates content version hashes at build time

set -e

SRCROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CONTENT_BASE="$SRCROOT/TKDojang/Sources/Core/Data/Content"
OUTPUT_FILE="$SRCROOT/TKDojang/Sources/Core/Data/ContentVersion.swift"

echo "Generating content version hashes..."

# Hash files in specific directories only (avoids sandbox issues with find)
hash_json_files() {
    local dir="$1"
    local pattern="$2"

    if [ ! -d "$dir" ]; then
        echo "00000000"
        return
    fi

    # Use shell globbing instead of find to avoid sandbox issues
    shopt -s nullglob
    local files=("$dir"/$pattern)
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        echo "00000000"
        return
    fi

    cat "${files[@]}" | shasum -a 256 | cut -d' ' -f1
}

# Hash terminology files (in Terminology subdirectory)
TERM_KEUP=$(hash_json_files "$CONTENT_BASE/Terminology" "*_keup_*.json")
TERM_DAN=$(hash_json_files "$CONTENT_BASE/Terminology" "*_dan_*.json")
TERMINOLOGY_HASH=$(echo "${TERM_KEUP}${TERM_DAN}" | shasum -a 256 | cut -d' ' -f1)

# Hash pattern files (in Patterns subdirectory)
PATTERNS_HASH=$(hash_json_files "$CONTENT_BASE/Patterns" "*_patterns.json")

# Hash step sparring files (in StepSparring subdirectory)
STEP_HASH=$(hash_json_files "$CONTENT_BASE/StepSparring" "*_step.json")
SEMI_FREE=$(hash_json_files "$CONTENT_BASE/StepSparring" "*semi_free*.json")
STEP_SPARRING_HASH=$(echo "${STEP_HASH}${SEMI_FREE}" | shasum -a 256 | cut -d' ' -f1)

# Hash other content files
BELT_SYSTEM_HASH=$(shasum -a 256 "$SRCROOT/TKDojang/Sources/belt_system.json" 2>/dev/null | cut -d' ' -f1 || echo "00000000")
LINE_WORK_HASH=$(hash_json_files "$CONTENT_BASE/LineWork" "*_linework.json")
THEORY_HASH=$(hash_json_files "$CONTENT_BASE/Theory" "*_theory.json")

BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$OUTPUT_FILE" << 'EOF'
// ContentVersion.swift
// Auto-generated - DO NOT EDIT

import Foundation

struct ContentVersion {
    static let terminologyHash = "TERMINOLOGY_PLACEHOLDER"
    static let patternsHash = "PATTERNS_PLACEHOLDER"
    static let stepSparringHash = "STEP_SPARRING_PLACEHOLDER"
    static let beltSystemHash = "BELT_SYSTEM_PLACEHOLDER"
    static let lineWorkHash = "LINE_WORK_PLACEHOLDER"
    static let theoryHash = "THEORY_PLACEHOLDER"
    static let generatedAt = "TIMESTAMP_PLACEHOLDER"
}
EOF

sed -i '' "s/TERMINOLOGY_PLACEHOLDER/$TERMINOLOGY_HASH/" "$OUTPUT_FILE"
sed -i '' "s/PATTERNS_PLACEHOLDER/$PATTERNS_HASH/" "$OUTPUT_FILE"
sed -i '' "s/STEP_SPARRING_PLACEHOLDER/$STEP_SPARRING_HASH/" "$OUTPUT_FILE"
sed -i '' "s/BELT_SYSTEM_PLACEHOLDER/$BELT_SYSTEM_HASH/" "$OUTPUT_FILE"
sed -i '' "s/LINE_WORK_PLACEHOLDER/$LINE_WORK_HASH/" "$OUTPUT_FILE"
sed -i '' "s/THEORY_PLACEHOLDER/$THEORY_HASH/" "$OUTPUT_FILE"
sed -i '' "s/TIMESTAMP_PLACEHOLDER/$BUILD_TIMESTAMP/" "$OUTPUT_FILE"

echo "Content hashes generated:"
echo "  Terminology: ${TERMINOLOGY_HASH:0:16}..."
echo "  Patterns:    ${PATTERNS_HASH:0:16}..."
echo "  Step Spar:   ${STEP_SPARRING_HASH:0:16}..."
echo "  Belt System: ${BELT_SYSTEM_HASH:0:16}..."
