#!/bin/bash

# Flow Checkpoint Hook — Session End
# Saves pipeline state and records a git checkpoint SHA when a Copilot session ends.
#
# Environment variables:
#   SKIP_FLOW_CHECKPOINT  - "true" to disable entirely (default: unset)
#   FLOW_LOG_DIR          - Directory for checkpoint logs (default: .github/logs/copilot/flow-checkpoint)
#   COPILOT_TRACKING_DIR  - State directory for the pipeline (default: .copilot-tracking)

set -euo pipefail

# ---------------------------------------------------------------------------
# Early exit conditions
# ---------------------------------------------------------------------------
if [[ "${SKIP_FLOW_CHECKPOINT:-}" == "true" ]]; then
  exit 0
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "⚠️  Flow Checkpoint: Not in a git repository — skipping"
  exit 0
fi

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
TRACKING_DIR="${COPILOT_TRACKING_DIR:-.copilot-tracking}"
LOG_DIR="${FLOW_LOG_DIR:-.github/logs/copilot/flow-checkpoint}"
STATE_FILE="$TRACKING_DIR/flow-state.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/checkpoint.log"

# ---------------------------------------------------------------------------
# Check if a flow is active
# ---------------------------------------------------------------------------
if [[ ! -f "$STATE_FILE" ]]; then
  echo "ℹ️  Flow Checkpoint: No active pipeline state found at $STATE_FILE — skipping"
  exit 0
fi

# ---------------------------------------------------------------------------
# Read current state
# ---------------------------------------------------------------------------
CURRENT_PHASE=""
FLOW_ID=""
PHASE_STATUS=""

if command -v jq &>/dev/null; then
  CURRENT_PHASE=$(jq -r '.current_phase // empty' "$STATE_FILE" 2>/dev/null || echo "")
  FLOW_ID=$(jq -r '.flow_id // empty' "$STATE_FILE" 2>/dev/null || echo "")
  PHASE_STATUS=$(jq -r ".phase_status[\"$CURRENT_PHASE\"] // empty" "$STATE_FILE" 2>/dev/null || echo "")
fi

# Fallback: grep-based extraction if jq unavailable or returned empty
if [[ -z "$CURRENT_PHASE" ]]; then
  CURRENT_PHASE=$(grep -oE '"current_phase"\s*:\s*[0-9]+' "$STATE_FILE" 2>/dev/null | grep -oE '[0-9]+$' | head -1 || echo "")
fi
if [[ -z "$FLOW_ID" ]]; then
  FLOW_ID=$(grep -oE '"flow_id"\s*:\s*"[^"]*"' "$STATE_FILE" 2>/dev/null | sed 's/.*"flow_id"\s*:\s*"//;s/"//' | head -1 || echo "unknown")
fi

# ---------------------------------------------------------------------------
# Record git checkpoint
# ---------------------------------------------------------------------------
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")

if [[ -n "$GIT_SHA" && -n "$CURRENT_PHASE" ]]; then
  CHECKPOINT_KEY="session_end_phase_${CURRENT_PHASE}"

  if command -v jq &>/dev/null; then
    # Update git_checkpoints and updated_at in state file atomically
    TEMP_FILE=$(mktemp)
    jq --arg key "$CHECKPOINT_KEY" \
       --arg sha "$GIT_SHA" \
       --arg ts "$TIMESTAMP" \
       '.git_checkpoints[$key] = $sha | .updated_at = $ts' \
       "$STATE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$STATE_FILE"
  else
    # Fallback: append note if jq not available
    echo "# checkpoint $CHECKPOINT_KEY=$GIT_SHA at $TIMESTAMP" >> "$STATE_FILE.checkpoints"
  fi

  echo "📍 Flow Checkpoint: Phase $CURRENT_PHASE state saved (sha: ${GIT_SHA:0:8})"

  # Write structured log entry
  printf '{"timestamp":"%s","event":"checkpoint_saved","phase":%s,"phase_status":"%s","git_sha":"%s","flow_id":"%s"}\n' \
    "$TIMESTAMP" "$CURRENT_PHASE" "${PHASE_STATUS:-unknown}" "$GIT_SHA" "$FLOW_ID" \
    >> "$LOG_FILE"
else
  echo "⚠️  Flow Checkpoint: Could not determine current phase or git SHA"

  printf '{"timestamp":"%s","event":"checkpoint_skipped","reason":"missing_phase_or_sha","flow_id":"%s"}\n' \
    "$TIMESTAMP" "$FLOW_ID" \
    >> "$LOG_FILE"
fi

exit 0
