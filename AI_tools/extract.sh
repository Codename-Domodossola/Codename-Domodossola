#!/bin/sh
# extract.sh
# Extract files from the last assistant message in a chat log.
# Files are identified by fenced code blocks with a filename hint.
#
# Filename hints recognised (in order of priority):
#   ```language filename.ext
#   ```language
#   # filename.ext  (first line of block)
#   --- filename.ext ---  (first line of block)
#
# Usage:
#   sh extract.sh <log_file> [output_dir]
#   sh extract.sh <log_file> -n        — dry run, list files only

LOG_FILE="$1"
OUT_DIR="${2:-./extracted}"
DRY_RUN=0
[ "$2" = "-n" ] && DRY_RUN=1 && OUT_DIR="./extracted"

if [ -z "$LOG_FILE" ]; then
    printf "Usage: sh extract.sh <log_file> [output_dir|-n]\n"
    exit 1
fi
if [ ! -f "$LOG_FILE" ]; then
    printf "Error: log not found: %s\n" "$LOG_FILE"; exit 1
fi

# Extract last assistant message content to a temp file (properly decoded)
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT
CONTENT_FILE="$TMPDIR_WORK/content.txt"

# Parse JSONL: skip session marker lines, collect message objects,
# find last assistant message, decode content (jq -r handles \n → newlines)
grep -v '^{"session":' "$LOG_FILE" | \
    jq -rs '[.[] | fromjson? // empty | select(.role == "assistant")] | last | .content' | \
    jq -r '.' > "$CONTENT_FILE"

if [ ! -s "$CONTENT_FILE" ] || grep -q '^null$' "$CONTENT_FILE"; then
    printf "No assistant message found in log.\n"; exit 1
fi

printf "Extracting from last assistant message...\n\n"

[ "$DRY_RUN" -eq 0 ] && mkdir -p "$OUT_DIR"

# Parse fenced code blocks with Python (more reliable than awk for multiline)
python3 - "$CONTENT_FILE" "$OUT_DIR" "$DRY_RUN" << 'PYEOF'
import sys, re, os

content_file = sys.argv[1]
out_dir      = sys.argv[2]
dry_run      = sys.argv[3] == "1"

with open(content_file, 'r') as f:
    text = f.read()

# Match fenced blocks: ```[lang][ filename]\n...\n```
pattern = re.compile(
    r'^```([^\n]*)\n(.*?)^```',
    re.MULTILINE | re.DOTALL
)

file_count = 0
unnamed_count = 0

for m in pattern.finditer(text):
    hint     = m.group(1).strip()   # e.g. "sh guardian_loop.sh" or "python"
    body     = m.group(2)

    # Determine filename from hint or first line of body
    filename = None
    parts = hint.split(None, 1)

    if len(parts) == 2:
        # "language filename.ext" — use the second part
        filename = parts[1].strip()
    elif len(parts) == 1:
        # Only language — check first line of body for a filename comment
        first_line = body.split('\n')[0].strip()
        # Matches: # filename.ext  or  --- filename.ext ---
        m2 = re.match(r'^(?:#|//|--+)\s*([\w./\-]+\.\w+)', first_line)
        if m2:
            filename = m2.group(1)

    if not filename:
        unnamed_count += 1
        lang = parts[0] if parts else "txt"
        ext_map = {
            'python':'py','py':'py','sh':'sh','bash':'sh','shell':'sh',
            'javascript':'js','js':'js','typescript':'ts','ts':'ts',
            'json':'json','yaml':'yaml','yml':'yml','markdown':'md',
            'md':'md','c':'c','cpp':'cpp','rust':'rs','go':'go',
        }
        ext = ext_map.get(lang.lower(), lang.lower() or 'txt')
        filename = f"block_{unnamed_count:02d}.{ext}"

    # Safety: strip any path traversal
    filename = os.path.basename(filename)

    if dry_run:
        print(f"  [{hint or 'no lang'}] → {filename}  ({len(body)} chars)")
    else:
        out_path = os.path.join(out_dir, filename)
        with open(out_path, 'w') as f:
            f.write(body)
        print(f"  ✅ {out_path}")
    file_count += 1

if file_count == 0:
    print("No fenced code blocks found.")
else:
    print(f"\n{file_count} file(s) extracted.")
PYEOF
