#!/bin/bash

# fast-test-runner.sh  
# PURPOSE: Optimized test execution strategy for faster development feedback

set -e

echo "🚀 Fast Test Runner - TKDojang"
echo "=============================="

# Fast unit tests that can run quickly (< 30 seconds total)
FAST_UNIT_TESTS=(
    "BeltSystemTests"
    "JSONConsistencyTests" 
    "TestDataFactoryTests"
    "MultiProfileSystemTests"
)

# Integration tests (moderate speed)
INTEGRATION_TESTS=(
    "ArchitecturalIntegrationTests"
    "ContentLoadingTests"
    "EdgeCasesPerformanceTests"
)

# UI tests (slowest - run separately)
UI_TESTS=(
    "TKDojangUITests"
)

# Function to run test suite with timing
run_test_suite() {
    local suite="$1"
    local category="$2"
    
    echo "⏱️  Running $category: $suite"
    start_time=$(date +%s)
    
    if xcodebuild -project TKDojang.xcodeproj \
                   -scheme TKDojang \
                   -destination "platform=iOS Simulator,id=0A227615-B123-4282-BB13-2CD2EFB0A434" \
                   test -only-testing:"TKDojangTests/$suite" \
                   > /tmp/test_${suite}.log 2>&1; then
        
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "  ✅ $suite passed in ${duration}s"
        return 0
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo "  ❌ $suite failed in ${duration}s"
        echo "     Check /tmp/test_${suite}.log for details"
        return 1
    fi
}

# Parse command line arguments
MODE=${1:-"fast"}

case $MODE in
    "fast")
        echo "🔬 Running Fast Unit Tests Only"
        echo "================================"
        
        failed_tests=0
        total_time=0
        
        for suite in "${FAST_UNIT_TESTS[@]}"; do
            start=$(date +%s)
            if ! run_test_suite "$suite" "Unit"; then
                failed_tests=$((failed_tests + 1))
            fi
            end=$(date +%s)
            total_time=$((total_time + (end - start)))
        done
        
        echo ""
        echo "📊 Fast Test Summary:"
        echo "Total time: ${total_time}s"
        echo "Failed tests: $failed_tests"
        
        if [ $failed_tests -eq 0 ]; then
            echo "✅ All fast tests passed!"
            exit 0
        else
            echo "❌ $failed_tests test suite(s) failed"
            exit 1
        fi
        ;;
        
    "integration")
        echo "🎯 Running Integration Tests"
        echo "============================"
        
        failed_tests=0
        for suite in "${INTEGRATION_TESTS[@]}"; do
            if ! run_test_suite "$suite" "Integration"; then
                failed_tests=$((failed_tests + 1))
            fi
        done
        
        echo "Integration tests completed with $failed_tests failures"
        exit $failed_tests
        ;;
        
    "ui")
        echo "🖥️  Running UI Tests"
        echo "==================="
        
        failed_tests=0
        for suite in "${UI_TESTS[@]}"; do
            if ! run_test_suite "$suite" "UI"; then
                failed_tests=$((failed_tests + 1))
            fi
        done
        
        echo "UI tests completed with $failed_tests failures"
        exit $failed_tests
        ;;
        
    "all")
        echo "🔄 Running All Tests (Sequential)"
        echo "================================="
        
        # Run in order of speed for faster feedback
        echo "Phase 1: Fast Unit Tests"
        $0 fast
        unit_result=$?
        
        echo ""
        echo "Phase 2: Integration Tests"  
        $0 integration
        integration_result=$?
        
        echo ""
        echo "Phase 3: UI Tests"
        $0 ui
        ui_result=$?
        
        total_failures=$((unit_result + integration_result + ui_result))
        
        echo ""
        echo "📊 Complete Test Summary:"
        echo "Unit test failures: $unit_result"
        echo "Integration test failures: $integration_result"  
        echo "UI test failures: $ui_result"
        echo "Total failures: $total_failures"
        
        exit $total_failures
        ;;
        
    *)
        echo "Usage: $0 [fast|integration|ui|all]"
        echo ""
        echo "Modes:"
        echo "  fast        - Run only fast unit tests (~30s)"
        echo "  integration - Run integration tests (~2-3min)"
        echo "  ui          - Run UI tests (~5-10min)"  
        echo "  all         - Run all tests sequentially"
        echo ""
        echo "Default: fast"
        exit 1
        ;;
esac