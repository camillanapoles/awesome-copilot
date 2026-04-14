---
applyTo: '*'
description: 'Defines mandatory quality gate criteria for each phase transition in the strategic end-to-end automation pipeline. Every transition from one phase to the next requires explicit verification of these criteria before proceeding.'
---

# Quality Gates — End-to-End Pipeline Transition Criteria

These instructions define the mandatory quality gates that must pass before any phase transition in the strategic automation pipeline. **No phase may be skipped. No gate may be waived without explicit user approval and documented justification.**

## What Are Quality Gates?

Quality gates are explicit, verifiable criteria that must be satisfied before work progresses from one phase to the next. They exist to prevent the accumulation of technical debt, security debt, and quality debt across the pipeline.

Each gate is evaluated by a dedicated verification agent — never by the agent that performed the work.

---

## Gate 1: DISCOVERY → PLANNING

**Purpose:** Ensure sufficient context exists before any planning work begins.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| Context map is complete — all affected files identified | Read `.copilot-tracking/phase-1-discovery.json`; `affected_files` must be non-empty |
| All first-order dependencies are identified | `dependencies` field is populated |
| Risks are catalogued (even if the list is empty with justification) | `risks` field exists with content or documented empty justification |
| All blocking ambiguities are resolved | `clarifications_needed` is empty or each item has a resolution |
| No duplicate or contradictory information in findings | Manual review of discovery document |

### Gate Verdict

- **PASS:** All criteria met — proceed to PLANNING
- **FAIL:** Any criterion unmet — return to DISCOVERY subagent with specific gaps identified

---

## Gate 2: PLANNING → VALIDATION

**Purpose:** Ensure the plan is complete, unambiguous, and ready for governance review.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| `plan.md` exists and is non-empty | File system check |
| `plan-details.md` exists with per-step specifications | File system check |
| `implementation-prompt.md` exists as machine-readable prompt | File system check |
| Plan has at least one step with explicit acceptance criteria | Parse plan structure |
| No `[NEEDS CLARIFICATION]` markers remain | Grep for placeholder text |
| Each step specifies: files affected, what changes, how to test | Structured review |
| Effort estimates present for each step (S/M/L) | Parse plan metadata |
| No step depends on an undefined external system | Dependency validation |

### Gate Verdict

- **PASS:** All criteria met — proceed to VALIDATION
- **FAIL:** Return to PLANNING with specific deficiencies listed

---

## Gate 3: VALIDATION → GENERATION

**Purpose:** Confirm governance and security clearance before code is generated.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| Governance verdict is `APPROVED` | Read `.copilot-tracking/phase-3-validation.json` |
| Zero CRITICAL governance violations | `violations` contains no CRITICAL items |
| Zero HIGH governance violations (or each has documented acceptance) | `violations` HIGH items have documented user acceptance |
| Governance score ≥ 70/100 | Read `governance_score` field |
| No data exfiltration risk identified | Review `violations` for exfiltration category |
| No hardcoded secrets in the plan | Secret pattern scan on plan documents |
| Least-privilege principle confirmed | Governance review includes privilege assessment |

### Gate Verdict

- **PASS:** All criteria met — proceed to GENERATION
- **FAIL:** Return to PLANNING for plan revision; governance failures are never auto-approved

---

## Gate 4: GENERATION → IMPLEMENTATION

**Purpose:** Ensure generated code is complete and unambiguous before being applied.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| Generation manifest exists listing all files | Read `.copilot-tracking/phase-4-generation-manifest.json` |
| No placeholder comments in generated code | Grep for `TODO`, `FIXME`, `...`, `// implement`, `# implement`, `/* TODO */` |
| All imports are concrete and resolvable | Static analysis of import statements |
| Error handling is present for all external calls | Code review of generated output |
| Generated code is syntactically valid | Language-specific syntax check |
| Each generated function/method has a corresponding test stub | Verify test coverage plan |

### Gate Verdict

- **PASS:** All criteria met — proceed to IMPLEMENTATION
- **FAIL:** Return to GENERATION with specific gaps; do not apply incomplete code

---

## Gate 5: IMPLEMENTATION → TESTING

**Purpose:** Verify all changes were applied correctly and the system still compiles.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| All files in generation manifest are applied | Cross-reference manifest with actual file system |
| Build/compilation succeeds with zero errors | Read `.copilot-tracking/phase-5-implementation.json`: `build_result == "success"` |
| No files outside the manifest were modified | `git diff --name-only` compared to manifest |
| No merge conflicts introduced | `git status` check |
| No new linting errors introduced | Run linter on modified files |
| Build output contains zero warnings classified as errors | Review `build_output` field |

### Gate Verdict

- **PASS:** All criteria met — proceed to TESTING
- **FAIL:** Delegate to `failure-triage` agent with build error context

---

## Gate 6: TESTING → REVIEW

**Purpose:** Confirm the implementation is functionally correct before security review.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| All tests pass (zero failures) | Read `.copilot-tracking/phase-6-testing.json`: `tests_failed == 0` |
| Line coverage on changed files ≥ 80% | `coverage_percentage >= 80` |
| No regressions in existing test suite | `regressions_found` is empty |
| Edge cases are covered (null, empty, boundary, error paths) | QA subagent report confirms coverage |
| Tests are deterministic (no flaky tests) | All tests pass on two consecutive runs |
| Test names are descriptive and follow project conventions | Manual review of generated test names |

### Gate Verdict

- **PASS:** All criteria met — proceed to REVIEW
- **FAIL:** Delegate to `failure-triage` agent with test failure details

---

## Gate 7: REVIEW → VERIFICATION

**Purpose:** Confirm the implementation is secure before independent verification.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| Security review verdict is `PASS` | Read `.copilot-tracking/phase-7-review.json`: `verdict == "PASS"` |
| Zero CRITICAL severity findings | No CRITICAL items in `findings` |
| Zero HIGH severity findings (or each has documented acceptance) | HIGH items have user-approved acceptance |
| Zero secrets found in code | `secrets_found` is empty |
| OWASP Top 10 categories assessed | `owasp_coverage` lists all 10 categories |
| All dependencies checked for known CVEs | Dependency scan included in review |
| No hardcoded environment-specific values | Configuration review passed |

### Gate Verdict

- **PASS:** All criteria met — proceed to VERIFICATION
- **FAIL:** Return to IMPLEMENTATION for security remediation; security gates are never waived automatically

---

## Gate 8: VERIFICATION → DEPLOYMENT

**Purpose:** Confirm all claims about the implementation are independently verifiable.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| Verification verdict is `PASS` | Read `.copilot-tracking/phase-8-verification.json`: `verdict == "PASS"` |
| Zero DISPUTED claims | `claims_disputed` is empty |
| Zero fabrication risks identified | `fabrication_risks` is empty |
| Confidence score ≥ 85/100 | `confidence_score >= 85` |
| All acceptance criteria from the plan are independently verified | Cross-reference plan criteria with verification results |
| Design critique (gem-critic) findings are resolved or accepted | Critique findings documented with disposition |

### Gate Verdict

- **PASS:** All criteria met — proceed to DEPLOYMENT
- **FAIL:** Return to the appropriate phase based on the nature of disputed claims

---

## Gate 9: DEPLOYMENT → MONITORING

**Purpose:** Confirm deployment succeeded and CI pipeline is healthy.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| Git push succeeded | Read `.copilot-tracking/phase-9-deployment.json`: `push_status == "success"` |
| CI pipeline is not failing | `ci_status` is `pass` or `pending` (never `fail`) |
| Commit SHA is recorded | `commit_sha` field is non-empty |
| Commit message follows conventional commits format | Parse commit message structure |
| No force push was used | Verify standard push was used |
| Branch protection rules were respected | CI/CD platform confirmation |

### Gate Verdict

- **PASS:** All criteria met — proceed to MONITORING
- **FAIL:** Escalate to user immediately; never auto-retry deployment failures

---

## Gate 10: MONITORING → COMPLETE

**Purpose:** Confirm the flow is complete with a documented health baseline.

### Required Evidence

| Criterion | Verification Method |
|-----------|-------------------|
| Health report generated | Read `.copilot-tracking/phase-10-monitoring.json` |
| Deployment metrics recorded (files changed, tests added, coverage delta) | Health report contains metrics |
| All 9 previous gate results are summarised | Gate summary included in report |
| Recommendations for future improvements documented | `recommendations` field is populated |
| Flow state updated to `COMPLETE` | Read `.copilot-tracking/flow-state.json`: `current_phase == "COMPLETE"` |

### Gate Verdict

- **PASS:** Flow is COMPLETE
- **FAIL:** Return to MONITORING agent with specific gaps

---

## Gate Override Protocol

In exceptional circumstances, a gate may be overridden. This requires:

1. **User explicit approval** — The user must explicitly type "OVERRIDE GATE [n]" to confirm.
2. **Documented justification** — The reason must be written to `.copilot-tracking/gate-overrides.json`.
3. **Risk acceptance** — The user must acknowledge the risk of proceeding without the gate.
4. **Audit trail** — Override is logged permanently and cannot be deleted.

**Gates that can NEVER be overridden:**
- Gate 3 (security validation) — if CRITICAL violations exist
- Gate 7 (security review) — if CRITICAL findings or secrets found
- Gate 9 (deployment) — if push fails; deployment must succeed or not proceed

---

## Gate Evaluation Cadence

- Gates are evaluated **after** each phase, **before** the next phase begins.
- Gate evaluation is always performed by a **separate subagent** from the one that did the work.
- Gate results are persisted in `.copilot-tracking/phase-N-*.json` files for audit purposes.
- Failed gates generate a structured failure report routed to the `failure-triage` agent.
