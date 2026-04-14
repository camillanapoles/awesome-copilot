# Strategic Automation Plugin

End-to-end strategic automation framework with a 10-phase flow controller, quality gates, failure triage, traceability enforcement, and pipeline checkpointing. Eliminates gaps in the software delivery lifecycle from discovery through monitoring.

## Installation

```bash
# Using Copilot CLI
copilot plugin install strategic-automation@awesome-copilot
```

## What's Included

### Agents

| Agent | Description |
|-------|-------------|
| `flow-controller` | Strategic end-to-end orchestrator implementing a 10-phase state machine with mandatory quality gates, rollback management, and structured audit logging |
| `failure-triage` | First-responder agent that classifies failures by type (build, test, security, logic, performance, accessibility, governance, deployment), routes to specialist agents, and escalates when retries are exhausted |

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/strategic-automation:strategic-flow-controller` | Activate the full 10-phase end-to-end automation pipeline for any software delivery request |

## The 10-Phase Pipeline

```
Phase 1: DISCOVERY      → Map context, dependencies, and risks
Phase 2: PLANNING       → Create deterministic, machine-readable plan
Phase 3: VALIDATION     → Governance and security clearance
Phase 4: GENERATION     → Generate complete, copy-paste-ready code
Phase 5: IMPLEMENTATION → Apply changes to the repository
Phase 6: TESTING        → Automated test generation and execution
Phase 7: REVIEW         → Security and quality review
Phase 8: VERIFICATION   → Independent claim verification
Phase 9: DEPLOYMENT     → Commit, push, and CI validation
Phase 10: MONITORING    → Health baseline and compliance confirmation
```

Each phase is gated by explicit quality criteria. No phase can be skipped.

## Gap Coverage

This plugin addresses the following gaps in standard automation pipelines:

| Gap | Solution |
|-----|---------|
| No inter-agent communication | Flow Controller as central delegation hub |
| No state machine | Explicit 10-phase state with transition enforcement |
| No quality gates between phases | Mandatory gate criteria per transition |
| No rollback mechanism | Git checkpoints before phases 5 and 9 |
| No failure routing | Failure Triage Agent with specialist delegation |
| No traceability | End-to-end traceability instructions (included separately) |

## Companion Resources

For complete gap elimination, use alongside:

- **Instructions:** `quality-gates.instructions.md` — detailed gate criteria
- **Instructions:** `end-to-end-traceability.instructions.md` — code/test/requirement traceability
- **Hook:** `flow-checkpoint` — session-boundary state saving and gate pre-validation
- **Workflow:** `strategic-flow-health-report.md` — periodic pipeline health monitoring

## Source

This plugin is part of [Awesome Copilot](https://github.com/github/awesome-copilot), a community-driven collection of GitHub Copilot extensions.

## License

MIT
