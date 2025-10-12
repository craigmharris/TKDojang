# TAGB Taekwondo Techniques Database

## Overview

This directory contains a comprehensive JSON-based database of Taekwondo techniques following the TAGB (Traditional Association of Great Britain) curriculum. The database is designed to support a detailed techniques feature in the TKDojang app, allowing users to explore every aspect of Taekwondo from basic movements to advanced applications.

## Database Structure

### Core Files

1. **`techniques_index.json`** - Master index containing category overview and search filters
2. **`kicks.json`** - All kicking techniques (10 techniques)
3. **`strikes.json`** - Hand strikes and punching techniques (16 techniques)  
4. **`blocks.json`** - Defensive blocking techniques (16 techniques)
5. **`stances.json`** - Body positions and stances (9 techniques)
6. **`hand_techniques.json`** - Advanced hand/arm techniques (4 techniques)
7. **`footwork.json`** - Movement and foot striking techniques (5 techniques)
8. **`sparring.json`** - Sparring formats and applications (7 techniques)
9. **`fundamentals.json`** - Core drills and fundamental skills (4 techniques)
10. **`combinations.json`** - Common technique combinations (3 combinations)

### Reference Files

- **`target_areas.json`** - Comprehensive target area reference with safety guidelines
- **`belt_requirements.json`** - Detailed requirements for each belt level (10th Kup to 2nd Dan)

## JSON Schema Structure

Each technique entry contains the following comprehensive metadata:

### Core Information
- **`id`** - Unique identifier
- **`names`** - Korean, romanized Korean, English, and phonetic pronunciation
- **`description`** - Detailed explanation of the technique
- **`execution`** - Step-by-step execution instructions

### Technical Details
- **`striking_tool`** / **`blocking_tool`** - What part of the body is used
- **`target_areas`** - Valid targets for the technique
- **`applicable_stances`** - Compatible stances
- **`belt_levels`** - Which belt levels learn this technique
- **`difficulty`** - Basic, intermediate, advanced, or expert

### Learning Support
- **`tags`** - Searchable categorization tags
- **`variations`** - Related technique variations
- **`images`** - Placeholder array for 3 instructional images
- **`common_mistakes`** - Typical errors beginners make

## Search and Filter Capabilities

The database supports filtering by:
- **Belt Level** - 10th Kup through 2nd Dan
- **Difficulty** - Basic, Intermediate, Advanced, Expert
- **Category** - Kicks, Strikes, Blocks, Stances, etc.
- **Striking Tool** - Apkumchi, Balkal, Joomok, Sonnal, etc.
- **Target Area** - Head, Body, Legs, specific anatomical targets
- **Stance Compatibility** - Which stances work with each technique

## Safety and Control

The database includes comprehensive safety information:
- **Caution Levels** - From training-safe to training-only
- **Control Requirements** - Specified for each target area
- **Safety Guidelines** - General safety principles
- **Common Mistakes** - Help prevent injury and poor form

## Korean Language Support

Every technique includes:
- **Korean Hangul** - Original Korean characters
- **Romanized Korean** - English alphabet representation
- **Phonetic Guide** - Pronunciation assistance
- **Cultural Context** - Meanings and significance where applicable

## Belt Progression Integration

The database maps techniques to the TAGB belt progression system:
- **Technique Introduction** - Which belt level introduces each technique
- **Skill Building** - How techniques build upon previous learning
- **Mastery Path** - Progression from basic to advanced applications
- **Belt Requirements** - Specific requirements for each grading level

## Usage in TKDojang App

This database is designed to support several app features:

### Technique Browser
- Hierarchical browsing by category
- Search and filter functionality
- Detailed technique views with images
- Related technique suggestions

### Learning Integration
- Belt-appropriate technique filtering
- Progress tracking capabilities
- Favorite/bookmark functionality
- Difficulty-based recommendations

### Reference Features
- Korean pronunciation guide
- Target area reference
- Safety guidelines
- Combination suggestions

## Content Sources

Techniques compiled from:
- TAGB official syllabus materials
- ITF technique standards
- Traditional Korean Taekwondo curriculum
- Existing TKDojang terminology files (primary source for Korean names and belt levels)
- Comprehensive martial arts references
- Expert practitioner knowledge

## Cross-Referencing with Terminology

This technique database has been cross-referenced with all terminology files in the app to ensure:
- **Consistency** - Korean names, romanization, and phonetics match existing terminology exactly
- **Completeness** - Every technique mentioned in terminology files has a detailed entry
- **Accuracy** - Belt level requirements align with established curriculum
- **Integration** - Seamless connection between terminology learning and technique practice

## Total Content

- **67+ Individual Techniques** across all categories
- **12 Belt Levels** with specific requirements
- **25+ Target Areas** with safety guidelines  
- **8 Major Categories** of techniques
- **Multiple Variations** for most techniques
- **Comprehensive Korean Language** support

## Future Expansion

The JSON structure supports easy addition of:
- Additional technique variations
- Video content references
- Interactive demonstrations
- Advanced combinations
- Competition-specific techniques
- Historical technique evolution

This database provides the foundation for a comprehensive Taekwondo learning experience within the TKDojang app.