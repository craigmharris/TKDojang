#!/usr/bin/env python3
"""
LineWork Exercise Processing Script
Transforms CSV data into JSON format matching existing TKDojang structure
"""

import json
import csv
import re
from pathlib import Path
from typing import Dict, List, Any, Optional

class LineWorkProcessor:
    def __init__(self, csv_path: str, json_dir: str):
        self.csv_path = csv_path
        self.json_dir = Path(json_dir)
        self.belt_mapping = {
            "8th_keup": {"level": "8th Keup", "color": "yellow"},
            "7th_keup": {"level": "7th Keup", "color": "green"},
            "6th_keup": {"level": "6th Keup", "color": "green"},
            "5th_keup": {"level": "5th Keup", "color": "blue"},
            "4th_keup": {"level": "4th Keup", "color": "blue"},
            "3rd_keup": {"level": "3rd Keup", "color": "brown"},
            "2nd_keup": {"level": "2nd Keup", "color": "brown"}
        }
        self.existing_translations = {}
        self.load_existing_translations()
        
    def load_existing_translations(self):
        """Load existing romanised/hangul translations from current JSON files"""
        print("📚 Loading existing translations...")
        
        for belt_id in self.belt_mapping.keys():
            json_file = self.json_dir / f"{belt_id}_linework.json"
            if json_file.exists():
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    
                for exercise in data.get('line_work_exercises', []):
                    for technique in exercise.get('techniques', []):
                        key = technique['english'].lower().strip()
                        self.existing_translations[key] = {
                            'romanised': technique.get('romanised', ''),
                            'hangul': technique.get('hangul', ''),
                            'category': technique.get('category', ''),
                            'description': technique.get('description', '')
                        }
        
        print(f"✅ Loaded {len(self.existing_translations)} existing translations")
    
    def to_title_case(self, text: str) -> str:
        """Convert to Title Case with proper handling of special cases"""
        if not text:
            return text
            
        # Handle special cases
        special_cases = {
            'x-fist': 'X-Fist',
            'x-block': 'X-Block', 
            'u-shaped': 'U-Shaped',
            'w shaped': 'W Shaped',
            'l stance': 'L Stance',
            '(x2)': '(x2)',
            '(360 deg)': '(360 deg)',
            '(180 deg)': '(180 deg)',
            '(same leg)': '(Same Leg)',
            'won hyo': 'Won Hyo',
            'joong gun': 'Joong Gun',
            'yul gok': 'Yul Gok',
            'toi gye': 'Toi Gye',
            'hwa rang': 'Hwa Rang'
        }
        
        text = text.strip()
        lower_text = text.lower()
        
        # Check for exact special case matches
        for special, replacement in special_cases.items():
            if special in lower_text:
                text = text.replace(special, replacement)
                text = text.replace(special.title(), replacement)
        
        # Apply title case
        words = text.split()
        result = []
        
        for word in words:
            # Don't title case articles/prepositions unless they're first word
            if word.lower() in ['and', 'or', 'in', 'on', 'to', 'of', 'from', 'into'] and len(result) > 0:
                result.append(word.lower())
            else:
                result.append(word.capitalize())
        
        return ' '.join(result)
    
    def parse_techniques(self, techniques_str: str) -> List[str]:
        """Parse pipe-separated technique string"""
        if not techniques_str:
            return []
        
        techniques = [t.strip() for t in techniques_str.split('|') if t.strip()]
        return [self.to_title_case(tech) for tech in techniques]
    
    def infer_category(self, technique_name: str) -> str:
        """Infer category based on technique name"""
        name_lower = technique_name.lower()
        
        if any(word in name_lower for word in ['stance', 'ready']):
            return 'Stances'
        elif any(word in name_lower for word in ['kick', 'kicking']):
            return 'Kicks'
        elif any(word in name_lower for word in ['block', 'blocking', 'guard']):
            return 'Blocking'
        elif any(word in name_lower for word in ['punch', 'strike', 'thrust', 'fist', 'elbow']):
            return 'Striking'
        elif any(word in name_lower for word in ['grab', 'grasp', 'release']):
            return 'Grappling'
        elif any(word in name_lower for word in ['spin', 'turn', 'jump']):
            return 'Movement'
        else:
            return 'Techniques'
    
    def get_target_area(self, technique_name: str) -> Optional[str]:
        """Determine target area from technique name"""
        name_lower = technique_name.lower()
        
        if any(word in name_lower for word in ['high', 'head', 'upper']):
            return 'High section'
        elif any(word in name_lower for word in ['middle', 'middle section', 'solar plexus']):
            return 'Middle section'
        elif any(word in name_lower for word in ['low', 'leg', 'waist']):
            return 'Low section'
        else:
            return None
    
    def create_technique_object(self, technique_name: str) -> Dict[str, Any]:
        """Create technique object with translations and metadata"""
        key = technique_name.lower().strip()
        
        # Use existing translation if available
        if key in self.existing_translations:
            translation = self.existing_translations[key]
            romanised = translation['romanised']
            hangul = translation['hangul']
            description = translation['description']
        else:
            # Use fallback - keep existing translations intact
            romanised = "Technique Name"  # Placeholder - should be updated manually later
            hangul = "기술명"  # Placeholder 
            description = f"Execute {technique_name.lower()} with proper form and technique"
        
        return {
            "id": re.sub(r'[^a-z0-9_]', '_', technique_name.lower().replace(' ', '_')),
            "english": technique_name,
            "romanised": romanised,
            "hangul": hangul,
            "category": self.infer_category(technique_name),
            "target_area": self.get_target_area(technique_name),
            "description": description
        }
    
    def generate_execution_content(self, exercise_name: str, techniques: List[str], 
                                 direction: str, repetitions: int, notes: str = "") -> Dict[str, Any]:
        """Generate execution details based on techniques and context"""
        
        # Determine movement pattern
        if direction.upper() == "STATIC":
            pattern = f"Execute {exercise_name.lower()} from stationary position"
        elif direction.upper() == "FWD":
            pattern = f"Step forward while executing {exercise_name.lower()}"
        elif direction.upper() == "BWD":  
            pattern = f"Step backward while executing {exercise_name.lower()}"
        elif direction.upper() in ["FWD & BWD", "BOTH"]:
            pattern = f"Step forward executing {exercise_name.lower()}, then repeat stepping backward"
        else:
            pattern = f"Execute {exercise_name.lower()} with proper timing and form"
        
        # Generate key points based on techniques
        key_points = []
        if any('stance' in t.lower() for t in techniques):
            key_points.append("Maintain proper stance foundation throughout")
        if any('kick' in t.lower() for t in techniques):
            key_points.append("Control balance during kicking techniques")
        if any('block' in t.lower() for t in techniques):
            key_points.append("Effective blocking coverage and timing")
        if any('punch' in t.lower() or 'strike' in t.lower() for t in techniques):
            key_points.append("Generate power through hip rotation and body mechanics")
        if len(techniques) > 2:
            key_points.append("Smooth coordination between multiple techniques")
        
        # Add notes-specific key points
        if notes and "won hyo" in notes.lower():
            key_points.append("Follow Won Hyo pattern timing and characteristics")
        elif notes and any(pattern in notes.lower() for pattern in ["joong gun", "yul gok", "toi gye", "hwa rang"]):
            pattern_name = next(p for p in ["joong gun", "yul gok", "toi gye", "hwa rang"] if p in notes.lower())
            key_points.append(f"Execute according to {pattern_name.title()} pattern requirements")
        
        # Generate common mistakes
        common_mistakes = [
            "Poor timing between techniques",
            "Insufficient power generation", 
            "Loss of balance during execution",
            "Incorrect technique sequencing"
        ]
        
        # Generate execution tips
        execution_tips = [
            "Practice each component technique separately first",
            "Focus on smooth transitions between movements",
            "Maintain proper form throughout execution"
        ]
        
        return {
            "direction": direction.lower() if direction.upper() in ["FWD", "BWD", "STATIC"] else "both",
            "repetitions": repetitions,
            "movement_pattern": pattern,
            "key_points": key_points,
            "common_mistakes": common_mistakes,
            "execution_tips": execution_tips
        }
    
    def process_csv_row(self, row: Dict[str, str]) -> Optional[Dict[str, Any]]:
        """Process a single CSV row into exercise object"""
        try:
            belt_level = row['Belt Level'].strip()
            belt_id = row['Belt ID'].strip()
            order = int(row['Order'])
            exercise_name = self.to_title_case(row['Exercise Name'].strip())
            direction = row['Direction'].strip()
            movement_type = row['Movement Type'].strip()
            techniques_str = row['Techniques (pipe-separated)'].strip()
            repetitions = int(row['Repetitions']) if row['Repetitions'].strip() else 5
            notes = row['Notes'].strip() if 'Notes' in row else ""
            
            # Parse techniques
            technique_names = self.parse_techniques(techniques_str)
            if not technique_names:
                print(f"⚠️  No techniques found for {exercise_name}")
                return None
            
            # Create technique objects
            techniques = [self.create_technique_object(name) for name in technique_names]
            
            # Generate execution content
            execution = self.generate_execution_content(
                exercise_name, technique_names, direction, repetitions, notes
            )
            
            # Determine categories
            categories = list(set(tech['category'] for tech in techniques))
            
            # Create exercise object
            exercise = {
                "id": re.sub(r'[^a-z0-9_]', '_', exercise_name.lower().replace(' ', '_')),
                "movement_type": movement_type,
                "order": order,
                "name": exercise_name,
                "techniques": techniques,
                "execution": execution,
                "categories": sorted(categories)
            }
            
            # Add notes if present
            if notes:
                exercise["notes"] = notes
            
            return exercise
            
        except Exception as e:
            print(f"❌ Error processing row {row}: {e}")
            return None
    
    def process_belt_level(self, belt_id: str, exercises: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Create complete belt level JSON structure"""
        belt_info = self.belt_mapping[belt_id]
        
        # Generate skill focus based on exercises
        skill_focuses = []
        has_patterns = any('notes' in ex and any(p in ex['notes'].lower() 
                          for p in ['won hyo', 'joong gun', 'yul gok', 'toi gye', 'hwa rang']) 
                         for ex in exercises)
        if has_patterns:
            skill_focuses.append("Pattern integration and application")
        
        has_complex = any(len(ex['techniques']) > 3 for ex in exercises)
        if has_complex:
            skill_focuses.append("Complex multi-technique combinations")
        
        has_kicks = any('Kicks' in ex['categories'] for ex in exercises)
        if has_kicks:
            skill_focuses.append("Advanced kicking techniques")
        
        has_l_stance = any(any('l stance' in tech['english'].lower() 
                              for tech in ex['techniques']) for ex in exercises)
        if has_l_stance:
            skill_focuses.append("L stance proficiency and applications")
        
        # Default skill focuses if none detected
        if not skill_focuses:
            skill_focuses = [
                "Technical precision and coordination",
                "Defensive and offensive combinations",
                "Stance stability and transitions"
            ]
        
        return {
            "belt_level": belt_info["level"],
            "belt_id": belt_id,
            "belt_color": belt_info["color"],
            "line_work_exercises": exercises,
            "total_exercises": len(exercises),
            "skill_focus": skill_focuses
        }
    
    def process_all(self):
        """Process entire CSV and update all belt level files"""
        print("🚀 Starting LineWork processing...")
        
        # Read CSV data
        belt_exercises = {}
        
        with open(self.csv_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            
            for row in reader:
                belt_id = row['Belt ID'].strip()
                
                # Only process the belts we want to update
                if belt_id not in self.belt_mapping:
                    continue
                
                exercise = self.process_csv_row(row)
                if exercise:
                    if belt_id not in belt_exercises:
                        belt_exercises[belt_id] = []
                    belt_exercises[belt_id].append(exercise)
        
        # Process each belt level
        results = {}
        for belt_id, exercises in belt_exercises.items():
            print(f"📝 Processing {belt_id}: {len(exercises)} exercises")
            
            # Sort exercises by order
            exercises.sort(key=lambda x: x['order'])
            
            # Create belt level data
            belt_data = self.process_belt_level(belt_id, exercises)
            results[belt_id] = belt_data
            
            # Write to file
            output_file = self.json_dir / f"{belt_id}_linework.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(belt_data, f, indent=2, ensure_ascii=False)
            
            print(f"✅ Updated {output_file}")
        
        return results
    
    def generate_summary(self, results: Dict[str, Any]):
        """Generate processing summary for verification"""
        print("\n" + "="*60)
        print("📊 PROCESSING SUMMARY")
        print("="*60)
        
        total_exercises = 0
        for belt_id, data in results.items():
            exercises = data['line_work_exercises']
            total_exercises += len(exercises)
            print(f"\n🥋 {data['belt_level']} ({belt_id}):")
            print(f"   • {len(exercises)} exercises")
            print(f"   • Skill focus: {', '.join(data['skill_focus'])}")
            
            # Show first exercise as sample
            if exercises:
                sample = exercises[0]
                print(f"   • Sample: {sample['name']}")
                print(f"     - Techniques: {len(sample['techniques'])}")
                print(f"     - Categories: {', '.join(sample['categories'])}")
                if 'notes' in sample:
                    print(f"     - Notes: {sample['notes']}")
        
        print(f"\n🎯 TOTAL: {total_exercises} exercises processed across {len(results)} belt levels")
        print("\n🔍 VERIFICATION SUGGESTIONS:")
        print("   1. Check 6th Keup exercise 1 (Won Hyo pattern reference)")
        print("   2. Check 4th Keup exercise 1 (Joong Gun pattern reference)")  
        print("   3. Check 2nd Keup exercise 11-14 (jumping techniques)")
        print("   4. Verify Title Case conversion is consistent")
        print("   5. Confirm existing romanised/hangul preserved")
        print("="*60)

def main():
    # Configuration
    csv_path = "/Users/craig/TKDojang/linework_exercises.csv"
    json_dir = "/Users/craig/TKDojang/TKDojang/Sources/Core/Data/Content/LineWork"
    
    # Process
    processor = LineWorkProcessor(csv_path, json_dir)
    results = processor.process_all()
    processor.generate_summary(results)
    
    print("\n✨ Processing complete! Ready for verification.")

if __name__ == "__main__":
    main()