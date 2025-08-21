# Pattern JSON Structure Documentation

## Overview

The TKDojang app uses a fixed JSON structure for pattern content that provides consistency with terminology and step sparring systems. This document outlines the JSON schema and implementation details.

## File Organization

Pattern content is organized in belt-specific JSON files:

```
TKDojang/Sources/Core/Data/Content/Patterns/
├── 9th_keup_patterns.json    # Chon-Ji
├── 8th_keup_patterns.json    # Dan-Gun  
├── 7th_keup_patterns.json    # Do-San
├── 6th_keup_patterns.json    # Won-Hyo
├── 5th_keup_patterns.json    # Yul-Gok
├── 4th_keup_patterns.json    # Joong-Gun
├── 3rd_keup_patterns.json    # Toi-Gye
├── 2nd_keup_patterns.json    # Hwa-Rang
└── 1st_keup_patterns.json    # Chung-Mu
```

## JSON Schema

### Root Structure

```json
{
  "belt_level": "9th_keup",
  "category": "patterns",
  "type": "traditional_patterns",
  "description": "Traditional patterns for 9th keup students",
  "metadata": {
    "created_at": "2025-08-20T00:00:00Z",
    "source": "ITF Pattern Manual",
    "total_count": 1
  },
  "patterns": [...]
}
```

### Pattern Object Schema

```json
{
  "name": "Chon-Ji",
  "hangul": "천지",
  "pronunciation": "chon-ji", 
  "phonetic": "/tʃʰon.dʑi/",
  "english_meaning": "Heaven and Earth",
  "significance": "In the Orient, it is interpreted as...",
  "move_count": 19,
  "diagram_description": "Plus sign (+)",
  "starting_stance": "Parallel ready stance",
  "difficulty": 1,
  "applicable_belt_levels": ["9th_keup"],
  "video_url": "https://example.com/patterns/chon-ji.mp4",
  "diagram_image_url": "https://example.com/diagrams/chon-ji-diagram.jpg",
  "moves": [...]
}
```

### Move Object Schema

```json
{
  "move_number": 1,
  "stance": "Left walking stance",
  "technique": "Low block",
  "korean_technique": "Najunde makgi",
  "direction": "West",
  "target": "Lower section",
  "key_points": "Keep shoulders square, bend knees properly",
  "common_mistakes": "Lifting block too high",
  "execution_notes": "Ensure proper weight distribution in walking stance",
  "image_url": "https://example.com/moves/chon-ji-1.jpg"
}
```

## Key Features

### Educational Content
- **Korean Integration**: Authentic Korean technique names alongside English
- **Learning Aids**: Key points, common mistakes, and execution notes for each move
- **Historical Context**: Pattern significance and cultural background

### Technical Implementation
- **Consistent Schema**: Matches terminology and step sparring JSON structure
- **Belt Level Filtering**: Patterns associated with appropriate belt levels
- **Multimedia Support**: URL fields for videos and images
- **Validation**: Structured data ensures content consistency

### Content Management
- **Easy Updates**: Content changes without code modifications
- **Version Control**: JSON files tracked in git for change history
- **Expandable**: Framework supports all 24 ITF patterns

## Loading Architecture

### PatternContentLoader
- Follows same pattern as `StepSparringContentLoader` and `ModularContentLoader`
- Handles JSON parsing and SwiftData model creation
- Supports MainActor requirements for SwiftUI integration

### Service Integration
- `PatternDataService` updated to use JSON loading instead of hardcoded Swift methods
- Maintains existing API for UI components
- Proper belt level association through database lookups

## Current Implementation Status

### Completed Patterns
- **Chon-Ji (9th Keup)**: Complete with all 19 moves detailed
- **Dan-Gun (8th Keup)**: Complete with all 21 moves detailed  
- **Do-San (7th Keup)**: Complete with all 24 moves detailed
- **Won-Hyo (6th Keup)**: Complete with all 28 moves detailed
- **Yul-Gok (5th Keup)**: Partial implementation (7 moves), easily expandable

### Framework Ready
- **Joong-Gun through Chung-Mu**: Pattern metadata complete, ready for move expansion
- **Consistent Structure**: All files follow identical schema
- **Build Integration**: All JSON files properly bundled in app

## Development Benefits

1. **Maintainability**: Content updates without code changes
2. **Consistency**: Unified structure across all content types
3. **Scalability**: Easy addition of new patterns or moves
4. **Internationalization**: Framework supports multiple languages
5. **Validation**: Schema ensures data integrity and completeness

## Future Enhancements

- **Content Validation Tools**: Automated JSON schema validation
- **Move Sequence Validation**: Ensure logical move progressions
- **Multimedia Integration**: Support for actual video and image content
- **Translation Support**: Multiple language versions of patterns
- **Advanced Filtering**: Search and filter by technique types, stances, etc.