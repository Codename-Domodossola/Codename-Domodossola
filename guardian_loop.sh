#!/bin/sh
# guardian_loop.sh
# Orchestrates the GUARDIAN evaluation loop for Codename Domodossola.
# Requires: curl, jq, git
# Usage: sh guardian_loop.sh <artifact_file_relative_to_repo_root>
#
# The script clones the repo into a temp directory, works on the clone,
# and on ACCEPTED proposes a PR via GitHub. The original repo is never
# touched until you explicitly approve.

# =============================================================================
# CONFIGURATION — edit here
# =============================================================================

# GitHub repo URL (HTTPS, with credentials already configured via git credential store)
REPO_URL="https://github.com/Codename_Domodossola/Codename_Domodossola.git"

# API backend base URL.
# Anthropic official:  https://api.anthropic.com
# Copilot proxy:       http://localhost:6012
API_BASE="https://api.anthropic.com"

# Models to use.
# Anthropic official model strings:
#   claude-sonnet-4-6          — production model; use this for GUARDIAN
#   claude-opus-4-6            — stronger reasoning; candidate for META
GUARDIAN_MODEL="claude-sonnet-4-6"
META_MODEL="claude-sonnet-4-6"

# Maximum loop iterations before giving up.
MAX_ROUNDS=10

# Git identity for commits made by the loop (can be your own name/email)
GIT_AUTHOR_NAME="guardian-loop"
GIT_AUTHOR_EMAIL="guardian@domodossola"

# =============================================================================
# END CONFIGURATION
# =============================================================================

# Environment variable overrides (for CI or scripted use).
API_BASE="${API_BASE_OVERRIDE:-$API_BASE}"
GUARDIAN_MODEL="${GUARDIAN_MODEL_OVERRIDE:-$GUARDIAN_MODEL}"
META_MODEL="${META_MODEL_OVERRIDE:-$META_MODEL}"
MAX_ROUNDS="${MAX_ROUNDS_OVERRIDE:-$MAX_ROUNDS}"
REPO_URL="${REPO_URL_OVERRIDE:-$REPO_URL}"

# Artifact path is relative to repo root (e.g. docs/examples/TP/TP_deployment_requirements.md)
ARTIFACT_REL="$1"
if [ -z "$ARTIFACT_REL" ]; then
    echo "Usage: sh guardian_loop.sh <artifact_path_relative_to_repo_root>"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY not set"
    exit 1
fi

# --- Derive GitHub owner/repo for PR URL ---
# Strips https://github.com/ prefix and .git suffix
REPO_PATH=$(printf "%s" "$REPO_URL" \
    | sed 's|https://github.com/||' \
    | sed 's|\.git$||')

# --- Working directories ---
# Script lives in repo root; work dir is ../guardian_loop/<PID> (sibling of repo,
# outside git tracking, persists across Termux restarts)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(dirname "$SCRIPT_DIR")/guardian_loop/$$"
CLONE_DIR="$WORK_DIR/repo"
mkdir -p "$WORK_DIR"
# No trap: directory is persistent — clean up manually with: rm -rf ../guardian_loop/

# --- Branch name for this session ---
BRANCH="guardian/$(date '+%Y%m%d_%H%M%S')"

# --- Clone repo and create branch ---
printf "Cloning %s ...\n" "$REPO_URL"
git clone --quiet "$REPO_URL" "$CLONE_DIR"
cd "$CLONE_DIR"
git checkout -b "$BRANCH"
cd - > /dev/null
printf "Working on branch: %s\n\n" "$BRANCH"

# --- File paths (all inside the clone) ---
ARTIFACT_FILE="$CLONE_DIR/$ARTIFACT_REL"
INSTRUCTION="$CLONE_DIR/docs/notes/2026-06-07-Claude_project_intruction.txt"
CORE_SPEC="$CLONE_DIR/docs/1-Codename_Domodossola_Core_Specifications_1.0a1.md"
ANNEX_A="$CLONE_DIR/docs/2-Codename_Domodossola_C_S_Annex_A-Subordinate_documents_1.0a1.md"
CONTRIBUTING="$CLONE_DIR/CONTRIBUTING"
META_CONTEXT="$CLONE_DIR/docs/notes/meta_guardian_context.md"

# Verify artifact exists in clone
if [ ! -f "$ARTIFACT_FILE" ]; then
    printf "Error: artifact not found in repo: %s\n" "$ARTIFACT_REL"
    exit 1
fi

# --- Persistent log directory (inside the clone, will be committed) ---
LOG_SESSION_DIR="$CLONE_DIR/guardian_loop/logs/$(date '+%Y%m%d_%H%M%S')"
CURRENT_DIR="$CLONE_DIR/guardian_loop/current_round"
mkdir -p "$LOG_SESSION_DIR" "$CURRENT_DIR"

# --- Helper: call Claude API ---
call_claude() {
    system_file="$1"
    user_file="$2"
    model="$3"

    system=$(cat "$system_file")
    user=$(cat "$user_file")

    payload=$(jq -n \
        --arg model "$model" \
        --arg system "$system" \
        --arg user "$user" \
        '{
            model: $model,
            max_tokens: 4096,
            system: $system,
            messages: [{ role: "user", content: $user }]
        }')

    curl -s "${API_BASE}/v1/messages" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$payload" \
        | jq -r '.content[0].text'
}

# --- Build GUARDIAN system prompt ---
build_guardian_system() {
    cat "$INSTRUCTION"
}

# --- Build GUARDIAN user message ---
build_guardian_user() {
    artifact="$1"
    printf "GUARDIAN - evaluate the following artifact for compliance.\n\n"
    printf "## Core Specification\n\n"
    cat "$CORE_SPEC"
    printf "\n\n## Annex A\n\n"
    cat "$ANNEX_A"
    printf "\n\n## CONTRIBUTING\n\n"
    cat "$CONTRIBUTING"
    printf "\n\n## Artifact under review\n\n"
    cat "$artifact"
}

# --- Build meta-evaluator system prompt ---
build_meta_system() {
    printf "You are the meta-evaluator for the Codename Domodossola GUARDIAN loop.\n\n"
    printf "Your job is to evaluate each GUARDIAN finding and determine its root cause,\n"
    printf "then decide what to correct — or whether to escalate to the human.\n\n"

    printf "## Decision logic\n\n"
    printf "For each finding, reason as follows:\n\n"

    printf "1. Is the finding correct (genuine non-conformity)?\n"
    printf "   - NO  → false positive: correct the GUARDIAN prompt\n"
    printf "   - YES → continue to step 2\n\n"

    printf "2. Is the root cause in the artifact?\n"
    printf "   - YES → correct the ARTIFACT\n"
    printf "   - NO  → continue to step 3\n\n"

    printf "3. Is the root cause in the specification?\n"
    printf "   - Ambiguity (artifact is compliant under a reasonable reading,\n"
    printf "     but the spec wording allows conflicting interpretations)\n"
    printf "     → ESCALATE with proposed spec clarification\n"
    printf "   - Outright error in the spec\n"
    printf "     → ESCALATE with explanation only, no diff\n\n"

    printf "## Output format\n\n"
    printf "Use exactly one of these three outcomes:\n\n"

    printf "ACCEPTED\n"
    printf "  (on a line by itself — all findings are correct and the artifact is compliant)\n\n"

    printf "CORRECTION\n"
    printf "  Target: prompt | artifact\n"
    printf "  Reason: <why this target needs changing>\n"
    printf "  Option A: <rationale>\n"
    printf "  \`\`\`diff\n"
    printf "  <unified diff with path relative to repo root, no a/ b/ prefix>\n"
    printf "  \`\`\`\n"
    printf "  Option B: <rationale>   (if applicable)\n"
    printf "  \`\`\`diff\n"
    printf "  ...\n"
    printf "  \`\`\`\n\n"

    printf "ESCALATE\n"
    printf "  Target: spec\n"
    printf "  Reason: <explain the ambiguity or error>\n"
    printf "  Artifact status: compliant | non-compliant\n"
    printf "  Option A: <rationale>   (omit entirely if outright error — no diff proposed)\n"
    printf "  \`\`\`diff\n"
    printf "  <unified diff against spec file>\n"
    printf "  \`\`\`\n\n"

    printf "## Rules\n\n"
    printf "- Never modify the spec autonomously. ESCALATE and let the human decide.\n"
    printf "- Diffs MUST be in unified diff format (diff -u).\n"
    printf "- Diff headers MUST use paths relative to the repo root, with no a/ b/ prefix.\n"
    printf "  Example:  --- docs/examples/TP/TP_deployment_requirements.md\n"
    printf "            +++ docs/examples/TP/TP_deployment_requirements.md\n"
    printf "- Reason about governance intent, not just citation syntax.\n"
    printf "- If multiple findings are present, address each one separately before giving the outcome.\n\n"

    cat "$META_CONTEXT"
}

# --- Build meta-evaluator user message ---
build_meta_user() {
    guardian_response="$1"
    artifact="$2"
    printf "## GUARDIAN response\n\n"
    cat "$guardian_response"
    printf "\n\n## Artifact under review\n\n"
    cat "$artifact"
    printf "\n\n---\n\n"
    printf "Apply the decision logic from your instructions to each finding.\n"
    printf "Address each finding individually, then output exactly one of: ACCEPTED, CORRECTION, ESCALATE.\n"
}

# --- Extract diff for a named option and apply it to the clone ---
apply_option() {
    meta_response_file="$1"
    option_label="$2"   # "A", "B", or "only"

    if [ "$option_label" = "only" ]; then
        awk '
            BEGIN { in_block=0; done=0; }
            !done && /^```diff/ { in_block=1; next; }
            in_block && /^```/ { in_block=0; done=1; }
            in_block { print; }
        ' "$meta_response_file" > "$WORK_DIR/chosen.patch"
    else
        awk -v label="$option_label" '
            BEGIN { found=0; in_block=0; }
            /^Option [A-Z]/ {
                if ($2 == label ":") { found=1; } else { found=0; }
            }
            found && /^```diff/ { in_block=1; next; }
            in_block && /^```/ { in_block=0; found=0; }
            in_block { print; }
        ' "$meta_response_file" > "$WORK_DIR/chosen.patch"
    fi

    if [ ! -s "$WORK_DIR/chosen.patch" ]; then
        printf "Could not extract diff for option %s.\n" "$option_label"
        return 1
    fi

    printf "\n--- Diff to apply ---\n"
    cat "$WORK_DIR/chosen.patch"
    printf "\n---\n"

    # Apply patch inside the clone
    cd "$CLONE_DIR"
    patch -p0 < "$WORK_DIR/chosen.patch"
    cd - > /dev/null
    printf "Patch applied.\n"
}

# --- Git commit inside the clone ---
git_commit() {
    message="$1"
    cd "$CLONE_DIR"
    git add -A
    GIT_AUTHOR_NAME="$GIT_AUTHOR_NAME" \
    GIT_AUTHOR_EMAIL="$GIT_AUTHOR_EMAIL" \
    GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" \
    GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL" \
    git commit --quiet -m "$message" 2>/dev/null || true  # no-op if nothing changed
    cd - > /dev/null
}

# --- Detect how many options are in the meta response ---
count_options() {
    grep -c "^Option [A-Z]:" "$1" || echo 0
}

# --- Handle ESCALATE outcome ---
handle_escalate() {
    printf "\n⚠️  ESCALATE — spec issue detected. Human decision required.\n"
    grep "^Artifact status:" "$WORK_DIR/meta_response.txt" || true
    printf "\n"

    if grep -q "^\`\`\`diff" "$WORK_DIR/meta_response.txt"; then
        n_options=$(count_options "$WORK_DIR/meta_response.txt")
        if [ "$n_options" -gt 1 ]; then
            option_list=$(seq 1 "$n_options" | awk '{printf "%s", sprintf("%c", 64+$1)} END {print ""}')
            printf "Proposed spec clarifications: %s\n" "$option_list"
            printf "Apply option [%s], skip [s], or explain: " "$option_list"
        else
            printf "A spec clarification is proposed.\n"
            printf "Apply [a], skip [s], or explain: "
        fi

        read answer
        case "$answer" in
            [Ss])
                printf "\nSkipped. Recording escalation and stopping loop.\n"
                printf "\n\n### Round %d ESCALATE (skipped by user)\n\n" "$round" >> "$META_CONTEXT"
                grep "^Reason:" "$WORK_DIR/meta_response.txt" >> "$META_CONTEXT" || true
                exit 2
                ;;
            [A-Za-z])
                upper=$(printf "%s" "$answer" | tr '[:lower:]' '[:upper:]')
                if [ "$n_options" -le 1 ]; then
                    apply_option "$WORK_DIR/meta_response.txt" "only"
                else
                    apply_option "$WORK_DIR/meta_response.txt" "$upper"
                fi
                git_commit "round $(printf '%02d' $round): ESCALATE — spec clarification applied (option $upper)"
                printf "\nSpec updated. Recording and stopping loop.\n"
                printf "\n\n### Round %d ESCALATE (spec clarification applied: option %s)\n\n" \
                    "$round" "$upper" >> "$META_CONTEXT"
                exit 2
                ;;
            *)
                printf "\nRecording explanation and stopping loop.\n"
                printf "\n\n### Round %d ESCALATE (user explanation)\n\n%s\n" \
                    "$round" "$answer" >> "$META_CONTEXT"
                exit 2
                ;;
        esac
    else
        printf "No correction proposed (outright spec error).\n"
        printf "Recording and stopping loop.\n"
        printf "\n\n### Round %d ESCALATE (spec error, no diff proposed)\n\n" "$round" >> "$META_CONTEXT"
        grep "^Reason:" "$WORK_DIR/meta_response.txt" >> "$META_CONTEXT" || true
        exit 2
    fi
}

# --- On ACCEPTED: show global diff and propose PR ---
handle_accepted() {
    printf "\n✅ GUARDIAN response accepted.\n\n"

    # Commit the final state (logs + any last changes)
    git_commit "round $(printf '%02d' $round): ACCEPTED"

    # Show global diff vs main
    printf "=== Global diff vs main ===\n\n"
    cd "$CLONE_DIR"
    git diff main.."$BRANCH"
    cd - > /dev/null

    # Push automatically — work dir is already persistent
    printf "\nPushing branch...\n"
    cd "$CLONE_DIR"
    git push --quiet origin "$BRANCH"
    cd - > /dev/null

    PR_URL="https://github.com/${REPO_PATH}/compare/${BRANCH}?expand=1"
    printf "\n✅ Branch pushed.\n"
    printf "Open this URL to create the PR:\n\n"
    printf "  %s\n\n" "$PR_URL"
    printf "Work dir preserved at: %s\n" "$WORK_DIR"
    printf "Clean up when done:    rm -rf %s\n" "$WORK_DIR"
}

# =============================================================================
# MAIN
# =============================================================================

printf "Backend:        %s\n" "$API_BASE"
printf "GUARDIAN model: %s\n" "$GUARDIAN_MODEL"
printf "META model:     %s\n" "$META_MODEL"
printf "Artifact:       %s\n" "$ARTIFACT_REL"
printf "Branch:         %s\n" "$BRANCH"
printf "Log session:    %s\n" "$LOG_SESSION_DIR"

round=0

while [ $round -lt $MAX_ROUNDS ]; do
    round=$((round + 1))
    printf "\n=== Round %d ===\n" "$round"

    # Run GUARDIAN
    printf "Running GUARDIAN...\n"
    build_guardian_system > "$WORK_DIR/guardian_system.txt"
    build_guardian_user "$ARTIFACT_FILE" > "$WORK_DIR/guardian_user.txt"
    call_claude \
        "$WORK_DIR/guardian_system.txt" \
        "$WORK_DIR/guardian_user.txt" \
        "$GUARDIAN_MODEL" \
        > "$WORK_DIR/guardian_response.txt"

    printf "\n--- GUARDIAN response ---\n"
    cat "$WORK_DIR/guardian_response.txt"

    # Run meta-evaluator
    printf "\nRunning meta-evaluator...\n"
    build_meta_system > "$WORK_DIR/meta_system.txt"
    build_meta_user \
        "$WORK_DIR/guardian_response.txt" \
        "$ARTIFACT_FILE" \
        > "$WORK_DIR/meta_user.txt"
    call_claude \
        "$WORK_DIR/meta_system.txt" \
        "$WORK_DIR/meta_user.txt" \
        "$META_MODEL" \
        > "$WORK_DIR/meta_response.txt"

    printf "\n--- Meta-evaluator assessment ---\n"
    cat "$WORK_DIR/meta_response.txt"

    # Persist logs
    LOG_ROUND_DIR="$LOG_SESSION_DIR/round_$(printf '%02d' $round)"
    mkdir -p "$LOG_ROUND_DIR"
    cp "$WORK_DIR/guardian_response.txt" "$CURRENT_DIR/guardian_response.txt"
    cp "$WORK_DIR/meta_response.txt"     "$CURRENT_DIR/meta_response.txt"
    cp "$WORK_DIR/guardian_response.txt" "$LOG_ROUND_DIR/guardian_response.txt"
    cp "$WORK_DIR/meta_response.txt"     "$LOG_ROUND_DIR/meta_response.txt"

    # Check outcome
    if grep -q "^ACCEPTED$" "$WORK_DIR/meta_response.txt"; then
        handle_accepted
        exit 0
    fi

    if grep -q "^ESCALATE$" "$WORK_DIR/meta_response.txt"; then
        handle_escalate
        # handle_escalate always exits
    fi

    # CORRECTION path
    printf "\nTarget: "
    grep "^Target:" "$WORK_DIR/meta_response.txt" | head -1 || printf "not specified\n"

    n_options=$(count_options "$WORK_DIR/meta_response.txt")

    if [ "$n_options" -gt 1 ]; then
        option_list=$(seq 1 "$n_options" | awk '{printf "%s", sprintf("%c", 64+$1)} END {print ""}')
        printf "\nOptions available: %s\n" "$option_list"
        printf "Choose [%s/explain]: " "$option_list"
    else
        printf "\nApply proposed correction? [a/explain]: "
    fi

    read answer

    case "$answer" in
        [A-Za-z])
            upper=$(printf "%s" "$answer" | tr '[:lower:]' '[:upper:]')
            if [ "$n_options" -le 1 ]; then
                apply_option "$WORK_DIR/meta_response.txt" "only"
            else
                apply_option "$WORK_DIR/meta_response.txt" "$upper"
            fi
            git_commit "round $(printf '%02d' $round): correction applied (option $upper)"
            ;;
        *)
            printf "\nRecording explanation and continuing...\n"
            printf "\n\n### Round %d user explanation\n\n%s\n" "$round" "$answer" \
                >> "$META_CONTEXT"
            ;;
    esac
done

printf "\nMax rounds (%d) reached without acceptance.\n" "$MAX_ROUNDS"
exit 1
