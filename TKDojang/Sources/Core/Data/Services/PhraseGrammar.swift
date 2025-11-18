import Foundation

/**
 * PhraseGrammar.swift
 *
 * PURPOSE: Define grammatical rules for Korean Taekwondo phrase construction (7-Category System)
 *
 * FEATURES:
 * - Templates for 2-6 word phrase structures
 * - Slot definitions with allowed categories
 * - Validation rules for phrase correctness
 * - Progressive difficulty (start simple, add complexity)
 * - Based on analysis of 96 actual techniques
 *
 * 7-CATEGORY SYSTEM:
 * 1. TECHNIQUE_MODIFIER: Modifies entire technique (twin, double, flying, x, w)
 * 2. POSITION: Body part orientation (outer forearm, back fist, inner knife)
 * 3. TOOL: Body parts used (forearm, fist, palm, knife, foot, elbow)
 * 4. DIRECTION: Movement path (inward, outward, rising, turning, front kick)
 * 5. TARGET: Height sections (high, middle, low)
 * 6. EXECUTION: How action is performed (pressing, snap, guarding, wedging, checking)
 * 7. ACTION: Core technique verb - ALWAYS REQUIRED (block, kick, strike, punch, thrust)
 *
 * GRAMMAR RULES:
 * - Action is ALWAYS the last slot (required)
 * - Technique_Modifier always comes first (if present)
 * - Position comes before Tool (if both present)
 * - Execution typically penultimate (before Action)
 * - Target and Direction are flexible middle positions
 *
 * PEDAGOGY:
 * - Teaches phrase **grammar patterns**, not memorization
 * - Users learn core structures, then add complexity progressively
 * - Example progression:
 *   - 2-word: "Forearm Block" (Tool + Action)
 *   - 3-word: "Outer Forearm Block" (Position + Tool + Action)
 *   - 4-word: "Outer Forearm High Block" (Position + Tool + Target + Action)
 *   - 5-word: "Twin Outer Forearm High Block" (Technique_Modifier + Position + Tool + Target + Action)
 *   - 6-word: "Twin Outer Forearm Inward High Block" (Technique_Modifier + Position + Tool + Direction + Target + Action)
 */

// MARK: - Phrase Template

struct PhraseTemplate: Identifiable {
    let id: String
    let wordCount: Int
    let displayName: String
    let description: String
    let slots: [PhraseSlot]
    let examples: [PhraseExample]
    let difficulty: String

    /**
     * Validate if a phrase matches this template's structure
     */
    func matches(phrase: [CategorizedWord]) -> Bool {
        guard phrase.count == wordCount else { return false }

        for (index, slot) in slots.enumerated() {
            let word = phrase[index]
            if !slot.allowedCategories.contains(word.category) {
                return false
            }
        }

        return true
    }

    /**
     * Get the category expected at a specific slot index
     */
    func categoryForSlot(at index: Int) -> [WordCategory] {
        guard index < slots.count else { return [] }
        return slots[index].allowedCategories
    }
}

// MARK: - Phrase Slot

struct PhraseSlot: Identifiable {
    let id: String
    let position: Int
    let label: String
    let allowedCategories: [WordCategory]
    let isRequired: Bool

    var displayLabel: String {
        isRequired ? label : "\(label) (optional)"
    }
}

// MARK: - Phrase Example

struct PhraseExample: Identifiable {
    let id = UUID()
    let english: String
    let romanised: String
    let breakdown: [String] // Word-by-word breakdown with categories
}

// MARK: - Grammar Templates

class PhraseGrammar {

    // MARK: - Template Definitions

    /**
     * Get all available phrase templates
     */
    static func allTemplates() -> [PhraseTemplate] {
        return [
            twoWordTemplates(),
            threeWordTemplates(),
            fourWordTemplates(),
            fiveWordTemplates(),
            sixWordTemplates()
        ].flatMap { $0 }
    }

    /**
     * Get templates for a specific word count
     */
    static func templates(for wordCount: Int) -> [PhraseTemplate] {
        switch wordCount {
        case 2: return twoWordTemplates()
        case 3: return threeWordTemplates()
        case 4: return fourWordTemplates()
        case 5: return fiveWordTemplates()
        case 6: return sixWordTemplates()
        default: return []
        }
    }

    // MARK: - 2-Word Templates

    private static func twoWordTemplates() -> [PhraseTemplate] {
        return [
            // Template 1: Tool + Action (most common)
            PhraseTemplate(
                id: "2w-tool-action",
                wordCount: 2,
                displayName: "Tool + Action",
                description: "Body part plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Forearm Block",
                        romanised: "Palmok Makgi",
                        breakdown: ["Tool: Forearm", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Fist Punch",
                        romanised: "Joomuk Jirugi",
                        breakdown: ["Tool: Fist", "Action: Punch"]
                    )
                ],
                difficulty: "Beginner"
            ),

            // Template 2: Execution + Action (action modifiers)
            PhraseTemplate(
                id: "2w-execution-action",
                wordCount: 2,
                displayName: "Execution + Action",
                description: "How performed plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Execution",
                        allowedCategories: [.execution],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Pressing Block",
                        romanised: "Noollo Makgi",
                        breakdown: ["Execution: Pressing", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Snap Kick",
                        romanised: "Bituro Chagi",
                        breakdown: ["Execution: Snap", "Action: Kick"]
                    )
                ],
                difficulty: "Beginner"
            ),

            // Template 3: Direction + Action
            PhraseTemplate(
                id: "2w-direction-action",
                wordCount: 2,
                displayName: "Direction + Action",
                description: "Movement direction plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Rising Block",
                        romanised: "Chookyo Makgi",
                        breakdown: ["Direction: Rising", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Turning Kick",
                        romanised: "Dollyo Chagi",
                        breakdown: ["Direction: Turning", "Action: Kick"]
                    )
                ],
                difficulty: "Beginner"
            )
        ]
    }

    // MARK: - 3-Word Templates

    private static func threeWordTemplates() -> [PhraseTemplate] {
        return [
            // Template 1: Position + Tool + Action (VERY common)
            PhraseTemplate(
                id: "3w-position-tool-action",
                wordCount: 3,
                displayName: "Position + Tool + Action",
                description: "Body part orientation plus tool plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Position",
                        allowedCategories: [.position],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Outer Forearm Block",
                        romanised: "Bakat Palmok Makgi",
                        breakdown: ["Position: Outer", "Tool: Forearm", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Back Fist Strike",
                        romanised: "Dung Joomuk Taerigi",
                        breakdown: ["Position: Back", "Tool: Fist", "Action: Strike"]
                    )
                ],
                difficulty: "Beginner"
            ),

            // Template 2: Tool + Execution + Action
            PhraseTemplate(
                id: "3w-tool-execution-action",
                wordCount: 3,
                displayName: "Tool + Execution + Action",
                description: "Body part plus how performed plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Execution",
                        allowedCategories: [.execution],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Knife Checking Block",
                        romanised: "Sonkal Momchau Makgi",
                        breakdown: ["Tool: Knife", "Execution: Checking", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Palm Pressing Block",
                        romanised: "Sonbadak Noollo Makgi",
                        breakdown: ["Tool: Palm", "Execution: Pressing", "Action: Block"]
                    )
                ],
                difficulty: "Intermediate"
            ),

            // Template 3: Tool + Target + Action
            PhraseTemplate(
                id: "3w-tool-target-action",
                wordCount: 3,
                displayName: "Tool + Target + Action",
                description: "Body part plus target height plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Fist Middle Punch",
                        romanised: "Joomuk Kaunde Jirugi",
                        breakdown: ["Tool: Fist", "Target: Middle", "Action: Punch"]
                    ),
                    PhraseExample(
                        english: "Foot High Kick",
                        romanised: "Balkal Nopunde Chagi",
                        breakdown: ["Tool: Foot", "Target: High", "Action: Kick"]
                    )
                ],
                difficulty: "Intermediate"
            ),

            // Template 4: Technique_Modifier + Tool + Action
            PhraseTemplate(
                id: "3w-techniquemodifier-tool-action",
                wordCount: 3,
                displayName: "Technique Modifier + Tool + Action",
                description: "Whole-technique modifier plus body part plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Technique Modifier",
                        allowedCategories: [.techniqueModifier],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Twin Fist Punch",
                        romanised: "Sang Joomuk Jirugi",
                        breakdown: ["Technique Modifier: Twin", "Tool: Fist", "Action: Punch"]
                    ),
                    PhraseExample(
                        english: "Double Knife Strike",
                        romanised: "Doo Sonkal Taerigi",
                        breakdown: ["Technique Modifier: Double", "Tool: Knife", "Action: Strike"]
                    )
                ],
                difficulty: "Intermediate"
            ),

            // Template 5: Direction + Tool + Action
            PhraseTemplate(
                id: "3w-direction-tool-action",
                wordCount: 3,
                displayName: "Direction + Tool + Action",
                description: "Movement direction plus body part plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Rising Elbow Strike",
                        romanised: "Chookyo Palkup Taerigi",
                        breakdown: ["Direction: Rising", "Tool: Elbow", "Action: Strike"]
                    ),
                    PhraseExample(
                        english: "Turning Knife Strike",
                        romanised: "Dollyo Sonkal Taerigi",
                        breakdown: ["Direction: Turning", "Tool: Knife", "Action: Strike"]
                    )
                ],
                difficulty: "Intermediate"
            )
        ]
    }

    // MARK: - 4-Word Templates

    private static func fourWordTemplates() -> [PhraseTemplate] {
        return [
            // Template 1: Position + Tool + Direction + Action
            PhraseTemplate(
                id: "4w-position-tool-direction-action",
                wordCount: 4,
                displayName: "Position + Tool + Direction + Action",
                description: "Body part orientation plus tool plus movement plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Position",
                        allowedCategories: [.position],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Outer Forearm Inward Block",
                        romanised: "Bakat Palmok Anaero Makgi",
                        breakdown: ["Position: Outer", "Tool: Forearm", "Direction: Inward", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Inner Knife Outward Strike",
                        romanised: "An Sonkal Bakuro Taerigi",
                        breakdown: ["Position: Inner", "Tool: Knife", "Direction: Outward", "Action: Strike"]
                    )
                ],
                difficulty: "Advanced"
            ),

            // Template 2: Position + Tool + Target + Action
            PhraseTemplate(
                id: "4w-position-tool-target-action",
                wordCount: 4,
                displayName: "Position + Tool + Target + Action",
                description: "Body part orientation plus tool plus height plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Position",
                        allowedCategories: [.position],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Outer Forearm High Block",
                        romanised: "Bakat Palmok Nopunde Makgi",
                        breakdown: ["Position: Outer", "Tool: Forearm", "Target: High", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Inner Knife Middle Strike",
                        romanised: "An Sonkal Kaunde Taerigi",
                        breakdown: ["Position: Inner", "Tool: Knife", "Target: Middle", "Action: Strike"]
                    )
                ],
                difficulty: "Advanced"
            ),

            // Template 3: Tool + Direction + Target + Action
            PhraseTemplate(
                id: "4w-tool-direction-target-action",
                wordCount: 4,
                displayName: "Tool + Direction + Target + Action",
                description: "Body part plus movement plus height plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Knife Inward High Block",
                        romanised: "Sonkal Anaero Nopunde Makgi",
                        breakdown: ["Tool: Knife", "Direction: Inward", "Target: High", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Fist Front Middle Punch",
                        romanised: "Joomuk Apuro Kaunde Jirugi",
                        breakdown: ["Tool: Fist", "Direction: Front", "Target: Middle", "Action: Punch"]
                    )
                ],
                difficulty: "Advanced"
            ),

            // Template 4: Technique_Modifier + Tool + Execution + Action
            PhraseTemplate(
                id: "4w-techniquemodifier-tool-execution-action",
                wordCount: 4,
                displayName: "Technique Modifier + Tool + Execution + Action",
                description: "Whole-technique modifier plus tool plus how performed plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Technique Modifier",
                        allowedCategories: [.techniqueModifier],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Execution",
                        allowedCategories: [.execution],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Twin Knife Guarding Block",
                        romanised: "Sang Sonkal Daebi Makgi",
                        breakdown: ["Technique Modifier: Twin", "Tool: Knife", "Execution: Guarding", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "X Knife Checking Block",
                        romanised: "Kyocha Sonkal Momchau Makgi",
                        breakdown: ["Technique Modifier: X", "Tool: Knife", "Execution: Checking", "Action: Block"]
                    )
                ],
                difficulty: "Advanced"
            ),

            // Template 5: Direction + Tool + Target + Action
            PhraseTemplate(
                id: "4w-direction-tool-target-action",
                wordCount: 4,
                displayName: "Direction + Tool + Target + Action",
                description: "Movement plus body part plus height plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Front Knife High Strike",
                        romanised: "Apuro Sonkal Nopunde Taerigi",
                        breakdown: ["Direction: Front", "Tool: Knife", "Target: High", "Action: Strike"]
                    ),
                    PhraseExample(
                        english: "Rising Fist Middle Punch",
                        romanised: "Chookyo Joomuk Kaunde Jirugi",
                        breakdown: ["Direction: Rising", "Tool: Fist", "Target: Middle", "Action: Punch"]
                    )
                ],
                difficulty: "Advanced"
            ),

            // Template 6: Tool + Target + Execution + Action
            PhraseTemplate(
                id: "4w-tool-target-execution-action",
                wordCount: 4,
                displayName: "Tool + Target + Execution + Action",
                description: "Body part plus height plus how performed plus technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Execution",
                        allowedCategories: [.execution],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Knife High Checking Block",
                        romanised: "Sonkal Nopunde Momchau Makgi",
                        breakdown: ["Tool: Knife", "Target: High", "Execution: Checking", "Action: Block"]
                    ),
                    PhraseExample(
                        english: "Palm Middle Pressing Block",
                        romanised: "Sonbadak Kaunde Noollo Makgi",
                        breakdown: ["Tool: Palm", "Target: Middle", "Execution: Pressing", "Action: Block"]
                    )
                ],
                difficulty: "Advanced"
            )
        ]
    }

    // MARK: - 5-Word Templates

    private static func fiveWordTemplates() -> [PhraseTemplate] {
        return [
            // Template 1: Technique_Modifier + Position + Tool + Target + Action
            PhraseTemplate(
                id: "5w-techniquemodifier-position-tool-target-action",
                wordCount: 5,
                displayName: "Technique Modifier + Position + Tool + Target + Action",
                description: "Complete phrase with modifier, position, tool, height, and technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Technique Modifier",
                        allowedCategories: [.techniqueModifier],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Position",
                        allowedCategories: [.position],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-5",
                        position: 5,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Twin Outer Forearm High Block",
                        romanised: "Sang Bakat Palmok Nopunde Makgi",
                        breakdown: [
                            "Technique Modifier: Twin",
                            "Position: Outer",
                            "Tool: Forearm",
                            "Target: High",
                            "Action: Block"
                        ]
                    ),
                    PhraseExample(
                        english: "Double Inner Knife Middle Strike",
                        romanised: "Doo An Sonkal Kaunde Taerigi",
                        breakdown: [
                            "Technique Modifier: Double",
                            "Position: Inner",
                            "Tool: Knife",
                            "Target: Middle",
                            "Action: Strike"
                        ]
                    )
                ],
                difficulty: "Expert"
            ),

            // Template 2: Position + Tool + Direction + Target + Action
            PhraseTemplate(
                id: "5w-position-tool-direction-target-action",
                wordCount: 5,
                displayName: "Position + Tool + Direction + Target + Action",
                description: "Complex phrase with orientation, tool, movement, height, and technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Position",
                        allowedCategories: [.position],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-5",
                        position: 5,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Outer Forearm Inward High Block",
                        romanised: "Bakat Palmok Anaero Nopunde Makgi",
                        breakdown: [
                            "Position: Outer",
                            "Tool: Forearm",
                            "Direction: Inward",
                            "Target: High",
                            "Action: Block"
                        ]
                    ),
                    PhraseExample(
                        english: "Inner Knife Outward Middle Strike",
                        romanised: "An Sonkal Bakuro Kaunde Taerigi",
                        breakdown: [
                            "Position: Inner",
                            "Tool: Knife",
                            "Direction: Outward",
                            "Target: Middle",
                            "Action: Strike"
                        ]
                    )
                ],
                difficulty: "Expert"
            ),

            // Template 3: Tool + Direction + Target + Execution + Action
            PhraseTemplate(
                id: "5w-tool-direction-target-execution-action",
                wordCount: 5,
                displayName: "Tool + Direction + Target + Execution + Action",
                description: "Complex phrase with tool, movement, height, execution, and technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Execution",
                        allowedCategories: [.execution],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-5",
                        position: 5,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Knife Inward High Checking Block",
                        romanised: "Sonkal Anaero Nopunde Momchau Makgi",
                        breakdown: [
                            "Tool: Knife",
                            "Direction: Inward",
                            "Target: High",
                            "Execution: Checking",
                            "Action: Block"
                        ]
                    ),
                    PhraseExample(
                        english: "Palm Downward Middle Pressing Block",
                        romanised: "Sonbadak Naeryo Kaunde Noollo Makgi",
                        breakdown: [
                            "Tool: Palm",
                            "Direction: Downward",
                            "Target: Middle",
                            "Execution: Pressing",
                            "Action: Block"
                        ]
                    )
                ],
                difficulty: "Expert"
            ),

            // Template 4: Technique_Modifier + Position + Tool + Direction + Action
            PhraseTemplate(
                id: "5w-techniquemodifier-position-tool-direction-action",
                wordCount: 5,
                displayName: "Technique Modifier + Position + Tool + Direction + Action",
                description: "Complex phrase with modifier, orientation, tool, movement, and technique",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Technique Modifier",
                        allowedCategories: [.techniqueModifier],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Position",
                        allowedCategories: [.position],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-5",
                        position: 5,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Twin Outer Forearm Inward Block",
                        romanised: "Sang Bakat Palmok Anaero Makgi",
                        breakdown: [
                            "Technique Modifier: Twin",
                            "Position: Outer",
                            "Tool: Forearm",
                            "Direction: Inward",
                            "Action: Block"
                        ]
                    ),
                    PhraseExample(
                        english: "X Inner Knife Outward Strike",
                        romanised: "Kyocha An Sonkal Bakuro Taerigi",
                        breakdown: [
                            "Technique Modifier: X",
                            "Position: Inner",
                            "Tool: Knife",
                            "Direction: Outward",
                            "Action: Strike"
                        ]
                    )
                ],
                difficulty: "Expert"
            )
        ]
    }

    // MARK: - 6-Word Templates

    private static func sixWordTemplates() -> [PhraseTemplate] {
        return [
            // Template 1: Technique_Modifier + Position + Tool + Direction + Target + Action (MAXIMUM complexity)
            PhraseTemplate(
                id: "6w-techniquemodifier-position-tool-direction-target-action",
                wordCount: 6,
                displayName: "Technique Modifier + Position + Tool + Direction + Target + Action",
                description: "Complete phrase with all major elements - maximum complexity",
                slots: [
                    PhraseSlot(
                        id: "slot-1",
                        position: 1,
                        label: "Technique Modifier",
                        allowedCategories: [.techniqueModifier],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-2",
                        position: 2,
                        label: "Position",
                        allowedCategories: [.position],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-3",
                        position: 3,
                        label: "Tool",
                        allowedCategories: [.tool],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-4",
                        position: 4,
                        label: "Direction",
                        allowedCategories: [.direction],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-5",
                        position: 5,
                        label: "Target",
                        allowedCategories: [.target],
                        isRequired: true
                    ),
                    PhraseSlot(
                        id: "slot-6",
                        position: 6,
                        label: "Action",
                        allowedCategories: [.action],
                        isRequired: true
                    )
                ],
                examples: [
                    PhraseExample(
                        english: "Twin Outer Forearm Inward High Block",
                        romanised: "Sang Bakat Palmok Anaero Nopunde Makgi",
                        breakdown: [
                            "Technique Modifier: Twin",
                            "Position: Outer",
                            "Tool: Forearm",
                            "Direction: Inward",
                            "Target: High",
                            "Action: Block"
                        ]
                    ),
                    PhraseExample(
                        english: "Double Inner Knife Outward Middle Strike",
                        romanised: "Doo An Sonkal Bakuro Kaunde Taerigi",
                        breakdown: [
                            "Technique Modifier: Double",
                            "Position: Inner",
                            "Tool: Knife",
                            "Direction: Outward",
                            "Target: Middle",
                            "Action: Strike"
                        ]
                    )
                ],
                difficulty: "Expert"
            )
        ]
    }

    // MARK: - Validation

    /**
     * Validate if a phrase follows valid grammar rules
     */
    static func isValidPhrase(words: [CategorizedWord]) -> Bool {
        let templates = templates(for: words.count)
        return templates.contains { $0.matches(phrase: words) }
    }

    /**
     * Find all templates that match a given phrase
     */
    static func matchingTemplates(for words: [CategorizedWord]) -> [PhraseTemplate] {
        let templates = templates(for: words.count)
        return templates.filter { $0.matches(phrase: words) }
    }
}
