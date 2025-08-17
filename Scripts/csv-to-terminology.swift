#!/usr/bin/env swift

import Foundation

/**
 * CSV to Terminology JSON Converter
 * 
 * PURPOSE: Standalone tool to convert CSV content into TKDojang terminology JSON files
 * 
 * USAGE:
 * 1. Create CSV file with columns: English Term, Korean Hangul, Romanized, Phonetic, Definition, Category, Difficulty, Belt Level
 * 2. Run: swift csv-to-terminology.swift input.csv output_directory
 * 
 * CSV FORMAT EXAMPLE:
 * English Term,Korean Hangul,Romanized,Phonetic,Definition,Category,Difficulty,Belt Level
 * Front kick,앞차기,ap chagi,ap cha-gi,A basic forward kicking technique,techniques,2,8th_keup
 * Attention,차렷,charyeot,cha-ryət,Standing at attention position,basics,1,10th_keup
 */

// MARK: - Data Models

struct TerminologyEntry: Codable {
    let english_term: String
    let korean_hangul: String
    let romanized_pronunciation: String
    let phonetic_pronunciation: String?
    let definition: String?
    let category: String
    let difficulty: Int
    let belt_level: String
    let created_at: String
    
    init(englishTerm: String, koreanHangul: String, romanized: String, phonetic: String?, 
         definition: String?, category: String, difficulty: Int, beltLevel: String) {
        self.english_term = englishTerm
        self.korean_hangul = koreanHangul
        self.romanized_pronunciation = romanized
        self.phonetic_pronunciation = phonetic?.isEmpty == true ? nil : phonetic
        self.definition = definition?.isEmpty == true ? nil : definition
        self.category = category
        self.difficulty = difficulty
        self.belt_level = beltLevel
        
        let formatter = ISO8601DateFormatter()
        self.created_at = formatter.string(from: Date())
    }
}

struct TerminologyCollection: Codable {
    let belt_level: String
    let category: String
    let terminology: [TerminologyEntry]
    let metadata: Metadata
    
    struct Metadata: Codable {
        let created_at: String
        let total_count: Int
        let source: String
        
        init(totalCount: Int) {
            let formatter = ISO8601DateFormatter()
            self.created_at = formatter.string(from: Date())
            self.total_count = totalCount
            self.source = "CSV Import Tool"
        }
    }
}

// MARK: - CSV Parser

class CSVParser {
    func parseCSV(fileURL: URL) throws -> [TerminologyEntry] {
        let content = try String(contentsOf: fileURL)
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard lines.count > 1 else {
            throw CSVError.emptyFile
        }
        
        // Skip header row
        let dataLines = Array(lines.dropFirst())
        var entries: [TerminologyEntry] = []
        
        for (index, line) in dataLines.enumerated() {
            do {
                let entry = try parseLine(line, lineNumber: index + 2)
                entries.append(entry)
            } catch {
                print("⚠️ Warning: Skipping line \(index + 2): \(error)")
            }
        }
        
        return entries
    }
    
    private func parseLine(_ line: String, lineNumber: Int) throws -> TerminologyEntry {
        let fields = parseCSVLine(line)
        
        guard fields.count >= 7 else {
            throw CSVError.insufficientFields(lineNumber: lineNumber, fieldCount: fields.count)
        }
        
        let englishTerm = fields[0].trimmingCharacters(in: .whitespaces)
        let koreanHangul = fields[1].trimmingCharacters(in: .whitespaces)
        let romanized = fields[2].trimmingCharacters(in: .whitespaces)
        let phonetic = fields.count > 3 ? fields[3].trimmingCharacters(in: .whitespaces) : nil
        let definition = fields.count > 4 ? fields[4].trimmingCharacters(in: .whitespaces) : nil
        let category = fields.count > 5 ? fields[5].trimmingCharacters(in: .whitespaces) : "general"
        let difficultyString = fields.count > 6 ? fields[6].trimmingCharacters(in: .whitespaces) : "1"
        let beltLevel = fields.count > 7 ? fields[7].trimmingCharacters(in: .whitespaces) : "10th_keup"
        
        guard !englishTerm.isEmpty, !koreanHangul.isEmpty, !romanized.isEmpty else {
            throw CSVError.missingRequiredFields(lineNumber: lineNumber)
        }
        
        let difficulty = Int(difficultyString) ?? 1
        
        return TerminologyEntry(
            englishTerm: englishTerm,
            koreanHangul: koreanHangul,
            romanized: romanized,
            phonetic: phonetic,
            definition: definition,
            category: category,
            difficulty: difficulty,
            beltLevel: beltLevel
        )
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        fields.append(currentField) // Add the last field
        return fields
    }
}

// MARK: - JSON Generator

class JSONGenerator {
    func generateJSONFiles(entries: [TerminologyEntry], outputDirectory: URL) throws {
        // Group entries by belt level and category
        let groupedEntries = Dictionary(grouping: entries) { entry in
            "\(entry.belt_level)_\(entry.category)"
        }
        
        for (key, entries) in groupedEntries {
            let components = key.components(separatedBy: "_")
            guard components.count >= 2 else { continue }
            
            let beltLevel = components[0] + "_" + components[1] // Handle "10th_keup" format
            let category = components.dropFirst(2).joined(separator: "_")
            
            let collection = TerminologyCollection(
                belt_level: beltLevel,
                category: category,
                terminology: entries.sorted { $0.english_term < $1.english_term },
                metadata: TerminologyCollection.Metadata(totalCount: entries.count)
            )
            
            // Write JSON file with belt name prefix directly to output directory
            let fileName = "\(beltLevel)_\(category).json"
            let fileURL = outputDirectory.appendingPathComponent(fileName)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            let jsonData = try encoder.encode(collection)
            try jsonData.write(to: fileURL)
            
            print("✅ Created: \(fileName) (\(entries.count) terms)")
        }
    }
}

// MARK: - Error Types

enum CSVError: Error, LocalizedError {
    case emptyFile
    case insufficientFields(lineNumber: Int, fieldCount: Int)
    case missingRequiredFields(lineNumber: Int)
    case invalidDifficulty(lineNumber: Int, value: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "CSV file is empty or contains no data rows"
        case .insufficientFields(let lineNumber, let fieldCount):
            return "Line \(lineNumber): Expected at least 7 fields, found \(fieldCount)"
        case .missingRequiredFields(let lineNumber):
            return "Line \(lineNumber): Missing required fields (English Term, Korean Hangul, or Romanized)"
        case .invalidDifficulty(let lineNumber, let value):
            return "Line \(lineNumber): Invalid difficulty value '\(value)' (should be 1-5)"
        }
    }
}

// MARK: - Main Function

func main() {
    let arguments = CommandLine.arguments
    
    guard arguments.count >= 3 else {
        printUsage()
        exit(1)
    }
    
    let inputPath = arguments[1]
    let outputPath = arguments[2]
    
    let inputURL = URL(fileURLWithPath: inputPath)
    let outputURL = URL(fileURLWithPath: outputPath)
    
    do {
        print("🔄 Reading CSV file: \(inputPath)")
        
        let parser = CSVParser()
        let entries = try parser.parseCSV(fileURL: inputURL)
        
        print("📊 Parsed \(entries.count) terminology entries")
        
        // Show summary by belt and category
        let summary = Dictionary(grouping: entries) { "\($0.belt_level) - \($0.category)" }
        print("\n📋 Content Summary:")
        for (key, entries) in summary.sorted(by: { $0.key < $1.key }) {
            print("   \(key): \(entries.count) terms")
        }
        
        print("\n🏗️ Generating JSON files in: \(outputPath)")
        
        let generator = JSONGenerator()
        try generator.generateJSONFiles(entries: entries, outputDirectory: outputURL)
        
        print("\n✅ Conversion completed successfully!")
        print("📁 Files created in: \(outputURL.path)")
        
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
}

func printUsage() {
    print("""
    TKDojang CSV to Terminology JSON Converter
    
    USAGE:
        swift csv-to-terminology.swift <input_csv_file> <output_directory>
    
    CSV FORMAT:
        English Term,Korean Hangul,Romanized,Phonetic,Definition,Category,Difficulty,Belt Level
    
    EXAMPLE:
        swift csv-to-terminology.swift terminology.csv ../TKDojang/Sources/Core/Data/Content/Belts/
    
    BELT LEVELS:
        10th_keup, 9th_keup, 8th_keup, 7th_keup, 6th_keup, 5th_keup, 4th_keup, 3rd_keup, 2nd_keup, 1st_keup,
        1st_dan, 2nd_dan, 3rd_dan, 4th_dan, 5th_dan
    
    CATEGORIES:
        basics, numbers, techniques, stances, blocks, strikes, kicks, patterns, titles, philosophy
    """)
}

// Run the main function
main()