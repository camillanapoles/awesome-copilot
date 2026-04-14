#!/bin/bash

# Flow Checkpoint Hook — Pre-Tool-Use Gate Validator
# Checks that quality gate criteria are met before allowing tool invocations
# that would advance the pipeline to the next phase.
#
# Environment variables:
#   GATE_MODE             - "warn" (log only) or "block" (exit non-zero) (default: warn)
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
  exit 0
fi

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
TRACKING_DIR="${COPILOT_TRACKING_DIR:-.copilot-tracking}"
STATE_FILE="$TRACKING_DIR/flow-state.json"
LOG_DIR="${FLOW_LOG_DIR:-.github/logs/copilot/flow-checkpoint}"
MODE="${GATE_MODE:-warn}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/checkpoint.log"

# ---------------------------------------------------------------------------
# No active flow — nothing to validate
# ---------------------------------------------------------------------------
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Read tool invocation from stdin
# ---------------------------------------------------------------------------
INPUT=$(cat)

TOOL_NAME=""
TOOL_INPUT=""

if command -v jq &>/dev/null; then
  TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.toolName // empty' 2>/dev/null || echo "")
  TOOL_INPUT=$(printf '%s' "$INPUT" | jq -r '.toolInput // empty' 2>/dev/null || echo "")
fi

if [[ -z "$TOOL_NAME" ]]; then
  TOOL_NAME=$(printf '%s' "$INPUT" | grep -oE '"toolName"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"toolName"\s*:\s*"//;s/"//' || echo "")
fi

# Only validate file-editing and execution tools — read-only tools are always safe
WRITE_TOOLS="editFile|createFile|deleteFile|runInTerminal|executeCommand|bash|edit|execute"
if ! echo "$TOOL_NAME" | grep -qE "($WRITE_TOOLS)"; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Read current pipeline state
# ---------------------------------------------------------------------------
CURRENT_PHASE=""
FLOW_ID=""

if command -v jq &>/dev/null; then
  CURRENT_PHASE=$(jq -r '.current_phase // empty' "$STATE_FILE" 2>/dev/null || echo "")
  FLOW_ID=$(jq -r '.flow_id // empty' "$STATE_FILE" 2>/dev/null || echo "")
fi

if [[ -z "$CURRENT_PHASE" ]]; then
  CURRENT_PHASE=$(grep -oE '"current_phase"\s*:\s*[0-9]+' "$STATE_FILE" 2>/dev/null | grep -oE '[0-9]+$' | head -1 || echo "")
fi

# If we can't determine the phase, pass through (don't block unknown state)
if [[ -z "$CURRENT_PHASE" ]]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Gate validation: check that the previous phase gate was passed
# ---------------------------------------------------------------------------
GATE_VIOLATED=false
GATE_NAME=""
GATE_REASON=""

check_phase_file_exists() {
  local phase_file="$TRACKING_DIR/$1"
  if [[ ! -f "$phase_file" ]]; then
    GATE_VIOLATED=true
    GATE_REASON="Required phase output $1 not found"
    return 1
  fi

  local status=""
  if command -v jq &>/dev/null; then
    status=$(jq -r '.status // empty' "$phase_file" 2>/dev/null || echo "")
  fi
  if [[ -z "$status" ]]; then
    status=$(grep -oE '"status"\s*:\s*"[^"]*"' "$phase_file" 2>/dev/null | sed 's/.*"status"\s*:\s*"//;s/"//' | head -1 || echo "")
  fi

  if [[ "$status" != "passed" ]]; then
    GATE_VIOLATED=true
    GATE_REASON="$1 has status '$status' (expected 'passed')"
    return 1
  fi
  return 0
}

case "$CURRENT_PHASE" in
  2)
    GATE_NAME="discovery_to_planning"
    check_phase_file_exists "phase-1-discovery.json" || true
    ;;
  3)
    GATE_NAME="planning_to_validation"
    # Check all three plan files exist
    for f in "plan.md" "plan-details.md" "implementation-prompt.md"; do
      if [[ ! -f "$TRACKING_DIR/$f" ]]; then
        GATE_VIOLATED=true
        GATE_REASON="Required planning file $f not found in $TRACKING_DIR"
        break
      fi
    done
    ;;
  4)
    GATE_NAME="validation_to_generation"
    check_phase_file_exists "phase-3-validation.json" || true
    if [[ "$GATE_VIOLATED" == "false" ]] && command -v jq &>/dev/null; then
      VERDICT=$(jq -r '.verdict // empty' "$TRACKING_DIR/phase-3-validation.json" 2>/dev/null || echo "")
      if [[ "$VERDICT" != "APPROVED" ]]; then
        GATE_VIOLATED=true
        GATE_REASON="Governance verdict is '$VERDICT' (expected 'APPROVED')"
      fi
    fi
    ;;
  5)
    GATE_NAME="generation_to_implementation"
    check_phase_file_exists "phase-4-generation-manifest.json" || true
    ;;
  6)
    GATE_NAME="implementation_to_testing"
    check_phase_file_exists "phase-5-implementation.json" || true
    if [[ "$GATE_VIOLATED" == "false" ]] && command -v jq &>/dev/null; then
      BUILD=$(jq -r '.build_result // empty' "$TRACKING_DIR/phase-5-implementation.json" 2>/dev/null || echo "")
      if [[ "$BUILD" != "success" ]]; then
        GATE_VIOLATED=true
        GATE_REASON="Build result is '$BUILD' (expected 'success')"
      fi
    fi
    ;;
  7)
    GATE_NAME="testing_to_review"
    check_phase_file_exists "phase-6-testing.json" || true
    if [[ "$GATE_VIOLATED" == "false" ]] && command -v jq &>/dev/null; then
      FAILED=$(jq -r '.tests_failed // 1' "$TRACKING_DIR/phase-6-testing.json" 2>/dev/null || echo "1")
      if [[ "$FAILED" != "0" ]]; then
        GATE_VIOLATED=true
        GATE_REASON="$FAILED test(s) are failing"
      fi
    fi
    ;;
  8)
    GATE_NAME="review_to_verification"
    check_phase_file_exists "phase-7-review.json" || true
    if [[ "$GATE_VIOLATED" == "false" ]] && command -v jq &>/dev/null; then
      VERDICT=$(jq -r '.verdict // empty' "$TRACKING_DIR/phase-7-review.json" 2>/dev/null || echo "")
      if [[ "$VERDICT" != "PASS" ]]; then
        GATE_VIOLATED=true
        GATE_REASON="Security review verdict is '$VERDICT' (expected 'PASS')"
      fi
    fi
    ;;
  9)
    GATE_NAME="verification_to_deployment"
    check_phase_file_exists "phase-8-verification.json" || true
    if [[ "$GATE_VIOLATED" == "false" ]] && command -v jq &>/dev/null; then
      VERDICT=$(jq -r '.verdict // empty' "$TRACKING_DIR/phase-8-verification.json" 2>/dev/null || echo "")
      if [[ "$VERDICT" != "PASS" ]]; then
        GATE_VIOLATED=true
        GATE_REASON="Verification verdict is '$VERDICT' (expected 'PASS')"
      fi
    fi
    ;;
  *)
    # Phase 1, 10, or unknown — no gate to validate
    exit 0
    ;;
esac

# ---------------------------------------------------------------------------
# Report gate result
# ---------------------------------------------------------------------------
if [[ "$GATE_VIOLATED" == "true" ]]; then
  printf '{"timestamp":"%s","event":"gate_warning","phase":%s,"gate":"%s","result":"not_passed","reason":"%s","mode":"%s","tool":"%s","flow_id":"%s"}\n' \
    "$TIMESTAMP" "$CURRENT_PHASE" "$GATE_NAME" "$GATE_REASON" "$MODE" "$TOOL_NAME" "${FLOW_ID:-unknown}" \
    >> "$LOG_FILE"

  if [[ "$MODE" == "block" ]]; then
    echo ""
    echo "🚧 Flow Checkpoint: Gate '$GATE_NAME' not passed"
    echo "   Phase: $CURRENT_PHASE"
    echo "   Reason: $GATE_REASON"
    echo "   Tool blocked: $TOOL_NAME"
    echo ""
    echo "   Pass the gate criteria before proceeding, or set GATE_MODE=warn to log without blocking."
    exit 1
  else
    echo "⚠️  Flow Checkpoint: Gate '$GATE_NAME' not verified (GATE_MODE=warn — continuing)"
    echo "   Reason: $GATE_REASON"
  fi
else
  printf '{"timestamp":"%s","event":"gate_validated","phase":%s,"gate":"%s","result":"passed","tool":"%s","flow_id":"%s"}\n' \
    "$TIMESTAMP" "$CURRENT_PHASE" "$GATE_NAME" "$TOOL_NAME" "${FLOW_ID:-unknown}" \
    >> "$LOG_FILE"
fi

exit 0
