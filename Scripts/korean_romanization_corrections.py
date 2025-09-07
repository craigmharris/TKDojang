#!/usr/bin/env python3
"""
Korean Romanization Correction Script for TKDojang Pattern Files

This script corrects Korean technique romanizations in pattern JSON files
by mapping English technique names to their correct Korean equivalents
using the terminology reference files.
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Any

class KoreanRomanizationCorrector:
    def __init__(self):
        # Build Korean mapping from terminology files
        self.korean_mapping = self._build_korean_mapping()
        self.corrections_applied = []
        
    def _build_korean_mapping(self) -> Dict[str, str]:
        """Build mapping of English techniques to Korean romanizations from terminology files"""
        mapping = {}
        
        # Define technique mappings based on terminology analysis
        # Basic punches
        mapping.update({
            "Obverse Punch": "Baro Jirugi",
            "Reverse Punch": "Bandae Jirugi",
            "High Punch": "Nopunde Jirugi",
            "Middle Punch": "Kaunde Jirugi",
            "Low Punch": "Najunde Jirugi",
            "Upset Punch": "Dwijibo Jirugi",
            "Twin Vertical Punch": "Sang Sewo Jirugi",
            "Double Punch": "Doo Jirugi",
            "Flat Fingertip Thrust": "Opun Sonkut Tulgi",
            "Straight Fingertip Thrust": "Sun Sonkut Tulgi",
            "Upset Fingertip Thrust": "Dwijibo Sonkut Tulgi"
        })
        
        # Basic blocks
        mapping.update({
            "Inner Forearm Block": "An Palmok Makgi",
            "Inner Forearm Middle Block": "An Palmok Kaunde Makgi",
            "Outer Forearm Block": "Bakat Palmok Makgi",
            "Outer Forearm Low Block": "Bakat Palmok Najunde Makgi",
            "Outer Forearm Middle Block": "Bakat Palmok Kaunde Makgi",
            "Outer Forearm High Block": "Bakat Palmok Nopunde Makgi",
            "Outer Forearm Middle Inward Block": "Bakat Palmok Kaunde Anaero Makgi",
            "Twin Outer Forearm Block": "Sang Bakat Palmok Makgi",
            "Double Forearm Block": "Doo Palmok Makgi",
            "Forearm Guarding Block": "Palmok Daebi Makgi",
            "Forearm Rising Block": "Palmok Chookyo Makgi",
            "Inner Forearm Circular Block": "An Palmok Dollimyo Makgi"
        })
        
        # Knife hand techniques
        mapping.update({
            "Knife Hand Block": "Sonkal Makgi",
            "Knife Hand Guarding Block": "Sonkal Daebi Makgi", 
            "Knife Hand Strike": "Sonkal Taerigi",
            "Inward Knife Hand Strike": "Anaero Sonkal Taerigi",
            "Knife Hand Downward Strike": "Naeryo Sonkal Taerigi",
            "Reverse Knife Hand Strike": "Bandae Sonkal Taerigi",
            "Reverse Knife Hand Inward Strike": "Sonkal Dung Anaero Taerigi",
            "Twin Knife Hand Block": "Sang Sonkal Makgi",
            "X Knife Hand Checking Block": "Kyocha Sonkal Momchau Makgi"
        })
        
        # Back fist techniques
        mapping.update({
            "Back Fist Strike": "Dung Joomuk Taerigi",
            "Back Fist Rear Strike": "Dung Joomuk Dwutcha Taerigi",
            "Back Fist Side Strike": "Dung Joomuk Yop Taerigi",
            "Back Fist Strike/Outer Forearm Low Block": "Dung Joomuk Taerigi/Bakat Palmok Najunde Makgi"
        })
        
        # Palm techniques  
        mapping.update({
            "Palm Pushing Block": "Sonbadak Mireo Makgi",
            "Twin Palm Upward Block": "Sang Sonbadak Ollyo Makgi",
            "Twin Upward Palm Block": "Sang Sonbadak Ollyo Makgi"
        })
        
        # Kicks
        mapping.update({
            "Front Kick": "Ap Chagi",
            "Front Snap Kick": "Ap Cha Busigi",
            "Side Piercing Kick": "Yop Cha Jirugi", 
            "Side Piercing Kick to Rear": "Dwi Yop Cha Jirugi",
            "Turning Kick": "Dollyo Chagi",
            "Reverse Side Kick": "Bandae Yop Chagi",
            "Flying Side Piercing Kick": "Twimyo Yop Cha Jirugi",
            "Rising Kick": "Ap Cha Olligi",
            "Knee Kick": "Moorup Chagi"
        })
        
        # Special blocks
        mapping.update({
            "X-Fist Pressing Block": "Kyocha Joomuk Noollo Makgi",
            "U-shape Block": "Digutja Makgi",
            "W Shaped Block": "San Makgi",
            "Double Forearm Pushing Block": "Doo Palmok Mireo Makgi"
        })
        
        # Complex techniques
        mapping.update({
            "Grab (Opponent's Head)": "Meori Japgi",
            "Grab to Shoulders": "Eokae Japgi",
            "Release Move": "Nohgi",
            "Posture Move": "Jasei Dongjak",
            "Flying Side Piercing Kick / Knife Hand Guarding Block": "Twimyo Yop Cha Jirugi/Sonkal Daebi Makgi",
            "Back Fist Strike / Outer Forearm Low Block": "Dung Joomuk Taerigi/Bakat Palmok Najunde Makgi",
            "Front Outer Forearm Block / Back Fist Side Strike": "Ap Bakat Palmok Makgi/Dung Joomuk Yop Taerigi",
            "Inner Forearm Block / Outer Forearm Block": "An Palmok Makgi/Bakat Palmok Makgi",
            "Jump 360 to Knife Hand Guarding Block": "360 Twimyo Sonkal Daebi Makgi"
        })
        
        # Elbow techniques
        mapping.update({
            "Side Elbow Thrust": "Yop Palkup Taerigi"
        })
        
        return mapping
    
    def correct_korean_romanizations(self, pattern_file_path: str) -> bool:
        """
        Correct Korean romanizations in a pattern file
        
        Args:
            pattern_file_path: Path to pattern JSON file
            
        Returns:
            bool: True if corrections were made, False otherwise
        """
        try:
            with open(pattern_file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            corrections_made = False
            file_corrections = []
            
            # Process each pattern in the file
            for pattern in data.get('patterns', []):
                pattern_name = pattern.get('name', 'Unknown')
                
                # Process each move in the pattern
                for move in pattern.get('moves', []):
                    move_number = move.get('move_number', 0)
                    english_technique = move.get('technique', '')
                    current_korean = move.get('korean_technique', '')
                    
                    # Check if we have a better Korean romanization
                    if english_technique in self.korean_mapping:
                        correct_korean = self.korean_mapping[english_technique]
                        
                        # Only update if current Korean is different
                        if current_korean != correct_korean:
                            old_korean = current_korean
                            move['korean_technique'] = correct_korean
                            corrections_made = True
                            
                            correction_info = {
                                'pattern': pattern_name,
                                'move': move_number,
                                'english_technique': english_technique,
                                'old_korean': old_korean,
                                'new_korean': correct_korean
                            }
                            file_corrections.append(correction_info)
            
            # Write back if corrections were made
            if corrections_made:
                with open(pattern_file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                
                self.corrections_applied.extend(file_corrections)
                print(f"✓ Updated {len(file_corrections)} Korean romanizations in {os.path.basename(pattern_file_path)}")
                
                # Print detailed corrections
                for correction in file_corrections:
                    print(f"  Move {correction['move']}: {correction['english_technique']}")
                    print(f"    Old: {correction['old_korean']}")
                    print(f"    New: {correction['new_korean']}")
            else:
                print(f"  No Korean corrections needed in {os.path.basename(pattern_file_path)}")
            
            return corrections_made
            
        except Exception as e:
            print(f"❌ Error processing {pattern_file_path}: {e}")
            return False
    
    def process_all_patterns(self, patterns_directory: str) -> None:
        """Process all pattern files in the directory"""
        patterns_path = Path(patterns_directory)
        
        if not patterns_path.exists():
            print(f"❌ Patterns directory not found: {patterns_directory}")
            return
        
        # Find all pattern JSON files
        pattern_files = list(patterns_path.glob("*_patterns.json"))
        
        if not pattern_files:
            print(f"❌ No pattern files found in {patterns_directory}")
            return
        
        print(f"Found {len(pattern_files)} pattern files to process...")
        
        total_files_updated = 0
        total_corrections = 0
        
        # Process each pattern file
        for pattern_file in sorted(pattern_files):
            print(f"\nProcessing {pattern_file.name}...")
            corrections_before = len(self.corrections_applied)
            
            if self.correct_korean_romanizations(str(pattern_file)):
                total_files_updated += 1
            
            corrections_after = len(self.corrections_applied)
            file_corrections = corrections_after - corrections_before
            total_corrections += file_corrections
        
        # Print summary
        print(f"\n{'='*60}")
        print(f"KOREAN ROMANIZATION CORRECTION SUMMARY")
        print(f"{'='*60}")
        print(f"Files processed: {len(pattern_files)}")
        print(f"Files updated: {total_files_updated}")
        print(f"Total Korean corrections applied: {total_corrections}")
        
        if self.corrections_applied:
            print(f"\nDetailed corrections:")
            for correction in self.corrections_applied:
                print(f"  {correction['pattern']} Move {correction['move']}: {correction['english_technique']}")
                print(f"    {correction['old_korean']} → {correction['new_korean']}")

def main():
    """Main function to run Korean romanization corrections"""
    # Define paths
    script_dir = Path(__file__).parent
    patterns_dir = script_dir.parent / "TKDojang/Sources/Core/Data/Content/Patterns"
    
    print("Korean Romanization Correction Script")
    print("=====================================")
    
    # Create corrector and process patterns
    corrector = KoreanRomanizationCorrector()
    corrector.process_all_patterns(str(patterns_dir))

if __name__ == "__main__":
    main()