#!/bin/bash

# optimize-test-performance.sh
# PURPOSE: Analyze and optimize TKDojang test suite performance

set -e

echo "🚀 TKDojang Test Performance Optimization"
echo "======================================="

# Function to run specific test suites with timing
run_test_suite() {
    local suite_name="$1"
    echo "⏱️  Running $suite_name..."
    
    start_time=$(date +%s)
    
    xcodebuild -project TKDojang.xcodeproj \
               -scheme TKDojang \
               -destination "platform=iOS Simulator,id=0A227615-B123-4282-BB13-2CD2EFB0A434" \
               test -only-testing:"TKDojangTests/$suite_name" \
               2>/dev/null | grep -E "(passed|failed|Test Suite)" || true
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    echo "  📊 $suite_name completed in ${duration}s"
    return $duration
}

echo "📋 Test Suite Performance Analysis:"
echo ""

# Test core unit test suites (fast)
echo "🔬 Unit Test Suites (should be fast):"
unit_suites=(
    "TestDataFactoryTests"
    "JSONConsistencyTests" 
    "BeltSystemTests"
    "MultiProfileSystemTests"
)

total_unit_time=0
for suite in "${unit_suites[@]}"; do
    run_test_suite "$suite"
    suite_time=$?
    total_unit_time=$((total_unit_time + suite_time))
done

echo ""
echo "🔬 Unit Tests Total: ${total_unit_time}s"

echo ""
echo "🎯 Integration Test Suites (moderate):"
integration_suites=(
    "ArchitecturalIntegrationTests"
    "ContentLoadingTests"
    "EdgeCasesPerformanceTests"
)

total_integration_time=0
for suite in "${integration_suites[@]}"; do
    run_test_suite "$suite"
    suite_time=$?
    total_integration_time=$((total_integration_time + suite_time))
done

echo ""
echo "🎯 Integration Tests Total: ${total_integration_time}s"

echo ""
echo "🖥️  UI Test Suites (slow - optimization candidates):"
ui_suites=(
    "TKDojangUITests"
)

total_ui_time=0
for suite in "${ui_suites[@]}"; do
    run_test_suite "$suite"
    suite_time=$?
    total_ui_time=$((total_ui_time + suite_time))
done

echo ""
echo "🖥️  UI Tests Total: ${total_ui_time}s"

# Calculate totals
total_time=$((total_unit_time + total_integration_time + total_ui_time))

echo ""
echo "📊 PERFORMANCE SUMMARY"
echo "====================="
echo "Unit Tests:        ${total_unit_time}s (target: <30s)"
echo "Integration Tests: ${total_integration_time}s (target: <60s)" 
echo "UI Tests:          ${total_ui_time}s (target: <120s)"
echo "TOTAL:            ${total_time}s"
echo ""

# Provide optimization recommendations
echo "💡 OPTIMIZATION RECOMMENDATIONS:"
echo "================================"

if [ $total_unit_time -gt 30 ]; then
    echo "⚠️  Unit tests are slow (${total_unit_time}s > 30s target)"
    echo "   • Review TestDataFactory usage"
    echo "   • Minimize SwiftData operations in unit tests"
    echo "   • Use more mocking/stubbing"
fi

if [ $total_integration_time -gt 60 ]; then
    echo "⚠️  Integration tests are slow (${total_integration_time}s > 60s target)"
    echo "   • Reduce duplicate setup/teardown"
    echo "   • Parallelize independent tests"
    echo "   • Use smaller test data sets"
fi

if [ $total_ui_time -gt 120 ]; then
    echo "⚠️  UI tests are slow (${total_ui_time}s > 120s target)"
    echo "   • Reduce wait times and timeouts"
    echo "   • Use shortcuts instead of full navigation"
    echo "   • Consider breaking into smaller test cases"
fi

if [ $total_time -lt 300 ]; then
    echo "✅ Overall test performance is acceptable (${total_time}s < 5min target)"
else
    echo "🔴 Test suite is too slow (${total_time}s > 5min target)"
    echo "   • Consider running UI tests separately from unit tests"
    echo "   • Implement parallel test execution"
fi

echo ""
echo "🎯 Next Steps:"
echo "• Review slowest test suites first"  
echo "• Implement parallel execution for independent tests"
echo "• Consider CI/CD pipeline optimizations"