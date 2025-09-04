#!/bin/bash

# TKDojang Asset Catalog Structure Generator
# Creates iOS asset catalog structure for all TKDojang images

ASSETS_DIR="/Users/craig/TKDojang/TKDojang/TKDojang.xcassets"
PATTERNS_DIR="$ASSETS_DIR/Patterns"
STEP_SPARRING_DIR="$ASSETS_DIR/StepSparring"
BRANDING_DIR="$ASSETS_DIR/Branding"

echo "🎯 Creating TKDojang iOS Asset Catalog Structure..."

# Pattern names from the JSON files
PATTERNS=(
    "chon-ji"
    "dan-gun" 
    "do-san"
    "won-hyo"
    "yul-gok"
    "joong-gun"
    "toi-gye"
    "hwa-rang"
    "choong-moo"
)

# Pattern move counts (from JSON analysis)
# Function to get move count for each pattern
get_move_count() {
    case $1 in
        "chon-ji") echo 19 ;;
        "dan-gun") echo 21 ;;
        "do-san") echo 24 ;;
        "won-hyo") echo 28 ;;
        "yul-gok") echo 38 ;;
        "joong-gun") echo 32 ;;
        "toi-gye") echo 37 ;;
        "hwa-rang") echo 29 ;;
        "choong-moo") echo 30 ;;
        *) echo 0 ;;
    esac
}

echo "📁 Creating pattern diagram image sets..."

# Create pattern diagram image sets
for pattern in "${PATTERNS[@]}"; do
    if [ "$pattern" != "chon-ji" ]; then # chon-ji already created
        DIAGRAM_DIR="$PATTERNS_DIR/Diagrams/${pattern}-diagram.imageset"
        mkdir -p "$DIAGRAM_DIR"
        
        cat > "$DIAGRAM_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${pattern}-diagram.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${pattern}-diagram@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${pattern}-diagram@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
        echo "  ✅ Created ${pattern}-diagram.imageset"
    fi
done

echo "🥊 Creating pattern move image sets..."

# Create pattern move image sets
for pattern in "${PATTERNS[@]}"; do
    move_count=$(get_move_count "$pattern")
    
    for ((i=1; i<=move_count; i++)); do
        MOVE_DIR="$PATTERNS_DIR/Moves/${pattern}-${i}.imageset"
        mkdir -p "$MOVE_DIR"
        
        cat > "$MOVE_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${pattern}-${i}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${pattern}-${i}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${pattern}-${i}@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
        echo "  ✅ Created ${pattern}-${i}.imageset"
    done
    echo "  📋 Completed all $move_count moves for $pattern"
done

echo "🥋 Creating step sparring directory structure..."

# Create step sparring directory
mkdir -p "$STEP_SPARRING_DIR"

# Step sparring sequences (from JSON analysis)
STEP_SPARRING_SEQUENCES=(
    "three-step-1" "three-step-2" "three-step-3" "three-step-4" "three-step-5"
    "three-step-6" "three-step-7" "three-step-8" "three-step-9" "three-step-10"
    "two-step-1" "two-step-2" "two-step-3" "two-step-4" 
    "two-step-5" "two-step-6" "two-step-7" "two-step-8"
)

# Each sequence needs attack, defense, and counter images
ACTIONS=("attack" "defense" "counter")

for sequence in "${STEP_SPARRING_SEQUENCES[@]}"; do
    for action in "${ACTIONS[@]}"; do
        SPARRING_DIR="$STEP_SPARRING_DIR/${sequence}-${action}.imageset"
        mkdir -p "$SPARRING_DIR"
        
        cat > "$SPARRING_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${sequence}-${action}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${sequence}-${action}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${sequence}-${action}@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
        echo "  ✅ Created ${sequence}-${action}.imageset"
    done
done

echo "🎨 Creating branding assets..."

# Create branding directory
mkdir -p "$BRANDING_DIR"

# Launch logo
LAUNCH_DIR="$BRANDING_DIR/launch-logo.imageset"
mkdir -p "$LAUNCH_DIR"

cat > "$LAUNCH_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "launch-logo.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "launch-logo@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "launch-logo@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "  ✅ Created launch-logo.imageset"

echo ""
echo "🎯 Asset Catalog Structure Creation Complete!"
echo ""
echo "📊 Summary:"
echo "  📱 App Icons: 1 set (18 sizes)"
echo "  📋 Pattern Diagrams: 9 sets"
echo "  🥊 Pattern Moves: 258 sets"
echo "  🥋 Step Sparring: 54 sets (18 sequences × 3 actions)"
echo "  🎨 Branding: 1 set"
echo "  📁 Total Image Sets: 322"
echo ""
echo "📍 Location: $ASSETS_DIR"
echo ""
echo "Next Steps:"
echo "  1. Add asset catalog to Xcode project"
echo "  2. Generate images using Leonardo AI"
echo "  3. Place images in respective .imageset folders"
echo "  4. Update JSON files with local asset paths"