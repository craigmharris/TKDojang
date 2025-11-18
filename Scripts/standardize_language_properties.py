#!/usr/bin/env python3
"""
Standardize language property names across all TKDojang JSON files.

Target schema:
- english: English term (British spelling, Title Case)
- romanised: Romanised Korean pronunciation (British spelling)
- hangul: Korean script (Hangul)
- phonetic: IPA phonetic pronunciation

This script preserves existing JSON structure (nesting levels) and only renames property keys.
Missing fields are omitted entirely (no null/empty values).
"""

import json
import hashlib
import os
from pathlib import Path
from typing import Dict, Any, List, Tuple
from collections import defaultdict


class LanguagePropertyStandardizer:
    """Standardizes language property names while preserving JSON structure."""

    def __init__(self, content_dir: Path, dry_run: bool = False, verbose: bool = False):
        self.content_dir = content_dir
        self.dry_run = dry_run
        self.verbose = verbose
        self.stats = defaultdict(int)
        self.changes_log = []

    def standardize_terminology(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Standardize Terminology files (root-level properties in terminology array)."""
        mapping = {
            'english_term': 'english',
            'romanized_pronunciation': 'romanised',
            'korean_hangul': 'hangul',
            'phonetic_pronunciation': 'phonetic'
        }

        if 'terminology' in data:
            for term in data['terminology']:
                self._rename_keys(term, mapping)

        return data

    def standardize_techniques(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Standardize Techniques files (nested in 'names' object)."""
        mapping = {
            'korean_romanized': 'romanised',
            'korean': 'hangul',
            'korean_hangul': 'hangul'
            # 'english' and 'phonetic' already correct
        }

        if 'techniques' in data:
            for technique in data['techniques']:
                if 'names' in technique:
                    self._rename_keys(technique['names'], mapping)

        return data

    def standardize_linework(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Standardize LineWork files (techniques array)."""
        # Already uses correct naming (english, romanised, hangul)
        # No changes needed - British spelling already present!
        return data

    def standardize_patterns(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Standardize Patterns files (multiple nesting levels)."""

        if 'patterns' in data:
            for pattern in data['patterns']:
                # Pattern level mappings
                pattern_mapping = {
                    'name': 'english',
                    'pronunciation': 'romanised'
                    # 'hangul' and 'phonetic' already correct
                }
                self._rename_keys(pattern, pattern_mapping)

                # Move level mappings
                if 'moves' in pattern:
                    move_mapping = {
                        'technique': 'english',
                        'korean_technique': 'romanised'
                    }
                    for move in pattern['moves']:
                        self._rename_keys(move, move_mapping)

        return data

    def standardize_stepsparring(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Standardize StepSparring files (action objects)."""
        action_mapping = {
            'technique': 'english',
            'korean_name': 'romanised'
        }

        if 'sequences' in data:
            for sequence in data['sequences']:
                if 'steps' in sequence:
                    for step in sequence['steps']:
                        # Standardize attack, defense, counter actions
                        for action_type in ['attack', 'defense', 'counter']:
                            if action_type in step and step[action_type]:
                                self._rename_keys(step[action_type], action_mapping)

        return data

    def standardize_theory(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Standardize Theory files (various nested locations)."""
        mapping = {
            'name': 'english',
            'korean': 'romanised'
            # 'english' already correct where used
        }

        # Handle theory_sections
        if 'theory_sections' in data:
            for section in data['theory_sections']:
                if 'content' in section:
                    content = section['content']

                    # Handle tenets
                    if 'tenets' in content:
                        for tenet in content['tenets']:
                            self._rename_keys(tenet, mapping)

                    # Handle greeting_terms
                    if 'greeting_terms' in content:
                        for term in content['greeting_terms']:
                            self._rename_keys(term, mapping)

                    # Handle other arrays that might have language properties
                    for key, value in content.items():
                        if isinstance(value, list):
                            for item in value:
                                if isinstance(item, dict):
                                    self._rename_keys(item, mapping)

        return data

    def standardize_vocabulary(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Standardize VocabularyBuilder files."""
        mapping = {
            'romanized': 'romanised'
            # 'english' and 'hangul' already correct
        }

        if 'words' in data:
            for word in data['words']:
                self._rename_keys(word, mapping)

        return data

    def _rename_keys(self, obj: Dict[str, Any], mapping: Dict[str, str], context: str = "") -> None:
        """Rename keys in-place according to mapping. Omit fields with empty values."""
        keys_to_rename = []
        for old_key, new_key in mapping.items():
            if old_key in obj:
                value = obj[old_key]
                # Only include if value is non-empty
                if value and value != "":
                    keys_to_rename.append((old_key, new_key, value))
                else:
                    # Remove empty values
                    del obj[old_key]
                    self.stats['empty_fields_removed'] += 1
                    if self.verbose:
                        self.changes_log.append(f"  {context}: removed empty field '{old_key}'")

        # Apply renamings
        for old_key, new_key, value in keys_to_rename:
            if old_key != new_key:  # Only rename if actually different
                obj[new_key] = value
                del obj[old_key]
                self.stats['properties_renamed'] += 1
                if self.verbose:
                    self.changes_log.append(f"  {context}: {old_key} → {new_key}")

    def detect_file_type(self, file_path: Path) -> str:
        """Detect file type based on path pattern."""
        path_str = str(file_path)

        if '/Terminology/' in path_str:
            return 'terminology'
        elif '/Techniques/' in path_str:
            return 'techniques'
        elif '/LineWork/' in path_str:
            return 'linework'
        elif '/Patterns/' in path_str:
            return 'patterns'
        elif '/StepSparring/' in path_str:
            return 'stepsparring'
        elif '/Theory/' in path_str:
            return 'theory'
        elif '/VocabularyBuilder/' in path_str:
            return 'vocabulary'
        else:
            return 'unknown'

    def process_file(self, file_path: Path) -> Tuple[bool, str]:
        """
        Process a single JSON file.

        Returns:
            (success: bool, message: str)
        """
        try:
            # Read original file
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Detect file type and apply appropriate transformation
            file_type = self.detect_file_type(file_path)

            # Store initial rename count to track changes per file
            initial_renames = self.stats['properties_renamed']

            if file_type == 'terminology':
                data = self.standardize_terminology(data)
            elif file_type == 'techniques':
                data = self.standardize_techniques(data)
            elif file_type == 'linework':
                data = self.standardize_linework(data)
            elif file_type == 'patterns':
                data = self.standardize_patterns(data)
            elif file_type == 'stepsparring':
                data = self.standardize_stepsparring(data)
            elif file_type == 'theory':
                data = self.standardize_theory(data)
            elif file_type == 'vocabulary':
                data = self.standardize_vocabulary(data)
            else:
                return False, f"Unknown file type: {file_type}"

            changes_count = self.stats['properties_renamed'] - initial_renames

            # Write file if not dry-run
            if not self.dry_run:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                    f.write('\n')  # Add trailing newline
                self.stats['files_written'] += 1
            else:
                self.stats['files_analyzed'] += 1

            status_msg = f"✓ {file_type.upper()}"
            if changes_count > 0:
                status_msg += f" ({changes_count} properties renamed)"

            return True, status_msg

        except Exception as e:
            return False, f"Error: {str(e)}"

    def process_all(self) -> None:
        """Process all JSON files in content directory."""
        json_files = list(self.content_dir.rglob('*.json'))

        print(f"\n{'='*70}")
        print(f"TKDojang Language Property Standardization")
        print(f"{'='*70}")
        print(f"Mode: {'DRY RUN (no files will be modified)' if self.dry_run else 'LIVE (files will be modified)'}")
        print(f"Files found: {len(json_files)}")
        print(f"{'='*70}\n")

        results = []
        for file_path in sorted(json_files):
            rel_path = file_path.relative_to(self.content_dir)
            success, message = self.process_file(file_path)
            results.append((rel_path, success, message))

            status_icon = "✓" if success else "✗"
            print(f"{status_icon} {rel_path}: {message}")

        # Print summary
        print(f"\n{'='*70}")
        print(f"Summary")
        print(f"{'='*70}")
        print(f"Total files processed: {len(json_files)}")
        print(f"Successful: {sum(1 for _, success, _ in results if success)}")
        print(f"Failed: {sum(1 for _, success, _ in results if not success)}")
        print(f"Properties renamed: {self.stats['properties_renamed']}")
        print(f"Empty fields removed: {self.stats['empty_fields_removed']}")
        if self.dry_run:
            print(f"Files analyzed (dry-run): {self.stats['files_analyzed']}")
        else:
            print(f"Files written: {self.stats['files_written']}")
        print(f"{'='*70}\n")

        # Show failures
        failures = [(path, msg) for path, success, msg in results if not success]
        if failures:
            print(f"{'='*70}")
            print(f"FAILURES:")
            print(f"{'='*70}")
            for path, msg in failures:
                print(f"✗ {path}: {msg}")
            print(f"{'='*70}\n")


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Standardize language property names in TKDojang JSON files'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without modifying files'
    )
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Show detailed change log for each file'
    )
    parser.add_argument(
        '--content-dir',
        type=Path,
        default=Path(__file__).parent.parent / 'TKDojang' / 'Sources' / 'Core' / 'Data' / 'Content',
        help='Path to Content directory (default: auto-detect)'
    )

    args = parser.parse_args()

    if not args.content_dir.exists():
        print(f"Error: Content directory not found: {args.content_dir}")
        return 1

    standardizer = LanguagePropertyStandardizer(
        args.content_dir,
        dry_run=args.dry_run,
        verbose=args.verbose
    )
    standardizer.process_all()

    return 0


if __name__ == '__main__':
    exit(main())
