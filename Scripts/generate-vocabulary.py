#!/usr/bin/env python3
"""Generate vocabulary from English ↔ Korean romanized mappings"""

import json
from collections import defaultdict
from pathlib import Path

def main():
    # Load all terminology JSON files
    terminology_dir = Path("TKDojang/Sources/Core/Data/Content/Terminology")
    json_files = list(terminology_dir.glob("*.json"))

    # Extract word mappings: (english, romanized) -> hangul_examples
    word_map = defaultdict(lambda: {"romanized": None, "hangul_variants": [], "count": 0})

    total_terms = 0

    for json_file in json_files:
        with open(json_file, encoding='utf-8') as f:
            data = json.load(f)

        terms = data if isinstance(data, list) else data.get('terminology', [])
        total_terms += len(terms)

        for term in terms:
            english_words = term['english_term'].split()
            romanized_words = term['romanized_pronunciation'].split()
            hangul = term['korean_hangul']

            # Match word-by-word
            for eng, rom in zip(english_words, romanized_words):
                key = eng.lower()
                word_map[key]["romanized"] = rom  # Use most recent (or could do most common)
                word_map[key]["count"] += 1

                # Store hangul if it has spaces (otherwise it's compound)
                if ' ' in hangul:
                    hangul_words = hangul.split()
                    # Try to match positionally
                    idx = english_words.index(eng)
                    if idx < len(hangul_words):
                        word_map[key]["hangul_variants"].append(hangul_words[idx])

    # Build vocabulary
    vocabulary = []
    for english, data in word_map.items():
        # Get most common hangul variant if available
        hangul = None
        if data["hangul_variants"]:
            hangul = max(set(data["hangul_variants"]),
                        key=lambda x: data["hangul_variants"].count(x))

        vocabulary.append({
            "english": english.title(),
            "romanized": data["romanized"],
            "hangul": hangul,
            "frequency": data["count"]
        })

    # Sort by frequency
    vocabulary.sort(key=lambda x: x['frequency'], reverse=True)

    # Write output
    output = {"words": vocabulary}
    output_path = Path("TKDojang/Sources/Core/Data/Content/VocabularyBuilder/vocabulary_words.json")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"✅ Generated {len(vocabulary)} words from {total_terms} terms ({len(json_files)} JSON files)")
    print(f"📝 {output_path}")

    # Show top 20 most frequent word mappings
    print(f"\nTop 20 most frequent word mappings:")
    for word in vocabulary[:20]:
        hangul_display = word['hangul'] if word['hangul'] else "(compound)"
        print(f"  {word['english']:15} → {word['romanized']:15} ({hangul_display:10}) [×{word['frequency']}]")

if __name__ == "__main__":
    main()
