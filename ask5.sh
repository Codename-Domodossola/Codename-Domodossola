#!/bin/sh
# ask.sh
# Multi-turn chat with Claude using a bundle as initial knowledge.
# All large data passes through temp files — no shell argument size limits.
#
# Usage:
#   sh ask.sh <bundle_file>              — start or resume chat (log auto-named)
#   sh ask.sh <bundle_file> <log_file>   — start or resume a named chat
#
# Commands during chat:
#   /quit /exit   — end session
#   /log          — print path to current log file
#   /clear        — start a new session (appends marker to same log file)

# =============================================================================
# CONFIGURATION
# =============================================================================

MODEL="claude-fable-5"
MAX_TOKENS=16000
API_BASE="https://api.anthropic.com"
LOG_DIR="./chat_logs"

# =============================================================================
# END CONFIGURATION
# =============================================================================

API_BASE="${API_BASE_OVERRIDE:-$API_BASE}"
MODEL="${MODEL_OVERRIDE:-$MODEL}"

BUNDLE_FILE="$1"
if [ -z "$BUNDLE_FILE" ]; then
    printf "Usage: sh ask.sh <bundle_file> [log_file]\n"; exit 1
fi
if [ ! -f "$BUNDLE_FILE" ]; then
    printf "Error: bundle not found: %s\n" "$BUNDLE_FILE"; exit 1
fi
if [ -z "$ANTHROPIC_API_KEY" ]; then
    printf "Error: ANTHROPIC_API_KEY not set\n"; exit 1
fi

mkdir -p "$LOG_DIR"
if [ -n "$2" ]; then
    LOG_FILE="$2"
else
    LOG_FILE="$LOG_DIR/chat_$(date '+%Y%m%d_%H%M%S').jsonl"
fi

# Temp files — all large data lives here
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

PAYLOAD_FILE="$TMPDIR_WORK/payload.json"
MESSAGES_FILE="$TMPDIR_WORK/messages.json"   # current messages array
HISTORY_FILE="$TMPDIR_WORK/history.json"     # loaded from log
USER_FILE="$TMPDIR_WORK/user.txt"            # user message text
REPLY_FILE="$TMPDIR_WORK/reply.txt"          # assistant reply text

# ---------------------------------------------------------------------------
# Log helpers (JSONL: one JSON object per line)
# ---------------------------------------------------------------------------

log_session_start() {
    jq -cn \
        --arg ts     "$(date '+%Y-%m-%dT%H:%M:%S')" \
        --arg bundle "$BUNDLE_FILE" \
        '{session: $ts, bundle: $bundle}' >> "$LOG_FILE"
}

log_message() {
    # log_message <role> <content_file>
    jq -cn \
        --arg     role    "$1" \
        --rawfile content "$2" \
        '{role: $role, content: $content}' >> "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# Load conversation history from log into HISTORY_FILE
# Only messages after the last SESSION_START marker are included.
# ---------------------------------------------------------------------------

load_history() {
    if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
        printf '[]' > "$HISTORY_FILE"
        return
    fi
    # Extract lines after last session marker, parse as JSONL array
    awk '
        /^{"session":/ { buf = "" }
        !/^{"session":/ { buf = (buf == "" ? "" : buf "\n") $0 }
        END { print buf }
    ' "$LOG_FILE" | jq -Rs '
        split("\n") |
        map(select(length > 0)) |
        map(fromjson? // empty)
    ' > "$HISTORY_FILE"
}

# ---------------------------------------------------------------------------
# Build messages array into MESSAGES_FILE
# First user message of a session gets the bundle prepended via file concat.
# ---------------------------------------------------------------------------

build_messages() {
    user_msg_file="$1"   # file containing the raw user message text

    load_history
    hist_len=$(jq 'length' "$HISTORY_FILE")

    if [ "$hist_len" -eq 0 ]; then
        # First message of session: prepend bundle content to user message
        COMBINED="$TMPDIR_WORK/combined_first.txt"
        cat "$BUNDLE_FILE" > "$COMBINED"
        printf "\n\n---\n\n" >> "$COMBINED"
        cat "$user_msg_file" >> "$COMBINED"

        jq -cn \
            --rawfile content "$COMBINED" \
            '[{role: "user", content: $content}]' > "$MESSAGES_FILE"
    else
        # Subsequent messages: rebuild history with bundle on first message,
        # append new user message — all via files
        FIRST_CONTENT="$TMPDIR_WORK/first_content.txt"
        FIRST_RAW="$TMPDIR_WORK/first_raw.txt"

        # Extract original content of first message to file
        jq -r '.[0].content' "$HISTORY_FILE" > "$FIRST_RAW"

        # Prepend bundle to it
        cat "$BUNDLE_FILE" > "$FIRST_CONTENT"
        printf "\n\n---\n\n" >> "$FIRST_CONTENT"
        cat "$FIRST_RAW" >> "$FIRST_CONTENT"

        # Rebuild: first message with bundle, rest unchanged, plus new user msg
        jq -n \
            --rawfile first_content "$FIRST_CONTENT" \
            --rawfile new_content   "$user_msg_file" \
            --slurpfile history     "$HISTORY_FILE" \
            '($history[0] | .[0].content = $first_content) +
             ($history[0][1:]) +
             [{role: "user", content: $new_content}]' > "$MESSAGES_FILE"
    fi
}

# ---------------------------------------------------------------------------
# Send one turn
# ---------------------------------------------------------------------------

send_message() {
    user_msg_file="$1"

    build_messages "$user_msg_file"

    jq -n \
        --arg     model      "$MODEL" \
        --argjson max_tokens "$MAX_TOKENS" \
        --slurpfile messages "$MESSAGES_FILE" \
        '{model: $model, max_tokens: $max_tokens, messages: $messages[0]}' \
        > "$PAYLOAD_FILE"

    response=$(curl -s "${API_BASE}/v1/messages" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        --data-binary "@$PAYLOAD_FILE")

    # Save raw response for debugging
    printf "%s" "$response" > "$TMPDIR_WORK/last_response.json"

    err=$(printf "%s" "$response" | jq -r '.error.message // empty')
    if [ -n "$err" ]; then
        printf "API error: %s\n" "$err" >&2
        printf "%s\n" "$response" | jq '.' >&2
        return 1
    fi

    # stop_reason may be "end_turn", "max_tokens", etc — log if unexpected
    stop=$(printf "%s" "$response" | jq -r '.stop_reason // "unknown"')
    if [ "$stop" = "max_tokens" ]; then
        printf "(warning: response truncated — increase MAX_TOKENS)\n" >&2
    fi

    # Extract all text blocks (content is an array)
    printf "%s" "$response" | jq -r '
        .content // [] |
        map(select(.type == "text") | .text) |
        join("\n")
    ' > "$REPLY_FILE"

    if [ ! -s "$REPLY_FILE" ]; then
        printf "Empty response. Raw:\n" >&2
        jq '.' "$TMPDIR_WORK/last_response.json" >&2
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

log_session_start

printf "Model:  %s\n" "$MODEL"
printf "Bundle: %s\n" "$BUNDLE_FILE"
printf "Log:    %s\n" "$LOG_FILE"
printf "Commands: /quit  /log  /clear\n"
printf "%s\n\n" "----------------------------------------"

# Show last exchange if resuming
load_history
hist_len=$(jq 'length' "$HISTORY_FILE")
if [ "$hist_len" -gt 0 ]; then
    printf "(Resuming — %s messages in history)\n\n" "$hist_len"
    jq -r '.[-2:] | .[] | "[\(.role | ascii_upcase)]\n\(.content)\n"' \
        "$HISTORY_FILE" 2>/dev/null
fi

while true; do
    printf "You: "
    read user_input

    case "$user_input" in
        /quit|/exit)
            printf "Bye.\n"; break ;;
        /log)
            printf "Log: %s\n" "$LOG_FILE"; continue ;;
        /clear)
            log_session_start
            printf '[]' > "$HISTORY_FILE"
            printf "New session started.\n\n"; continue ;;
        "")
            continue ;;
    esac

    printf "%s" "$user_input" > "$USER_FILE"

    if send_message "$USER_FILE"; then
        log_message "user"      "$USER_FILE"
        log_message "assistant" "$REPLY_FILE"
        printf "\nClaude: "
        cat "$REPLY_FILE"
        printf "\n\n"
    fi
done
