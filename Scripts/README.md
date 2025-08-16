# TKDojang Development Scripts

This directory contains standalone tools for content management and development tasks.

## CSV to Terminology Converter

### Purpose
Converts CSV files containing Korean terminology into JSON files for the TKDojang app.

### Usage
```bash
cd Scripts
swift csv-to-terminology.swift sample_terminology.csv ../TKDojang/Sources/Core/Data/Content/Belts/
```

### CSV Format
Your CSV file should have these columns (header row required):
```
English Term,Korean Hangul,Romanized,Phonetic,Definition,Category,Difficulty,Belt Level
```

**Column Descriptions:**
- **English Term**: English translation (required)
- **Korean Hangul**: Korean text in Hangul script (required)
- **Romanized**: Romanized pronunciation (required)
- **Phonetic**: IPA or simplified phonetic guide (optional)
- **Definition**: Extended explanation (optional)
- **Category**: Content category (optional, defaults to "general")
- **Difficulty**: 1-5 scale (optional, defaults to 1)
- **Belt Level**: Target belt level (optional, defaults to "10th_keup")

### Valid Belt Levels
```
10th_keup, 9th_keup, 8th_keup, 7th_keup, 6th_keup, 5th_keup, 
4th_keup, 3rd_keup, 2nd_keup, 1st_keup,
1st_dan, 2nd_dan, 3rd_dan, 4th_dan, 5th_dan
```

### Valid Categories
```
basics, numbers, techniques, stances, blocks, strikes, kicks, 
patterns, titles, philosophy
```

### Example CSV Content
```csv
English Term,Korean Hangul,Romanized,Phonetic,Definition,Category,Difficulty,Belt Level
Attention,차렷,charyeot,cha-ryət,Standing at attention position,basics,1,10th_keup
Front kick,앞차기,ap chagi,ap cha-gi,A basic forward kicking technique,techniques,2,8th_keup
```

### Output
The tool creates JSON files organized by belt level and category:
```
Belts/
├── 10th_keup/
│   ├── basics.json
│   └── numbers.json
├── 8th_keup/
│   ├── techniques.json
│   └── blocks.json
```

### Features
- **Validation**: Checks for required fields and valid data
- **Grouping**: Automatically groups content by belt level and category
- **Formatting**: Creates properly formatted JSON matching app expectations
- **Error Handling**: Reports line numbers for any parsing issues
- **Summary**: Shows content distribution after processing

### Tips for Content Creation
1. Use a spreadsheet program (Excel, Google Sheets) to create your CSV
2. Start with one belt level at a time
3. Use the sample_terminology.csv as a template
4. Test with small batches before doing large imports
5. Keep backups of your CSV files for future updates