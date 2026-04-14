---
name: strategic-flow-controller
description: 'End-to-end strategic automation skill that orchestrates a 10-phase flow (Discovery → Planning → Validation → Generation → Implementation → Testing → Review → Verification → Deployment → Monitoring) with explicit quality gates, rollback management, and structured state tracking. Eliminates gaps in the automation pipeline through mandatory phase transitions and audit-ready logging.'
---

# Strategic Flow Controller

Activate the complete end-to-end automation pipeline for any software delivery request. This skill orchestrates the full lifecycle from discovery through monitoring — with explicit quality gates, rollback safety nets, and zero tolerance for skipped phases.

## When to Use This Skill

Use the Strategic Flow Controller when you need:
- **Complete automation** of a feature, fix, or refactoring from idea to production
- **Audit-ready delivery** with traceable requirements, test coverage, and decision records
- **Governance-compliant changes** that require security validation before implementation
- **Zero-gap delivery** where every phase is validated before proceeding

Do NOT use this skill for:
- Quick one-line fixes (use direct implementation instead)
- Exploratory research with no immediate implementation intent
- Documentation-only changes

---

## Activation

When a user invokes this skill, immediately:

1. **Initialize the state file** at `.copilot-tracking/flow-state.json`
2. **Present the 10-phase overview** to the user
3. **Confirm the request** and record it as `request_summary`
4. **Activate the Flow Controller agent** (`flow-controller`)

```bash
mkdir -p .copilot-tracking .copilot-tracking/adrs
```

Initialize state:
```json
{
  "flow_id": "<generate-uuid>",
  "request_summary": "<from user>",
  "current_phase": 1,
  "phase_status": {
    "1": "pending", "2": "pending", "3": "pending", "4": "pending", "5": "pending",
    "6": "pending", "7": "pending", "8": "pending", "9": "pending", "10": "pending"
  },
  "git_checkpoints": {},
  "gate_results": {},
  "failure_history": [],
  "started_at": "<iso8601>",
  "updated_at": "<iso8601>"
}
```

---

## Phase Execution Templates

### Phase 1: DISCOVERY

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] Run `context-architect` to map affected files and dependencies
- [ ] Run `first-ask` to surface and resolve ambiguities
- [ ] Populate `phase-1-discovery.json` with structured findings
- [ ] Evaluate Gate 1 criteria
- [ ] Transition state to `passed` or `failed`

**Output file template (`phase-1-discovery.json`):**
```json
{
  "phase": 1,
  "status": "passed",
  "affected_files": [],
  "dependencies": [],
  "existing_patterns": [],
  "risks": [],
  "external_dependencies": [],
  "clarifications_needed": [],
  "completed_at": "<iso8601>"
}
```

---

### Phase 2: PLANNING

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] Record git checkpoint: `git rev-parse HEAD` → `before_phase_2`
- [ ] Run `task-planner` with discovery findings as context
- [ ] Run `structured-autonomy-plan` to generate commit-level breakdown
- [ ] Verify all three output files exist: `plan.md`, `plan-details.md`, `implementation-prompt.md`
- [ ] Evaluate Gate 2 criteria
- [ ] Present plan to user for review and confirmation

**Required files:**
- `.copilot-tracking/plan.md`
- `.copilot-tracking/plan-details.md`
- `.copilot-tracking/implementation-prompt.md`

---

### Phase 3: VALIDATION

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] Run `agent-governance-reviewer` on `plan.md` and `plan-details.md`
- [ ] Run `se-security-reviewer` security posture review
- [ ] Populate `phase-3-validation.json` with verdict and findings
- [ ] Evaluate Gate 3 criteria (verdict must be `APPROVED`)
- [ ] **Never auto-approve CRITICAL violations** — always escalate to user

**Output file template (`phase-3-validation.json`):**
```json
{
  "phase": 3,
  "status": "passed",
  "verdict": "APPROVED",
  "governance_score": 85,
  "violations": [],
  "recommendations": [],
  "approved_by": "agent-governance-reviewer",
  "completed_at": "<iso8601>"
}
```

---

### Phase 4: GENERATION

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] Run `structured-autonomy-generate` with `implementation-prompt.md` as input
- [ ] Scan generated code for placeholder patterns (`TODO`, `FIXME`, `...`)
- [ ] Validate imports are concrete and resolvable
- [ ] Populate `phase-4-generation-manifest.json`
- [ ] Evaluate Gate 4 criteria

**Output file template (`phase-4-generation-manifest.json`):**
```json
{
  "phase": 4,
  "status": "passed",
  "files_to_create": [],
  "files_to_modify": [],
  "files_to_delete": [],
  "completed_at": "<iso8601>"
}
```

---

### Phase 5: IMPLEMENTATION

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] **Record git checkpoint:** `git rev-parse HEAD` → save as `before_phase_5`
- [ ] Run `structured-autonomy-implement` with `phase-4-generation-manifest.json`
- [ ] Verify each file in manifest was applied
- [ ] Run build/compile to verify success
- [ ] Populate `phase-5-implementation.json`
- [ ] Evaluate Gate 5 criteria
- [ ] On failure: delegate to `failure-triage`, rollback to `before_phase_5` if unresolved

**Rollback command (only execute via subagent):**
```bash
git reset --hard <before_phase_5_sha>
```

---

### Phase 6: TESTING

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] Run `polyglot-test-agent` on all modified files
- [ ] Run `qa-subagent` for edge cases and error paths
- [ ] Run `playwright-tester` if web UI is involved
- [ ] Verify coverage ≥ 80% on changed files
- [ ] Run full regression suite
- [ ] Populate `phase-6-testing.json`
- [ ] Evaluate Gate 6 criteria
- [ ] On failure: delegate to `failure-triage`

---

### Phase 7: REVIEW

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] Run `gem-reviewer` for security and OWASP compliance
- [ ] Run `se-security-reviewer` for LLM/AI threat assessment (if applicable)
- [ ] Run `secrets-scanner` hook scan
- [ ] Populate `phase-7-review.json`
- [ ] Evaluate Gate 7 criteria
- [ ] **Never auto-approve CRITICAL findings** — always escalate to user

---

### Phase 8: VERIFICATION

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] Run `doublecheck` on all implementation claims
- [ ] Run `gem-critic` for design critique
- [ ] Verify all acceptance criteria from plan are independently confirmed
- [ ] Populate `phase-8-verification.json`
- [ ] Evaluate Gate 8 criteria

---

### Phase 9: DEPLOYMENT

**State transition:** `pending` → `in_progress` → `passed|failed`

**Checklist:**
- [ ] **Record git checkpoint:** `git rev-parse HEAD` → save as `before_phase_9`
- [ ] Stage all modified files
- [ ] Commit with conventional commit message referencing requirement IDs
- [ ] Push to remote branch
- [ ] Monitor CI pipeline (60-second minimum)
- [ ] Populate `phase-9-deployment.json`
- [ ] Evaluate Gate 9 criteria
- [ ] On failure: **escalate to user immediately** — never auto-retry

---

### Phase 10: MONITORING

**State transition:** `pending` → `in_progress` → `passed` → `COMPLETE`

**Checklist:**
- [ ] Aggregate metrics from all phase reports
- [ ] Generate health report with DORA-aligned metrics
- [ ] Document all gate results in summary
- [ ] Record recommendations for future improvements
- [ ] Update `flow-state.json` status to `COMPLETE`
- [ ] Populate `phase-10-monitoring.json`

**Health report template:**
```json
{
  "flow_id": "<uuid>",
  "request_summary": "<summary>",
  "started_at": "<iso8601>",
  "completed_at": "<iso8601>",
  "total_duration_minutes": 0,
  "metrics": {
    "files_changed": 0,
    "tests_added": 0,
    "coverage_delta_percent": 0,
    "security_findings_resolved": 0,
    "adrs_created": 0,
    "gate_overrides": 0
  },
  "gate_summary": {
    "1": "passed", "2": "passed", "3": "passed", "4": "passed", "5": "passed",
    "6": "passed", "7": "passed", "8": "passed", "9": "passed", "10": "passed"
  },
  "failure_history": [],
  "recommendations": []
}
```

---

## State Directory Reference

```
.copilot-tracking/
├── flow-state.json                    ← master state (required)
├── gate-overrides.json                ← audit log of gate overrides
├── traceability-map.json              ← code → requirement mappings
├── adrs/                              ← architecture decision records
│   └── ADR-001-<title>.md
├── plan.md                            ← implementation plan (phase 2)
├── plan-details.md                    ← detailed step specs (phase 2)
├── implementation-prompt.md           ← machine-readable prompt (phase 2)
├── phase-1-discovery.json
├── phase-2-planning.json
├── phase-3-validation.json
├── phase-4-generation-manifest.json
├── phase-5-implementation.json
├── phase-6-testing.json
├── phase-7-review.json
├── phase-8-verification.json
├── phase-9-deployment.json
└── phase-10-monitoring.json
```

---

## Quick Reference: Gate Pass Criteria

| Gate | Key Criteria |
|------|-------------|
| G1: Discovery → Planning | Context mapped, risks catalogued, ambiguities resolved |
| G2: Planning → Validation | Three plan files exist, no placeholders, acceptance criteria present |
| G3: Validation → Generation | Governance verdict APPROVED, score ≥ 70, zero CRITICAL violations |
| G4: Generation → Implementation | Manifest exists, zero placeholders, valid syntax |
| G5: Implementation → Testing | All files applied, build passes, no unplanned changes |
| G6: Testing → Review | Zero test failures, ≥ 80% coverage, no regressions |
| G7: Review → Verification | Security verdict PASS, zero CRITICAL findings, zero secrets |
| G8: Verification → Deployment | Claims verified, confidence ≥ 85, zero disputed claims |
| G9: Deployment → Monitoring | Push success, CI not failing |
| G10: → COMPLETE | Health report generated, state marked COMPLETE |

---

## Rollback Reference

| Situation | Rollback Target | Command |
|-----------|----------------|---------|
| Phase 5 build fails | `before_phase_5` SHA | `git reset --hard <sha>` |
| Phase 6 test regressions | `before_phase_5` SHA | `git reset --hard <sha>` |
| Phase 7 CRITICAL security | `before_phase_5` SHA | `git reset --hard <sha>` |
| Phase 9 deployment fails | Escalate to user | Never auto-rollback deployed code |
