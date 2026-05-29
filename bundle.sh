#!/bin/bash
# bundle.sh — generate a session bundle, never commit the output

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BUNDLE_FILE="bundle-${TIMESTAMP}.txt"

find . -type f \
  ! -path './.git/*' \
  ! -name 'bundle.txt' \
  ! -name 'bundle-*.txt' \
  ! -name 'bundle.sh' \
  | sort | while read f; do
    echo "================================================================"
    echo "FILE: $f"
    echo "================================================================"
    cat "$f"
    echo ""
done > "$BUNDLE_FILE"

echo "$BUNDLE_FILE ready."