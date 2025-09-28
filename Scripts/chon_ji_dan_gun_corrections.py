#!/usr/bin/env python3
"""
Chon Ji and Dan Gun Pattern Corrections Script

This script applies corrections to Chon Ji and Dan Gun patterns:
1. Remove "Left/Right " prefixes from stances
2. Split techniques that contain target sections
3. Standardize target section naming
4. Fix typos and inconsistencies
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Any

class ChonJiDanGunCorrector:
    def __init__(self):
        self.corrections_applied = []
        
    def apply_corrections(self, pattern_file_path: str) -> bool:
        """Apply corrections to a pattern file"""
        try:
            with open(pattern_file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            corrections_made = False
            file_corrections = []
            
            for pattern in data.get('patterns', []):
                pattern_name = pattern.get('name', 'Unknown')
                
                if pattern_name == "Chon-Ji":
                    corrections_made |= self._correct_chon_ji(pattern, file_corrections)
                elif pattern_name == "Dan-Gun":
                    corrections_made |= self._correct_dan_gun(pattern, file_corrections)
                    
            if corrections_made:
                with open(pattern_file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                
                self.corrections_applied.extend(file_corrections)
                print(f"✓ Updated {len(file_corrections)} corrections in {os.path.basename(pattern_file_path)}")
                
                # Print detailed corrections
                for correction in file_corrections:
                    print(f"  Move {correction['move']}: {correction['field']} - {correction['old']} → {correction['new']}")
            else:
                print(f"  No corrections needed in {os.path.basename(pattern_file_path)}")
                
            return corrections_made
            
        except Exception as e:
            print(f"❌ Error processing {pattern_file_path}: {e}")
            return False
    
    def _correct_chon_ji(self, pattern: Dict, file_corrections: List) -> bool:
        """Apply corrections specific to Chon Ji pattern"""
        corrections_made = False
        
        for move in pattern.get('moves', []):
            move_num = move.get('move_number', 0)
            
            # Remove Left/Right prefixes from stances
            stance = move.get('stance', '')
            if stance.startswith('Left ') or stance.startswith('Right '):
                old_stance = stance
                new_stance = stance.replace('Left ', '').replace('Right ', '')
                # Fix "L Stance" to "L-stance"
                if new_stance == "L Stance":
                    new_stance = "L-stance"
                move['stance'] = new_stance
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'stance',
                    'old': old_stance,
                    'new': new_stance
                })
            
            # Split techniques that contain target sections
            technique = move.get('technique', '')
            target = move.get('target', '')
            
            # Handle technique/target corrections
            new_technique, new_target = self._split_technique_target(technique, target, move_num)
            
            if new_technique != technique:
                move['technique'] = new_technique
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'technique',
                    'old': technique,
                    'new': new_technique
                })
            
            if new_target != target:
                move['target'] = new_target
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'target',
                    'old': target,
                    'new': new_target
                })
                
        return corrections_made
    
    def _correct_dan_gun(self, pattern: Dict, file_corrections: List) -> bool:
        """Apply corrections specific to Dan Gun pattern"""
        corrections_made = False
        
        for move in pattern.get('moves', []):
            move_num = move.get('move_number', 0)
            
            # Remove Left/Right prefixes from stances
            stance = move.get('stance', '')
            if stance.startswith('Left ') or stance.startswith('Right '):
                old_stance = stance
                new_stance = stance.replace('Left ', '').replace('Right ', '')
                # Fix "L Stance" to "L-stance"
                if new_stance == "L Stance":
                    new_stance = "L-stance"
                move['stance'] = new_stance
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'stance',
                    'old': old_stance,
                    'new': new_stance
                })
            
            # Fix specific technique typos
            technique = move.get('technique', '')
            if technique == "High Observe Punch":  # Move 4 typo
                move['technique'] = "High Obverse Punch"
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'technique',
                    'old': technique,
                    'new': "High Obverse Punch"
                })
                technique = "High Obverse Punch"
                
            if technique == "Twin Outer Forearm Bloack":  # Move 11 typo
                move['technique'] = "Twin Outer Forearm Block"
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'technique',
                    'old': technique,
                    'new': "Twin Outer Forearm Block"
                })
                technique = "Twin Outer Forearm Block"
            
            # Split techniques that contain target sections
            target = move.get('target', '')
            new_technique, new_target = self._split_technique_target(technique, target, move_num, pattern_name="Dan-Gun")
            
            if new_technique != technique:
                move['technique'] = new_technique
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'technique',
                    'old': technique,
                    'new': new_technique
                })
            
            if new_target != target:
                move['target'] = new_target
                corrections_made = True
                file_corrections.append({
                    'move': move_num,
                    'field': 'target',
                    'old': target,
                    'new': new_target
                })
                
        return corrections_made
    
    def _split_technique_target(self, technique: str, current_target: str, move_num: int, pattern_name: str = "Chon-Ji") -> tuple:
        """Split technique names that contain target sections and standardize targets"""
        
        # Handle techniques with embedded targets
        if technique == "Low Outer Forearm Block":
            return "Outer Forearm Block", "Low Section"
        elif technique == "Middle Obverse Punch":
            return "Obverse Punch", "Middle Section"
        elif technique == "High Obverse Punch":
            return "Obverse Punch", "High Section"
        elif technique == "Middle Inner Forearm Block":
            return "Inner Forearm Block", "Middle Section"
        elif technique == "High Obverse Block":
            return "Outer Forearm Block", "High Section"
        elif technique == "Rising Block":
            return "Forearm Rising Block", "High Section"
        
        # If no technique change needed, just standardize target
        new_target = self._standardize_target(current_target)
        return technique, new_target
    
    def _standardize_target(self, target: str) -> str:
        """Standardize target section names"""
        if not target or target == "null":
            return target
            
        # Convert various target formats to standard sections
        target_lower = target.lower()
        
        if target_lower in ["lower section", "low section"]:
            return "Low Section"
        elif target_lower in ["middle section", "solar plexus"]:
            return "Middle Section"
        elif target_lower in ["upper section", "high section", "head level"]:
            return "High Section"
        
        # Return original if no match (for now)
        return target

def main():
    """Main function to run corrections"""
    script_dir = Path(__file__).parent
    patterns_dir = script_dir.parent / "TKDojang/Sources/Core/Data/Content/Patterns"
    
    print("Chon Ji and Dan Gun Pattern Corrections")
    print("=====================================")
    
    corrector = ChonJiDanGunCorrector()
    
    # Process Chon Ji (9th keup)
    chon_ji_file = patterns_dir / "9th_keup_patterns.json"
    if chon_ji_file.exists():
        print(f"\nProcessing Chon Ji pattern...")
        corrector.apply_corrections(str(chon_ji_file))
    else:
        print(f"❌ Chon Ji file not found: {chon_ji_file}")
    
    # Process Dan Gun (8th keup)
    dan_gun_file = patterns_dir / "8th_keup_patterns.json"
    if dan_gun_file.exists():
        print(f"\nProcessing Dan Gun pattern...")
        corrector.apply_corrections(str(dan_gun_file))
    else:
        print(f"❌ Dan Gun file not found: {dan_gun_file}")
    
    # Print summary
    print(f"\n{'='*60}")
    print(f"CHON JI & DAN GUN CORRECTIONS SUMMARY")
    print(f"{'='*60}")
    print(f"Total corrections applied: {len(corrector.corrections_applied)}")
    
    if corrector.corrections_applied:
        print(f"\nAll corrections:")
        for correction in corrector.corrections_applied:
            print(f"  Move {correction['move']}: {correction['field']} - {correction['old']} → {correction['new']}")

if __name__ == "__main__":
    main()