# TKDojang Image Generation Workflow

This document provides the complete workflow for generating, integrating, and managing images for the TKDojang app using AI generation tools.

## 📋 **Complete System Overview**

The TKDojang image generation system consists of:

1. **📊 ImageRequirements.md** - Technical specifications for all 322 required images
2. **🎨 MasterPrompts.md** - AI generation prompts for Leonardo AI
3. **🎯 VisualStyleGuide.md** - Design consistency guidelines
4. **📱 iOS Asset Catalog** - Complete Xcode asset structure (322 image sets)
5. **🔄 This Workflow** - Step-by-step generation and integration process

---

## 🎯 **Quick Start: Generate Your First Images**

### Step 1: Set Up Leonardo AI Account
1. Visit [leonardo.ai](https://leonardo.ai)
2. Create account (150 free daily credits)
3. Create new project: "TKDojang App Images"

### Step 2: Generate Test Images
Copy this prompt from `MasterPrompts.md`:

```
Professional Taekwondo martial arts photography, high-quality studio lighting, clean white background, adult male martial artist in pristine white dobok uniform, yellow belt, athletic build, focused expression, performing left walking stance with low block using left forearm, defensive blocking technique, proper Taekwondo form, educational demonstration, photorealistic, 8K resolution, sharp details, even lighting, traditional Korean martial arts
```

**Leonardo AI Settings:**
- Model: Leonardo Diffusion XL
- Style: Photography
- Resolution: 600×800 (Portrait)
- Guidance: 15
- Steps: 50

### Step 3: Place in Asset Catalog
1. Download generated image
2. Rename to `chon-ji-1.png`
3. Place in: `/TKDojang/TKDojang.xcassets/Patterns/Moves/chon-ji-1.imageset/`
4. Test in Xcode project

---

## 🔄 **Complete Generation Workflow**

### Phase 1: Foundation Assets (Week 1)

**Target: 26 high-priority images**

#### Day 1-2: App Icons (5 images)
```bash
# Location: /TKDojang/TKDojang.xcassets/AppIcon.appiconset/
```

**Generation Process:**
1. Use **App Icon Master Prompt** from MasterPrompts.md
2. Generate 4 variations of each concept:
   - Kicking Figure Silhouette
   - Belt Symbol Design
   - TKD Letterform
   - Yin-Yang Kick
   - Geometric Pattern
3. Select best of each for different sizes
4. Generate all required sizes (20×20 to 1024×1024)

**Tools & Settings:**
- Model: Leonardo Vision XL
- Style: Vector Art
- Resolution: 1024×1024 (square)

#### Day 3-4: Chon-Ji Pattern Complete (20 images)

**Pattern Diagram (1 image):**
```bash
# Location: /TKDojang/TKDojang.xcassets/Patterns/Diagrams/chon-ji-diagram.imageset/
```

**Pattern Moves (19 images):**
```bash
# Location: /TKDojang/TKDojang.xcassets/Patterns/Moves/chon-ji-[1-19].imageset/
```

**Generation Strategy:**
1. Start with Move 1 using exact prompt from MasterPrompts.md
2. Establish character consistency (save reference image)
3. Generate moves 2-19 using character-consistent prompts
4. Maintain same lighting and character across all moves

#### Day 5: Launch Logo (1 image)
```bash
# Location: /TKDojang/TKDojang.xcassets/Branding/launch-logo.imageset/
```

**Quality Checkpoint:**
- ✅ All images meet technical specifications
- ✅ Character consistency across Chon-Ji moves
- ✅ Integration tested in Xcode project
- ✅ Performance impact assessed

### Phase 2: Pattern Expansion (Week 2-3)

**Target: 125 additional pattern images**

#### Remaining Pattern Diagrams (8 images)
Generate diagrams for: Dan-Gun, Do-San, Won-Hyo, Yul-Gok, Joong-Gun, Toi-Gye, Hwa-Rang, Chung-Mu

#### High-Priority Pattern Moves (117 images)
- **Dan-Gun**: 21 moves (8th Keup - high usage)
- **Do-San**: 24 moves (7th Keup - high usage)  
- **Won-Hyo**: 28 moves (6th Keup - moderate usage)
- **Yul-Gok**: 38 moves (5th Keup - advanced students)

**Belt Color Adjustments:**
- Dan-Gun: Orange belt
- Do-San: Green belt  
- Won-Hyo: Blue belt
- Yul-Gok: Purple belt

### Phase 3: Complete Library (Week 4-6)

**Target: 171 remaining images**

#### Advanced Pattern Moves (141 images)
- Joong-Gun: 32 moves (4th Keup)
- Toi-Gye: 37 moves (3rd Keup)
- Hwa-Rang: 29 moves (2nd Keup)
- Chung-Mu: 30 moves (1st Keup)

#### Step Sparring Complete (54 images)
- 3-Step Sparring: 30 images (10 sequences × 3 actions)
- 2-Step Sparring: 24 images (8 sequences × 3 actions)

---

## 🛠️ **Technical Integration Process**

### Asset Catalog Management

**File Structure (Already Created):**
```
TKDojang.xcassets/
├── AppIcon.appiconset/          # 18 icon sizes
├── Patterns/
│   ├── Diagrams/                # 9 pattern diagrams
│   │   ├── chon-ji-diagram.imageset/
│   │   ├── dan-gun-diagram.imageset/
│   │   └── ...
│   └── Moves/                   # 258 pattern moves
│       ├── chon-ji-1.imageset/
│       ├── chon-ji-2.imageset/
│       └── ...
├── StepSparring/                # 54 sparring images
│   ├── three-step-1-attack.imageset/
│   ├── three-step-1-defense.imageset/
│   └── ...
└── Branding/
    └── launch-logo.imageset/
```

### JSON File Updates

**Current State (URLs):**
```json
{
  "diagram_image_url": "https://example.com/diagrams/chon-ji-diagram.jpg",
  "image_url": "https://example.com/moves/chon-ji-1.jpg"
}
```

**Target State (Asset References):**
```json
{
  "diagram_image_url": "chon-ji-diagram",
  "image_url": "chon-ji-1"
}
```

**Update Script Required:**
```bash
# Create script to update all JSON files
# Replace URL references with asset catalog names
# Test all AsyncImage loading
```

### Xcode Project Integration

**Required Updates:**
1. **Asset Catalog Addition**: Add TKDojang.xcassets to Xcode project
2. **Build Settings**: Ensure assets are included in app bundle
3. **Info.plist**: Update app icon references if needed
4. **Testing**: Verify all images load correctly

---

## 📊 **Quality Assurance Process**

### Per-Image Quality Checklist

**Technical Requirements:**
- [ ] **Resolution**: Meets 2x/3x specifications
- [ ] **Format**: PNG with proper transparency
- [ ] **File Size**: <300KB for moves, <200KB for diagrams
- [ ] **Aspect Ratio**: Correct for category (3:4 portrait, 4:3 landscape, 1:1 square)

**Content Requirements:**
- [ ] **Technique Accuracy**: Proper Taekwondo technique
- [ ] **Uniform Quality**: Clean, well-fitted white dobok
- [ ] **Belt Accuracy**: Correct color for pattern level
- [ ] **Cultural Authenticity**: Respectful representation

**Design Consistency:**
- [ ] **Character Match**: Same character across pattern sets
- [ ] **Lighting**: Consistent studio lighting
- [ ] **Background**: Clean white/transparent
- [ ] **Pose Quality**: Professional martial arts demonstration

### Batch Quality Review

**After Each 20-30 Images:**
1. **Consistency Check**: Compare character appearance
2. **Technical Review**: Verify all specs met
3. **App Integration Test**: Load in actual app
4. **Performance Check**: Ensure no impact on app speed
5. **Refinement**: Adjust prompts if needed

---

## 🎨 **Advanced Generation Tips**

### Character Consistency Techniques

**Leonardo AI Settings for Consistency:**
1. **Save Seed Numbers**: Use consistent seed for character
2. **Reference Images**: Upload best character image as reference
3. **Prompt Consistency**: Use identical character description
4. **Batch Generation**: Generate similar poses together

**Character Reference Prompt Addition:**
```
[Use this addition to any prompt for consistency]
Character reference: same adult male martial artist as previous images, identical facial features, same athletic build, consistent appearance
```

### Lighting and Quality Optimization

**Professional Photography Prompts:**
```
Studio lighting setup: professional martial arts photography, soft box lighting, minimal shadows, even illumination, high-end camera equipment, commercial photography quality
```

**Quality Enhancement Modifiers:**
```
8K resolution, photorealistic, sharp focus, professional photography, commercial quality, high detail, crisp image, studio lighting, perfect exposure
```

### Belt-Specific Customization

**Per-Belt Prompt Adjustments:**
- **9th Keup (Chon-Ji)**: "yellow belt" 
- **8th Keup (Dan-Gun)**: "orange belt"
- **7th Keup (Do-San)**: "green belt"
- **6th Keup (Won-Hyo)**: "blue belt"
- **5th Keup (Yul-Gok)**: "purple belt"
- **4th Keup (Joong-Gun)**: "brown belt" or "red belt with black stripe"
- **3rd Keup (Toi-Gye)**: "red belt with black stripe"  
- **2nd Keup (Hwa-Rang)**: "red belt with black stripe"
- **1st Keup (Chung-Mu)**: "red belt with two black stripes"

---

## 📈 **Progress Tracking & Management**

### Daily Generation Targets

**Optimal Workflow (150 daily credits):**
- **150 credits** = ~37 high-quality images per day
- **Phase 1**: 7 days (26 images + buffer for quality)
- **Phase 2**: 10 days (125 images)
- **Phase 3**: 15 days (171 images)
- **Total**: ~32 days for complete library

### Weekly Milestones

**Week 1 Goal**: Foundation assets + Chon-Ji complete
- ✅ App functioning with generated icons
- ✅ Complete pattern learning for 9th Keup students
- ✅ Character consistency established

**Week 2-3 Goal**: Core pattern library
- ✅ Patterns for 9th-6th Keup complete
- ✅ Major user journey patterns available
- ✅ Quality standards refined

**Week 4-6 Goal**: Complete image library
- ✅ All patterns available
- ✅ Step sparring system complete
- ✅ Production-ready app

### Quality Metrics

**Success Criteria:**
- **Technical**: <5% images need regeneration for technical issues
- **Consistency**: >95% character consistency across pattern sets
- **Integration**: 100% images load correctly in app
- **Performance**: No significant impact on app loading time
- **User Experience**: Positive feedback on image quality and consistency

---

## 🔧 **Maintenance & Updates**

### Future Content Expansion

**Easy Addition Process:**
1. **New Patterns**: Add to asset catalog structure
2. **JSON Updates**: Follow established naming convention
3. **Prompt Reuse**: Use established character prompts
4. **Quality Standards**: Follow same review process

**Scalability Features:**
- **Asset catalog structure** supports unlimited patterns
- **Prompt templates** enable quick new content generation
- **Quality process** ensures consistency across additions
- **Integration pattern** easily repeatable

### Performance Optimization

**Asset Management:**
- **Compression**: Optimize all images for mobile distribution
- **Caching**: Leverage iOS image caching systems
- **Loading**: Implement progressive loading for large sets
- **Storage**: Monitor app bundle size impact

**Continuous Improvement:**
- **User Feedback**: Monitor usage patterns and quality feedback
- **Technical Updates**: Keep asset format current with iOS updates
- **Content Updates**: Refresh images as AI generation quality improves
- **Performance Monitoring**: Track app performance impact over time

---

## 📝 **Final Checklist: Ready for Production**

### Pre-Launch Verification
- [ ] **All 322 image sets created** in asset catalog
- [ ] **App icons generated** for all required sizes  
- [ ] **JSON files updated** with local asset references
- [ ] **Xcode project configured** with asset catalog
- [ ] **App builds successfully** with all images
- [ ] **Loading performance** meets requirements
- [ ] **Quality standards** met across all images
- [ ] **Character consistency** verified across pattern sets
- [ ] **Cultural accuracy** reviewed and approved
- [ ] **File sizes optimized** for app store distribution

### Launch Readiness
- [ ] **App Store screenshots** updated with new images
- [ ] **App description** highlights visual learning features
- [ ] **Marketing materials** showcase image quality
- [ ] **User documentation** updated for new visual features
- [ ] **Performance monitoring** tools configured
- [ ] **Feedback collection** system ready for user input

The TKDojang image generation system provides a complete, scalable solution for creating and managing martial arts educational imagery, ensuring consistency, quality, and cultural authenticity while maintaining optimal app performance and user experience.