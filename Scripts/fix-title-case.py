#!/usr/bin/env python3
"""
Fix title casing for English and romanised properties in content JSON files.

Ensures consistent title casing for:
- Terminology files: english, romanised properties
- Techniques files: english, romanised in names object
- Vocabulary files: english, romanised properties
"""

import json
import os
import re
from pathlib import Path


def to_title_case(text):
    """
    Convert text to title case with special handling for martial arts terms.

    Rules:
    - Each word starts with capital letter
    - Exception: Small words (of, the, a, an, and, or, to, in, with) after first word stay lowercase
    - Exception: Words after hyphens are capitalized (e.g., "3-Step", "U-Shape")
    - Exception: Parenthetical content maintains lowercase unless first word
    """
    if not text or not isinstance(text, str):
        return text

    # Handle hyphenated compounds (e.g., "3-step" → "3-Step", "w-shape" → "W-Shape")
    def title_case_hyphenated(match):
        parts = match.group(0).split('-')
        return '-'.join(p.capitalize() for p in parts)

    # First pass: handle hyphenated words
    text = re.sub(r'\b[\w]+-[\w]+\b', title_case_hyphenated, text)

    # Split into words
    words = text.split()
    if not words:
        return text

    # Small words that should be lowercase (unless first word)
    small_words = {'of', 'the', 'a', 'an', 'and', 'or', 'to', 'in', 'with'}

    # Title case each word, with exceptions
    result = []
    for i, word in enumerate(words):
        # Handle parentheticals
        if '(' in word and ')' in word:
            # Extract parts
            before_paren = word[:word.index('(')]
            in_paren = word[word.index('(')+1:word.index(')')]
            after_paren = word[word.index(')')+1:] if word.index(')') < len(word)-1 else ''

            # Capitalize before paren, lowercase inside paren (unless proper noun)
            result.append(f"{before_paren.capitalize()}({in_paren.lower()}){after_paren}")
        # First word is always capitalized (unless it's already hyphenated)
        elif i == 0:
            if '-' not in word:
                result.append(word.capitalize())
            else:
                result.append(word)  # Already handled by hyphen logic
        # Small prepositions/articles stay lowercase (unless first word)
        elif word.lower() in small_words:
            result.append(word.lower())
        # Keep words that are already title-cased or have hyphens
        elif '-' in word or word[0].isupper():
            result.append(word)
        else:
            result.append(word.capitalize())

    return ' '.join(result)


def fix_terminology_file(filepath):
    """Fix title casing in terminology JSON files."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    changed = False

    # Terminology files have a "terminology" array
    if 'terminology' in data:
        for term in data['terminology']:
            # Fix english property
            if 'english' in term:
                original = term['english']
                fixed = to_title_case(original)
                if original != fixed:
                    print(f"  {filepath.name}: '{original}' → '{fixed}'")
                    term['english'] = fixed
                    changed = True

            # Fix romanised property
            if 'romanised' in term:
                original = term['romanised']
                fixed = to_title_case(original)
                if original != fixed:
                    print(f"  {filepath.name}: '{original}' → '{fixed}'")
                    term['romanised'] = fixed
                    changed = True

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write('\n')  # Add trailing newline

    return changed


def fix_techniques_file(filepath):
    """Fix title casing in techniques JSON files."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    changed = False

    # Techniques files have a "techniques" array
    if 'techniques' in data:
        for technique in data['techniques']:
            # Names object contains english and romanised
            if 'names' in technique:
                # Fix english property
                if 'english' in technique['names']:
                    original = technique['names']['english']
                    fixed = to_title_case(original)
                    if original != fixed:
                        print(f"  {filepath.name}: '{original}' → '{fixed}'")
                        technique['names']['english'] = fixed
                        changed = True

                # Fix romanised property
                if 'romanised' in technique['names']:
                    original = technique['names']['romanised']
                    fixed = to_title_case(original)
                    if original != fixed:
                        print(f"  {filepath.name}: '{original}' → '{fixed}'")
                        technique['names']['romanised'] = fixed
                        changed = True

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write('\n')  # Add trailing newline

    return changed


def fix_vocabulary_file(filepath):
    """Fix title casing in vocabulary_words.json file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    changed = False

    # Vocabulary file has a "words" array
    if 'words' in data:
        for word in data['words']:
            # Fix english property
            if 'english' in word:
                original = word['english']
                fixed = to_title_case(original)
                if original != fixed:
                    print(f"  {filepath.name}: '{original}' → '{fixed}'")
                    word['english'] = fixed
                    changed = True

            # Fix romanised property
            if 'romanised' in word:
                original = word['romanised']
                fixed = to_title_case(original)
                if original != fixed:
                    print(f"  {filepath.name}: '{original}' → '{fixed}'")
                    word['romanised'] = fixed
                    changed = True

    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write('\n')  # Add trailing newline

    return changed


def main():
    """Process all content JSON files."""
    base_path = Path(__file__).parent.parent / 'TKDojang' / 'Sources' / 'Core' / 'Data' / 'Content'

    total_changed = 0

    # Process Terminology files
    print("📚 Processing Terminology files...")
    terminology_path = base_path / 'Terminology'
    if terminology_path.exists():
        for filepath in sorted(terminology_path.glob('*.json')):
            if fix_terminology_file(filepath):
                total_changed += 1

    # Process Techniques files
    print("\n🥋 Processing Techniques files...")
    techniques_path = base_path / 'Techniques'
    if techniques_path.exists():
        for filepath in sorted(techniques_path.glob('*.json')):
            if fix_techniques_file(filepath):
                total_changed += 1

    # Process Vocabulary file
    print("\n📖 Processing Vocabulary file...")
    vocabulary_path = base_path / 'VocabularyBuilder' / 'vocabulary_words.json'
    if vocabulary_path.exists():
        if fix_vocabulary_file(vocabulary_path):
            total_changed += 1

    print(f"\n✅ Complete! {total_changed} files modified")


if __name__ == '__main__':
    main()
