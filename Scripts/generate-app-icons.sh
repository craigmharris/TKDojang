#!/bin/bash

# AppIcon Generator Script for TKDojang
# Automatically resizes 1024x1024 master icon to all required iOS AppIcon sizes

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎨 TKDojang AppIcon Generator${NC}"
echo "=================================="

# Paths
MASTER_ICON="/Users/craig/TKDojang/TKDojang/TKDojang.xcassets/AppIcon.appiconset/4DAC1B46-47EE-4639-B178-27107A26EAB4_1_201_a.jpeg"
APPICON_DIR="/Users/craig/TKDojang/TKDojang/TKDojang.xcassets/AppIcon.appiconset"

# Check if master icon exists
if [ ! -f "$MASTER_ICON" ]; then
    echo -e "${RED}❌ Master icon not found at: $MASTER_ICON${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found master icon (1024x1024)${NC}"
echo "Generating all required AppIcon sizes..."
echo

# Array of required sizes and filenames based on Contents.json
declare -a SIZES=(
    "20:Icon-20.png"
    "29:Icon-29.png" 
    "40:Icon-40.png"
    "58:Icon-58.png"
    "60:Icon-60.png"
    "76:Icon-76.png"
    "80:Icon-80.png"
    "87:Icon-87.png"
    "120:Icon-120.png"
    "152:Icon-152.png"
    "167:Icon-167.png"
    "180:Icon-180.png"
)

# Function to resize image
resize_icon() {
    local size=$1
    local filename=$2
    local output_path="$APPICON_DIR/$filename"
    
    echo -e "📱 Generating ${size}x${size} → ${filename}"
    
    # Use sips to resize (built into macOS)
    sips -z $size $size "$MASTER_ICON" --out "$output_path" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✓ Created $filename${NC}"
    else
        echo -e "${RED}   ✗ Failed to create $filename${NC}"
    fi
}

# Generate all required sizes
for item in "${SIZES[@]}"; do
    IFS=':' read -r size filename <<< "$item"
    resize_icon $size $filename
done

echo
echo -e "${GREEN}🎉 AppIcon generation complete!${NC}"
echo -e "${BLUE}📁 All icons saved to: $APPICON_DIR${NC}"
echo
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. The AppIcon.appiconset should now show all required sizes"
echo "3. Build your project to see the new app icon"