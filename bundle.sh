#!/bin/bash
# bundle.sh — generate a session bundle, never commit the output
find . -type f \
  ! -path './.git/*' \
  ! -name 'bundle.txt' \
  ! -name 'bundle.sh' \
  | sort | while read f; do
    echo "================================================================"
    echo "FILE: $f"
    echo "================================================================"
    cat "$f"
    echo ""
done > bundle.txt
echo "bundle.txt ready."
