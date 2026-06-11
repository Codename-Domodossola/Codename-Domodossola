#!/bin/sh
# guardian_loop.sh
# GUARDIAN evaluation loop for Codename Domodossola.
# Requires: curl, jq, git
# Usage: sh guardian_loop.sh <artifact_path_relative_to_repo_root>
#
# All prompt files live in ../guardian_loop/prompts/ (local, never in repo).
# The repo is cloned fresh each session into ../guardian_loop/clone/.

# =============================================================================
# CONFIGURATION
# =============================================================================

REPO_URL="git@github.com:Codename-Domodossola/Codename-Domodossola.git"
API_BASE="https://api.anthropic.com"
GUARDIAN_MODEL="claude-sonnet-4-6"
META_MODEL="claude-sonnet-4-6"
GUARDIAN_MAX_TOKENS=16000
META_MAX_TOKENS=16000
MAX_ROUNDS=20

GIT_AUTHOR_NAME="guardian-loop"
GIT_AUTHOR_EMAIL="guardian@domodossola"

# =============================================================================
# END CONFIGURATION
# =============================================================================

API_BASE="${API_BASE_OVERRIDE:-$API_BASE}"
GUARDIAN_MODEL="${GUARDIAN_MODEL_OVERRIDE:-$GUARDIAN_MODEL}"
META_MODEL="${META_MODEL_OVERRIDE:-$META_MODEL}"
GUARDIAN_MAX_TOKENS="${GUARDIAN_MAX_TOKENS_OVERRIDE:-$GUARDIAN_MAX_TOKENS}"
META_MAX_TOKENS="${META_MAX_TOKENS_OVERRIDE:-$META_MAX_TOKENS}"
MAX_ROUNDS="${MAX_ROUNDS_OVERRIDE:-$MAX_ROUNDS}"
REPO_URL="${REPO_URL_OVERRIDE:-$REPO_URL}"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

ARTIFACT_REL="$1"
if [ -z "$ARTIFACT_REL" ]; then
    printf "Usage: sh guardian_loop.sh <artifact_path_relative_to_repo_root>\n"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    printf "Error: ANTHROPIC_API_KEY not set\n"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GL_DIR="$(dirname "$SCRIPT_DIR")/guardian_loop"
CLONE_DIR="$GL_DIR/clone"
PROMPTS_DIR="$GL_DIR/prompts"
SESSION_TS="$(date '+%Y%m%d_%H%M%S')"
LOG_DIR="$GL_DIR/logs/$SESSION_TS"
WORK_DIR="$GL_DIR/work"

GUARDIAN_PROMPT="$PROMPTS_DIR/guardian_prompt.txt"
META_PROMPT="$PROMPTS_DIR/meta_prompt.txt"
META_CONTEXT="$PROMPTS_DIR/meta_context.md"

mkdir -p "$PROMPTS_DIR" "$LOG_DIR" "$WORK_DIR"

# ---------------------------------------------------------------------------
# Initialize prompts/ if first run
# ---------------------------------------------------------------------------

PLACEHOLDER="# PLACEHOLDER"
_needs_init=0

for f in "$GUARDIAN_PROMPT" "$META_PROMPT" "$META_CONTEXT"; do
    if [ ! -f "$f" ]; then
        printf "%s — replace with actual content before running\n" "$PLACEHOLDER" > "$f"
        _needs_init=1
    elif grep -q "^$PLACEHOLDER" "$f"; then
        _needs_init=1
    fi
done

if [ "$_needs_init" -eq 1 ]; then
    printf "ERROR: placeholder files found in %s\n" "$PROMPTS_DIR"
    printf "Fill in the following files before running:\n"
    for f in "$GUARDIAN_PROMPT" "$META_PROMPT" "$META_CONTEXT"; do
        grep -q "^$PLACEHOLDER" "$f" 2>/dev/null && printf "  %s\n" "$f"
    done
    exit 1
fi

# ---------------------------------------------------------------------------
# Derive GitHub owner/repo for PR URL (works for SSH and HTTPS)
# ---------------------------------------------------------------------------

REPO_PATH=$(printf "%s" "$REPO_URL" \
    | sed 's|.*github.com[:/]||' \
    | sed 's|\.git$||')

# ---------------------------------------------------------------------------
# Clone repo
# ---------------------------------------------------------------------------

printf "Cloning %s ...\n" "$REPO_URL"
rm -rf "$CLONE_DIR"
git clone --quiet "$REPO_URL" "$CLONE_DIR"
git config --global --add safe.directory "$CLONE_DIR"

BRANCH="guardian/$SESSION_TS"
cd "$CLONE_DIR"
git checkout -b "$BRANCH"
cd - > /dev/null
printf "Branch: %s\n\n" "$BRANCH"

# ---------------------------------------------------------------------------
# Artifact and spec paths (inside clone)
# ---------------------------------------------------------------------------

ARTIFACT_FILE="$CLONE_DIR/$ARTIFACT_REL"

if [ ! -f "$ARTIFACT_FILE" ]; then
    printf "Error: artifact not found in repo: %s\n" "$ARTIFACT_REL"
    exit 1
fi

CORE_SPEC="$CLONE_DIR/docs/1-Codename_Domodossola_Core_Specifications_1.0a1.md"
ANNEX_A="$CLONE_DIR/docs/2-Codename_Domodossola_C_S_Annex_A-Subordinate_documents_1.0a1.md"
CONTRIBUTING="$CLONE_DIR/CONTRIBUTING"

# ---------------------------------------------------------------------------
# API helper
# ---------------------------------------------------------------------------

call_claude() {
    system_file="$1"
    user_file="$2"
    model="$3"
    max_tokens="$4"

    payload=$(jq -n \
        --arg     model      "$model" \
        --argjson max_tokens "$max_tokens" \
        --rawfile system     "$system_file" \
        --rawfile user       "$user_file" \
        '{
            model:      $model,
            max_tokens: $max_tokens,
            system:     $system,
            messages:   [{ role: "user", content: $user }]
        }')

    response=$(curl -s "${API_BASE}/v1/messages" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$payload")

    # Surface API errors immediately
    err=$(printf "%s" "$response" | jq -r '.error.message // empty')
    if [ -n "$err" ]; then
        printf "API error: %s\n" "$err" >&2
        exit 1
    fi

    printf "%s" "$response" | jq -r '.content[0].text'
}

# ---------------------------------------------------------------------------
# Prompt builders
# ---------------------------------------------------------------------------

build_guardian_user() {
    printf "Evaluate the following artifact for compliance.\n\n"
    printf "## Core Specification\n\n";    cat "$CORE_SPEC"
    printf "\n\n## Annex A\n\n";           cat "$ANNEX_A"
    printf "\n\n## CONTRIBUTING\n\n";      cat "$CONTRIBUTING"
    printf "\n\n## Artifact under review\n\n"; cat "$ARTIFACT_FILE"
}

build_meta1_user() {
    # Phase 1: analysis only, no diff
    guardian_response="$1"
    printf "## Core Specification\n\n";    cat "$CORE_SPEC"
    printf "\n\n## Annex A\n\n";           cat "$ANNEX_A"
    printf "\n\n## CONTRIBUTING\n\n";      cat "$CONTRIBUTING"
    printf "\n\n## Artifact under review\n\n"; cat "$ARTIFACT_FILE"
    printf "\n\n## GUARDIAN response\n\n"; cat "$guardian_response"
    printf "\n\n## Meta-evaluator context\n\n"; cat "$META_CONTEXT"
    printf "\n\n---\n\n"
    printf "Analyse each GUARDIAN finding. For each one:\n"
    printf "1. State whether it is a TRUE_POSITIVE or FALSE_POSITIVE, with reasoning.\n"
    printf "2. For TRUE_POSITIVE: state suggested target (artifact | spec).\n"
    printf "3. For FALSE_POSITIVE: explain why.\n\n"
    printf "Then output a structured summary in this exact format:\n\n"
    printf "ANALYSIS\n"
    printf "finding_id: <id>\n"
    printf "verdict: TRUE_POSITIVE | FALSE_POSITIVE\n"
    printf "target: artifact | spec | n/a\n"
    printf "reason: <one line>\n"
    printf "---\n"
    printf "(repeat for each finding)\n\n"
    printf "SUMMARY\n"
    printf "true_positives: <count>\n"
    printf "false_positives: <count>\n"
    printf "uncertain: <count>\n\n"
    printf "Rules:\n"
    printf "- Do NOT propose diffs in this phase.\n"
    printf "- Do NOT reference specific concrete errors in the artifact when reasoning\n"
    printf "  about guardian behaviour — reason about general behavioural patterns only.\n"
    printf "- If you are not certain about a finding, mark it uncertain and explain.\n"
}

build_meta2_user() {
    # Phase 2: produce diff on guardian_prompt only
    analysis="$1"
    user_instruction="$2"
    printf "## Current guardian prompt\n\n"; cat "$GUARDIAN_PROMPT"
    printf "\n\n## Phase 1 analysis\n\n";    printf "%s" "$analysis"
    if [ -n "$user_instruction" ]; then
        printf "\n\n## User instruction\n\n%s" "$user_instruction"
    fi
    printf "\n\n---\n\n"
    printf "Produce a unified diff to correct the guardian prompt.\n\n"
    printf "Rules:\n"
    printf "- Target: guardian_prompt.txt only.\n"
    printf "- Correct behavioural patterns, not specific concrete errors.\n"
    printf "  WRONG: 'do not flag missing field X in document Y'\n"
    printf "  RIGHT: 'do not flag absent optional sections when context implies they are not required'\n"
    printf "- Diff header must use path: guardian_prompt.txt\n"
    printf "- Output the diff inside a single triple-backtick diff block.\n"
    printf "- If no change is needed, output: NO_DIFF\n"
}

# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

git_commit() {
    cd "$CLONE_DIR"
    git add -A
    GIT_AUTHOR_NAME="$GIT_AUTHOR_NAME" \
    GIT_AUTHOR_EMAIL="$GIT_AUTHOR_EMAIL" \
    GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" \
    GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL" \
    git commit --quiet -m "$1" 2>/dev/null || true
    cd - > /dev/null
}

# ---------------------------------------------------------------------------
# Apply diff to guardian_prompt.txt
# ---------------------------------------------------------------------------

apply_guardian_diff() {
    diff_file="$1"
    cp "$GUARDIAN_PROMPT" "$GUARDIAN_PROMPT.bak"
    # patch expects the file in current dir; use -p0 with plain filename in header
    cd "$PROMPTS_DIR"
    if patch -p0 < "$diff_file"; then
        printf "Patch applied to guardian_prompt.txt\n"
        rm -f "$GUARDIAN_PROMPT.bak"
    else
        printf "Patch failed — restoring backup\n"
        cp "$GUARDIAN_PROMPT.bak" "$GUARDIAN_PROMPT"
        rm -f "$GUARDIAN_PROMPT.bak"
        return 1
    fi
    cd - > /dev/null
}

extract_diff() {
    # Extract first ```diff block from file $1 into file $2
    awk '
        BEGIN { in_block=0; done=0 }
        !done && /^```diff/ { in_block=1; next }
        in_block && /^```/  { in_block=0; done=1 }
        in_block            { print }
    ' "$1" > "$2"
}

# ---------------------------------------------------------------------------
# Parse meta phase 1 output
# ---------------------------------------------------------------------------

count_verdict() {
    # count_verdict <analysis_file> TRUE_POSITIVE | FALSE_POSITIVE | uncertain
    grep -c "^verdict: $2" "$1" 2>/dev/null || echo 0
}

list_finding_ids() {
    grep "^finding_id:" "$1" | awk '{print $2}'
}

# ---------------------------------------------------------------------------
# Log helpers
# ---------------------------------------------------------------------------

log_round() {
    round_dir="$LOG_DIR/round_$(printf '%02d' "$round")"
    mkdir -p "$round_dir"
    [ -f "$WORK_DIR/guardian_response.txt" ] && \
        cp "$WORK_DIR/guardian_response.txt" "$round_dir/"
    [ -f "$WORK_DIR/meta1_response.txt" ] && \
        cp "$WORK_DIR/meta1_response.txt"    "$round_dir/"
    [ -f "$WORK_DIR/meta2_response.txt" ] && \
        cp "$WORK_DIR/meta2_response.txt"    "$round_dir/"
}

# ---------------------------------------------------------------------------
# handle_accepted
# ---------------------------------------------------------------------------

handle_accepted() {
    printf "\n✅ ACCEPTED — all findings resolved.\n\n"
    git_commit "round $(printf '%02d' "$round"): ACCEPTED"

    printf "%s\n\n" "=== Global diff vs main ==="
    cd "$CLONE_DIR"
    git diff "main..$BRANCH"
    cd - > /dev/null

    printf "\nPushing branch...\n"
    cd "$CLONE_DIR"
    git push --quiet origin "$BRANCH"
    cd - > /dev/null

    PR_URL="https://github.com/${REPO_PATH}/compare/${BRANCH}?expand=1"
    printf "\n✅ Branch pushed.\n"
    printf "Open to create PR:\n  %s\n\n" "$PR_URL"
    printf "Work dir: %s\n" "$GL_DIR"
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

printf "Backend:        %s\n"   "$API_BASE"
printf "GUARDIAN model: %s\n"   "$GUARDIAN_MODEL"
printf "META model:     %s\n"   "$META_MODEL"
printf "Artifact:       %s\n"   "$ARTIFACT_REL"
printf "Branch:         %s\n"   "$BRANCH"
printf "Logs:           %s\n\n" "$LOG_DIR"

round=0
auto_mode=0
skip_guardian=0

# Tracking sets for auto mode (space-separated finding IDs)
tp_initial=""
fp_initial=""

while [ "$round" -lt "$MAX_ROUNDS" ]; do
    round=$((round + 1))
    printf "\n%s\n" "=== Round $round ==="

    # ------------------------------------------------------------------
    # GUARDIAN
    # ------------------------------------------------------------------

    if [ "$skip_guardian" -eq 0 ]; then
        printf "Running GUARDIAN...\n"
        cat "$GUARDIAN_PROMPT"                    > "$WORK_DIR/guardian_system.txt"
        build_guardian_user                       > "$WORK_DIR/guardian_user.txt"
        call_claude \
            "$WORK_DIR/guardian_system.txt" \
            "$WORK_DIR/guardian_user.txt" \
            "$GUARDIAN_MODEL" \
            "$GUARDIAN_MAX_TOKENS"                > "$WORK_DIR/guardian_response.txt"
        printf "\n%s\n" "--- GUARDIAN ---"
        cat "$WORK_DIR/guardian_response.txt"
    else
        printf "Skipping GUARDIAN (context update only).\n"
        skip_guardian=0
    fi

    # ------------------------------------------------------------------
    # META phase 1 — analysis
    # ------------------------------------------------------------------

    printf "\nRunning META (phase 1)...\n"
    cat "$META_PROMPT"                            > "$WORK_DIR/meta_system.txt"
    build_meta1_user "$WORK_DIR/guardian_response.txt" \
                                                  > "$WORK_DIR/meta1_user.txt"
    call_claude \
        "$WORK_DIR/meta_system.txt" \
        "$WORK_DIR/meta1_user.txt" \
        "$META_MODEL" \
        "$META_MAX_TOKENS"                        > "$WORK_DIR/meta1_response.txt"

    printf "\n%s\n" "--- META analysis ---"
    cat "$WORK_DIR/meta1_response.txt"

    log_round

    # Parse counts
    n_tp=$(count_verdict "$WORK_DIR/meta1_response.txt" "TRUE_POSITIVE")
    n_fp=$(count_verdict "$WORK_DIR/meta1_response.txt" "FALSE_POSITIVE")
    n_uc=$(count_verdict "$WORK_DIR/meta1_response.txt" "uncertain")

    printf "\nTP: %s  FP: %s  Uncertain: %s\n" "$n_tp" "$n_fp" "$n_uc"

    # ------------------------------------------------------------------
    # ACCEPTED?
    # ------------------------------------------------------------------

    if [ "$n_fp" -eq 0 ] && [ "$n_uc" -eq 0 ]; then
        handle_accepted
        exit 0
    fi

    # ------------------------------------------------------------------
    # AUTO MODE
    # ------------------------------------------------------------------

    if [ "$auto_mode" -eq 1 ]; then
        # Check for false negatives: TP from initial set now missing
        current_ids=$(list_finding_ids "$WORK_DIR/meta1_response.txt")
        for id in $tp_initial; do
            if ! printf "%s" "$current_ids" | grep -qw "$id"; then
                printf "\n⛔ AUTO STOP: finding '%s' (initial TRUE_POSITIVE) has disappeared.\n" "$id"
                printf "Guardian may have been over-corrected (false negative risk).\n"
                auto_mode=0
                break
            fi
        done

        # Check for new false positives not in initial FP set
        if [ "$auto_mode" -eq 1 ]; then
            for id in $(grep "^finding_id:" "$WORK_DIR/meta1_response.txt" \
                        | awk '{print $2}'); do
                verdict=$(grep -A1 "^finding_id: $id" "$WORK_DIR/meta1_response.txt" \
                          | grep "^verdict:" | awk '{print $2}')
                if [ "$verdict" = "FALSE_POSITIVE" ]; then
                    if ! printf "%s" "$fp_initial" | grep -qw "$id"; then
                        printf "\n⛔ AUTO STOP: new FALSE_POSITIVE '%s' appeared (not in initial set).\n" "$id"
                        auto_mode=0
                        break
                    fi
                fi
            done
        fi

        if [ "$auto_mode" -eq 1 ] && [ "$n_uc" -gt 0 ]; then
            printf "\n⛔ AUTO STOP: uncertain findings detected.\n"
            auto_mode=0
        fi

        if [ "$auto_mode" -eq 1 ]; then
            # All checks passed — produce and apply diff automatically
            printf "\nAUTO: producing diff...\n"
            build_meta2_user \
                "$(cat "$WORK_DIR/meta1_response.txt")" "" \
                                                  > "$WORK_DIR/meta2_user.txt"
            call_claude \
                "$WORK_DIR/meta_system.txt" \
                "$WORK_DIR/meta2_user.txt" \
                "$META_MODEL" \
                "$META_MAX_TOKENS"                > "$WORK_DIR/meta2_response.txt"

            if grep -q "^NO_DIFF" "$WORK_DIR/meta2_response.txt"; then
                printf "AUTO: no diff needed this round.\n"
            else
                extract_diff "$WORK_DIR/meta2_response.txt" "$WORK_DIR/chosen.patch"
                if [ -s "$WORK_DIR/chosen.patch" ]; then
                    apply_guardian_diff "$WORK_DIR/chosen.patch"
                    printf "AUTO: patch applied.\n"
                fi
            fi
            continue
        fi
        # If auto_mode was stopped above, fall through to manual
        printf "Falling back to manual mode.\n"
    fi

    # ------------------------------------------------------------------
    # MANUAL — choose target
    # ------------------------------------------------------------------

    printf "\nChoose action:\n"
    printf "  [d] diff    — META produces diff on guardian prompt\n"
    printf "  [e] edit    — pause, edit artifact/spec in clone manually\n"
    printf "  [r] raffina — add notes to meta context, re-run META\n"
    if [ "$n_fp" -gt 0 ] && [ "$n_uc" -eq 0 ]; then
        printf "  [a] auto    — automatic FP elimination loop\n"
    fi
    printf "Choice: "
    read choice

    case "$choice" in

        # --------------------------------------------------------------
        [Dd])
            # META phase 2 — produce diff
            user_instruction=""
            while true; do
                printf "\nRunning META (phase 2 — diff)...\n"
                build_meta2_user \
                    "$(cat "$WORK_DIR/meta1_response.txt")" \
                    "$user_instruction"           > "$WORK_DIR/meta2_user.txt"
                call_claude \
                    "$WORK_DIR/meta_system.txt" \
                    "$WORK_DIR/meta2_user.txt" \
                    "$META_MODEL" \
                    "$META_MAX_TOKENS"            > "$WORK_DIR/meta2_response.txt"

                printf "\n%s\n" "--- META diff ---"
                cat "$WORK_DIR/meta2_response.txt"

                if grep -q "^NO_DIFF" "$WORK_DIR/meta2_response.txt"; then
                    printf "\nMETA reports no diff needed. Returning to target selection.\n"
                    break
                fi

                printf "\n[a] apply  [t] talk (refine diff)  [s] skip: "
                read diff_choice
                case "$diff_choice" in
                    [Aa])
                        extract_diff "$WORK_DIR/meta2_response.txt" \
                                     "$WORK_DIR/chosen.patch"
                        if [ -s "$WORK_DIR/chosen.patch" ]; then
                            apply_guardian_diff "$WORK_DIR/chosen.patch"
                        else
                            printf "Could not extract diff.\n"
                        fi
                        break
                        ;;
                    [Tt])
                        printf "Explain what you want: "
                        read user_instruction
                        # loop back to produce new diff
                        ;;
                    *)
                        printf "Skipped.\n"
                        break
                        ;;
                esac
            done
    