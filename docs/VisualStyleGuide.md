# TKDojang Visual Style Guidelines

This document defines the visual style guidelines for TKDojang image generation, ensuring consistency with the existing SwiftUI app design and BeltTheme system.

## 🎨 **Visual Design Philosophy**

### Core Principles
1. **Traditional Authenticity**: Respect for traditional Taekwondo aesthetics and Korean martial arts culture
2. **Educational Clarity**: Clean, instructional photography that aids learning
3. **Professional Quality**: High-resolution, studio-quality martial arts photography
4. **Consistent Character**: Unified character appearance across all image content
5. **Belt-Themed Integration**: Visual elements that complement the existing BeltTheme color system

---

## 🎯 **Integration with Existing SwiftUI Design**

### BeltTheme Color System Compatibility

Based on `BeltTheme.swift` analysis, our image generation must complement these existing colors:

#### Primary Belt Colors (from belt_system.json):
```swift
// White Belt
primaryColor: "#FFFFFF", secondaryColor: "#FFFFFF"

// Yellow Belt  
primaryColor: "#FFD700", secondaryColor: "#FFD700"

// Orange Belt
primaryColor: "#FF8C00", secondaryColor: "#FFFFFF" 

// Green Belt
primaryColor: "#228B22", secondaryColor: "#FFFFFF"

// Blue Belt
primaryColor: "#4169E1", secondaryColor: "#FFFFFF"

// Purple Belt  
primaryColor: "#800080", secondaryColor: "#FFFFFF"

// Red Belt
primaryColor: "#DC143C", secondaryColor: "#FFFFFF"

// Black Belt
primaryColor: "#000000", secondaryColor: "#000000"
```

#### Supporting Colors:
- **Border Gray**: `#DEE2E6` - Used for card borders and subtle accents
- **Text Colors**: High contrast for accessibility
- **Background Light**: `#F8F9FA` - Clean, neutral backgrounds

### SwiftUI Component Harmony

Images must work seamlessly with existing UI components:

#### BeltCardBackground Integration:
- **White card backgrounds** with **belt-colored borders**
- **BeltKnot decorations** at bottom center of cards
- **Belt border patterns**: Primary-Secondary-Primary stripe design for tag belts
- **Corner radius**: 20px standard for cards
- **Shadow effects**: Subtle belt-color shadows (`primaryColor.opacity(0.15)`)

#### AsyncImage Implementation:
Images are loaded using existing `AsyncImage` components:
```swift
AsyncImage(url: URL(string: imageURL)) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
} placeholder: {
    ProgressView()
}
```

---

## 👕 **Character Design Standards**

### Primary Character Specifications

**Visual Consistency Requirements:**
- **Age**: Adult male, 25-30 years old appearance
- **Build**: Athletic, medium build (traditional martial artist physique)  
- **Height**: Approximately 5'8" to 6' tall appearance
- **Ethnicity**: Asian or mixed Asian appearance preferred for cultural authenticity

**Uniform Standards:**
- **Dobok**: Pristine white traditional Taekwondo uniform
- **Fit**: Well-fitted, not baggy or tight
- **Condition**: Clean, pressed, professional appearance
- **Belt**: Appropriate color for pattern level (varies by content)
- **Belt Positioning**: Properly tied, centered, traditional knot

**Facial Features & Expression:**
- **Expression**: Focused, professional, respectful
- **Hair**: Short, neat, traditional martial arts styling
- **Facial Hair**: Clean-shaven or minimal, well-groomed
- **Eyes**: Focused on technique, not looking at camera

### Secondary Character (Step Sparring)

For step sparring sequences requiring two practitioners:

**Attacker Character:**
- Similar build and age to primary character
- **Hair**: Different styling to distinguish from defender
- **Uniform**: Identical white dobok
- **Belt**: Appropriate for sequence level

**Defender Character:**  
- **Build**: Slightly different build (taller/shorter) for visual distinction
- **Hair**: Different color or style
- **Uniform**: Identical white dobok
- **Belt**: Same level as attacker

---

## 📸 **Photography Standards**

### Lighting & Technical Specifications

**Studio Lighting Setup:**
- **Primary lighting**: Bright, even studio lighting
- **Shadow control**: Minimal shadows, well-diffused light
- **Background**: Clean white or transparent (for imagesets)
- **Resolution**: Minimum 2x (Retina) resolution for all assets
- **Format**: PNG with transparency support

**Camera Angles & Composition:**

#### Pattern Move Photography:
- **Primary angle**: 3/4 profile view (45-degree angle)
- **Alternative angles**: Side profile for lateral techniques
- **Framing**: Full body in frame with technique clearly visible
- **Stance visibility**: Both feet and full stance clearly shown
- **Technique emphasis**: Primary technique (block, punch, kick) prominently featured

#### Pattern Diagram Photography:
- **Overhead view**: Top-down perspective for footwork diagrams  
- **Minimalist style**: Clean line art approach
- **Movement indicators**: Arrows and numbered positions
- **Scale consistency**: Uniform scaling across all pattern diagrams

#### Step Sparring Photography:
- **Two-person framing**: Both practitioners clearly visible
- **Spatial relationship**: Proper martial arts distance maintained
- **Action capture**: Specific moment of technique interaction
- **Landscape orientation**: 4:3 aspect ratio for dual-person shots

---

## 🎨 **Color Integration Guidelines**

### Belt-Level Color Theming

Images should subtly incorporate belt-appropriate colors:

#### Solid Color Belts (White, Yellow, Black):
- **Accent elements**: Minimal color accents matching belt color
- **Focus**: Technique clarity over color theming
- **Background**: Clean white or neutral

#### Tag Belts (Orange, Green, Blue, Purple, Red):
- **Primary-Secondary pattern**: Subtle incorporation of primary and white secondary colors
- **Border elements**: Small belt-colored border accents (not overwhelming)
- **Equipment accents**: Training equipment in belt-appropriate colors

### Existing UI Component Colors

**Maintain compatibility with:**
- **Progress bars**: BeltProgressBar segments use belt colors
- **Card borders**: BeltBorder components with 3-layer design
- **Navigation elements**: Belt-themed navigation components
- **Badge colors**: BeltBadge background colors

---

## 📐 **Technical Implementation Guidelines**

### iOS Asset Catalog Integration

**File Naming Convention:**
```
Patterns/Diagrams/{pattern-name}-diagram.imageset/
Patterns/Moves/{pattern-name}-{move-number}.imageset/
StepSparring/{sequence-type}-{number}-{action}.imageset/
AppIcon.appiconset/
Branding/launch-logo.imageset/
```

**Resolution Requirements:**
- **@1x**: Base resolution (1024x1024 for icons, varies for content)
- **@2x**: 2x resolution for Retina displays  
- **@3x**: 3x resolution for iPhone Plus/Pro displays

**File Format Standards:**
- **App Icons**: PNG, no transparency, exact size requirements
- **Content Images**: PNG with transparency support
- **Compression**: Optimized for mobile app distribution (web-optimized)

### JSON Integration Updates

**Pattern Images:**
```json
{
  "diagram_image_url": "chon-ji-diagram",
  "moves": [
    {
      "move_number": 1,
      "image_url": "chon-ji-1"
    }
  ]
}
```

**Asset Reference Format:**
- Use **asset catalog names** (without file extensions)
- **Local references** instead of URLs for bundled assets
- **Consistent naming** matching imageset names

---

## 🎯 **Quality Assurance Standards**

### Image Review Checklist

**Technical Quality:**
- [ ] Resolution meets 2x/3x requirements
- [ ] PNG format with proper transparency
- [ ] File size optimized for mobile distribution  
- [ ] No compression artifacts or blur
- [ ] Consistent lighting across image sets

**Content Accuracy:**
- [ ] Martial arts technique performed correctly
- [ ] Proper traditional dobok appearance
- [ ] Belt color matches intended pattern level
- [ ] Character consistency maintained
- [ ] Cultural authenticity respected

**Style Consistency:**
- [ ] Lighting matches established photography style
- [ ] Character appearance consistent with previous images
- [ ] Background style matches category requirements
- [ ] Color integration appropriate for belt level
- [ ] Overall aesthetic professional and educational

### Integration Testing

**SwiftUI Compatibility:**
- [ ] Images work with AsyncImage loading
- [ ] Transparency works with BeltCardBackground
- [ ] Aspect ratios work with .aspectRatio(.fit)
- [ ] Resolution appropriate for different device sizes
- [ ] Performance acceptable for app loading times

---

## 🚀 **Implementation Workflow**

### Phase 1: Foundation Assets (Priority 1)
1. **App Icon Generation**: 5 design variations using master prompts
2. **Chon-Ji Complete Set**: 1 diagram + 19 moves (20 assets)
3. **Launch Logo**: 1 branding asset
4. **Testing**: Integration with existing app for quality verification

### Phase 2: Content Expansion (Priority 2)  
1. **Pattern Diagrams**: Remaining 8 patterns
2. **Popular Patterns**: Dan-Gun and Do-San complete sets
3. **Integration Testing**: Verify quality and consistency
4. **Asset Optimization**: File size and performance optimization

### Phase 3: Complete Library (Priority 3)
1. **All Pattern Moves**: Complete remaining 239 pattern moves
2. **Step Sparring**: All 54 step sparring illustrations
3. **Alternative Designs**: Character variations and seasonal themes
4. **Final Polish**: Quality assurance and optimization

### Asset Integration Process

**For each generated image:**
1. **Quality Review**: Check against all quality standards
2. **File Optimization**: Compress for mobile distribution
3. **Asset Placement**: Place in appropriate .imageset folder
4. **JSON Updates**: Update references from URLs to asset names
5. **App Testing**: Verify loading and display in app
6. **Performance Check**: Ensure app performance remains optimal

---

## 📋 **Style Guide Summary**

### Essential Guidelines for AI Generation

**Character Consistency:**
- Same adult male character across all pattern moves
- Pristine white dobok with appropriate belt
- Professional, focused expression
- Athletic, traditional martial artist build

**Photography Quality:**
- Professional studio lighting
- Clean white/transparent backgrounds  
- High resolution (2x minimum)
- Proper martial arts technique demonstration

**Belt Integration:**
- Subtle incorporation of belt-appropriate colors
- Maintains compatibility with BeltTheme system
- Doesn't overwhelm the educational content
- Respects traditional martial arts aesthetics

**Technical Standards:**
- PNG format with transparency
- iOS asset catalog structure
- Optimized file sizes
- Consistent naming convention

This visual style guide ensures that all generated images integrate seamlessly with the existing TKDojang app design while maintaining the highest standards of quality, accuracy, and cultural authenticity.