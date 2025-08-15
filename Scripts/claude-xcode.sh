#!/bin/bash

# claude-xcode.sh
# Script to run Claude Code with proper Xcode context

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🏗️  Starting Claude Code for TKDojang App"
echo "📁 Project Root: $PROJECT_ROOT"

# Navigate to project root
cd "$PROJECT_ROOT"

# Check if Xcode project exists
if [ -f "TKDojang.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project found"
else
    echo "❌ Xcode project not found - please create it first"
    exit 1
fi

# Set Xcode environment variables
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export XCODE_PROJECT_PATH="$PROJECT_ROOT/TKDojang.xcodeproj"

# Launch Claude Code
echo "🤖 Launching Claude Code..."
claude-code

echo "👋 Claude Code session ended"