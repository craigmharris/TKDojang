#!/bin/bash

# fix-asset-warnings.sh
# PURPOSE: Clean up missing image asset warnings in TKDojang.xcassets
# Removes filename references for missing image files while preserving scale structure

set -e

echo "🔧 Fixing asset catalog warnings..."

# Find all Contents.json files in the asset catalog
find TKDojang/TKDojang.xcassets -name "Contents.json" -path "*.imageset/*" | while read contents_file; do
    imageset_dir=$(dirname "$contents_file")
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Process the JSON to remove filename entries for missing files
    python3 << EOF
import json
import os
import sys

contents_file = "$contents_file"
imageset_dir = "$imageset_dir"

try:
    with open(contents_file, 'r') as f:
        data = json.load(f)
    
    if 'images' in data:
        for image_entry in data['images']:
            if 'filename' in image_entry:
                filename = image_entry['filename']
                full_path = os.path.join(imageset_dir, filename)
                
                # If file doesn't exist, remove the filename reference
                if not os.path.exists(full_path):
                    del image_entry['filename']
                    print(f"  ✓ Removed missing file reference: {filename}")
    
    with open("$temp_file", 'w') as f:
        json.dump(data, f, indent=2)
        
except Exception as e:
    print(f"  ✗ Error processing {contents_file}: {e}")
    sys.exit(1)
EOF
    
    # Replace the original file if processing succeeded
    if [ $? -eq 0 ]; then
        mv "$temp_file" "$contents_file"
    else
        rm -f "$temp_file"
    fi
done

echo "✅ Asset catalog warnings cleanup complete"