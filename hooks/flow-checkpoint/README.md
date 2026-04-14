---
name: 'Flow Checkpoint'
description: 'Saves pipeline state between phases and validates quality gates before any phase transition in the strategic automation pipeline. Prevents gap accumulation by enforcing gate criteria at session boundaries.'
tags: ['automation', 'quality-gates', 'pipeline', 'checkpointing', 'e2e']
---

# Flow Checkpoint Hook

Saves pipeline state at session boundaries and validates quality gates before phase transitions, ensuring the strategic automation pipeline cannot advance past a failed gate even across multiple Copilot sessions.

## Overview

The strategic automation pipeline spans 10 phases that may be executed across multiple Copilot sessions. Without checkpointing, a session ending mid-phase could leave the pipeline in an inconsistent state where gates are bypassed and quality guarantees are lost.

This hook runs at two lifecycle events:

- **`preToolUse`** — Before any file edit or command execution: validates that the current phase's prerequisites are met
- **`sessionEnd`** — At session termination: saves the current pipeline state and records a git checkpoint SHA

## Features

- **State persistence:** Saves `.copilot-tracking/flow-state.json` on every session end
- **Git checkpoints:** Automatically records the current commit SHA before critical phases
- **Gate pre-validation:** Warns (or blocks) when a tool invocation would advance past an unverified gate
- **Structured logging:** JSON Lines audit log for all checkpoint events
- **Zero dependencies:** Uses only standard Unix tools (`git`, `jq` if available)
- **Graceful degradation:** Falls back to regex parsing if `jq` is unavailable

## Installation

1. Copy the hook folder to your repository:

   ```bash
   cp -r hooks/flow-checkpoint .github/hooks/
   ```

2. Make the scripts executable:

   ```bash
   chmod +x .github/hooks/flow-checkpoint/checkpoint.sh
   chmod +x .github/hooks/flow-checkpoint/validate-gates.sh
   ```

3. Create the required directories and add to `.gitignore`:

   ```bash
   mkdir -p .copilot-tracking .copilot-tracking/adrs
   mkdir -p .github/logs/copilot/flow-checkpoint
   echo ".github/logs/" >> .gitignore
   ```

4. Commit the hook configuration to your repository's default branch.

## Configuration

The hook is configured in `hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": ".github/hooks/flow-checkpoint/validate-gates.sh",
        "cwd": ".",
        "env": {
          "GATE_MODE": "warn"
        },
        "timeoutSec": 10
      }
    ],
    "sessionEnd": [
      {
        "type": "command",
        "bash": ".github/hooks/flow-checkpoint/checkpoint.sh",
        "cwd": ".",
        "timeoutSec": 30
      }
    ]
  }
}
```

### Environment Variables

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `GATE_MODE` | `warn`, `block` | `warn` | `block` prevents tool use when gate is not passed; `warn` logs only |
| `SKIP_FLOW_CHECKPOINT` | `true` | unset | Disable the hook entirely |
| `FLOW_LOG_DIR` | path | `.github/logs/copilot/flow-checkpoint` | Directory for checkpoint logs |
| `COPILOT_TRACKING_DIR` | path | `.copilot-tracking` | State directory for the pipeline |

## How It Works

### Session End (checkpoint.sh)

1. Checks if a flow state file exists in `.copilot-tracking/flow-state.json`
2. If found, reads the current phase and status
3. Records the current git commit SHA in the state file under `git_checkpoints`
4. Updates the `updated_at` timestamp
5. Writes a structured log entry with the checkpoint details

### Pre-Tool-Use (validate-gates.sh)

1. Reads the flow state file to determine the current phase
2. Checks if the invoked tool is a file-modification or execution tool
3. If the current phase's prerequisites (previous phase gate) are not satisfied, emits a warning or blocks
4. Logs the validation result

## Log Format

Checkpoint events are written to `.github/logs/copilot/flow-checkpoint/checkpoint.log`:

```json
{"timestamp":"2026-01-01T10:00:00Z","event":"checkpoint_saved","phase":5,"phase_status":"in_progress","git_sha":"abc123","flow_id":"uuid"}
{"timestamp":"2026-01-01T10:00:01Z","event":"gate_validated","phase":4,"gate":"generation_to_implementation","result":"passed"}
{"timestamp":"2026-01-01T10:00:02Z","event":"gate_warning","phase":3,"gate":"validation_to_generation","result":"not_passed","mode":"warn"}
```

## Customization

- **Change gate mode to block:** Set `GATE_MODE=block` in `hooks.json` to prevent tool use when gates are not passed
- **Custom tracking directory:** Set `COPILOT_TRACKING_DIR` to use a non-default state location
- **Add custom gate criteria:** Extend `validate-gates.sh` with additional checks for your project

## Disabling

To temporarily disable checkpointing:

- Set `SKIP_FLOW_CHECKPOINT=true` in the hook environment
- Or remove the entries from `hooks.json`
