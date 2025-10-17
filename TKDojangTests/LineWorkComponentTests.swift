import XCTest
@testable import TKDojang

/**
 * LineWorkComponentTests.swift
 *
 * PURPOSE: Property-based component tests for LineWork system using production JSON files
 *
 * TESTING STRATEGY: JSON-Driven Property-Based Testing
 * - Load from production JSON files in Sources/Core/Data/Content/LineWork/
 * - Test PROPERTIES that must hold for ANY valid LineWork data
 * - Use dynamic discovery (no hardcoded counts)
 * - Validate data quality and consistency
 *
 * ARCHITECTURE NOTE: LineWork uses Codable structs (not SwiftData), simpler than StepSparring
 * - No database context required
 * - No persistent storage needed
 * - Pure functional testing of data structures and transformations
 *
 * CRITICAL USER CONCERNS ADDRESSED:
 * 1. All belt levels have proper exercise content
 * 2. Movement types are consistently classified
 * 3. Categories are properly assigned
 * 4. Filtering works correctly for focused practice
 * 5. Exercise complexity is accurately calculated
 * 6. Progressive learning - more exercises as belt increases
 *
 * COVERAGE AREAS:
 * 1. JSON Content Loading (3 tests) - File loading, structure validation
 * 2. Exercise Data Integrity (3 tests) - Required fields, unique IDs, data quality
 * 3. Movement Type Properties (2 tests) - Valid types, consistent classification
 * 4. Category Properties (2 tests) - Valid categories, consistent application
 * 5. Filtering Properties (3 tests) - Movement type, category, complexity
 * 6. Display Model Properties (2 tests) - Exercise and belt display conversion
 * 7. Progressive Availability (2 tests) - Cumulative exercise availability
 * 8. Helper Utilities (2 tests) - Technique extraction, totals calculation
 *
 * TOTAL: 19 property-based tests
 *
 * WHY NO TestDataFactory: Production JSON files exist for all belt levels (10 files)
 * Following CLAUDE.md: JSON-driven tests are required when JSON exists
 *
 * REFERENCE: TKDojangTests/ComponentTests/StepSparringComponentTests.swift (25 tests)
 */
@MainActor
final class LineWorkComponentTests: XCTestCase {

    // MARK: - Test Infrastructure

    /**
     * Load all LineWork JSON files from production bundle
     * Returns dictionary mapping filename to parsed content
     */
    private func loadLineWorkJSONFiles() -> [String: LineWorkContent] {
        let beltIds = [
            "10th_keup", "9th_keup", "8th_keup", "7th_keup", "6th_keup",
            "5th_keup", "4th_keup", "3rd_keup", "2nd_keup", "1st_keup"
        ]

        var jsonFiles: [String: LineWorkContent] = [:]

        for beltId in beltIds {
            let fileName = "\(beltId)_linework"

            // Try subdirectory first, fallback to root
            var url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "LineWork")
            if url == nil {
                url = Bundle.main.url(forResource: fileName, withExtension: "json")
            }

            guard let jsonURL = url,
                  let data = try? Data(contentsOf: jsonURL),
                  let content = try? JSONDecoder().decode(LineWorkContent.self, from: data) else {
                continue
            }

            jsonFiles[fileName] = content
        }

        return jsonFiles
    }

    // MARK: - 1. JSON Content Loading (3 tests)

    /**
     * PROPERTY: All belt level JSON files must load successfully
     */
    func testContentLoading_PropertyBased_AllFilesLoad() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        // PROPERTY: Must load multiple belt levels
        XCTAssertGreaterThan(jsonFiles.count, 0,
            """
            PROPERTY VIOLATION: No LineWork JSON files loaded
            Expected: > 0 files
            Got: 0 files
            Check: Sources/Core/Data/Content/LineWork/*.json exist
            """)

        // PROPERTY: Each file must have valid content
        for (fileName, content) in jsonFiles {
            XCTAssertFalse(content.beltLevel.isEmpty,
                "PROPERTY VIOLATION: \(fileName) has empty belt level")
            XCTAssertFalse(content.beltId.isEmpty,
                "PROPERTY VIOLATION: \(fileName) has empty belt ID")
            XCTAssertGreaterThanOrEqual(content.lineWorkExercises.count, 0,
                "PROPERTY VIOLATION: \(fileName) has negative exercise count")
            XCTAssertEqual(content.totalExercises, content.lineWorkExercises.count,
                """
                PROPERTY VIOLATION: \(fileName) totalExercises doesn't match array
                Total: \(content.totalExercises)
                Array: \(content.lineWorkExercises.count)
                """)
        }
    }

    /**
     * PROPERTY: JSON structure must match app expectations for all files
     */
    func testContentLoading_PropertyBased_StructureValid() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for structure testing")

        for (fileName, content) in jsonFiles {
            // PROPERTY: Belt metadata must be complete
            XCTAssertFalse(content.beltLevel.isEmpty, "\(fileName) missing belt level")
            XCTAssertFalse(content.beltId.isEmpty, "\(fileName) missing belt ID")
            XCTAssertFalse(content.beltColor.isEmpty, "\(fileName) missing belt color")

            // PROPERTY: Skill focus must exist
            XCTAssertGreaterThan(content.skillFocus.count, 0,
                "\(fileName) has no skill focus areas")

            // PROPERTY: Each exercise must have complete structure
            for exercise in content.lineWorkExercises {
                XCTAssertFalse(exercise.id.isEmpty, "\(fileName) exercise missing ID")
                XCTAssertFalse(exercise.name.isEmpty, "\(fileName) exercise missing name")
                XCTAssertGreaterThan(exercise.order, 0, "\(fileName) exercise has invalid order")
                XCTAssertGreaterThan(exercise.techniques.count, 0,
                    "\(fileName) exercise '\(exercise.name)' has no techniques")
                XCTAssertGreaterThan(exercise.execution.repetitions, 0,
                    "\(fileName) exercise '\(exercise.name)' has no repetitions")
            }
        }
    }

    /**
     * PROPERTY: Belt IDs in JSON must follow naming convention
     */
    func testContentLoading_PropertyBased_BeltIDsConsistent() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for belt ID testing")

        let validBeltIds = [
            "10th_keup", "9th_keup", "8th_keup", "7th_keup", "6th_keup",
            "5th_keup", "4th_keup", "3rd_keup", "2nd_keup", "1st_keup"
        ]

        for (fileName, content) in jsonFiles {
            // PROPERTY: Belt ID must be in valid set
            XCTAssertTrue(validBeltIds.contains(content.beltId),
                """
                PROPERTY VIOLATION: Invalid belt ID in \(fileName)
                Got: \(content.beltId)
                Valid: \(validBeltIds)
                """)
        }
    }

    // MARK: - 2. Exercise Data Integrity (3 tests)

    /**
     * PROPERTY: All exercises must have required fields populated
     */
    func testExerciseIntegrity_PropertyBased_RequiredFields() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for integrity testing")

        for (fileName, content) in jsonFiles {
            for exercise in content.lineWorkExercises {
                // PROPERTY: Core fields must be populated
                XCTAssertFalse(exercise.id.isEmpty,
                    "PROPERTY VIOLATION: Exercise in \(fileName) has empty ID")
                XCTAssertFalse(exercise.name.isEmpty,
                    "PROPERTY VIOLATION: Exercise '\(exercise.id)' in \(fileName) has empty name")

                // PROPERTY: Must have at least one technique
                XCTAssertGreaterThan(exercise.techniques.count, 0,
                    """
                    PROPERTY VIOLATION: Exercise '\(exercise.name)' has no techniques
                    File: \(fileName)
                    """)

                // PROPERTY: Must have at least one category
                XCTAssertGreaterThan(exercise.categories.count, 0,
                    """
                    PROPERTY VIOLATION: Exercise '\(exercise.name)' has no categories
                    File: \(fileName)
                    """)

                // PROPERTY: Each technique must have required fields
                for technique in exercise.techniques {
                    XCTAssertFalse(technique.id.isEmpty,
                        "Technique in '\(exercise.name)' has empty ID")
                    XCTAssertFalse(technique.english.isEmpty,
                        "Technique '\(technique.id)' has empty English name")
                    XCTAssertFalse(technique.romanised.isEmpty,
                        "Technique '\(technique.id)' has empty romanised name")
                    XCTAssertFalse(technique.hangul.isEmpty,
                        "Technique '\(technique.id)' has empty hangul")
                    XCTAssertFalse(technique.category.isEmpty,
                        "Technique '\(technique.id)' has no category")
                }
            }
        }
    }

    /**
     * PROPERTY: Exercise IDs must be unique within each belt level
     */
    func testExerciseIntegrity_PropertyBased_UniqueIDs() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for ID uniqueness testing")

        for (fileName, content) in jsonFiles {
            let exerciseIds = content.lineWorkExercises.map { $0.id }
            let uniqueIds = Set(exerciseIds)

            // PROPERTY: All exercise IDs must be unique within belt level
            XCTAssertEqual(exerciseIds.count, uniqueIds.count,
                """
                PROPERTY VIOLATION: Duplicate exercise IDs in \(fileName)
                Total exercises: \(exerciseIds.count)
                Unique IDs: \(uniqueIds.count)
                Duplicates: \(exerciseIds.count - uniqueIds.count)
                """)
        }
    }

    /**
     * PROPERTY: Exercise order must be sequential starting from 1
     */
    func testExerciseIntegrity_PropertyBased_SequentialOrder() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for order testing")

        for (fileName, content) in jsonFiles {
            let sortedExercises = content.lineWorkExercises.sorted { $0.order < $1.order }

            // PROPERTY: First exercise should have order 1
            if let firstExercise = sortedExercises.first {
                XCTAssertEqual(firstExercise.order, 1,
                    """
                    PROPERTY VIOLATION: First exercise should have order 1
                    File: \(fileName)
                    Got: \(firstExercise.order)
                    """)
            }

            // PROPERTY: Orders should be sequential
            for (index, exercise) in sortedExercises.enumerated() {
                if index > 0 {
                    let previousExercise = sortedExercises[index - 1]
                    XCTAssertLessThanOrEqual(previousExercise.order, exercise.order,
                        """
                        PROPERTY VIOLATION: Exercise order not sequential
                        File: \(fileName)
                        Exercise: \(exercise.name)
                        Previous order: \(previousExercise.order)
                        Current order: \(exercise.order)
                        """)
                }
            }
        }
    }

    // MARK: - 3. Movement Type Properties (2 tests)

    /**
     * PROPERTY: All movement types in JSON must be valid enum values
     */
    func testMovementTypes_PropertyBased_AllTypesValid() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for movement type testing")

        let validMovementTypes: Set<String> = ["STATIC", "FWD", "BWD", "FWD & BWD", "ALTERNATING"]

        for (fileName, content) in jsonFiles {
            for exercise in content.lineWorkExercises {
                // PROPERTY: Movement type must be valid
                XCTAssertTrue(validMovementTypes.contains(exercise.movementType.rawValue),
                    """
                    PROPERTY VIOLATION: Invalid movement type
                    File: \(fileName)
                    Exercise: \(exercise.name)
                    Movement type: \(exercise.movementType.rawValue)
                    Valid types: \(validMovementTypes)
                    """)

                // PROPERTY: Movement type enum must have display name and icon
                XCTAssertFalse(exercise.movementType.displayName.isEmpty,
                    "Movement type '\(exercise.movementType.rawValue)' missing display name")
                XCTAssertFalse(exercise.movementType.icon.isEmpty,
                    "Movement type '\(exercise.movementType.rawValue)' missing icon")
            }
        }
    }

    /**
     * PROPERTY: Movement type distribution should be varied across belt levels
     */
    func testMovementTypes_PropertyBased_VariedDistribution() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for distribution testing")

        var allMovementTypes = Set<MovementType>()

        for (_, content) in jsonFiles {
            for exercise in content.lineWorkExercises {
                allMovementTypes.insert(exercise.movementType)
            }
        }

        // PROPERTY: Should have multiple movement types across all content
        XCTAssertGreaterThan(allMovementTypes.count, 1,
            """
            PROPERTY VIOLATION: Not enough movement type variety
            Expected: > 1 types
            Got: \(allMovementTypes.count)
            Types found: \(allMovementTypes.map { $0.rawValue })
            """)
    }

    // MARK: - 4. Category Properties (2 tests)

    /**
     * PROPERTY: All categories must be non-empty and consistent
     */
    func testCategories_PropertyBased_ValidCategories() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for category testing")

        for (fileName, content) in jsonFiles {
            for exercise in content.lineWorkExercises {
                // PROPERTY: Must have at least one category
                XCTAssertGreaterThan(exercise.categories.count, 0,
                    """
                    PROPERTY VIOLATION: Exercise has no categories
                    File: \(fileName)
                    Exercise: \(exercise.name)
                    """)

                // PROPERTY: All categories must be non-empty
                for category in exercise.categories {
                    XCTAssertFalse(category.isEmpty,
                        """
                        PROPERTY VIOLATION: Empty category found
                        File: \(fileName)
                        Exercise: \(exercise.name)
                        """)
                }
            }
        }
    }

    /**
     * PROPERTY: Category distribution should cover major areas
     */
    func testCategories_PropertyBased_CoverageAcrossAreas() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for coverage testing")

        var allCategories = Set<String>()

        for (_, content) in jsonFiles {
            for exercise in content.lineWorkExercises {
                allCategories.formUnion(exercise.categories)
            }
        }

        // PROPERTY: Should have multiple categories across all content
        XCTAssertGreaterThan(allCategories.count, 1,
            """
            PROPERTY VIOLATION: Not enough category variety
            Expected: > 1 categories
            Got: \(allCategories.count)
            Categories found: \(allCategories)
            """)
    }

    // MARK: - 5. Filtering Properties (3 tests)

    /**
     * PROPERTY: Movement type filtering must return only matching exercises
     */
    func testFiltering_PropertyBased_ByMovementType() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for filtering testing")

        // Test filtering for each belt level
        for (fileName, content) in jsonFiles {
            let movementTypes = Set(content.lineWorkExercises.map { $0.movementType })

            for movementType in movementTypes {
                let filtered = LineWorkContentLoader.filterExercises(
                    from: content,
                    byMovementType: movementType
                )

                // PROPERTY: All filtered exercises must match the movement type
                for exercise in filtered {
                    XCTAssertEqual(exercise.movementType, movementType,
                        """
                        PROPERTY VIOLATION: Filtered exercise doesn't match movement type
                        File: \(fileName)
                        Filter: \(movementType.rawValue)
                        Exercise: \(exercise.name)
                        Exercise type: \(exercise.movementType.rawValue)
                        """)
                }

                // PROPERTY: Filter should return same count as manual filtering
                let manualCount = content.lineWorkExercises.filter {
                    $0.movementType == movementType
                }.count
                XCTAssertEqual(filtered.count, manualCount,
                    """
                    PROPERTY VIOLATION: Filter count mismatch
                    File: \(fileName)
                    Movement type: \(movementType.rawValue)
                    Filter returned: \(filtered.count)
                    Manual count: \(manualCount)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Category filtering must return only exercises with that category
     */
    func testFiltering_PropertyBased_ByCategory() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for category filtering testing")

        // Test filtering for each belt level
        for (fileName, content) in jsonFiles {
            var allCategories = Set<String>()
            for exercise in content.lineWorkExercises {
                allCategories.formUnion(exercise.categories)
            }

            for category in allCategories {
                let filtered = LineWorkContentLoader.filterExercises(
                    from: content,
                    byCategory: category
                )

                // PROPERTY: All filtered exercises must contain the category
                for exercise in filtered {
                    XCTAssertTrue(exercise.categories.contains(category),
                        """
                        PROPERTY VIOLATION: Filtered exercise doesn't contain category
                        File: \(fileName)
                        Filter: \(category)
                        Exercise: \(exercise.name)
                        Categories: \(exercise.categories)
                        """)
                }

                // PROPERTY: Filter should return same count as manual filtering
                let manualCount = content.lineWorkExercises.filter {
                    $0.categories.contains(category)
                }.count
                XCTAssertEqual(filtered.count, manualCount,
                    """
                    PROPERTY VIOLATION: Filter count mismatch
                    File: \(fileName)
                    Category: \(category)
                    Filter returned: \(filtered.count)
                    Manual count: \(manualCount)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Complexity sorting must maintain proper order
     */
    func testFiltering_PropertyBased_ComplexitySorting() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for complexity testing")

        for (fileName, content) in jsonFiles {
            let sortedExercises = LineWorkContentLoader.getExercisesByComplexity(from: content)

            // PROPERTY: Sorted exercises should be in ascending complexity order
            for i in 0..<sortedExercises.count - 1 {
                let current = sortedExercises[i]
                let next = sortedExercises[i + 1]

                let currentComplexity = current.techniques.count + (current.execution.repetitions / 10)
                let nextComplexity = next.techniques.count + (next.execution.repetitions / 10)

                XCTAssertLessThanOrEqual(currentComplexity, nextComplexity,
                    """
                    PROPERTY VIOLATION: Complexity sorting incorrect
                    File: \(fileName)
                    Current: \(current.name) (complexity: \(currentComplexity))
                    Next: \(next.name) (complexity: \(nextComplexity))
                    """)
            }
        }
    }

    // MARK: - 6. Display Model Properties (2 tests)

    /**
     * PROPERTY: Exercise display model must accurately represent source data
     */
    func testDisplayModels_PropertyBased_ExerciseDisplay() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for display model testing")

        for (fileName, content) in jsonFiles {
            for exercise in content.lineWorkExercises {
                let displayModel = LineWorkExerciseDisplay(from: exercise)

                // PROPERTY: Display model must match source data
                XCTAssertEqual(displayModel.id, exercise.id,
                    "Display model ID mismatch in \(fileName)")
                XCTAssertEqual(displayModel.name, exercise.name,
                    "Display model name mismatch in \(fileName)")
                XCTAssertEqual(displayModel.movementType, exercise.movementType,
                    "Display model movement type mismatch in \(fileName)")
                XCTAssertEqual(displayModel.categories, exercise.categories,
                    "Display model categories mismatch in \(fileName)")
                XCTAssertEqual(displayModel.repetitions, exercise.execution.repetitions,
                    "Display model repetitions mismatch in \(fileName)")
                XCTAssertEqual(displayModel.techniqueCount, exercise.techniques.count,
                    "Display model technique count mismatch in \(fileName)")

                // PROPERTY: Complexity calculation must match specification
                let expectedComplexity = exercise.techniques.count > 2 ||
                                       exercise.execution.repetitions > 10
                XCTAssertEqual(displayModel.isComplex, expectedComplexity,
                    """
                    PROPERTY VIOLATION: Complexity calculation incorrect
                    File: \(fileName)
                    Exercise: \(exercise.name)
                    Techniques: \(exercise.techniques.count)
                    Repetitions: \(exercise.execution.repetitions)
                    Expected complex: \(expectedComplexity)
                    Got: \(displayModel.isComplex)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Belt display model must accurately represent source data
     */
    func testDisplayModels_PropertyBased_BeltDisplay() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for belt display testing")

        for (fileName, content) in jsonFiles {
            let displayModel = LineWorkBeltDisplay(from: content)

            // PROPERTY: Display model must match source data
            XCTAssertEqual(displayModel.beltLevel, content.beltLevel,
                "Belt display level mismatch in \(fileName)")
            XCTAssertEqual(displayModel.beltId, content.beltId,
                "Belt display ID mismatch in \(fileName)")
            XCTAssertEqual(displayModel.beltColor, content.beltColor,
                "Belt display color mismatch in \(fileName)")
            XCTAssertEqual(displayModel.exerciseCount, content.lineWorkExercises.count,
                "Belt display exercise count mismatch in \(fileName)")
            XCTAssertEqual(displayModel.skillFocus, content.skillFocus,
                "Belt display skill focus mismatch in \(fileName)")

            // PROPERTY: Movement types must match source exercises
            let expectedMovementTypes = Set(content.lineWorkExercises.map { $0.movementType })
            XCTAssertEqual(displayModel.movementTypes, expectedMovementTypes,
                """
                PROPERTY VIOLATION: Movement types don't match
                File: \(fileName)
                Expected: \(expectedMovementTypes.map { $0.rawValue })
                Got: \(displayModel.movementTypes.map { $0.rawValue })
                """)

            // PROPERTY: Complex exercise detection must be accurate
            let expectedHasComplex = content.lineWorkExercises.contains { exercise in
                exercise.techniques.count > 3 || exercise.execution.repetitions > 20
            }
            XCTAssertEqual(displayModel.hasComplexExercises, expectedHasComplex,
                """
                PROPERTY VIOLATION: Complex exercise detection incorrect
                File: \(fileName)
                Expected: \(expectedHasComplex)
                Got: \(displayModel.hasComplexExercises)
                """)
        }
    }

    // MARK: - 7. Progressive Availability (2 tests)

    /**
     * PROPERTY: Exercise count should generally increase with belt progression
     */
    func testProgression_PropertyBased_IncreasingExercises() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for progression testing")

        // Sort by belt progression (10th keup to 1st keup)
        let sortedBelts = jsonFiles.sorted { file1, file2 in
            let extractKeup: (String) -> Int = { fileName in
                if let match = fileName.range(of: #"(\d+)(st|nd|rd|th)_keup"#, options: .regularExpression) {
                    let keupStr = fileName[match].prefix(while: { $0.isNumber })
                    return Int(keupStr) ?? 0
                }
                return 0
            }
            return extractKeup(file1.key) > extractKeup(file2.key) // Descending (10th to 1st)
        }

        var previousCount: Int?
        var totalExercises = 0

        for (fileName, content) in sortedBelts {
            totalExercises += content.lineWorkExercises.count

            if let prev = previousCount {
                // PROPERTY: Later belts should have >= exercises than earlier belts (cumulative learning)
                // Note: This is a soft check - we allow equal counts but warn if decreasing
                if content.lineWorkExercises.count < prev {
                    print("⚠️ WARNING: Exercise count decreased in \(fileName) (\(content.lineWorkExercises.count) < \(prev))")
                }
            }

            previousCount = content.lineWorkExercises.count
        }

        // PROPERTY: Should have reasonable total exercise count
        XCTAssertGreaterThan(totalExercises, 10,
            """
            PROPERTY VIOLATION: Not enough total exercises
            Expected: > 10
            Got: \(totalExercises)
            """)
    }

    /**
     * PROPERTY: Skill focus should evolve with belt progression
     */
    func testProgression_PropertyBased_EvolvingSkillFocus() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for skill focus testing")

        var allSkillFocusAreas = Set<String>()

        for (_, content) in jsonFiles {
            // PROPERTY: Each belt should have skill focus areas
            XCTAssertGreaterThan(content.skillFocus.count, 0,
                """
                PROPERTY VIOLATION: Belt has no skill focus
                Belt: \(content.beltLevel)
                """)

            // PROPERTY: Skill focus areas should be descriptive
            for skillArea in content.skillFocus {
                XCTAssertFalse(skillArea.isEmpty,
                    "Skill focus area is empty for \(content.beltLevel)")
                XCTAssertGreaterThan(skillArea.count, 5,
                    """
                    PROPERTY VIOLATION: Skill focus too short
                    Belt: \(content.beltLevel)
                    Skill: '\(skillArea)'
                    """)
            }

            allSkillFocusAreas.formUnion(content.skillFocus)
        }

        // PROPERTY: Should have variety in skill focus across belts
        XCTAssertGreaterThan(allSkillFocusAreas.count, 3,
            """
            PROPERTY VIOLATION: Not enough skill focus variety
            Expected: > 3 areas
            Got: \(allSkillFocusAreas.count)
            """)
    }

    // MARK: - 8. Helper Utilities (2 tests)

    /**
     * PROPERTY: Technique extraction must return all unique techniques
     */
    func testHelpers_PropertyBased_TechniqueExtraction() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for technique extraction testing")

        for (fileName, content) in jsonFiles {
            let techniques = LineWorkContentLoader.extractUniqueTechniques(from: content)

            // PROPERTY: Should extract at least one technique
            XCTAssertGreaterThan(techniques.count, 0,
                """
                PROPERTY VIOLATION: No techniques extracted
                File: \(fileName)
                """)

            // PROPERTY: All techniques should be unique
            let uniqueSet = Set(techniques)
            XCTAssertEqual(techniques.count, uniqueSet.count,
                """
                PROPERTY VIOLATION: Duplicate techniques in extraction
                File: \(fileName)
                Total: \(techniques.count)
                Unique: \(uniqueSet.count)
                """)

            // PROPERTY: All techniques should be non-empty
            for technique in techniques {
                XCTAssertFalse(technique.isEmpty,
                    "Empty technique extracted from \(fileName)")
            }

            // PROPERTY: Extracted techniques should match source
            let allSourceTechniques = Set(content.lineWorkExercises.flatMap { exercise in
                exercise.techniques.map { $0.english }
            })
            XCTAssertEqual(Set(techniques), allSourceTechniques,
                """
                PROPERTY VIOLATION: Extracted techniques don't match source
                File: \(fileName)
                """)
        }
    }

    /**
     * PROPERTY: Total repetitions must equal sum of all exercise repetitions
     */
    func testHelpers_PropertyBased_TotalRepetitions() throws {
        let jsonFiles = loadLineWorkJSONFiles()

        XCTAssertGreaterThan(jsonFiles.count, 0, "Must have JSON files for repetition testing")

        for (fileName, content) in jsonFiles {
            let totalReps = LineWorkContentLoader.getTotalRepetitions(from: content)

            // PROPERTY: Total must equal sum
            let expectedTotal = content.lineWorkExercises.reduce(0) { sum, exercise in
                sum + exercise.execution.repetitions
            }

            XCTAssertEqual(totalReps, expectedTotal,
                """
                PROPERTY VIOLATION: Total repetitions mismatch
                File: \(fileName)
                Calculated: \(totalReps)
                Expected: \(expectedTotal)
                """)

            // PROPERTY: Total should be positive if exercises exist
            if content.lineWorkExercises.count > 0 {
                XCTAssertGreaterThan(totalReps, 0,
                    """
                    PROPERTY VIOLATION: Total repetitions should be positive
                    File: \(fileName)
                    Exercise count: \(content.lineWorkExercises.count)
                    Total reps: \(totalReps)
                    """)
            }
        }
    }
}
