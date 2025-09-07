#!/usr/bin/env python3
"""
Pattern Update Script
Updates pattern JSON files based on corrections in pattern_adjustments.csv

This script:
1. Reads CSV corrections for technique, direction, stance, movement, and target
2. Updates corresponding JSON files with standardized values
3. Provides detailed logging and validation
"""

import csv
import json
import os
import sys
from typing import Dict, List, Any

class PatternUpdater:
    def __init__(self, csv_file: str, patterns_dir: str):
        self.csv_file = csv_file
        self.patterns_dir = patterns_dir
        self.corrections = {}
        self.updates_applied = 0
        self.patterns_updated = set()
        
    def load_corrections(self) -> None:
        """Load corrections from CSV file"""
        print(f"📊 Loading corrections from {self.csv_file}")
        
        with open(self.csv_file, 'r', encoding='utf-8') as file:
            # Handle BOM if present
            content = file.read()
            if content.startswith('\ufeff'):
                content = content[1:]
            
            reader = csv.DictReader(content.splitlines())
            
            for row in reader:
                pattern_name = row['Pattern'].strip()
                move_number = int(row['Move'])
                
                # Create correction key
                key = f"{pattern_name}_{move_number}"
                
                self.corrections[key] = {
                    'direction': row['Direction'].strip(),
                    'movement': row['Movement'].strip(),
                    'stance': row['Stance'].strip(),
                    'technique': row['Technique'].strip(),
                    'target': row['Target'].strip()
                }
        
        print(f"✅ Loaded {len(self.corrections)} corrections for {len(set(c.split('_')[0] for c in self.corrections))} patterns")
    
    def standardize_values(self, correction: Dict[str, str]) -> Dict[str, str]:
        """Standardize values to match expected JSON format"""
        standardized = correction.copy()
        
        # Standardize movement values
        movement = standardized['movement']
        if movement == '-':
            standardized['movement'] = '-'
        elif movement.isdigit():
            # Handle cases like "90" -> "Left 90°" or "Right 90°" 
            # We need context to determine left/right, so preserve as is for now
            if movement == '90':
                standardized['movement'] = f"Left {movement}°"  # Default assumption
            else:
                standardized['movement'] = f"{movement}°" if not movement.endswith('°') else movement
        elif not movement.endswith('°') and any(deg in movement for deg in ['90', '180', '270', '360', '45', '135']):
            if '°' not in movement:
                standardized['movement'] = movement + '°'
        
        # Standardize stance values
        stance = standardized['stance']
        if 'L Stance' in stance and '-' not in stance:
            standardized['stance'] = stance.replace('L Stance', 'L-stance')
        elif stance == 'Walking Stance':
            standardized['stance'] = stance  # Keep as is
        
        # Ensure proper capitalization for techniques
        standardized['technique'] = standardized['technique'].strip()
        
        return standardized
    
    def normalize_pattern_name(self, name: str) -> str:
        """Convert CSV pattern name to JSON pattern name format"""
        # CSV uses "Do San" format, JSON uses "Do-San" format
        return name.replace(' ', '-')
    
    def find_pattern_file(self, pattern_name: str) -> str:
        """Find the JSON file containing the specified pattern"""
        # Convert CSV name format to JSON name format
        json_pattern_name = self.normalize_pattern_name(pattern_name)
        
        # Map pattern names to approximate belt levels for file searching
        pattern_file_map = {
            'Dan-Gun': ['9th_keup_patterns.json', '8th_keup_patterns.json'],
            'Do-San': ['7th_keup_patterns.json', '6th_keup_patterns.json'], 
            'Won-Hyo': ['5th_keup_patterns.json', '4th_keup_patterns.json'],
            'Yul-Gok': ['3rd_keup_patterns.json', '2nd_keup_patterns.json'],
            'Joong-Gun': ['1st_keup_patterns.json'],
            'Toi-Gye': ['1st_dan_patterns.json'],
            'Hwa-Rang': ['1st_dan_patterns.json', '2nd_dan_patterns.json'],
            'Choong-Moo': ['1st_dan_patterns.json', '2nd_dan_patterns.json']
        }
        
        # Try specific files first
        if json_pattern_name in pattern_file_map:
            for filename in pattern_file_map[json_pattern_name]:
                file_path = os.path.join(self.patterns_dir, filename)
                if os.path.exists(file_path):
                    # Check if pattern actually exists in this file
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            data = json.load(f)
                            for pattern in data.get('patterns', []):
                                if pattern['name'] == json_pattern_name:
                                    return file_path
                    except:
                        continue
        
        # Fallback: search all files
        for filename in os.listdir(self.patterns_dir):
            if filename.endswith('.json'):
                file_path = os.path.join(self.patterns_dir, filename)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        for pattern in data.get('patterns', []):
                            if pattern['name'] == json_pattern_name:
                                return file_path
                except:
                    continue
        
        raise FileNotFoundError(f"Pattern '{pattern_name}' not found in any JSON file")
    
    def update_pattern_file(self, file_path: str, pattern_name: str, corrections: Dict[str, Dict[str, str]]) -> int:
        """Update a specific pattern file with corrections"""
        json_pattern_name = self.normalize_pattern_name(pattern_name)
        print(f"📝 Updating {os.path.basename(file_path)} for pattern '{json_pattern_name}'")
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        updates_count = 0
        
        # Find the pattern and update moves
        for pattern in data.get('patterns', []):
            if pattern['name'] == json_pattern_name:
                for move in pattern.get('moves', []):
                    move_number = move['move_number']
                    correction_key = f"{pattern_name}_{move_number}"
                    
                    if correction_key in corrections:
                        correction = self.standardize_values(corrections[correction_key])
                        
                        # Apply corrections
                        old_values = {
                            'direction': move.get('direction', ''),
                            'movement': move.get('movement', ''),
                            'stance': move.get('stance', ''),
                            'technique': move.get('technique', ''),
                            'target': move.get('target', '')
                        }
                        
                        move['direction'] = correction['direction']
                        move['movement'] = correction['movement']
                        move['stance'] = correction['stance']
                        move['technique'] = correction['technique']
                        move['target'] = correction['target']
                        
                        print(f"   Move {move_number}:")
                        for field in ['direction', 'movement', 'stance', 'technique', 'target']:
                            if old_values[field] != correction[field]:
                                print(f"     {field}: '{old_values[field]}' → '{correction[field]}'")
                        
                        updates_count += 1
                
                break
        
        # Write updated file
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        return updates_count
    
    def apply_corrections(self) -> None:
        """Apply all corrections to JSON files"""
        print(f"\n🔧 Applying corrections to pattern files...")
        
        # Group corrections by pattern
        patterns_to_correct = {}
        for key, correction in self.corrections.items():
            pattern_name = key.split('_')[0]
            if pattern_name not in patterns_to_correct:
                patterns_to_correct[pattern_name] = {}
            patterns_to_correct[pattern_name][key] = correction
        
        # Process each pattern
        for pattern_name, pattern_corrections in patterns_to_correct.items():
            try:
                file_path = self.find_pattern_file(pattern_name)
                updates = self.update_pattern_file(file_path, pattern_name, pattern_corrections)
                self.updates_applied += updates
                self.patterns_updated.add(pattern_name)
                print(f"   ✅ Applied {updates} corrections to {pattern_name}")
                
            except FileNotFoundError as e:
                print(f"   ❌ {e}")
            except Exception as e:
                print(f"   ❌ Error updating {pattern_name}: {e}")
    
    def generate_report(self) -> None:
        """Generate summary report"""
        print(f"\n📊 UPDATE SUMMARY:")
        print(f"   Corrections loaded: {len(self.corrections)}")
        print(f"   Updates applied: {self.updates_applied}")
        print(f"   Patterns updated: {len(self.patterns_updated)}")
        print(f"   Updated patterns: {', '.join(sorted(self.patterns_updated))}")
        
        if self.updates_applied != len(self.corrections):
            print(f"   ⚠️  {len(self.corrections) - self.updates_applied} corrections were not applied")

def main():
    # Set up paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    csv_file = os.path.join(script_dir, 'pattern_adjustments.csv')
    patterns_dir = os.path.join(project_root, 'TKDojang/Sources/Core/Data/Content/Patterns')
    
    print("🥋 TKDojang Pattern Update Script")
    print(f"   CSV file: {csv_file}")
    print(f"   Patterns directory: {patterns_dir}")
    
    # Verify files exist
    if not os.path.exists(csv_file):
        print(f"❌ CSV file not found: {csv_file}")
        sys.exit(1)
    
    if not os.path.exists(patterns_dir):
        print(f"❌ Patterns directory not found: {patterns_dir}")
        sys.exit(1)
    
    # Run the update
    updater = PatternUpdater(csv_file, patterns_dir)
    
    try:
        updater.load_corrections()
        updater.apply_corrections()
        updater.generate_report()
        print(f"\n✅ Pattern update complete!")
        
    except Exception as e:
        print(f"\n❌ Update failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()