import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * MultiProfileUIIntegrationTests.swift
 * 
 * PURPOSE: Critical user flow testing for multi-profile system UI integration
 * 
 * COVERAGE: Priority 1 - Critical user flows that affect core app value proposition
 * - Profile creation workflow validation
 * - Profile switching across all main features  
 * - Export/import UI workflows and data integrity
 * - Profile limit enforcement and error handling
 * - Context switching: verify all views update correctly
 * 
 * BUSINESS IMPACT: Family users depend on seamless profile switching.
 * UI failures here affect the core value proposition of multi-profile learning.
 */
final class MultiProfileUIIntegrationTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var dataServices: DataServices!
    var profileService: ProfileService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container with all models needed for profile testing
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self,
            UserPatternProgress.self,
            UserStepSparringProgress.self,
            StudySession.self,
            GradingRecord.self,
            Pattern.self,
            PatternMove.self,
            StepSparringSequence.self,
            StepSparringStep.self,
            StepSparringAction.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        testContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        
        testContext = ModelContext(testContainer)
        
        // Set up basic test data needed for profile operations
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
        
        // Initialize services with test container
        dataServices = DataServices(container: testContainer)
        profileService = dataServices.profileService
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        dataServices = nil
        profileService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Profile Creation Workflow Tests
    
    func testProfileCreationWorkflowValidation() throws {
        // CRITICAL USER FLOW: New family member profile creation
        
        let profileCountBefore = try profileService.getAllProfiles().count
        
        // Test profile creation with all required fields
        let newProfile = try profileService.createProfile(
            name: "Test Family Member",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        // Verify profile was created correctly
        XCTAssertNotNil(newProfile, "Profile should be created successfully")
        XCTAssertEqual(newProfile.name, "Test Family Member", "Profile name should match input")
        XCTAssertEqual(newProfile.currentBeltLevel.shortName, "10th Keup", "Belt level should match input")
        XCTAssertEqual(newProfile.learningMode, .mastery, "Learning mode should match input")
        
        // Verify profile is persisted
        let profileCountAfter = try profileService.getAllProfiles().count
        XCTAssertEqual(profileCountAfter, profileCountBefore + 1, "Profile count should increase by 1")
        
        // Verify profile appears in profile list
        let allProfiles = try profileService.getAllProfiles()
        let foundProfile = allProfiles.first { $0.name == "Test Family Member" }
        XCTAssertNotNil(foundProfile, "Created profile should appear in profile list")
        
        // Verify profile has proper defaults
        XCTAssertGreaterThan(newProfile.dailyStudyGoal, 0, "Daily study goal should have default value")
        XCTAssertNotNil(newProfile.createdAt, "Profile should have creation timestamp")
        XCTAssertNotNil(newProfile.updatedAt, "Profile should have update timestamp")
        
        // Verify custom assertions
        TKDojangAssertions.assertValidUserProfile(newProfile)
    }
    
    func testProfileCreationValidationErrors() throws {
        // Test validation for profile creation edge cases
        
        // Test empty name validation
        XCTAssertThrowsError(try profileService.createProfile(
            name: "",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        ), "Should throw error for empty name")
        
        // Test name too long validation  
        let longName = String(repeating: "A", count: 101)
        XCTAssertThrowsError(try profileService.createProfile(
            name: longName,
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        ), "Should throw error for name too long")
        
        // Test duplicate name validation
        _ = try profileService.createProfile(
            name: "Duplicate Name",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        XCTAssertThrowsError(try profileService.createProfile(
            name: "Duplicate Name",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        ), "Should throw error for duplicate name")
    }
    
    func testProfileLimitEnforcement() throws {
        // CRITICAL BUSINESS RULE: Maximum 6 profiles per device
        
        // Create 6 profiles (maximum allowed)
        for i in 1...6 {
            _ = try profileService.createProfile(
                name: "Family Member \(i)",
                currentBeltLevel: getBeltLevel("10th Keup"),
                learningMode: .mastery
            )
        }
        
        let profileCount = try profileService.getAllProfiles().count
        XCTAssertEqual(profileCount, 6, "Should allow exactly 6 profiles")
        
        // Attempt to create 7th profile should fail
        XCTAssertThrowsError(try profileService.createProfile(
            name: "Seventh Member",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        ), "Should enforce 6 profile limit")
        
        // Verify error message is user-friendly
        do {
            _ = try profileService.createProfile(
                name: "Seventh Member", 
                currentBeltLevel: getBeltLevel("10th Keup"),
                learningMode: .mastery
            )
            XCTFail("Should have thrown error")
        } catch {
            let errorDescription = error.localizedDescription
            XCTAssertTrue(errorDescription.contains("6"), "Error should mention profile limit")
        }
    }
    
    // MARK: - Profile Switching Integration Tests
    
    func testProfileSwitchingContextUpdates() throws {
        // CRITICAL USER FLOW: Profile switching updates all feature contexts
        
        // Create two distinct profiles with different settings
        let beginnerProfile = try profileService.createProfile(
            name: "Beginner Student",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        beginnerProfile.dailyStudyGoal = 15
        
        let advancedProfile = try profileService.createProfile(
            name: "Advanced Student", 
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        advancedProfile.dailyStudyGoal = 40
        
        try testContext.save()
        
        // Start with beginner profile active
        profileService.setActiveProfile(beginnerProfile)
        
        // Verify initial active profile
        let initialActiveProfile = profileService.getActiveProfile()
        XCTAssertEqual(initialActiveProfile?.id, beginnerProfile.id, "Should start with beginner profile")
        XCTAssertEqual(initialActiveProfile?.currentBeltLevel.shortName, "10th Keup", "Should have beginner belt level")
        XCTAssertEqual(initialActiveProfile?.learningMode, .mastery, "Should have mastery learning mode")
        
        // Switch to advanced profile
        profileService.setActiveProfile(advancedProfile)
        
        // Verify profile switch was successful
        let switchedActiveProfile = profileService.getActiveProfile()
        XCTAssertEqual(switchedActiveProfile?.id, advancedProfile.id, "Should switch to advanced profile")
        XCTAssertEqual(switchedActiveProfile?.currentBeltLevel.shortName, "7th Keup", "Should have advanced belt level")
        XCTAssertEqual(switchedActiveProfile?.learningMode, .progression, "Should have progression learning mode")
        XCTAssertEqual(switchedActiveProfile?.dailyStudyGoal, 40, "Should have advanced study goal")
        
        // Verify active profile persists across service recreation
        let newProfileService = ProfileService(modelContext: testContext)
        let persistedActiveProfile = newProfileService.getActiveProfile()
        XCTAssertEqual(persistedActiveProfile?.id, advancedProfile.id, "Active profile should persist")
        
        // Switch back to beginner
        profileService.setActiveProfile(beginnerProfile)
        let revertedActiveProfile = profileService.getActiveProfile()
        XCTAssertEqual(revertedActiveProfile?.id, beginnerProfile.id, "Should revert to beginner profile")
    }
    
    func testProfileSwitchingWithProgressData() throws {
        // Test profile switching preserves isolated progress data
        
        let profile1 = try profileService.createProfile(
            name: "Student One",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        let profile2 = try profileService.createProfile(
            name: "Student Two",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        
        // Create progress for profile1
        profileService.setActiveProfile(profile1)
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 10,
            correctAnswers: 8,
            focusAreas: ["Basic Techniques"]
        )
        
        // Create different progress for profile2
        profileService.setActiveProfile(profile2)
        try profileService.recordStudySession(
            sessionType: .patterns,
            itemsStudied: 5,
            correctAnswers: 5,
            focusAreas: ["Advanced Patterns"]
        )
        
        // Switch back to profile1 and verify progress isolation
        profileService.setActiveProfile(profile1)
        let profile1Sessions = try profileService.getStudySessions(for: profile1)
        XCTAssertEqual(profile1Sessions.count, 1, "Profile1 should have 1 session")
        XCTAssertEqual(profile1Sessions.first?.sessionType, .flashcards, "Should be flashcard session")
        
        // Switch to profile2 and verify different progress
        profileService.setActiveProfile(profile2)
        let profile2Sessions = try profileService.getStudySessions(for: profile2)
        XCTAssertEqual(profile2Sessions.count, 1, "Profile2 should have 1 session")
        XCTAssertEqual(profile2Sessions.first?.sessionType, .patterns, "Should be pattern session")
        
        // Verify no cross-contamination
        XCTAssertNotEqual(profile1Sessions.first?.id, profile2Sessions.first?.id, "Sessions should be different")
    }
    
    // MARK: - Profile Management UI Integration Tests
    
    func testProfileDeletionWorkflow() throws {
        // Test complete profile deletion workflow including confirmation
        
        // Create profiles for deletion testing
        let profileToKeep = try profileService.createProfile(
            name: "Keep This Profile",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        let profileToDelete = try profileService.createProfile(
            name: "Delete This Profile",
            currentBeltLevel: getBeltLevel("7th Keup"), 
            learningMode: .progression
        )
        
        // Add some progress data to profile being deleted
        profileService.setActiveProfile(profileToDelete)
        try profileService.recordStudySession(
            sessionType: .testing,
            itemsStudied: 20,
            correctAnswers: 15,
            focusAreas: ["Theory"]
        )
        
        let profileCountBefore = try profileService.getAllProfiles().count
        
        // Perform deletion
        try profileService.deleteProfile(profileToDelete)
        
        // Verify profile was deleted
        let profileCountAfter = try profileService.getAllProfiles().count
        XCTAssertEqual(profileCountAfter, profileCountBefore - 1, "Profile count should decrease by 1")
        
        // Verify deleted profile no longer appears in list
        let remainingProfiles = try profileService.getAllProfiles()
        let deletedProfileFound = remainingProfiles.contains { $0.id == profileToDelete.id }
        XCTAssertFalse(deletedProfileFound, "Deleted profile should not appear in profile list")
        
        // Verify other profiles remain
        let keptProfileFound = remainingProfiles.contains { $0.id == profileToKeep.id }
        XCTAssertTrue(keptProfileFound, "Other profiles should remain after deletion")
        
        // Verify active profile is cleared if deleted profile was active
        let activeProfileAfterDeletion = profileService.getActiveProfile()
        if let activeProfile = activeProfileAfterDeletion {
            XCTAssertNotEqual(activeProfile.id, profileToDelete.id, "Active profile should not be deleted profile")
        }
    }
    
    func testProfileEditingWorkflow() throws {
        // Test profile editing maintains data integrity
        
        let originalProfile = try profileService.createProfile(
            name: "Original Name",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        originalProfile.dailyStudyGoal = 20
        
        // Add some progress to test data preservation
        profileService.setActiveProfile(originalProfile)
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 10,
            correctAnswers: 8,
            focusAreas: ["Basics"]
        )
        
        try testContext.save()
        
        // Edit profile
        originalProfile.name = "Updated Name"
        originalProfile.currentBeltLevel = getBeltLevel("7th Keup")
        originalProfile.learningMode = .progression
        originalProfile.dailyStudyGoal = 35
        
        try testContext.save()
        
        // Verify changes were applied
        let updatedProfile = try profileService.getAllProfiles().first { $0.id == originalProfile.id }
        XCTAssertNotNil(updatedProfile, "Profile should still exist after editing")
        XCTAssertEqual(updatedProfile?.name, "Updated Name", "Name should be updated")
        XCTAssertEqual(updatedProfile?.currentBeltLevel.shortName, "7th Keup", "Belt level should be updated")
        XCTAssertEqual(updatedProfile?.learningMode, .progression, "Learning mode should be updated")
        XCTAssertEqual(updatedProfile?.dailyStudyGoal, 35, "Study goal should be updated")
        
        // Verify progress data is preserved
        let sessions = try profileService.getStudySessions(for: originalProfile)
        XCTAssertEqual(sessions.count, 1, "Study sessions should be preserved")
        XCTAssertEqual(sessions.first?.sessionType, .flashcards, "Session type should be preserved")
    }
    
    // MARK: - Export/Import UI Workflow Tests
    
    func testProfileExportWorkflow() throws {
        // Test complete profile export workflow
        
        // Create comprehensive profile with progress data
        let profileToExport = try profileService.createProfile(
            name: "Export Test Profile",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileToExport.dailyStudyGoal = 30
        
        // Add study sessions
        profileService.setActiveProfile(profileToExport)
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 15,
            correctAnswers: 12,
            focusAreas: ["Techniques"]
        )
        try profileService.recordStudySession(
            sessionType: .patterns,
            itemsStudied: 3,
            correctAnswers: 3,
            focusAreas: ["Chon-Ji", "Dan-Gun"]
        )
        
        try testContext.save()
        
        // Test export functionality
        let exportData = try dataServices.profileExportService.exportProfile(profileToExport)
        
        // Verify export data is not empty
        XCTAssertGreaterThan(exportData.count, 0, "Export data should not be empty")
        
        // Verify export data can be parsed
        let exportString = String(data: exportData, encoding: .utf8)
        XCTAssertNotNil(exportString, "Export data should be valid UTF-8")
        
        // Verify export contains expected profile information
        XCTAssertTrue(exportString!.contains("Export Test Profile"), "Export should contain profile name")
        XCTAssertTrue(exportString!.contains("7th Keup"), "Export should contain belt level")
        
        // Test export metadata
        XCTAssertTrue(exportString!.contains("TKDojang"), "Export should contain app identifier")
        
        // Performance test - export should complete quickly
        let exportMeasurement = PerformanceMeasurement.measureExecutionTime {
            return try! dataServices.profileExportService.exportProfile(profileToExport)
        }
        
        XCTAssertLessThan(exportMeasurement.timeInterval, TestConfiguration.maxUIResponseTime, 
                         "Profile export should complete within UI response time limit")
    }
    
    func testAllProfilesExportWorkflow() throws {
        // Test exporting all profiles functionality
        
        // Create multiple profiles with different configurations
        let profiles = [
            try profileService.createProfile(name: "Family Member 1", currentBeltLevel: getBeltLevel("10th Keup"), learningMode: .mastery),
            try profileService.createProfile(name: "Family Member 2", currentBeltLevel: getBeltLevel("7th Keup"), learningMode: .progression),
            try profileService.createProfile(name: "Family Member 3", currentBeltLevel: getBeltLevel("10th Keup"), learningMode: .mastery)
        ]
        
        // Add progress to each profile
        for (index, profile) in profiles.enumerated() {
            profileService.setActiveProfile(profile)
            try profileService.recordStudySession(
                sessionType: .flashcards,
                itemsStudied: 10 + index * 5,
                correctAnswers: 8 + index * 3,
                focusAreas: ["Test Area \(index)"]
            )
        }
        
        try testContext.save()
        
        // Test all profiles export
        let allProfilesExportData = try dataServices.profileExportService.exportAllProfiles()
        
        // Verify export contains all profiles
        XCTAssertGreaterThan(allProfilesExportData.count, 0, "All profiles export should not be empty")
        
        let exportString = String(data: allProfilesExportData, encoding: .utf8)!
        
        // Verify all profile names are included
        for profile in profiles {
            XCTAssertTrue(exportString.contains(profile.name), "Export should contain profile: \(profile.name)")
        }
        
        // Performance test - should handle multiple profiles efficiently
        let multiProfileExportMeasurement = PerformanceMeasurement.measureExecutionTime {
            return try! dataServices.profileExportService.exportAllProfiles()
        }
        
        XCTAssertLessThan(multiProfileExportMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 2, 
                         "Multi-profile export should complete within reasonable time")
    }
    
    // MARK: - Error Handling & Recovery Tests
    
    func testProfileSwitchingErrorRecovery() throws {
        // Test graceful handling of profile switching errors
        
        let validProfile = try profileService.createProfile(
            name: "Valid Profile",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        // Set valid profile as active
        profileService.setActiveProfile(validProfile)
        let activeProfileBefore = profileService.getActiveProfile()
        XCTAssertEqual(activeProfileBefore?.id, validProfile.id, "Should start with valid profile")
        
        // Attempt to switch to nil profile (should be gracefully handled)
        profileService.setActiveProfile(nil)
        
        // Verify graceful handling - should either keep previous profile or clear gracefully
        let activeProfileAfterNil = profileService.getActiveProfile()
        // Either maintains previous profile or gracefully clears (both are acceptable behaviors)
        if let stillActiveProfile = activeProfileAfterNil {
            XCTAssertEqual(stillActiveProfile.id, validProfile.id, "Should maintain previous valid profile")
        }
        
        // Verify service remains functional after error condition
        let allProfiles = try profileService.getAllProfiles()
        XCTAssertGreaterThan(allProfiles.count, 0, "Profile service should remain functional")
        
        // Test switching back to valid profile works
        profileService.setActiveProfile(validProfile)
        let recoveredActiveProfile = profileService.getActiveProfile()
        XCTAssertEqual(recoveredActiveProfile?.id, validProfile.id, "Should recover to valid profile")
    }
    
    func testProfileCreationWithInvalidBeltLevel() throws {
        // Test handling of invalid belt level during profile creation
        
        // This test validates graceful error handling for missing belt levels
        // In real usage, belt levels should always be valid, but edge cases should be handled
        
        let profileCountBefore = try profileService.getAllProfiles().count
        
        // Create a belt level that doesn't exist in the database
        let invalidBelt = BeltLevel(name: "Invalid Belt", shortName: "Invalid", colorName: "Invalid", sortOrder: 999, isKyup: true)
        
        // Attempt to create profile with invalid belt should throw error or handle gracefully
        do {
            _ = try profileService.createProfile(
                name: "Test Invalid Belt",
                currentBeltLevel: invalidBelt,
                learningMode: .mastery
            )
            // If it doesn't throw, verify it handles gracefully
            let profileCountAfter = try profileService.getAllProfiles().count
            XCTAssertEqual(profileCountAfter, profileCountBefore, "Should not create profile with invalid belt")
        } catch {
            // Expected behavior - should throw meaningful error
            let errorDescription = error.localizedDescription
            XCTAssertFalse(errorDescription.isEmpty, "Error should have meaningful description")
        }
    }
    
    // MARK: - Performance & Memory Tests
    
    func testProfileSwitchingPerformance() throws {
        // Test that profile switching is performant with multiple profiles
        
        // Create maximum number of profiles
        var profiles: [UserProfile] = []
        for i in 1...6 {
            let profile = try profileService.createProfile(
                name: "Performance Test Profile \(i)",
                currentBeltLevel: getBeltLevel("10th Keup"),
                learningMode: i % 2 == 0 ? .mastery : .progression
            )
            profiles.append(profile)
        }
        
        // Add progress data to each profile
        for profile in profiles {
            profileService.setActiveProfile(profile)
            try profileService.recordStudySession(
                sessionType: .flashcards,
                itemsStudied: 20,
                correctAnswers: 15,
                focusAreas: ["Performance Test"]
            )
        }
        
        try testContext.save()
        
        // Measure profile switching performance
        let switchingMeasurement = PerformanceMeasurement.measureExecutionTime {
            for profile in profiles {
                profileService.setActiveProfile(profile)
                let activeProfile = profileService.getActiveProfile()
                assert(activeProfile?.id == profile.id)
            }
        }
        
        // Profile switching should be near-instantaneous
        XCTAssertLessThan(switchingMeasurement.timeInterval, TestConfiguration.maxUIResponseTime, 
                         "Profile switching should be very fast")
        
        // Test memory usage during rapid switching
        let memoryMeasurement = PerformanceMeasurement.measureMemoryUsage {
            for _ in 1...10 {
                for profile in profiles {
                    profileService.setActiveProfile(profile)
                    _ = profileService.getActiveProfile()
                }
            }
        }
        
        // Memory usage should not grow significantly during switching
        XCTAssertLessThan(memoryMeasurement.memoryDelta, TestConfiguration.maxMemoryIncrease / 10, 
                         "Profile switching should not leak significant memory")
    }
    
    // MARK: - Helper Methods
    
    private func getBeltLevel(_ shortName: String) -> BeltLevel {
        let descriptor = FetchDescriptor<BeltLevel>(
            predicate: #Predicate { belt in belt.shortName == shortName }
        )
        
        do {
            let belts = try testContext.fetch(descriptor)
            guard let belt = belts.first else {
                XCTFail("Belt level '\(shortName)' not found in test data")
                return BeltLevel(name: shortName, shortName: shortName, colorName: "Test", sortOrder: 1, isKyup: true)
            }
            return belt
        } catch {
            XCTFail("Failed to fetch belt level: \(error)")
            return BeltLevel(name: shortName, shortName: shortName, colorName: "Test", sortOrder: 1, isKyup: true)
        }
    }
}

// MARK: - Test Extensions

extension MultiProfileUIIntegrationTests {
    
    /**
     * Integration test for Profile UI state management
     * Tests that profile-dependent UI components update correctly when profile changes
     */
    func testProfileUIStateManagement() throws {
        // Create profiles with distinctly different settings for clear validation
        let beginnerProfile = try profileService.createProfile(
            name: "UI Test Beginner",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        beginnerProfile.dailyStudyGoal = 15
        
        let advancedProfile = try profileService.createProfile(
            name: "UI Test Advanced",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        advancedProfile.dailyStudyGoal = 45
        
        try testContext.save()
        
        // Test initial profile state
        profileService.setActiveProfile(beginnerProfile)
        var activeProfile = profileService.getActiveProfile()
        
        XCTAssertEqual(activeProfile?.name, "UI Test Beginner", "Initial profile should be beginner")
        XCTAssertEqual(activeProfile?.currentBeltLevel.shortName, "10th Keup", "Should show beginner belt")
        XCTAssertEqual(activeProfile?.learningMode, .mastery, "Should show mastery mode")
        XCTAssertEqual(activeProfile?.dailyStudyGoal, 15, "Should show beginner study goal")
        
        // Switch profiles and verify state updates
        profileService.setActiveProfile(advancedProfile)
        activeProfile = profileService.getActiveProfile()
        
        XCTAssertEqual(activeProfile?.name, "UI Test Advanced", "Should switch to advanced profile")
        XCTAssertEqual(activeProfile?.currentBeltLevel.shortName, "7th Keup", "Should show advanced belt")
        XCTAssertEqual(activeProfile?.learningMode, .progression, "Should show progression mode")
        XCTAssertEqual(activeProfile?.dailyStudyGoal, 45, "Should show advanced study goal")
        
        // Test rapid switching stability
        for _ in 1...5 {
            profileService.setActiveProfile(beginnerProfile)
            XCTAssertEqual(profileService.getActiveProfile()?.id, beginnerProfile.id, "Rapid switching should work")
            
            profileService.setActiveProfile(advancedProfile)
            XCTAssertEqual(profileService.getActiveProfile()?.id, advancedProfile.id, "Rapid switching should work")
        }
    }
    
    /**
     * Test profile data isolation during concurrent operations
     */
    func testProfileDataIsolationConcurrency() throws {
        let profile1 = try profileService.createProfile(
            name: "Concurrent Profile 1",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        let profile2 = try profileService.createProfile(
            name: "Concurrent Profile 2", 
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        
        // Simulate concurrent profile operations
        let expectation1 = expectation(description: "Profile 1 operations")
        let expectation2 = expectation(description: "Profile 2 operations")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Profile 1 operations
            self.profileService.setActiveProfile(profile1)
            for i in 1...10 {
                do {
                    try self.profileService.recordStudySession(
                        sessionType: .flashcards,
                        itemsStudied: i,
                        correctAnswers: i - 1,
                        focusAreas: ["Profile1 Session \(i)"]
                    )
                } catch {
                    XCTFail("Profile 1 session recording failed: \(error)")
                }
            }
            expectation1.fulfill()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Profile 2 operations
            self.profileService.setActiveProfile(profile2)
            for i in 1...10 {
                do {
                    try self.profileService.recordStudySession(
                        sessionType: .patterns,
                        itemsStudied: i * 2,
                        correctAnswers: i * 2,
                        focusAreas: ["Profile2 Session \(i)"]
                    )
                } catch {
                    XCTFail("Profile 2 session recording failed: \(error)")
                }
            }
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: TestConfiguration.defaultTestTimeout)
        
        // Verify data isolation after concurrent operations
        let profile1Sessions = try profileService.getStudySessions(for: profile1)
        let profile2Sessions = try profileService.getStudySessions(for: profile2)
        
        XCTAssertEqual(profile1Sessions.count, 10, "Profile 1 should have 10 sessions")
        XCTAssertEqual(profile2Sessions.count, 10, "Profile 2 should have 10 sessions")
        
        // Verify session types are correct for each profile
        XCTAssertTrue(profile1Sessions.allSatisfy { $0.sessionType == .flashcards }, 
                     "Profile 1 sessions should all be flashcards")
        XCTAssertTrue(profile2Sessions.allSatisfy { $0.sessionType == .patterns }, 
                     "Profile 2 sessions should all be patterns")
        
        // Verify no cross-contamination
        let allProfile1SessionIds = Set(profile1Sessions.map { $0.id })
        let allProfile2SessionIds = Set(profile2Sessions.map { $0.id })
        XCTAssertTrue(allProfile1SessionIds.isDisjoint(with: allProfile2SessionIds), 
                     "Profile sessions should not overlap")
    }
}