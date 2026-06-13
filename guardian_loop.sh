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
META_MODEL="claude-fable-5"
GUARDIAN_MAX_TOKENS=16000
META_MAX_TOKENS=16000
MAX_ROUNDS=20

# Normative knowledge source.
# Set BUNDLE_FILE to use the full repo bundle instead of individual spec files.
# Path is relative to CLONE_DIR, or absolute.
# Example: BUNDLE_FILE="bundle-20260611-233352.txt"
BUNDLE_FILE=""

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
BUNDLE_FILE="${BUNDLE_FILE_OVERRIDE:-$BUNDLE_FILE}"
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

# Resolve bundle path (relative to CLONE_DIR if not absolute)
if [ -n "$BUNDLE_FILE" ]; then
    case "$BUNDLE_FILE" in
        /*) BUNDLE_PATH="$BUNDLE_FILE" ;;
        *)  BUNDLE_PATH="$CLONE_DIR/$BUNDLE_FILE" ;;
    esac
    if [ ! -f "$BUNDLE_PATH" ]; then
        printf "Error: BUNDLE_FILE not found: %s
" "$BUNDLE_PATH"
        exit 1
    fi
fi

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
    printf "## Normative knowledge\n\n"
    if [ -n "$BUNDLE_FILE" ]; then
        cat "$BUNDLE_PATH"
    else
        printf "### Core Specification\n\n"; cat "$CORE_SPEC"
        printf "\n\n### Annex A\n\n";      cat "$ANNEX_A"
        printf "\n\n### CONTRIBUTING\n\n"; cat "$CONTRIBUTING"
    fi
    printf "\n\n## Artifact under review\n\n"
    cat "$ARTIFACT_FILE"
    printf "\n\n---\n\n"
    printf "Evaluate the artifact under review.\n"
}

build_meta1_user() {
    guardian_response="$1"
    printf "## Normative knowledge\n\n"
    if [ -n "$BUNDLE_FILE" ]; then
        cat "$BUNDLE_PATH"
    else
        printf "### Core Specification\n\n"; cat "$CORE_SPEC"
        printf "\n\n### Annex A\n\n";        cat "$ANNEX_A"
        printf "\n\n### CONTRIBUTING\n\n";   cat "$CONTRIBUTING"
    fi
    printf "\n\n## Current GUARDIAN system prompt\n\n"
    cat "$GUARDIAN_PROMPT"
    printf "\n\n## Artifact under review\n\n"
    cat "$ARTIFACT_FILE"
    printf "\n\n## GUARDIAN response\n\n"
    cat "$guardian_response"
    printf "\n\n## Meta-evaluator context\n\n"
    cat "$META_CONTEXT"
    printf "\n\n---\n\n"
    printf "Analyse the GUARDIAN response.\n"
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
# save_session_synthesis — append meta synthesis to meta_context.md
# ---------------------------------------------------------------------------

save_session_synthesis() {
    outcome="$1"      # ACCEPTED | ESCALATE | MAX_ROUNDS
    user_notes="$2"   # may be empty

    printf "\n\nRunning META (session synthesis)...\n"

    # Build synthesis request
    {
        printf "## Meta-evaluator context so far\n\n"
        cat "$META_CONTEXT"
        printf "\n\n## Session log\n\n"
        ls "$LOG_DIR"/round_*/meta1_response.txt 2>/dev/null | while read f; do
            round_label=$(basename "$(dirname "$f")")
            printf "### %s\n\n" "$round_label"
            cat "$f"
            printf "\n\n"
        done
        printf "## Session outcome: %s\n\n" "$outcome"
        if [ -n "$user_notes" ]; then
            printf "## User notes\n\n%s\n\n" "$user_notes"
        fi
        printf "---\n\n"
        printf "Produce a SESSION SYNTHESIS for the meta context.\n"
        printf "Follow the format defined in your instructions.\n"
    } > "$WORK_DIR/synthesis_user.txt"

    call_claude         "$WORK_DIR/meta_system.txt"         "$WORK_DIR/synthesis_user.txt"         "$META_MODEL"         "$META_MAX_TOKENS" > "$WORK_DIR/synthesis_response.txt"

    printf "\n%s\n" "--- Session synthesis ---"
    cat "$WORK_DIR/synthesis_response.txt"

    # Append to meta_context
    printf "\n\n" >> "$META_CONTEXT"
    cat "$WORK_DIR/synthesis_response.txt" >> "$META_CONTEXT"
    printf "\nSynthesis appended to meta_context.md\n"
}

# ---------------------------------------------------------------------------
# handle_accepted
# ---------------------------------------------------------------------------

handle_accepted() {
    printf "\nCollect any notes for the session synthesis (Enter to skip): "
    read _synth_notes
    save_session_synthesis "ACCEPTED" "$_synth_notes"

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
            ;;

        # --------------------------------------------------------------
        [Ee])
            printf "\nPause — edit files in:\n"
            printf "  Artifact/spec: %s\n" "$CLONE_DIR"
            printf "  (use Markor or any editor)\n"
            printf "Press Enter when done: "
            read _
            printf "Reloading and re-running from GUARDIAN...\n"
            skip_guardian=0
            ;;

        # --------------------------------------------------------------
        [Rr])
            printf "Add notes for meta context (press Enter twice when done):\n"
            notes=""
            while IFS= read -r line; do
                [ -z "$line" ] && break
                notes="${notes}${line}\n"
            done
            if [ -n "$notes" ]; then
                # Append notes + brief analysis summary to meta_context
                printf "\n\n### Session %s — Round %d\n\n" \
                    "$SESSION_TS" "$round"          >> "$META_CONTEXT"
                printf "%b" "$notes"                >> "$META_CONTEXT"
                printf "\nSummary: TP=%s FP=%s Uncertain=%s\n" \
                    "$n_tp" "$n_fp" "$n_uc"         >> "$META_CONTEXT"
            fi
            printf "Re-running META with updated context...\n"
            skip_guardian=1
            ;;

        # --------------------------------------------------------------
        [Aa])
            if [ "$n_fp" -gt 0 ] && [ "$n_uc" -eq 0 ]; then
                printf "\nStarting AUTO mode.\n"
                printf "Recording initial finding sets...\n"
                tp_initial=$(grep -B1 "^verdict: TRUE_POSITIVE" \
                    "$WORK_DIR/meta1_response.txt" \
                    | grep "^finding_id:" | awk '{print $2}' \
                    | tr '\n' ' ')
                fp_initial=$(grep -B1 "^verdict: FALSE_POSITIVE" \
                    "$WORK_DIR/meta1_response.txt" \
                    | grep "^finding_id:" | awk '{print $2}' \
                    | tr '\n' ' ')
                printf "TP to preserve: %s\n" "$tp_initial"
                printf "FP to eliminate: %s\n" "$fp_initial"
                auto_mode=1
            else
                printf "AUTO requires FP > 0 and Uncertain = 0.\n"
            fi
            ;;

        *)
            printf "Unknown choice — please enter d, e, r%s.\n" \
                "$([ "$n_fp" -gt 0 ] && [ "$n_uc" -eq 0 ] && printf ', a' || true)"
            ;;
    esac

done

save_session_synthesis "MAX_ROUNDS" ""
printf "\nMax rounds (%d) reached without acceptance.\n" "$MAX_ROUNDS"
exit 1
