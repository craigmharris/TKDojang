import XCTest
import SwiftData
@testable import TKDojang

/**
 * TheoryTechniquesDataTests.swift
 *
 * PURPOSE: Property-based tests for Theory and Techniques reference data
 *
 * TESTING STRATEGY: Property-Based Testing
 * - Test PROPERTIES that must hold for ANY valid reference data
 * - Use randomization where applicable
 * - Validate JSON-driven content loading
 *
 * DESIGN NOTE: Theory and Techniques are read-only JSON-based reference systems
 * with no SwiftData models or user progress tracking. Tests focus on data
 * loading, filtering, and search functionality.
 *
 * COVERAGE AREAS:
 * 1. Techniques Data Loading Properties (3 tests) - JSON loading and caching
 * 2. Techniques Filtering Properties (3 tests) - Belt/category/search filtering
 * 3. Techniques Data Integrity (2 tests) - Required fields and IDs
 * 4. Theory Data Loading Properties (2 tests) - Belt-specific content loading
 * 5. Theory Data Structure Properties (2 tests) - Sections and questions
 *
 * TOTAL: 12 property-based tests
 */
@MainActor
final class TheoryTechniquesDataTests: XCTestCase {
    var techniqueService: TechniquesDataService!

    override func setUp() {
        super.setUp()
        techniqueService = TechniquesDataService()
    }

    override func tearDown() {
        techniqueService = nil
        super.tearDown()
    }

    // MARK: - 1. Techniques Data Loading Properties (3 tests)

    /**
     * PROPERTY: Technique service must load data successfully
     */
    func testTechniquesLoading_PropertyBased_LoadsSuccessfully() async throws {
        await techniqueService.loadAllTechniques()

        let allTechniques = techniqueService.getAllTechniques()

        // PROPERTY: Must load at least some techniques
        XCTAssertGreaterThan(allTechniques.count, 0,
            """
            PROPERTY VIOLATION: No techniques loaded
            Expected: > 0 techniques
            Got: 0 techniques
            """)

        // PROPERTY: Loading error should be nil on success
        XCTAssertNil(techniqueService.loadingError,
            "PROPERTY VIOLATION: Loading error should be nil after successful load")
    }

    /**
     * PROPERTY: Categories must load correctly
     */
    func testTechniquesLoading_PropertyBased_CategoriesLoadCorrectly() async throws {
        await techniqueService.loadAllTechniques()

        let categories = techniqueService.getCategories()

        // PROPERTY: Must have at least one category
        XCTAssertGreaterThan(categories.count, 0,
            "PROPERTY VIOLATION: No categories loaded")

        // PROPERTY: Each category must have required fields
        for category in categories {
            XCTAssertFalse(category.id.isEmpty,
                "PROPERTY VIOLATION: Category has empty ID")
            XCTAssertFalse(category.name.isEmpty,
                "PROPERTY VIOLATION: Category '\(category.id)' has empty name")
            XCTAssertFalse(category.file.isEmpty,
                "PROPERTY VIOLATION: Category '\(category.id)' has no file reference")
        }
    }

    /**
     * PROPERTY: Techniques grouped by category must match total count
     */
    func testTechniquesLoading_PropertyBased_CategoryGroupingConsistency() async throws {
        await techniqueService.loadAllTechniques()

        let allTechniques = techniqueService.getAllTechniques()
        let categories = Set(allTechniques.map { $0.category })

        var techniquesByCategory = 0

        for category in categories {
            let techniques = techniqueService.getTechniques(for: category)
            techniquesByCategory += techniques.count
        }

        // PROPERTY: Sum of techniques by category must equal total
        XCTAssertEqual(techniquesByCategory, allTechniques.count,
            """
            PROPERTY VIOLATION: Category grouping inconsistent
            Total techniques: \(allTechniques.count)
            Sum by category: \(techniquesByCategory)
            """)
    }

    // MARK: - 2. Techniques Filtering Properties (3 tests)

    /**
     * PROPERTY: Belt level filtering must only return appropriate techniques
     */
    func testTechniquesFiltering_PropertyBased_BeltLevelFiltering() async throws {
        await techniqueService.loadAllTechniques()

        let filterOptions = techniqueService.getFilterOptions()
        let beltLevels = filterOptions.beltLevels

        // Test with 3 random belt levels
        for _ in 0..<min(3, beltLevels.count) {
            guard let testBelt = beltLevels.randomElement() else { continue }

            let filtered = techniqueService.filterTechniques(beltLevel: testBelt)

            // PROPERTY: All returned techniques must include the belt level
            for technique in filtered {
                XCTAssertTrue(technique.beltLevels.contains(testBelt),
                    """
                    PROPERTY VIOLATION: Technique doesn't include filter belt
                    Technique: \(technique.displayName)
                    Filter belt: \(testBelt)
                    Technique belts: \(technique.beltLevels)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Category filtering must only return techniques from that category
     */
    func testTechniquesFiltering_PropertyBased_CategoryFiltering() async throws {
        await techniqueService.loadAllTechniques()

        let filterOptions = techniqueService.getFilterOptions()
        let categories = filterOptions.categories

        // Test with 3 random categories
        for _ in 0..<min(3, categories.count) {
            guard let testCategory = categories.randomElement() else { continue }

            let filtered = techniqueService.filterTechniques(category: testCategory)

            // PROPERTY: All returned techniques must match the category
            for technique in filtered {
                XCTAssertEqual(technique.category, testCategory,
                    """
                    PROPERTY VIOLATION: Technique category mismatch
                    Technique: \(technique.displayName)
                    Expected category: \(testCategory)
                    Got: \(technique.category)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Search must return techniques matching query in any field
     */
    func testTechniquesFiltering_PropertyBased_SearchReturnsMatchingResults() async throws {
        await techniqueService.loadAllTechniques()

        let allTechniques = techniqueService.getAllTechniques()

        // Test with 3 random techniques
        for _ in 0..<min(3, allTechniques.count) {
            guard let technique = allTechniques.randomElement() else { continue }

            // Search for part of the English name
            let searchTerm = String(technique.displayName.prefix(4))
            let results = techniqueService.searchTechniques(query: searchTerm)

            // PROPERTY: Results must contain the technique we searched for
            let found = results.contains { $0.id == technique.id }
            XCTAssertTrue(found,
                """
                PROPERTY VIOLATION: Search didn't find technique
                Search term: \(searchTerm)
                Expected technique: \(technique.displayName)
                Results count: \(results.count)
                """)

            // PROPERTY: All results must contain the search term somewhere
            for result in results {
                let matchesEnglish = result.displayName.lowercased().contains(searchTerm.lowercased())
                let matchesKorean = result.koreanName.contains(searchTerm)
                let matchesDescription = result.description.lowercased().contains(searchTerm.lowercased())
                let matchesTags = result.tags.contains { $0.lowercased().contains(searchTerm.lowercased()) }

                let matches = matchesEnglish || matchesKorean || matchesDescription || matchesTags

                XCTAssertTrue(matches,
                    """
                    PROPERTY VIOLATION: Search result doesn't contain search term
                    Search term: \(searchTerm)
                    Result: \(result.displayName)
                    """)
            }
        }
    }

    // MARK: - 3. Techniques Data Integrity (2 tests)

    /**
     * PROPERTY: All technique IDs must be unique
     */
    func testTechniquesIntegrity_PropertyBased_UniqueIdentifiers() async throws {
        await techniqueService.loadAllTechniques()

        let allTechniques = techniqueService.getAllTechniques()
        let ids = allTechniques.map { $0.id }
        let uniqueIds = Set(ids)

        // PROPERTY: All IDs must be unique
        XCTAssertEqual(ids.count, uniqueIds.count,
            """
            PROPERTY VIOLATION: Duplicate technique IDs found
            Total techniques: \(ids.count)
            Unique IDs: \(uniqueIds.count)
            Duplicates: \(ids.count - uniqueIds.count)
            """)
    }

    /**
     * PROPERTY: All techniques must have required fields populated
     */
    func testTechniquesIntegrity_PropertyBased_RequiredFieldsPopulated() async throws {
        await techniqueService.loadAllTechniques()

        let allTechniques = techniqueService.getAllTechniques()

        for technique in allTechniques {
            // PROPERTY: Must have ID
            XCTAssertFalse(technique.id.isEmpty,
                "PROPERTY VIOLATION: Technique has empty ID")

            // PROPERTY: Must have English name
            XCTAssertFalse(technique.displayName.isEmpty,
                "PROPERTY VIOLATION: Technique '\(technique.id)' has empty English name")

            // PROPERTY: Must have description
            XCTAssertFalse(technique.description.isEmpty,
                "PROPERTY VIOLATION: Technique '\(technique.displayName)' has empty description")

            // PROPERTY: Must have category
            XCTAssertFalse(technique.category.isEmpty,
                "PROPERTY VIOLATION: Technique '\(technique.displayName)' has no category")

            // PROPERTY: Must have at least one belt level
            XCTAssertGreaterThan(technique.beltLevels.count, 0,
                "PROPERTY VIOLATION: Technique '\(technique.displayName)' has no belt levels")

            // PROPERTY: Must have difficulty
            XCTAssertFalse(technique.difficulty.isEmpty,
                "PROPERTY VIOLATION: Technique '\(technique.displayName)' has no difficulty")
        }
    }

    // MARK: - 4. Theory Data Loading Properties (2 tests)

    /**
     * PROPERTY: Theory content must load for all belt levels
     */
    func testTheoryLoading_PropertyBased_LoadsForAllBelts() async throws {
        let theoryContent = await TheoryContentLoader.loadAllTheoryContent()

        // PROPERTY: Must load content for multiple belts
        XCTAssertGreaterThan(theoryContent.count, 0,
            "PROPERTY VIOLATION: No theory content loaded")

        // PROPERTY: Each belt must have content
        for (beltId, content) in theoryContent {
            XCTAssertFalse(content.beltLevel.isEmpty,
                "PROPERTY VIOLATION: Belt '\(beltId)' has empty belt level name")

            XCTAssertGreaterThan(content.theorySections.count, 0,
                """
                PROPERTY VIOLATION: Belt '\(beltId)' has no theory sections
                Expected: > 0 sections
                Got: 0 sections
                """)
        }
    }

    /**
     * PROPERTY: Specific belt theory content must load successfully
     */
    func testTheoryLoading_PropertyBased_SpecificBeltLoadsCorrectly() async throws {
        // Test with a known belt level
        let testBelts = ["10th_keup", "7th_keup", "1st_keup"]

        for beltId in testBelts {
            if let content = await TheoryContentLoader.loadTheoryContent(for: beltId) {
                // PROPERTY: Belt ID must match
                XCTAssertEqual(content.beltId, beltId,
                    """
                    PROPERTY VIOLATION: Belt ID mismatch
                    Requested: \(beltId)
                    Got: \(content.beltId)
                    """)

                // PROPERTY: Must have sections
                XCTAssertGreaterThan(content.theorySections.count, 0,
                    "PROPERTY VIOLATION: Belt '\(beltId)' has no theory sections")
            }
        }
    }

    // MARK: - 5. Theory Data Structure Properties (2 tests)

    /**
     * PROPERTY: Theory sections must have required structure
     */
    func testTheoryStructure_PropertyBased_SectionsHaveRequiredFields() async throws {
        let theoryContent = await TheoryContentLoader.loadAllTheoryContent()

        for (beltId, content) in theoryContent {
            for section in content.theorySections {
                // PROPERTY: Section must have ID
                XCTAssertFalse(section.id.isEmpty,
                    "PROPERTY VIOLATION: Belt '\(beltId)' section has empty ID")

                // PROPERTY: Section must have title
                XCTAssertFalse(section.title.isEmpty,
                    "PROPERTY VIOLATION: Belt '\(beltId)' section '\(section.id)' has empty title")

                // PROPERTY: Section must have category
                XCTAssertFalse(section.category.isEmpty,
                    "PROPERTY VIOLATION: Belt '\(beltId)' section '\(section.id)' has no category")

                // PROPERTY: Questions array must be valid (can be empty, but not nil)
                XCTAssertNotNil(section.questions,
                    "PROPERTY VIOLATION: Belt '\(beltId)' section '\(section.id)' has nil questions")
            }
        }
    }

    /**
     * PROPERTY: Theory questions must be extractable and well-formed
     */
    func testTheoryStructure_PropertyBased_QuestionsWellFormed() async throws {
        let theoryContent = await TheoryContentLoader.loadAllTheoryContent()

        for (beltId, content) in theoryContent {
            let questions = TheoryContentLoader.extractQuestions(from: content)

            for question in questions {
                // PROPERTY: Question text must not be empty
                XCTAssertFalse(question.question.isEmpty,
                    "PROPERTY VIOLATION: Belt '\(beltId)' has question with empty text")

                // PROPERTY: Answer must not be empty
                XCTAssertFalse(question.answer.isEmpty,
                    """
                    PROPERTY VIOLATION: Belt '\(beltId)' question has empty answer
                    Question: \(question.question)
                    """)

                // PROPERTY: Question ID must match question text
                XCTAssertEqual(question.id, question.question,
                    """
                    PROPERTY VIOLATION: Question ID doesn't match question text
                    ID: \(question.id)
                    Question: \(question.question)
                    """)
            }
        }
    }

    // MARK: - Bonus Integration Tests

    /**
     * PROPERTY: Filter options must reflect actual data
     */
    func testTechniquesIntegration_PropertyBased_FilterOptionsReflectData() async throws {
        await techniqueService.loadAllTechniques()

        let filterOptions = techniqueService.getFilterOptions()
        let allTechniques = techniqueService.getAllTechniques()

        // Extract actual values from techniques
        let actualCategories = Set(allTechniques.map { $0.category })
        let actualDifficulties = Set(allTechniques.map { $0.difficulty })

        // PROPERTY: Filter categories must match actual categories
        let filterCategories = Set(filterOptions.categories)
        XCTAssertEqual(filterCategories, actualCategories,
            """
            PROPERTY VIOLATION: Filter categories don't match actual data
            Filter categories: \(filterCategories)
            Actual categories: \(actualCategories)
            """)

        // PROPERTY: Filter difficulties must match actual difficulties
        let filterDifficulties = Set(filterOptions.difficulties)
        XCTAssertEqual(filterDifficulties, actualDifficulties,
            """
            PROPERTY VIOLATION: Filter difficulties don't match actual data
            Filter difficulties: \(filterDifficulties)
            Actual difficulties: \(actualDifficulties)
            """)
    }

    /**
     * PROPERTY: Category filtering by sections works correctly
     */
    func testTheoryIntegration_PropertyBased_CategoryFilteringWorks() async throws {
        let theoryContent = await TheoryContentLoader.loadAllTheoryContent()

        for (beltId, content) in theoryContent {
            // Get all unique categories
            let categories = Set(content.theorySections.map { $0.category })

            for category in categories {
                let filtered = TheoryContentLoader.filterSections(from: content, byCategory: category)

                // PROPERTY: All filtered sections must match category
                for section in filtered {
                    XCTAssertEqual(section.category, category,
                        """
                        PROPERTY VIOLATION: Filtered section has wrong category
                        Belt: \(beltId)
                        Expected category: \(category)
                        Got: \(section.category)
                        Section: \(section.title)
                        """)
                }

                // PROPERTY: Filter should return same count as manual filtering
                let manualCount = content.theorySections.filter { $0.category == category }.count
                XCTAssertEqual(filtered.count, manualCount,
                    """
                    PROPERTY VIOLATION: Filter count mismatch
                    Belt: \(beltId)
                    Category: \(category)
                    Filter returned: \(filtered.count)
                    Manual count: \(manualCount)
                    """)
            }
        }
    }
}
