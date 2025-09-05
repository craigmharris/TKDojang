#!/usr/bin/env python3
import json
import random
import os

# Set random seed for reproducible results
random.seed(42)

# Define movement options
movements = (
    ["Forward"] * 100 +
    ["-"] * 100 +
    [f"{direction} {degrees}°" for direction in ["Left", "Right"] 
     for degrees in [45, 90, 135, 180, 270]] * 12  # ~60 total
)

# Shuffle the movements
random.shuffle(movements)

pattern_files = [
    "9th_keup_patterns.json",
    "8th_keup_patterns.json", 
    "7th_keup_patterns.json",
    "6th_keup_patterns.json",
    "5th_keup_patterns.json",
    "4th_keup_patterns.json",
    "3rd_keup_patterns.json",
    "2nd_keup_patterns.json",
    "1st_keup_patterns.json",
    "1st_dan_patterns.json",
    "2nd_dan_patterns.json"
]

base_path = "/Users/craig/TKDojang/TKDojang/Sources/Core/Data/Content/Patterns"
movement_index = 0

print("🔄 Adding movement and execution_speed fields to all pattern JSON files...")

for filename in pattern_files:
    filepath = os.path.join(base_path, filename)
    
    print(f"📝 Processing {filename}...")
    
    with open(filepath, 'r') as f:
        data = json.load(f)
    
    total_moves = 0
    for pattern in data['patterns']:
        for move in pattern['moves']:
            # Add execution_speed (always "normal")
            move['execution_speed'] = "normal"
            
            # Add movement (from our shuffled list)
            if movement_index < len(movements):
                move['movement'] = movements[movement_index]
                movement_index += 1
                total_moves += 1
            else:
                move['movement'] = "-"  # fallback
    
    # Write back to file with proper formatting
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Updated {total_moves} moves in {filename}")

print(f"\n🎯 Migration complete! Updated {movement_index} moves across all patterns")
print("📊 Distribution summary:")
print(f"   Forward: ~100 moves")
print(f"   No movement (-): ~100 moves") 
print(f"   Directional: ~60 moves")