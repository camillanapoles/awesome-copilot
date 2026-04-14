---
applyTo: '**'
description: 'Auto-activates the 10-phase strategic flow controller for every Copilot agent interaction. Injects pipeline orchestration, quality gates, traceability enforcement, and failure triage into all tasks regardless of file type or context.'
---

# Strategic Flow Auto-Activation

This instruction applies globally to **all files and all agent interactions**. It ensures the strategic automation pipeline is always active and enforced.

## Mandatory Pipeline Entry

When any Copilot agent begins a task:

1. **Identify the current pipeline phase** by checking `.copilot-tracking/flow-state.json` if it exists, or defaulting to Phase 1 (DISCOVERY).
2. **Do not proceed** to implementation until DISCOVERY and PLANNING phases are complete.
3. **Gate every phase transition** using the criteria in `instructions/quality-gates.instructions.md`.
4. **Record traceability** for every change using `instructions/end-to-end-traceability.instructions.md`.

## Phase Reference

| Phase | Name | Entry Gate |
|-------|------|-----------|
| 1 | DISCOVERY | Task received, context undefined |
| 2 | PLANNING | Context mapped, risks catalogued |
| 3 | VALIDATION | Plan generated, dependencies identified |
| 4 | GENERATION | Governance approved, zero security violations |
| 5 | REVIEW | Code generated, traceability recorded |
| 6 | TESTING | Review comments resolved |
| 7 | SECURITY | All tests passing, coverage met |
| 8 | DEPLOYMENT | Zero critical vulnerabilities |
| 9 | VERIFICATION | Deployment succeeded |
| 10 | MONITORING | Acceptance criteria verified |

## Agent Delegation Rules

- **Never implement directly** without completing DISCOVERY (Phase 1) and PLANNING (Phase 2).
- **Delegate failures** to `agents/failure-triage.agent.md` when any phase gate fails.
- **Escalate blockers** — do not silently continue past a failed gate.
- **The Flow Controller** (`agents/flow-controller.agent.md`) is the authoritative orchestrator. All other agents are subagents that receive delegated work.

## State Persistence

The `hooks/flow-checkpoint/` hook automatically:
- Saves pipeline state to `.copilot-tracking/flow-state.json` on session end.
- Validates gate criteria before any tool use (`preToolUse`).
- Initialises the pipeline state at session start if no state file exists.

## Zero-Gap Guarantee

No work may be committed unless:
- It is traceable to a requirement (Phase 1 output).
- It has corresponding test coverage (Phase 6 output).
- It has passed security scanning (Phase 7 output).
- The audit log records all phase transitions.
