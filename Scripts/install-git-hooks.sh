#!/bin/bash
#
# Install Git hooks for TKDojang development
#
# PURPOSE: Symlink pre-commit hook to enable automatic content hash generation
# USAGE: Run once per repository clone: bash Scripts/install-git-hooks.sh
#

set -e

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔧 Installing Git hooks...${NC}"

# Get the repository root (where .git directory is located)
REPO_ROOT=$(git rev-parse --show-toplevel)

# Source and destination paths
HOOKS_SOURCE="$REPO_ROOT/Scripts/pre-commit"
HOOKS_DEST="$REPO_ROOT/.git/hooks/pre-commit"

# Verify source hook exists
if [ ! -f "$HOOKS_SOURCE" ]; then
    echo -e "${RED}❌ Error: Source hook not found at $HOOKS_SOURCE${NC}"
    exit 1
fi

# Ensure source hook is executable
if [ ! -x "$HOOKS_SOURCE" ]; then
    echo -e "${YELLOW}⚙️  Making source hook executable...${NC}"
    chmod +x "$HOOKS_SOURCE"
fi

# Check if hook already installed
if [ -L "$HOOKS_DEST" ]; then
    CURRENT_TARGET=$(readlink "$HOOKS_DEST")
    if [ "$CURRENT_TARGET" = "$HOOKS_SOURCE" ]; then
        echo -e "${GREEN}✅ Pre-commit hook already installed correctly${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Existing hook symlink points to: $CURRENT_TARGET${NC}"
        echo -e "${YELLOW}   Updating to: $HOOKS_SOURCE${NC}"
        rm "$HOOKS_DEST"
    fi
elif [ -f "$HOOKS_DEST" ]; then
    echo -e "${YELLOW}⚠️  Existing pre-commit hook found (not a symlink)${NC}"
    echo -e "${YELLOW}   Backing up to: $HOOKS_DEST.backup${NC}"
    mv "$HOOKS_DEST" "$HOOKS_DEST.backup"
fi

# Create .git/hooks directory if it doesn't exist
mkdir -p "$REPO_ROOT/.git/hooks"

# Create symlink
ln -s "$HOOKS_SOURCE" "$HOOKS_DEST"

echo -e "${GREEN}✅ Pre-commit hook installed successfully${NC}"
echo ""
echo -e "${YELLOW}📝 What this hook does:${NC}"
echo "   • Detects JSON content changes in commits"
echo "   • Auto-generates content version hashes"
echo "   • Stages updated ContentVersion.swift"
echo ""
echo -e "${GREEN}🎉 Setup complete! The hook will run automatically on git commit.${NC}"
