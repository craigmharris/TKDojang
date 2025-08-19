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
