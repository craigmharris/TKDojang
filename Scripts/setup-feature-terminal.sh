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
