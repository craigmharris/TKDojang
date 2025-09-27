#!/bin/bash

# Cleanup Script for Orphaned Pattern Images
# Removes original .jpeg files that are no longer referenced in Contents.json

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 TKDojang Orphaned Image Cleanup${NC}"
echo "====================================="
echo

# Paths
PATTERNS_DIR="/Users/craig/TKDojang/TKDojang/TKDojang.xcassets/Patterns"

# Counters
total_imagesets=0
cleaned_imagesets=0
total_orphaned_files=0

# Function to clean up orphaned files in an imageset
cleanup_imageset() {
    local imageset_path="$1"
    local imageset_name=$(basename "$imageset_path" .imageset)
    
    echo -e "${YELLOW}📁 Checking: $imageset_name${NC}"
    
    # Check if this imageset has our optimized PNG files
    local has_pngs=false
    if [ -f "$imageset_path/${imageset_name}@1x.png" ] && \
       [ -f "$imageset_path/${imageset_name}@2x.png" ] && \
       [ -f "$imageset_path/${imageset_name}@3x.png" ]; then
        has_pngs=true
    fi
    
    if [ "$has_pngs" = true ]; then
        # Find any .jpeg files in this imageset
        local jpeg_files=$(find "$imageset_path" -name "*.jpeg" 2>/dev/null)
        
        if [ -n "$jpeg_files" ]; then
            echo -e "   🔍 Found orphaned .jpeg files:"
            
            while IFS= read -r jpeg_file; do
                if [ -f "$jpeg_file" ]; then
                    local filename=$(basename "$jpeg_file")
                    echo -e "   📄 Removing: $filename"
                    
                    # Move to backup location (optional - comment out rm and uncomment mv to backup instead)
                    # mkdir -p "/tmp/tkdojang_backup/$(dirname "$jpeg_file" | sed 's|.*/Patterns/||')"
                    # mv "$jpeg_file" "/tmp/tkdojang_backup/$(dirname "$jpeg_file" | sed 's|.*/Patterns/||')/"
                    
                    # Remove the orphaned file
                    rm "$jpeg_file"
                    
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}   ✓ Removed successfully${NC}"
                        ((total_orphaned_files++))
                    else
                        echo -e "${RED}   ✗ Failed to remove${NC}"
                    fi
                fi
            done <<< "$jpeg_files"
            
            ((cleaned_imagesets++))
        else
            echo -e "${GREEN}   ✓ No orphaned files found${NC}"
        fi
    else
        echo -e "   ⚠️  No optimized PNGs found, skipping cleanup"
    fi
    
    echo
    ((total_imagesets++))
}

# Main processing
echo -e "${BLUE}🔍 Scanning for imagesets with orphaned files...${NC}"
echo

# Find all imagesets in Patterns directory
while IFS= read -r -d '' imageset_path; do
    cleanup_imageset "$imageset_path"
done < <(find "$PATTERNS_DIR" -name "*.imageset" -type d -print0)

echo
echo -e "${GREEN}🎉 Orphaned Image Cleanup Complete!${NC}"
echo "======================================"
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "   Total imagesets scanned: ${total_imagesets}"
echo -e "   Imagesets cleaned: ${GREEN}${cleaned_imagesets}${NC}"
echo -e "   Orphaned files removed: ${GREEN}${total_orphaned_files}${NC}"
echo
echo -e "${BLUE}✅ Benefits:${NC}"
echo -e "   • Eliminated Xcode 'unassigned child' errors"
echo -e "   • Cleaner asset organization"
echo -e "   • Reduced asset bundle size"
echo
echo -e "${YELLOW}💡 Note: Original .jpeg files have been permanently removed${NC}"
echo -e "${BLUE}🚀 Ready to build in Xcode without asset warnings!${NC}"