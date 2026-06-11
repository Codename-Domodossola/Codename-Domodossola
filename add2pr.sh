#!/bin/sh
# add_to_pr.sh
# Commit and push current changes in the guardian_loop clone.
# Run this from anywhere after manually editing files in ../guardian_loop/clone/
# Usage: sh add_to_pr.sh ["commit message"]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLONE_DIR="$(dirname "$SCRIPT_DIR")/guardian_loop/clone"

if [ ! -d "$CLONE_DIR/.git" ]; then
    printf "Error: no clone found at %s\n" "$CLONE_DIR"
    printf "Run guardian_loop.sh first.\n"
    exit 1
fi

cd "$CLONE_DIR"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    printf "Error: currently on %s — expected a guardian/* branch.\n" "$BRANCH"
    exit 1
fi

# Show what will be committed
printf "Branch: %s\n\n" "$BRANCH"
git status --short

if [ -z "$(git status --porcelain)" ]; then
    printf "\nNothing to commit.\n"
    exit 0
fi

# Commit message
if [ -n "$1" ]; then
    MSG="$1"
else
    printf "\nCommit message: "
    read MSG
    if [ -z "$MSG" ]; then
        printf "Aborted — empty message.\n"
        exit 1
    fi
fi

git add -A
git commit -m "$MSG"
git push origin "$BRANCH"

REPO_PATH=$(git remote get-url origin \
    | sed 's|.*github.com[:/]||' \
    | sed 's|\.git$||')

printf "\n✅ Pushed.\n"
printf "PR URL: https://github.com/%s/compare/%s?expand=1\n" \
    "$REPO_PATH" "$BRANCH"
