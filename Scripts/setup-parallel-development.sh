#!/bin/bash

# Setup script for parallel development tracks
# This script sets up the branch structure, git hooks, and terminal configurations

set -e

echo "🚀 Setting up parallel development environment..."

# Ensure we're in the right directory
if [[ ! -f "TKDojang.xcodeproj/project.pbxproj" ]]; then
    echo "❌ Error: Must run from TKDojang project root"
    exit 1
fi

# Ensure clean working directory
if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Error: Working directory must be clean before setup"
    echo "Please commit or stash your changes first"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "📍 Current branch: $CURRENT_BRANCH"

# Create feature branches from current state
echo "🌿 Creating feature branches..."
git checkout -b feature/testing-infrastructure 2>/dev/null || git checkout feature/testing-infrastructure
git push -u origin feature/testing-infrastructure 2>/dev/null || echo "Branch already exists on remote"

git checkout $CURRENT_BRANCH
git checkout -b feature/content-expansion 2>/dev/null || git checkout feature/content-expansion  
git push -u origin feature/content-expansion 2>/dev/null || echo "Branch already exists on remote"

# Return to original branch
git checkout $CURRENT_BRANCH

# Create git hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook for branch protection
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Branch protection hook for parallel development tracks
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get staged files
STAGED_FILES=$(git diff --cached --name-only)

if [[ $BRANCH == "feature/testing-infrastructure" ]]; then
    # Check for forbidden feature changes in testing branch
    if echo "$STAGED_FILES" | grep -E "Sources/Features/.*\.(swift)$" | grep -v -E "(Protocol|Testable)" > /dev/null; then
        echo "❌ TESTING TRACK: Cannot modify feature files"
        echo "Forbidden files:"
        echo "$STAGED_FILES" | grep -E "Sources/Features/.*\.(swift)$" | grep -v -E "(Protocol|Testable)"
        echo ""
        echo "🧪 Testing track is limited to:"
        echo "  ✅ Tests/ directory"
        echo "  ✅ Scripts/test-* files" 
        echo "  ✅ Testability interfaces only"
        exit 1
    fi
    
    # Check for terminology content changes
    if echo "$STAGED_FILES" | grep -E "Sources/Core/Data/Content/.*\.(json)$" > /dev/null; then
        echo "❌ TESTING TRACK: Cannot modify terminology content"
        echo "Content changes belong in feature track"
        exit 1
    fi
fi

if [[ $BRANCH == "feature/content-expansion" ]]; then
    # Check for forbidden test changes in feature branch
    if echo "$STAGED_FILES" | grep -E "Tests/.*\.(swift)$" > /dev/null; then
        echo "❌ FEATURE TRACK: Cannot modify test files"
        echo "Forbidden files:"
        echo "$STAGED_FILES" | grep -E "Tests/.*\.(swift)$"
        echo ""
        echo "🚀 Feature track is limited to:"
        echo "  ✅ Sources/Features/ directory"
        echo "  ✅ Content and UX improvements"
        echo "  ✅ New terminology content"
        exit 1
    fi
    
    # Check for core architecture changes
    if echo "$STAGED_FILES" | grep -E "Sources/Core/(Coordinators|Data/Models)/.*\.(swift)$" > /dev/null; then
        echo "⚠️  FEATURE TRACK: Core architecture changes detected"
        echo "Modified files:"
        echo "$STAGED_FILES" | grep -E "Sources/Core/(Coordinators|Data/Models)/.*\.(swift)$"
        echo ""
        read -p "Are you sure these changes maintain API compatibility? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Aborting commit. Coordinate architecture changes across tracks."
            exit 1
        fi
    fi
fi

echo "✅ Branch protection: All changes are appropriate for $BRANCH"
EOF

# Make hook executable
chmod +x .git/hooks/pre-commit

# Create terminal setup scripts
cat > Scripts/setup-testing-terminal.sh << 'EOF'
#!/bin/bash

# Terminal setup for testing track
export CLAUDE_TRACK="testing"
export PS1="\[\033[34m\][🧪 TESTING]\[\033[0m\] \w $ "

echo "🧪 TESTING TRACK ACTIVE"
echo "Branch: feature/testing-infrastructure"
echo "Focus: Test infrastructure only"
echo "Forbidden: Feature modifications, UI changes"
echo ""

# Switch to testing branch
git checkout feature/testing-infrastructure

# Show current status
git status --short
echo ""
echo "Ready for testing development! 🧪"
EOF

cat > Scripts/setup-feature-terminal.sh << 'EOF'
#!/bin/bash

# Terminal setup for feature track  
export CLAUDE_TRACK="features"
export PS1="\[\033[32m\][🚀 FEATURES]\[\033[0m\] \w $ "

echo "🚀 FEATURE TRACK ACTIVE"
echo "Branch: feature/content-expansion"
echo "Focus: Content and UX enhancements"  
echo "Forbidden: Test modifications, architecture changes"
echo ""

# Switch to feature branch
git checkout feature/content-expansion

# Show current status
git status --short
echo ""
echo "Ready for feature development! 🚀"
EOF

# Make terminal scripts executable
chmod +x Scripts/setup-testing-terminal.sh
chmod +x Scripts/setup-feature-terminal.sh

# Create integration helper script
cat > Scripts/integrate-tracks.sh << 'EOF'
#!/bin/bash

# Integration script for merging both development tracks
echo "🔄 Starting track integration..."

# Ensure clean working directories on both branches
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Checking testing branch..."
git checkout feature/testing-infrastructure
if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Testing branch has uncommitted changes"
    exit 1
fi

echo "Checking feature branch..."  
git checkout feature/content-expansion
if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Feature branch has uncommitted changes"
    exit 1
fi

# Return to develop branch for integration
git checkout develop

echo "🔗 Merging testing infrastructure..."
git merge --no-ff feature/testing-infrastructure -m "Integrate testing infrastructure track"

echo "🔗 Merging feature developments..."
git merge --no-ff feature/content-expansion -m "Integrate feature development track"

echo "✅ Integration complete!"
echo "🧪 Running integration tests..."

# TODO: Add actual test commands here
echo "Integration validation would run here"

echo "🎉 Both tracks successfully integrated!"
EOF

chmod +x Scripts/integrate-tracks.sh

echo ""
echo "✅ Parallel development environment setup complete!"
echo ""
echo "📋 Next steps for you:"
echo "1. Open TWO terminal windows/tabs"
echo "2. In Terminal 1: source Scripts/setup-testing-terminal.sh" 
echo "3. In Terminal 2: source Scripts/setup-feature-terminal.sh"
echo "4. Start Claude Code in each terminal with appropriate context"
echo ""
echo "🎯 Quick validation:"
echo "- Each terminal should show colored prompts"
echo "- Git hooks will prevent cross-track modifications"
echo "- Integration script available: Scripts/integrate-tracks.sh"