#!/bin/bash

# Pattern Image Optimizer for TKDojang
# Resizes all pattern images to optimal @3x, @2x, @1x sizes
# 886px → 870px/@3x, 580px/@2x, 290px/@1x

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎨 TKDojang Pattern Image Optimizer${NC}"
echo "==========================================="
echo

# Paths
PATTERNS_DIR="/Users/craig/TKDojang/TKDojang/TKDojang.xcassets/Patterns"

# Target sizes
SIZE_3X=870
SIZE_2X=580
SIZE_1X=290

# Counters
total_imagesets=0
processed_imagesets=0
skipped_imagesets=0

# Function to get clean filename from original (remove UUID prefix)
get_clean_filename() {
    local original_file="$1"
    local imageset_name="$2"
    
    # Extract extension
    local ext="${original_file##*.}"
    
    # Create clean filename based on imageset name
    echo "${imageset_name}"
}

# Function to create standard Contents.json
create_contents_json() {
    local imageset_path="$1"
    local base_name="$2"
    
    cat > "$imageset_path/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${base_name}@1x.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${base_name}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${base_name}@3x.png",
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

# Function to resize image
resize_image() {
    local source_file="$1"
    local output_file="$2"
    local size="$3"
    
    # Use sips to crop to square from center and resize
    sips -z $size $size --cropToHeightWidth $size $size "$source_file" --out "$output_file" >/dev/null 2>&1
    return $?
}

# Function to process a single imageset
process_imageset() {
    local imageset_path="$1"
    local imageset_name=$(basename "$imageset_path" .imageset)
    
    echo -e "${YELLOW}📁 Processing: $imageset_name${NC}"
    
    # Find the source image (should be .jpeg)
    local source_image=$(find "$imageset_path" -name "*.jpeg" | head -1)
    
    if [ -z "$source_image" ]; then
        echo -e "${RED}   ⚠️  No source image found, skipping${NC}"
        ((skipped_imagesets++))
        return 1
    fi
    
    # Check current dimensions
    local current_width=$(sips -g pixelWidth "$source_image" | grep "pixelWidth" | awk '{print $2}')
    local current_height=$(sips -g pixelHeight "$source_image" | grep "pixelHeight" | awk '{print $2}')
    
    echo -e "   📏 Source: ${current_width}x${current_height}"
    
    # Generate the three sizes
    local base_name="$imageset_name"
    
    # @3x (870px)
    echo -e "   🔄 Creating @3x (${SIZE_3X}px)..."
    resize_image "$source_image" "$imageset_path/${base_name}@3x.png" $SIZE_3X
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✓ @3x created${NC}"
    else
        echo -e "${RED}   ✗ @3x failed${NC}"
        return 1
    fi
    
    # @2x (580px)
    echo -e "   🔄 Creating @2x (${SIZE_2X}px)..."
    resize_image "$source_image" "$imageset_path/${base_name}@2x.png" $SIZE_2X
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✓ @2x created${NC}"
    else
        echo -e "${RED}   ✗ @2x failed${NC}"
        return 1
    fi
    
    # @1x (290px)  
    echo -e "   🔄 Creating @1x (${SIZE_1X}px)..."
    resize_image "$source_image" "$imageset_path/${base_name}@1x.png" $SIZE_1X
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✓ @1x created${NC}"
    else
        echo -e "${RED}   ✗ @1x failed${NC}"
        return 1
    fi
    
    # Create new Contents.json
    echo -e "   📝 Updating Contents.json..."
    create_contents_json "$imageset_path" "$base_name"
    echo -e "${GREEN}   ✓ Contents.json updated${NC}"
    
    # Optionally remove original jpeg (keeping it for now as backup)
    # rm "$source_image"
    
    echo -e "${GREEN}   🎉 $imageset_name complete!${NC}"
    echo
    
    ((processed_imagesets++))
    return 0
}

# Main processing
echo -e "${BLUE}🔍 Scanning for pattern imagesets...${NC}"

# Find all imagesets in Patterns directory
while IFS= read -r -d '' imageset_path; do
    ((total_imagesets++))
    process_imageset "$imageset_path"
done < <(find "$PATTERNS_DIR" -name "*.imageset" -type d -print0)

echo
echo -e "${GREEN}🎉 Pattern Image Optimization Complete!${NC}"
echo "============================================="
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "   Total imagesets found: ${total_imagesets}"
echo -e "   Successfully processed: ${GREEN}${processed_imagesets}${NC}"
echo -e "   Skipped: ${YELLOW}${skipped_imagesets}${NC}"
echo
echo -e "${BLUE}📁 Each imageset now contains:${NC}"
echo -e "   • ${imageset_name}@1x.png (290x290px)"
echo -e "   • ${imageset_name}@2x.png (580x580px)"  
echo -e "   • ${imageset_name}@3x.png (870x870px)"
echo -e "   • Updated Contents.json"
echo
echo -e "${YELLOW}💡 Note: Original .jpeg files preserved as backup${NC}"
echo -e "${BLUE}🚀 Ready to build and test in Xcode!${NC}"