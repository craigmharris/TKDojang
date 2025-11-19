#!/bin/bash
# update-content-hashes-dev.sh
# Run this manually during development after changing content JSON files

cd "$(dirname "$0")/.."
bash Scripts/generate-content-hashes.sh
echo ""
echo "✅ Content hashes updated. Rebuild your project to use the new hashes."
