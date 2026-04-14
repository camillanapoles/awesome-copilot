---
name: "Strategic Flow Health Report"
description: 'Generates a periodic health report of the strategic automation pipeline, summarising completed flows, phase failure rates, quality gate pass rates, and pipeline health trends. Posts the report as a GitHub issue for team visibility.'
on:
  schedule: weekly on Mondays
permissions:
  contents: read
  issues: write
safe-outputs:
  create-issue:
    title-prefix: "[flow-health] "
    labels: [report, automation, quality]
---

## Strategic Flow Health Report

Generate a comprehensive health report for the strategic automation pipeline based on the `.copilot-tracking/` state files across the repository.

## What to Include

### 1. Pipeline Activity Summary

- Number of flows initiated in the reporting period
- Number of flows completed successfully (reached Phase 10)
- Number of flows abandoned or rolled back
- Average flow duration (start to Phase 10 completion)

### 2. Phase Failure Analysis

For each of the 10 phases, report:
- How many flows passed through this phase successfully
- How many flows failed at this phase
- Most common failure reasons at this phase
- Average retries needed before passing

Highlight phases with failure rates above 20% as requiring attention.

### 3. Quality Gate Pass Rates

For each of the 10 quality gates (Gate 1 through Gate 10), report:
- Gate pass rate (percentage of first-attempt passes)
- Number of gate overrides logged in `gate-overrides.json`
- Most common gate failure criteria

Flag gates where the override rate exceeds 10% as requiring review.

### 4. Failure Triage Efficiency

From failure triage reports across all flows:
- Most frequent failure categories (build, test, security, logic, performance, accessibility, governance, deployment)
- Average attempts needed to resolve each category
- Number of failures escalated to user vs. resolved autonomously

### 5. Security and Governance Metrics

- Number of flows with CRITICAL security findings in Phase 7
- Number of governance violations detected in Phase 3
- Number of secrets found and remediated in Phase 7
- Average governance score across all validated flows

### 6. Traceability Coverage

From `traceability-map.json` files:
- Percentage of flows with complete requirement traceability
- Percentage of modified files with ≥ 80% test coverage
- Number of ADRs created across all flows
- Number of orphan changes (files with no linked requirement)

### 7. Deployment Health

- Deployment success rate (Phase 9 first-attempt pass rate)
- Average CI pipeline pass time
- Number of rollbacks triggered
- Number of deployment escalations to user

### 8. Recommendations

Based on the metrics above, provide 3-5 actionable recommendations to improve pipeline health, such as:
- Phases with consistently high failure rates may indicate missing context in Phase 1
- High gate override rates may indicate gate criteria need calibration
- Frequent security findings may indicate a gap in Phase 3 governance review

## Report Format

Structure the report as a GitHub issue with the following sections:
1. Executive Summary (3-5 bullet points of key findings)
2. Phase Activity Table
3. Gate Pass Rate Table
4. Top Failure Categories Chart (as markdown table)
5. Security and Governance Highlights
6. Recommendations
