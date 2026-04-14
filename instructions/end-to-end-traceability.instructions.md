---
applyTo: '*'
description: 'Enforces end-to-end traceability between code changes, tests, and requirements throughout the strategic automation pipeline. Every change must be traceable to a requirement, every file must have test coverage, and significant decisions must be recorded as ADRs.'
---

# End-to-End Traceability

Every change in the codebase must be traceable forward to a requirement and backward from a test. This instruction defines the traceability contract that all agents and contributors must uphold.

## Why Traceability Matters

Without traceability:
- Changes cannot be audited against requirements
- Test coverage cannot be measured per requirement
- Regression detection cannot attribute failures to specific changes
- Architectural decisions are lost over time

With traceability:
- Every PR links to a requirement
- Every requirement has test coverage
- Every significant decision has an ADR
- Every failure can be traced to a specific change

---

## The Three Traceability Contracts

### Contract 1: Code → Requirement

Every code change must be linked to a requirement.

**How to fulfil this contract:**

1. Before writing any code, identify the requirement it satisfies.
2. Record the mapping in `.copilot-tracking/traceability-map.json`:

```json
{
  "mappings": [
    {
      "requirement_id": "REQ-001",
      "requirement_summary": "User can reset password via email",
      "files_changed": ["src/auth/reset.ts", "src/email/templates/reset.html"],
      "commit_sha": "<sha>",
      "pr_number": 42,
      "phase": 5,
      "changed_at": "<iso8601>"
    }
  ]
}
```

3. Reference the requirement in the commit message:
   ```
   feat(auth): implement password reset flow

   Implements REQ-001: User can reset password via email.
   Closes #42
   ```

**Requirement ID Sources (in priority order):**
- GitHub Issue number (e.g., `#42` → `REQ-GH-42`)
- Plan step number from `.copilot-tracking/plan.md` (e.g., `STEP-3` → `REQ-PLAN-3`)
- User story number if using a project management tool (e.g., `US-12`)
- If none of the above exist, use the flow ID and phase (e.g., `REQ-FLOW-abc123-PHASE-5`)

### Contract 2: File → Test Coverage

Every modified file must have corresponding test coverage.

**How to fulfil this contract:**

For every file listed in the implementation manifest, at least one of the following must exist:
- A unit test in the corresponding test file (e.g., `src/auth/reset.ts` → `tests/auth/reset.test.ts`)
- An integration test that exercises the file's exported functions
- An E2E test that covers the feature the file implements

**Test-file naming conventions by language:**
| Language | Pattern |
|----------|---------|
| TypeScript/JavaScript | `*.test.ts`, `*.spec.ts`, `__tests__/*.ts` |
| Python | `test_*.py`, `*_test.py` |
| Go | `*_test.go` |
| Java | `*Test.java`, `*Spec.java` |
| C# | `*Tests.cs`, `*Specs.cs` |
| Rust | `#[cfg(test)]` module in same file |

Record the coverage mapping in `.copilot-tracking/traceability-map.json`:

```json
{
  "coverage_map": [
    {
      "source_file": "src/auth/reset.ts",
      "test_files": ["tests/auth/reset.test.ts"],
      "coverage_percentage": 87,
      "uncovered_lines": [45, 67],
      "requirement_ids": ["REQ-GH-42"]
    }
  ]
}
```

### Contract 3: Decision → ADR

Any significant architectural or design decision must be recorded as an Architecture Decision Record (ADR).

**When to write an ADR:**

Write an ADR when you are making a decision that:
- Cannot easily be reversed without significant rework
- Affects multiple files or components
- Involves choosing between multiple viable alternatives
- Introduces a new dependency
- Changes a cross-cutting concern (authentication, logging, error handling, etc.)
- Deviates from an existing pattern in the codebase

**ADR Format:**

Save ADRs to `.copilot-tracking/adrs/ADR-<number>-<title-slug>.md`:

```markdown
# ADR-001: [Title of the Decision]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN
**Deciders:** [agent or person names]

## Context

[What is the issue that motivates this decision? What forces are at play?]

## Decision

[What is the change being proposed or that was decided?]

## Consequences

### Positive
- [Positive consequence 1]
- [Positive consequence 2]

### Negative
- [Negative consequence or trade-off 1]

### Neutral
- [Neutral consequence or constraint]

## Alternatives Considered

### Alternative 1: [Name]
- **Why rejected:** [reason]

### Alternative 2: [Name]
- **Why rejected:** [reason]

## Related Requirements
- REQ-[id]: [summary]
```

---

## Traceability Verification Checklist

Before any phase gate passes, the traceability agent must verify:

### Before Phase 5 (Implementation)
- [ ] Every step in the plan has a `requirement_id` assigned
- [ ] The traceability map template is created with placeholders

### After Phase 5 (Implementation)
- [ ] Every modified file has a `requirement_id` in `traceability-map.json`
- [ ] Every modified file appears in at least one test file reference

### After Phase 6 (Testing)
- [ ] Coverage map is populated for all source files
- [ ] Coverage percentage is ≥ 80% for all modified files
- [ ] Uncovered lines are documented with justification

### After Phase 7 (Review)
- [ ] All ADRs for this change are written and accepted
- [ ] ADR numbers are referenced in the traceability map

### Before Phase 9 (Deployment)
- [ ] `traceability-map.json` is complete and valid JSON
- [ ] All `requirement_ids` reference a real requirement source
- [ ] Commit message references at least one requirement

---

## Traceability Gap Detection

When generating the traceability map, flag the following as gaps:

| Gap Type | Definition | Action |
|----------|-----------|--------|
| **Orphan change** | File modified with no linked requirement | Block gate; require requirement assignment |
| **Untested file** | Modified file with no test coverage | Block gate; require test creation |
| **Stale ADR** | Decision made > 30 days ago not yet recorded | Warn; recommend ADR creation |
| **Coverage below threshold** | File coverage < 80% | Block gate; require additional tests |
| **Missing commit reference** | Commit message lacks requirement ID | Block deployment gate; require amend |

---

## Integration with `.copilot-tracking/`

The traceability system integrates with the Flow Controller's state directory:

```
.copilot-tracking/
├── flow-state.json              ← current pipeline state
├── traceability-map.json        ← code → requirement mappings
├── adrs/                        ← architecture decision records
│   ├── ADR-001-*.md
│   └── ADR-002-*.md
├── phase-1-discovery.json
├── phase-2-planning.json
├── ...
└── phase-10-monitoring.json
```

All traceability files must be committed alongside the code changes they document.

---

## Minimum Traceability Standards

| Standard | Requirement |
|----------|-------------|
| Requirement coverage | 100% of changed files must have at least one requirement ID |
| Test coverage | ≥ 80% line coverage on all changed files |
| ADR completeness | All non-trivial decisions have an ADR within the same PR |
| Commit hygiene | All commits reference a requirement ID |
| Traceability map | Exists and is valid JSON before deployment |
