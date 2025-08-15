import Foundation
import SwiftData

/**
 * TerminologySeeder.swift
 * 
 * PURPOSE: Seeds the database with initial TAGB terminology content
 * 
 * USAGE: Call during app first launch or for development/testing
 * You can modify and expand this to add your complete TAGB syllabus
 */

@MainActor
class TerminologySeeder {
    private let dataService: TerminologyDataService
    
    init(dataService: TerminologyDataService) {
        self.dataService = dataService
    }
    
    /**
     * Seeds the database with sample terminology data
     * 
     * PURPOSE: Provides initial content for testing and development
     * CUSTOMIZE: Replace with your complete TAGB terminology
     */
    func seedSampleData() {
        print("🌱 Seeding terminology database...")
        
        // Create belt levels and categories first
        let beltLevels = dataService.createBeltLevels()
        let categories = dataService.createTerminologyCategories()
        
        // Create lookup dictionaries for easy access
        let beltLevelDict = Dictionary(uniqueKeysWithValues: beltLevels.map { ($0.shortName, $0) })
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })
        
        // Seed basic terminology
        seedBasicTerms(beltLevels: beltLevelDict, categories: categoryDict)
        seedNumbers(beltLevels: beltLevelDict, categories: categoryDict)
        seedBasicTechniques(beltLevels: beltLevelDict, categories: categoryDict)
        seedStances(beltLevels: beltLevelDict, categories: categoryDict)
        
        print("✅ Terminology database seeded successfully!")
    }
    
    // MARK: - Seeding Methods
    
    private func seedBasicTerms(beltLevels: [String: BeltLevel], categories: [String: TerminologyCategory]) {
        guard let whiteBelt = beltLevels["10th Keup"],
              let basicsCategory = categories["basics"] else { return }
        
        let basicTerms = [
            ("Attention", "차렷", "cha-ryeot", "Ready position/Attention"),
            ("Bow", "경례", "kyung-rye", "Formal bow showing respect"),
            ("Begin", "시작", "si-jak", "Start or begin"),
            ("Stop", "그만", "geu-man", "Stop or finish"),
            ("Rest", "쉬어", "shwi-eo", "At ease/relax"),
            ("Taekwondo", "태권도", "tae-kwon-do", "The way of hand and foot"),
            ("Student", "제자", "je-ja", "Student or disciple"),
            ("Master", "사범님", "sa-beom-nim", "Master or instructor"),
            ("Dojang", "도장", "do-jang", "Training hall"),
            ("Dobok", "도복", "do-bok", "Training uniform")
        ]
        
        basicTerms.forEach { (english, korean, pronunciation, definition) in
            _ = dataService.addTerminologyEntry(
                englishTerm: english,
                koreanHangul: korean,
                romanizedPronunciation: pronunciation,
                beltLevel: whiteBelt,
                category: basicsCategory,
                difficulty: 1,
                definition: definition
            )
        }
    }
    
    private func seedNumbers(beltLevels: [String: BeltLevel], categories: [String: TerminologyCategory]) {
        guard let whiteBelt = beltLevels["10th Keup"],
              let numbersCategory = categories["numbers"] else { return }
        
        let numbers = [
            ("One", "하나", "ha-na", "Number 1"),
            ("Two", "둘", "dul", "Number 2"),
            ("Three", "셋", "set", "Number 3"),
            ("Four", "넷", "net", "Number 4"),
            ("Five", "다섯", "da-seot", "Number 5"),
            ("Six", "여섯", "yeo-seot", "Number 6"),
            ("Seven", "일곱", "il-gop", "Number 7"),
            ("Eight", "여덟", "yeo-deol", "Number 8"),
            ("Nine", "아홉", "a-hop", "Number 9"),
            ("Ten", "열", "yeol", "Number 10")
        ]
        
        numbers.forEach { (english, korean, pronunciation, definition) in
            _ = dataService.addTerminologyEntry(
                englishTerm: english,
                koreanHangul: korean,
                romanizedPronunciation: pronunciation,
                beltLevel: whiteBelt,
                category: numbersCategory,
                difficulty: 1,
                definition: definition
            )
        }
    }
    
    private func seedBasicTechniques(beltLevels: [String: BeltLevel], categories: [String: TerminologyCategory]) {
        guard let whiteBelt = beltLevels["10th Keup"],
              let yellowBelt = beltLevels["8th Keup"],
              let techniquesCategory = categories["techniques"] else { return }
        
        let whiteBeltTechniques = [
            ("Punch", "지르기", "ji-reu-gi", "Basic punching technique"),
            ("Block", "막기", "mak-gi", "Basic blocking technique"),
            ("Kick", "차기", "cha-gi", "Basic kicking technique")
        ]
        
        whiteBeltTechniques.forEach { (english, korean, pronunciation, definition) in
            _ = dataService.addTerminologyEntry(
                englishTerm: english,
                koreanHangul: korean,
                romanizedPronunciation: pronunciation,
                beltLevel: whiteBelt,
                category: techniquesCategory,
                difficulty: 1,
                definition: definition
            )
        }
        
        let yellowBeltTechniques = [
            ("Front kick", "앞차기", "ap-cha-gi", "Kick with the ball of the foot forward"),
            ("Rising block", "올려막기", "ol-lyeo-mak-gi", "Upward blocking technique"),
            ("Middle punch", "몸통지르기", "mom-tong-ji-reu-gi", "Punch to the middle section")
        ]
        
        yellowBeltTechniques.forEach { (english, korean, pronunciation, definition) in
            _ = dataService.addTerminologyEntry(
                englishTerm: english,
                koreanHangul: korean,
                romanizedPronunciation: pronunciation,
                beltLevel: yellowBelt,
                category: techniquesCategory,
                difficulty: 2,
                definition: definition
            )
        }
    }
    
    private func seedStances(beltLevels: [String: BeltLevel], categories: [String: TerminologyCategory]) {
        guard let whiteBelt = beltLevels["10th Keup"],
              let stancesCategory = categories["stances"] else { return }
        
        let stances = [
            ("Attention stance", "차렷서기", "cha-ryeot-seo-gi", "Feet together, body straight"),
            ("Parallel stance", "나란히서기", "na-ran-hi-seo-gi", "Feet parallel, shoulder width apart"),
            ("Walking stance", "걷기서기", "geot-gi-seo-gi", "Natural walking position"),
            ("Front stance", "앞서기", "ap-seo-gi", "Long stance with front leg bent"),
            ("Back stance", "뒤서기", "dwi-seo-gi", "Weight on back leg, front leg light")
        ]
        
        stances.forEach { (english, korean, pronunciation, definition) in
            _ = dataService.addTerminologyEntry(
                englishTerm: english,
                koreanHangul: korean,
                romanizedPronunciation: pronunciation,
                beltLevel: whiteBelt,
                category: stancesCategory,
                difficulty: 2,
                definition: definition
            )
        }
    }
}

// MARK: - Helper Extensions

extension TerminologySeeder {
    /**
     * Adds a complete belt level's worth of terminology
     * 
     * USAGE: Call this method to add all terms for a specific belt
     * CUSTOMIZE: Replace with your actual TAGB syllabus requirements
     */
    func seedBeltLevel(_ beltName: String, terms: [(english: String, korean: String, pronunciation: String, category: String, definition: String?)]) {
        // Implementation for bulk adding terms for a specific belt level
        // This makes it easier to organize your content by belt requirements
    }
    
    /**
     * Validates that all seeded content is correctly formatted
     */
    func validateSeededContent() -> Bool {
        // Add validation logic to ensure Korean characters are valid Hangul
        // Check pronunciation formatting
        // Verify belt level assignments are correct
        return true
    }
}