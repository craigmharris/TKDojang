import XCTest
import SwiftData
@testable import TKDojang

/// Diagnostic test to isolate the BeltLevel fetch crash
@MainActor
final class DiagnosticTest: XCTestCase {

    func testBareMinimumBeltLevelFetch() throws {
        // Create fresh container
        let schema = Schema([BeltLevel.self])
        let testDatabaseURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "DiagnosticTest_\(UUID().uuidString).sqlite")
        let configuration = ModelConfiguration(schema: schema, url: testDatabaseURL, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        // Create ONE BeltLevel with NO modifications
        let belt = BeltLevel(
            name: "10th Keup (White Belt)",
            shortName: "10th Keup",
            colorName: "White",
            sortOrder: 15,
            isKyup: true
        )

        // Insert and save
        context.insert(belt)
        try context.save()

        // Try to fetch - THIS IS WHERE ProfileDataTests crashes
        let fetched = try context.fetch(FetchDescriptor<BeltLevel>())

        XCTAssertEqual(fetched.count, 1, "Should fetch the one belt we created")
        XCTAssertEqual(fetched.first?.name, "10th Keup (White Belt)")
    }
}
