#!/bin/bash

# TKDojang Test Configuration
# Source this file before running tests: source .claude/test-config.sh

# Test Device Configuration
export TEST_DEVICE_ID="0A227615-B123-4282-BB13-2CD2EFB0A434"
export TEST_DEVICE_NAME="iPhone 16"
export TEST_PLATFORM="iOS Simulator"
export TEST_DESTINATION="platform=${TEST_PLATFORM},id=${TEST_DEVICE_ID}"

# Timeout Configuration
export BUILD_TIMEOUT=180000  # 3 minutes (180 seconds)
export TEST_TIMEOUT=120000   # 2 minutes (120 seconds)

# Project Configuration
export PROJECT_PATH="TKDojang.xcodeproj"
export SCHEME="TKDojang"

# Helper Functions
function xcode_build_for_testing() {
    echo "🔨 Building for testing..."
    xcodebuild -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION" \
        build-for-testing 2>&1 | grep -E "(error:|warning:|BUILD.*SUCCEEDED|BUILD.*FAILED)"
}

function xcode_test_class() {
    local test_class=$1
    echo "🧪 Running tests for ${test_class}..."
    xcodebuild test-without-building \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION" \
        -only-testing:"TKDojangTests/${test_class}" \
        2>&1 | grep -E "(Test Suite|Test Case.*passed|Test Case.*failed|TEST.*SUCCEEDED|TEST.*FAILED)"
}

function xcode_test_method() {
    local test_class=$1
    local test_method=$2
    echo "🔬 Running single test: ${test_class}.${test_method}..."
    xcodebuild test-without-building \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION" \
        -only-testing:"TKDojangTests/${test_class}/${test_method}" \
        2>&1 | tail -20
}

function xcode_check_build_errors() {
    echo "🔍 Checking for build errors..."
    xcodebuild -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$TEST_DESTINATION" \
        build-for-testing 2>&1 | grep -E "error:" | head -20
}

# Usage Information
echo "✅ Test configuration loaded"
echo "   Device: ${TEST_DEVICE_NAME} (${TEST_DEVICE_ID})"
echo "   Destination: ${TEST_DESTINATION}"
echo ""
echo "Available commands:"
echo "  xcode_build_for_testing              - Build once for testing"
echo "  xcode_test_class ClassName           - Run all tests in a class"
echo "  xcode_test_method ClassName method   - Run single test method"
echo "  xcode_check_build_errors             - Check for compilation errors"
