#!/usr/bin/env python3
"""
Update CodingKeys in test files to match standardized JSON property names.

This script updates test files that load JSON directly to use the new
standardized property names (english, romanised, hangul, phonetic).
"""

import re
from pathlib import Path
from typing import List, Tuple


class TestCodingKeysUpdater:
    """Updates CodingKeys in Swift test files to match new JSON schema."""

    def __init__(self, tests_dir: Path, dry_run: bool = False):
        self.tests_dir = tests_dir
        self.dry_run = dry_run
        self.stats = {
            'files_processed': 0,
            'files_modified': 0,
            'replacements_made': 0
        }

    def update_file(self, file_path: Path) -> Tuple[bool, int]:
        """
        Update a single Swift test file.

        Returns:
            (was_modified: bool, replacement_count: int)
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()

        modified_content = original_content
        replacement_count = 0

        # Pattern 1: CodingKeys enum cases - StepSparring
        # korean_name = "korean_name" → korean_name = "romanised"
        pattern1 = r'case\s+(\w*[Kk]orean[Nn]ame)\s*=\s*"korean_name"'
        replacement1 = r'case \1 = "romanised"'
        modified_content, count1 = re.subn(pattern1, replacement1, modified_content)
        replacement_count += count1

        # Pattern 2: CodingKeys enum cases - Terminology
        # romanizedPronunciation = "romanized_pronunciation" → romanizedPronunciation = "romanised"
        pattern2 = r'case\s+(\w*[Rr]omanized\w*)\s*=\s*"romanized_pronunciation"'
        replacement2 = r'case \1 = "romanised"'
        modified_content, count2 = re.subn(pattern2, replacement2, modified_content)
        replacement_count += count2

        # Pattern 3: CodingKeys enum cases - Terminology
        # englishTerm = "english_term" → englishTerm = "english"
        pattern3 = r'case\s+(\w*[Ee]nglish[Tt]erm)\s*=\s*"english_term"'
        replacement3 = r'case \1 = "english"'
        modified_content, count3 = re.subn(pattern3, replacement3, modified_content)
        replacement_count += count3

        # Pattern 4: CodingKeys enum cases - Terminology
        # koreanHangul = "korean_hangul" → koreanHangul = "hangul"
        pattern4 = r'case\s+(\w*[Kk]orean[Hh]angul)\s*=\s*"korean_hangul"'
        replacement4 = r'case \1 = "hangul"'
        modified_content, count4 = re.subn(pattern4, replacement4, modified_content)
        replacement_count += count4

        # Pattern 5: CodingKeys enum cases - Terminology
        # phoneticPronunciation = "phonetic_pronunciation" → phoneticPronunciation = "phonetic"
        pattern5 = r'case\s+(\w*[Pp]honetic[Pp]ronunciation)\s*=\s*"phonetic_pronunciation"'
        replacement5 = r'case \1 = "phonetic"'
        modified_content, count5 = re.subn(pattern5, replacement5, modified_content)
        replacement_count += count5

        # Pattern 6: CodingKeys enum cases - Pattern
        # pronunciation = "pronunciation" → pronunciation = "romanised"
        # (only when in Pattern context, not Theory which uses different semantics)
        pattern6 = r'case\s+(pronunciation)\s*=\s*"pronunciation"'
        replacement6 = r'case \1 = "romanised"'
        # Only apply if file contains "Pattern" in name or has PatternJSON structs
        if 'Pattern' in file_path.name or 'PatternJSON' in original_content:
            modified_content, count6 = re.subn(pattern6, replacement6, modified_content)
            replacement_count += count6

        # Pattern 7: CodingKeys enum cases - Pattern moves
        # technique = "technique" → technique = "english"
        # koreanTechnique = "korean_technique" → koreanTechnique = "romanised"
        # (only in Pattern move contexts)
        if 'Pattern' in file_path.name or 'PatternJSON' in original_content:
            pattern7a = r'case\s+(technique)\s*=\s*"technique"'
            replacement7a = r'case \1 = "english"'
            modified_content, count7a = re.subn(pattern7a, replacement7a, modified_content)
            replacement_count += count7a

            pattern7b = r'case\s+(\w*[Kk]orean[Tt]echnique)\s*=\s*"korean_technique"'
            replacement7b = r'case \1 = "romanised"'
            modified_content, count7b = re.subn(pattern7b, replacement7b, modified_content)
            replacement_count += count7b

        # Pattern 8: Property access - .romanized → .romanised
        pattern8 = r'\.romanized\b'
        replacement8 = r'.romanised'
        modified_content, count8 = re.subn(pattern8, replacement8, modified_content)
        replacement_count += count8

        # Pattern 9: VocabularyWord/similar structs
        # "romanized" in Codable property lists
        pattern9 = r'"romanized"'
        replacement9 = r'"romanised"'
        if 'Vocabulary' in file_path.name:
            modified_content, count9 = re.subn(pattern9, replacement9, modified_content)
            replacement_count += count9

        was_modified = (modified_content != original_content)

        if was_modified and not self.dry_run:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(modified_content)
            self.stats['files_modified'] += 1

        self.stats['replacements_made'] += replacement_count
        return was_modified, replacement_count

    def process_all(self) -> None:
        """Process all Swift test files in the tests directory."""
        test_files = list(self.tests_dir.glob('**/*.swift'))

        print(f"\n{'='*70}")
        print(f"Test CodingKeys Updater")
        print(f"{'='*70}")
        print(f"Mode: {'DRY RUN (no files will be modified)' if self.dry_run else 'LIVE (files will be modified)'}")
        print(f"Test files found: {len(test_files)}")
        print(f"{'='*70}\n")

        results = []
        for file_path in sorted(test_files):
            was_modified, replacement_count = self.update_file(file_path)
            self.stats['files_processed'] += 1

            if was_modified or replacement_count > 0:
                rel_path = file_path.relative_to(self.tests_dir)
                status = "✓ MODIFIED" if was_modified else "○ NO CHANGE"
                results.append((rel_path, replacement_count))
                print(f"{status} {rel_path}: {replacement_count} replacements")

        # Print summary
        print(f"\n{'='*70}")
        print(f"Summary")
        print(f"{'='*70}")
        print(f"Files processed: {self.stats['files_processed']}")
        print(f"Files modified: {self.stats['files_modified']}")
        print(f"Total replacements: {self.stats['replacements_made']}")
        print(f"{'='*70}\n")


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Update CodingKeys in Swift test files to match new JSON schema'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without modifying files'
    )
    parser.add_argument(
        '--tests-dir',
        type=Path,
        default=Path(__file__).parent.parent / 'TKDojangTests',
        help='Path to tests directory (default: auto-detect)'
    )

    args = parser.parse_args()

    if not args.tests_dir.exists():
        print(f"Error: Tests directory not found: {args.tests_dir}")
        return 1

    updater = TestCodingKeysUpdater(args.tests_dir, dry_run=args.dry_run)
    updater.process_all()

    return 0


if __name__ == '__main__':
    exit(main())
