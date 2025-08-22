# TKDojang Image Requirements

This document outlines all image assets needed for the TKDojang Taekwondo learning app, their technical specifications, and integration requirements.

## 📊 Image Analysis Summary

Based on codebase analysis, TKDojang requires **4 primary categories** of images:

1. **App Icons & Branding** (7 assets)
2. **Pattern Diagrams** (9 assets) 
3. **Pattern Move Illustrations** (~200+ assets)
4. **Step Sparring Illustrations** (18+ assets)

**Total Estimated Images: 234+ assets**

---

## 🎯 **Category 1: App Icons & Branding**

### App Icon Set
| Asset | Dimensions | Format | Notes |
|-------|------------|--------|-------|
| App Icon 1024x1024 | 1024×1024px | PNG | App Store, no transparency |
| App Icon 180x180 | 180×180px | PNG | iPhone @3x |
| App Icon 120x120 | 120×120px | PNG | iPhone @2x |
| App Icon 167x167 | 167×167px | PNG | iPad Pro @2x |
| App Icon 152x152 | 152×152px | PNG | iPad @2x |
| App Icon 76x76 | 76×76px | PNG | iPad @1x |
| App Icon 40x40 | 40×40px | PNG | Spotlight |

### Launch Screen Assets
| Asset | Dimensions | Format | Notes |
|-------|------------|--------|-------|
| Launch Logo | 300×300px | PNG | Center logo with transparency |

**Design Requirements:**
- Modern, clean martial arts aesthetic
- Incorporates belt colors (black, red, white)
- Taekwondo-specific iconography (kicks, stances)
- Works at all sizes (scalable design)
- Professional appearance suitable for App Store

---

## 🥋 **Category 2: Pattern Diagrams**

Pattern diagrams show the floor pattern/footwork path for each Taekwondo form.

### Current Patterns Identified:
1. **Chon-Ji** (9th Keup) - Plus sign (+) 
2. **Dan-Gun** (8th Keup) - I-shape pattern
3. **Do-San** (7th Keup) - Plus sign pattern  
4. **Won-Hyo** (6th Keup) - I-shape pattern
5. **Yul-Gok** (5th Keup) - Plus sign pattern
6. **Joong-Gun** (4th Keup) - I-shape pattern
7. **Toi-Gye** (3rd Keup) - Complex pattern
8. **Hwa-Rang** (2nd Keup) - I-shape pattern
9. **Chung-Mu** (1st Keup) - I-shape pattern

### Technical Specifications:
| Property | Specification |
|----------|---------------|
| **Dimensions** | 800×600px (4:3 aspect ratio) |
| **Format** | PNG with transparency |
| **DPI** | 144 DPI (2x for Retina) |
| **File Size** | <200KB per image |
| **Background** | Transparent |
| **Colors** | Belt-themed accent colors + neutral gray |

### Design Requirements:
- Clean, minimalist line art style
- Footprint positions numbered sequentially
- Starting position clearly marked
- Movement direction indicated with arrows
- Belt-appropriate color theming
- Consistent scale across all diagrams

### JSON Integration:
```json
"diagram_image_url": "patterns/diagrams/chon-ji-diagram.png"
```

---

## 🥊 **Category 3: Pattern Move Illustrations**

Individual move demonstrations for each pattern technique.

### Current Pattern Moves Required:
| Pattern | Moves | File Naming |
|---------|-------|-------------|
| Chon-Ji | 19 moves | `chon-ji-{1-19}.png` |
| Dan-Gun | 21 moves | `dan-gun-{1-21}.png` |
| Do-San | 24 moves | `do-san-{1-24}.png` |
| Won-Hyo | 28 moves | `won-hyo-{1-28}.png` |
| Yul-Gok | 38 moves | `yul-gok-{1-38}.png` |
| Joong-Gun | 32 moves | `joong-gun-{1-32}.png` |
| Toi-Gye | 37 moves | `toi-gye-{1-37}.png` |
| Hwa-Rang | 29 moves | `hwa-rang-{1-29}.png` |
| Chung-Mu | 30 moves | `chung-mu-{1-30}.png` |

**Total Pattern Moves: 258 illustrations**

### Technical Specifications:
| Property | Specification |
|----------|---------------|
| **Dimensions** | 600×800px (3:4 portrait aspect ratio) |
| **Format** | PNG with transparency |
| **DPI** | 144 DPI (2x for Retina) |
| **File Size** | <300KB per image |
| **Background** | Transparent or subtle gradient |
| **Subject** | Single martial artist in white dobok |

### Design Requirements:
- Consistent character design (adult male/female)
- White traditional Taekwondo uniform (dobok)
- Black belt
- Clear technique demonstration
- Professional lighting
- Neutral background
- Focus on proper form and technique
- Belt-level appropriate complexity

### Common Techniques to Illustrate:
- **Stances**: Walking stance, L-stance, Parallel stance, Ready stance
- **Blocks**: Low block, Middle block, High block, Inner forearm block
- **Strikes**: Obverse punch, Reverse punch, Knife hand strike
- **Kicks**: Front kick, Side kick, Turning kick
- **Special techniques**: Twin forearm block, Pressing block, etc.

### JSON Integration:
```json
"image_url": "patterns/moves/chon-ji-1.png"
```

---

## 🥋 **Category 4: Step Sparring Illustrations**

Demonstrations of attack, defense, and counter-attack combinations.

### Current Step Sparring Sequences:
| Type | Belt Level | Sequences | Total Illustrations |
|------|------------|-----------|-------------------|
| 3-Step | 8th-6th Keup | 10 sequences | 30 illustrations |
| 2-Step | 5th-4th Keup | 8 sequences | 16 illustrations |

**Total Step Sparring Illustrations: 46 images**

### Technical Specifications:
| Property | Specification |
|----------|---------------|
| **Dimensions** | 800×600px (4:3 landscape aspect ratio) |
| **Format** | PNG with transparency |
| **DPI** | 144 DPI (2x for Retina) |
| **File Size** | <400KB per image |
| **Background** | Transparent or dojo setting |
| **Subjects** | Two martial artists (attacker + defender) |

### Design Requirements:
- Two practitioners in white doboks
- Different belt levels (colored belts)
- Clear spatial relationship
- Attack/defense moment captured
- Proper technique form
- Professional martial arts photography style
- Dynamic but educational poses

### Sequence Structure:
Each step sparring sequence needs 3 types of illustrations:
1. **Attack demonstration** - Attacker executing technique
2. **Defense demonstration** - Defender blocking/countering
3. **Counter-attack demonstration** - Defender's counter technique

### JSON Integration:
```json
// In step sparring JSON files - no image URLs currently
// Need to add image support to StepSparringModels.swift
```

---

## 🎨 **Visual Style Guidelines**

### Color Palette (Based on BeltTheme.swift Analysis):
- **Primary Colors**: Belt-specific colors from TAGB system
  - White Belt: `#FFFFFF`
  - Yellow Belt: `#FFD700`
  - Orange Belt: `#FF8C00`
  - Green Belt: `#228B22`
  - Blue Belt: `#4169E1`
  - Purple Belt: `#800080`
  - Red Belt: `#DC143C`
  - Black Belt: `#000000`

- **Accent Colors**:
  - Neutral Gray: `#6C757D`
  - Border Gray: `#DEE2E6`
  - Text Dark: `#000000`
  - Background Light: `#F8F9FA`

### Typography Harmony:
- Match SwiftUI system fonts
- Clean, modern sans-serif
- High contrast for accessibility

### Design Principles:
1. **Consistency**: Uniform character design across all images
2. **Clarity**: High contrast, clear details
3. **Professionalism**: Traditional martial arts aesthetic
4. **Accessibility**: Works for all user types
5. **Scalability**: Looks good at various sizes
6. **Cultural Authenticity**: Respects Taekwondo traditions

---

## 📱 **iOS Asset Catalog Structure**

### Recommended Asset Organization:
```
TKDojang.xcassets/
├── AppIcon.appiconset/
│   ├── Icon-1024.png
│   ├── Icon-180.png
│   ├── Icon-120.png
│   └── ...
├── Patterns/
│   ├── Diagrams/
│   │   ├── chon-ji-diagram.imageset/
│   │   ├── dan-gun-diagram.imageset/
│   │   └── ...
│   └── Moves/
│       ├── chon-ji-1.imageset/
│       ├── chon-ji-2.imageset/
│       └── ...
├── StepSparring/
│   ├── three-step-1-attack.imageset/
│   ├── three-step-1-defense.imageset/
│   └── ...
└── Branding/
    ├── launch-logo.imageset/
    └── ...
```

### Asset Naming Convention:
- **Patterns**: `{pattern-name}-{move-number}` (e.g., `chon-ji-1`)
- **Diagrams**: `{pattern-name}-diagram` (e.g., `chon-ji-diagram`)
- **Step Sparring**: `{type}-{sequence}-{action}` (e.g., `three-step-1-attack`)

---

## 🔗 **Integration Points**

### Code Integration Required:
1. **Update JSON files** with actual asset paths
2. **Asset catalog setup** in Xcode project
3. **AsyncImage implementation** already exists in codebase
4. **Error handling** for missing images
5. **Caching strategy** for performance

### Current Image Loading Implementation:
Located in: `PatternPracticeView.swift:198-205`
```swift
if let imageURL = move.imageURL, !imageURL.isEmpty {
    AsyncImage(url: URL(string: imageURL)) { image in
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    } placeholder: {
        ProgressView()
    }
}
```

---

## 📋 **Implementation Priority**

### Phase 1: Core Assets (High Priority)
1. App Icon set (7 assets)
2. Chon-Ji pattern complete set (1 diagram + 19 moves = 20 assets)
3. Launch screen logo (1 asset)

### Phase 2: Pattern Expansion (Medium Priority)
1. Remaining 8 pattern diagrams 
2. Dan-Gun and Do-San move sets (45 moves total)

### Phase 3: Advanced Content (Lower Priority)
1. Remaining pattern moves (193+ moves)
2. Step sparring illustrations (46 images)

### Phase 4: Polish & Enhancement
1. Alternative character designs
2. Seasonal/themed variants
3. Animation source materials

---

## 📝 **Notes for Image Generation**

### Key Requirements for AI Generation:
1. **Consistency**: Same character model across all images
2. **Accuracy**: Proper Taekwondo techniques and forms
3. **Quality**: Professional martial arts photography style
4. **Format**: High-resolution PNG with transparency
5. **Efficiency**: Batch generation capability

### Challenge Areas:
- Maintaining consistent character appearance
- Accurate martial arts technique representation
- Proper traditional dobok (uniform) appearance
- Correct belt positioning and colors
- Professional lighting and composition

This requirements document serves as the foundation for systematic image generation and integration into the TKDojang app.