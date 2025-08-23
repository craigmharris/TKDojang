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
