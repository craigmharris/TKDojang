# Test Architecture Review Checklist

**PURPOSE**: Ensure all tests follow TKDojang's JSON-driven, property-based testing architecture.

**WHEN TO USE**: Before committing ANY test changes, run through this checklist.

---

## ✅ Pre-Work Validation (Before Writing Tests)

### 1. Check for Production JSON Data

```bash
# List available JSON files for the feature being tested
ls -la TKDojang/Sources/Core/Data/Content/Patterns/
ls -la TKDojang/Sources/Core/Data/Content/Terminology/
ls -la TKDojang/Sources/Core/Data/Content/StepSparring/
ls -la TKDojang/Sources/Core/Data/Content/LineWork/
ls -la TKDojang/Sources/Core/Data/Content/Theory/
ls -la TKDojang/Sources/Core/Data/Content/Techniques/
```

- [ ] Confirmed JSON files exist for this feature
- [ ] Listed all available JSON files (document below)
- [ ] If NO JSON exists, documented justification for TestDataFactory usage

**Available JSON Files**:
```
[List files here]
```

### 2. Review Existing Test Architecture

```bash
# Check current test data source
grep -c "createBasicTestData\|TestDataFactory" path/to/YourTest.swift
grep -c "Bundle.main.url.*json\|JSONDecoder" path/to/YourTest.swift
```

- [ ] Documented current data source approach
- [ ] Identified if current approach violates CLAUDE.md principles

---

## ✅ Data Source Validation

### Primary Check: Are We Using Production JSON?

- [ ] **YES** - Tests load from `Sources/Core/Data/Content/` JSON files
- [ ] **NO** - Using TestDataFactory (proceed to justification)

### If Using TestDataFactory:

**Select ONE valid justification** (or reject the approach):

- [ ] Testing data loading failure scenarios (mock error conditions)
- [ ] Unit testing TestDataFactory itself
- [ ] New feature where JSON doesn't exist yet (temporary, mark as TODO)
- [ ] ❌ INVALID: "It's easier to use synthetic data"
- [ ] ❌ INVALID: "JSON data is insufficient" (fix JSON instead)
- [ ] ❌ INVALID: "No particular reason, that's what was there"

**Documented Justification**:
```
[Explain why TestDataFactory is necessary here]
```

---

## ✅ Property-Based Testing Validation

### Check for Hardcoded Expectations

```bash
# Should return NOTHING for dynamic discovery tests
grep -n "XCTAssertEqual.*count.*[0-9]" path/to/YourTest.swift
grep -n "XCTAssertEqual.*\.count.*5\|10\|15" path/to/YourTest.swift
```

- [ ] No hardcoded count expectations found
- [ ] If hardcoded counts exist, documented why they're necessary

### Check for Dynamic Discovery

```bash
# Should find patterns like: for (fileName, data) in jsonFiles
grep -n "for.*in.*jsonFiles\|for.*in.*loadedData" path/to/YourTest.swift
```

- [ ] Tests iterate over dynamically discovered data
- [ ] Tests adapt to whatever content is available
- [ ] Would work correctly if JSON files are added/removed

### Property Validation

- [ ] Tests validate **properties** (relationships, invariants) not specific values
- [ ] Tests would catch data quality issues in JSON files
- [ ] Tests don't depend on exact content of JSON files

---

## ✅ JSON-Driven Validation

### JSON Loading Implementation

```bash
# Count JSON loading occurrences (should be > 0)
grep -c "Bundle.main.url.*json\|Bundle.main.path.*json" path/to/YourTest.swift
grep -c "JSONDecoder().decode" path/to/YourTest.swift
```

- [ ] Tests use `Bundle.main.url(forResource:withExtension:subdirectory:)`
- [ ] Tests use `JSONDecoder()` to parse JSON
- [ ] Tests handle JSON loading errors gracefully

### JSON Content Validation

- [ ] Tests validate app data **matches** JSON source files
- [ ] Tests would fail if JSON structure changes
- [ ] Tests would catch missing/malformed JSON data

---

## ✅ Code Quality Checks

### Test File Structure

- [ ] Test file has clear comments explaining data source
- [ ] If using TestDataFactory, justification is documented in code comments
- [ ] Test setUp() clearly shows data loading approach

### Example Good Patterns

```swift
// ✅ GOOD: Loads from production JSON
func loadPatternJSON() -> [PatternJSONData] {
    let bundle = Bundle.main
    let url = bundle.url(forResource: "9th_keup_patterns",
                        withExtension: "json",
                        subdirectory: "Patterns")!
    let data = try! Data(contentsOf: url)
    return try! JSONDecoder().decode([PatternJSONData].self, from: data)
}

// ❌ BAD: Uses synthetic data when JSON exists
let testData = TestDataFactory()
try testData.createBasicTestData(in: context)
```

---

## ✅ Compliance Validation

### Run Automated Checks

```bash
# Execute all validation commands
cd /Users/craig/TKDojang/TKDojangTests

# 1. Check TestDataFactory usage
echo "TestDataFactory occurrences:"
grep -c "createBasicTestData\|TestDataFactory" path/to/YourTest.swift

# 2. Check JSON loading
echo "JSON loading occurrences:"
grep -c "Bundle.main.url.*json\|JSONDecoder" path/to/YourTest.swift

# 3. Check for hardcoded counts
echo "Hardcoded counts (should be empty):"
grep -n "XCTAssertEqual.*count.*[0-9]" path/to/YourTest.swift

# 4. Check dynamic discovery
echo "Dynamic discovery patterns:"
grep -n "for.*in.*json" path/to/YourTest.swift
```

### Results Summary

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| TestDataFactory count | 0 | [__] | [ ] PASS / [ ] FAIL |
| JSON loading count | > 0 | [__] | [ ] PASS / [ ] FAIL |
| Hardcoded counts | 0 | [__] | [ ] PASS / [ ] FAIL |
| Dynamic discovery | > 0 | [__] | [ ] PASS / [ ] FAIL |

---

## ✅ Final Self-Review

### CLAUDE.md Compliance Questions

Answer each question honestly:

1. **Does production JSON exist for this feature?**
   - [ ] Yes - and I'm using it
   - [ ] Yes - but I'm using TestDataFactory (justified above)
   - [ ] No - feature has no JSON yet

2. **Would these tests catch real JSON data quality issues?**
   - [ ] Yes - tests validate JSON structure and content
   - [ ] Partial - tests validate some but not all JSON aspects
   - [ ] No - tests only validate synthetic data

3. **Are there hardcoded expectations that shouldn't exist?**
   - [ ] No - tests adapt dynamically
   - [ ] Yes - but documented why (see above)

4. **Did I apply "Senior Engineering Advisor" role to my own work?**
   - [ ] Yes - challenged approach, validated against CLAUDE.md
   - [ ] No - proceeded without validating architecture

### Re-Read Required Sections

Before marking complete, re-read:

- [ ] CLAUDE.md "Test Architecture Principles (MANDATORY)" section
- [ ] CLAUDE.md "Testing Requirements" section
- [ ] CLAUDE.md "Communication Style & Technical Approach" (apply to self)

---

## ✅ Compliance Status

**Final Declaration** (choose one):

- [ ] ✅ **COMPLIANT** - Uses production JSON, follows all principles
- [ ] ⚠️ **COMPLIANT WITH EXCEPTION** - Uses TestDataFactory with valid justification documented above
- [ ] ❌ **NON-COMPLIANT** - Violates architecture principles (must refactor before committing)

**Reason if Non-Compliant**:
```
[Explain what needs to be fixed]
```

---

## 📋 Commit Message Template

If compliant, use this commit message structure:

```
test: [Add/Refactor] [FeatureName] tests with JSON-driven approach

- Load from production JSON in Sources/Core/Data/Content/[Type]/
- Dynamic discovery across [N] JSON files
- Property-based validation of [specific properties]
- [Any other relevant changes]

Architecture Compliance:
- TestDataFactory usage: [0 occurrences / Justified (reason)]
- JSON loading: [N] occurrences
- Dynamic discovery: ✅ Implemented
- Hardcoded counts: ❌ None

Validates real production data quality issues.
```

---

## 🚨 Red Flags Checklist

If ANY of these are true, tests are NON-COMPLIANT:

- [ ] ❌ Component test uses `createBasicTestData()` when JSON exists
- [ ] ❌ "Fixed" test by increasing synthetic data count
- [ ] ❌ Hardcoded expected counts like `XCTAssertEqual(patterns.count, 5)`
- [ ] ❌ Tests pass with TestDataFactory but would fail with real JSON
- [ ] ❌ grep shows 0 JSON loading but feature has JSON files
- [ ] ❌ No documented justification for TestDataFactory usage

**If any red flags present, STOP and refactor before committing.**
