#!/bin/bash

# Test script for single pattern image optimization
source_dir="/Users/craig/TKDojang/TKDojang/TKDojang.xcassets/Patterns/Moves/chon-ji-1.imageset"

echo "🧪 Testing single pattern optimization..."
echo "Source: $source_dir"

# Check current state
echo "📋 Current contents:"
ls -la "$source_dir"

echo ""
echo "📏 Current image dimensions:"
find "$source_dir" -name "*.jpeg" -exec sips -g pixelWidth -g pixelHeight {} \;

# Test resize on a copy
echo ""
echo "🔄 Testing resize operations..."
source_image=$(find "$source_dir" -name "*.jpeg" | head -1)

if [ -n "$source_image" ]; then
    echo "Source image: $source_image"
    
    # Test @3x resize
    echo "Testing @3x (870px) resize..."
    sips -z 870 870 --cropToHeightWidth 870 870 "$source_image" --out "/tmp/test-3x.png" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ @3x resize successful"
        sips -g pixelWidth -g pixelHeight "/tmp/test-3x.png"
    else
        echo "❌ @3x resize failed"
    fi
    
    # Test @2x resize  
    echo "Testing @2x (580px) resize..."
    sips -z 580 580 --cropToHeightWidth 580 580 "$source_image" --out "/tmp/test-2x.png" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ @2x resize successful"
        sips -g pixelWidth -g pixelHeight "/tmp/test-2x.png"
    else
        echo "❌ @2x resize failed"
    fi
    
    # Test @1x resize
    echo "Testing @1x (290px) resize..."
    sips -z 290 290 --cropToHeightWidth 290 290 "$source_image" --out "/tmp/test-1x.png" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ @1x resize successful"
        sips -g pixelWidth -g pixelHeight "/tmp/test-1x.png"
    else
        echo "❌ @1x resize failed"
    fi
    
    # Clean up test files
    rm -f /tmp/test-*.png
    
else
    echo "❌ No source image found"
fi