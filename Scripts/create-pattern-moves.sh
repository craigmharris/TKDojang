#!/bin/bash

# Create pattern move image sets with correct move counts
ASSETS_DIR="/Users/craig/TKDojang/TKDojang/TKDojang.xcassets"
MOVES_DIR="$ASSETS_DIR/Patterns/Moves"

echo "🥊 Creating pattern move image sets with correct counts..."

create_move_imageset() {
    local pattern=$1
    local move_num=$2
    
    MOVE_DIR="$MOVES_DIR/${pattern}-${move_num}.imageset"
    mkdir -p "$MOVE_DIR"
    
    cat > "$MOVE_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${pattern}-${move_num}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${pattern}-${move_num}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${pattern}-${move_num}@3x.png",
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
}

# Chon-Ji (19 moves)
echo "  📋 Creating Chon-Ji moves (19)"
for i in {1..19}; do
    create_move_imageset "chon-ji" $i
done

# Dan-Gun (21 moves) 
echo "  📋 Creating Dan-Gun moves (21)"
for i in {1..21}; do
    create_move_imageset "dan-gun" $i
done

# Do-San (24 moves)
echo "  📋 Creating Do-San moves (24)"
for i in {1..24}; do
    create_move_imageset "do-san" $i
done

# Won-Hyo (28 moves)
echo "  📋 Creating Won-Hyo moves (28)"
for i in {1..28}; do
    create_move_imageset "won-hyo" $i
done

# Yul-Gok (38 moves)
echo "  📋 Creating Yul-Gok moves (38)"
for i in {1..38}; do
    create_move_imageset "yul-gok" $i
done

# Joong-Gun (32 moves)
echo "  📋 Creating Joong-Gun moves (32)"
for i in {1..32}; do
    create_move_imageset "joong-gun" $i
done

# Toi-Gye (37 moves)
echo "  📋 Creating Toi-Gye moves (37)"
for i in {1..37}; do
    create_move_imageset "toi-gye" $i
done

# Hwa-Rang (29 moves)
echo "  📋 Creating Hwa-Rang moves (29)"
for i in {1..29}; do
    create_move_imageset "hwa-rang" $i
done

# Choong-Moo (30 moves)
echo "  📋 Creating Choong-Moo moves (30)"
for i in {1..30}; do
    create_move_imageset "choong-moo" $i
done

echo ""
echo "✅ Pattern move image sets created successfully!"
echo "📊 Total: 19+21+24+28+38+32+37+29+30 = 258 move image sets"