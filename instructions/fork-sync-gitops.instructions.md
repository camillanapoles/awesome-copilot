---
applyTo: '**'
description: 'Best practices for keeping a GitHub fork continuously synchronized with its upstream repository without losing local changes. Covers branch model, sync workflows, conflict prevention, rebase vs merge decision matrix, and a pre-push checklist.'
---

# Fork Sync GitOps — Keep Your Fork Always Up to Date

## The Core Problem

A fork diverges from its upstream over time. Without a disciplined synchronization practice, upstream changes accumulate, conflicts compound, and merging becomes increasingly painful. This instruction defines the repeatable process to stay synchronized while preserving your own changes.

---

## Branch Model (Golden Rule)

Maintain a strict separation between the **mirror branch** (tracks upstream) and **work branches** (your changes):

```
upstream/main
      │
      ▼ (sync only — no direct commits)
fork/main         ← Mirror branch — always identical to upstream
      │
      ▼ (branch from here)
fork/feature/*    ← Work branches — your features and fixes
fork/fix/*
fork/docs/*
```

**Rules:**
- The mirror branch (`main` / `staged` — match whatever the upstream uses) is **read-only for development**. Never commit directly to it.
- Work branches are always branched off the mirror branch after a sync.
- Upstream changes flow in one direction: upstream → mirror → work branches.

---

## First-Time Setup

Run once after forking:

```bash
# 1. Clone your fork
git clone https://github.com/<YOUR_USER>/<REPO>.git
cd <REPO>

# 2. Add the original repository as "upstream" remote
git remote add upstream https://github.com/<ORIGINAL_ORG>/<REPO>.git

# 3. Verify remotes
git remote -v
# origin    https://github.com/<YOUR_USER>/<REPO>.git (fetch/push)
# upstream  https://github.com/<ORIGINAL_ORG>/<REPO>.git (fetch/push)

# 4. Disable push to upstream (safety guard)
git remote set-url --push upstream DISABLE

# 5. Set tracking on your mirror branch
git checkout main        # or "staged" — match the upstream default branch
git branch --set-upstream-to=upstream/main main
```

---

## Daily Sync Routine

Run **before starting any work** and **before opening a PR**:

```bash
# Step 1 — Safety checkpoint: save any uncommitted work
git stash push -m "pre-sync stash $(date +%Y-%m-%dT%H:%M)"

# Step 2 — Fetch all upstream changes (does not modify local files yet)
git fetch upstream

# Step 3 — Update the mirror branch
git checkout main
git merge --ff-only upstream/main
# If ff-only fails, upstream diverged — see "Conflict Resolution" below

# Step 4 — Push mirror to your fork on GitHub (keeps fork UI up to date)
git push origin main

# Step 5 — Rebase your work branch onto the updated mirror
git checkout feature/my-feature
git rebase main

# Step 6 — Restore stashed work (if any)
git stash pop

# Step 7 — Verify no unexpected divergence
git status
git log --oneline --graph --decorate -10
```

---

## Rebase vs Merge Decision Matrix

| Situation | Recommended Strategy | Reason |
|-----------|---------------------|--------|
| Updating your work branch with upstream changes | **Rebase** | Linear history, easier to read and bisect |
| Integrating a long-running feature branch into `main` | **Merge** | Preserves feature branch context |
| Your work branch was already pushed and shared | **Merge** | Rebasing rewrites history — breaking for others |
| Working alone on a private branch | **Rebase** | Keeps history clean |
| Many conflicts expected (complex divergence) | **Merge** | Easier to resolve conflicts interactively |
| Preparing a PR to the upstream repository | **Rebase** then squash | Presents clean, reviewable history |

**Quick rule:** if the branch is private → rebase. If the branch is shared → merge.

---

## Conflict Resolution Protocol

When `git rebase main` or `git merge` reports conflicts:

```bash
# 1. Identify conflicting files
git diff --name-only --diff-filter=U

# 2. Open each file and resolve markers
#    <<<<<<< HEAD        ← your changes
#    =======
#    >>>>>>> upstream    ← upstream changes

# 3. After resolving each file
git add <resolved-file>

# 4. Continue the rebase (or merge)
git rebase --continue
# or
git merge --continue

# 5. If the conflict is too complex, abort and start fresh
git rebase --abort
# or
git merge --abort

# 6. Recovery: return to a known-good checkpoint
git reset --hard <checkpoint-sha>   # see "Checkpoint Tags" below
```

### Conflict Priority Order

Resolve files in this order to minimize cascading issues:

1. Lock files (`package-lock.json`, `go.sum`, `Pipfile.lock`) — accept upstream, then reinstall dependencies locally
2. Configuration files (`*.yml`, `*.json` root configs) — merge carefully; both sets of changes often need to coexist
3. Generated files (`README.md` from build, `marketplace.json`) — regenerate with the build tool instead of resolving manually
4. Source code files — resolve semantically, not just textually

---

## Checkpoint Tags (Safe Recovery Points)

Create a tag before every sync operation so you can always go back:

```bash
# Before syncing
git tag checkpoint/pre-sync-$(date +%Y%m%d) HEAD

# List all checkpoints
git tag -l 'checkpoint/*'

# Recover from a checkpoint
git checkout checkpoint/pre-sync-20260416
# or hard reset a branch
git reset --hard checkpoint/pre-sync-20260416
```

---

## Anti-Conflict Long-Term Practices

- **Short-lived branches:** Merge or close work branches within days, not weeks. Branches older than two weeks accumulate compounding conflicts.
- **Sync before starting:** Always run the daily sync routine before beginning any new work.
- **Sync before PR:** Always sync and rebase immediately before opening or updating a pull request to upstream.
- **Avoid high-collision files:** Files that are frequently modified upstream (`README.md`, `package.json`, generated indexes) should not be edited on a work branch without syncing first.
- **Small, focused commits:** Commit one logical change per commit. This makes conflict resolution and `git bisect` much more effective.
- **Conventional commits:** Use the format `type(scope): message` (e.g., `feat(agent): add fork-sync agent`) so history is scannable and rollbacks are targeted.
- **Never force-push the mirror branch:** `git push --force` on `main` breaks every collaborator's local clone.

---

## Pre-Push Checklist

Before every `git push` to your fork:

- [ ] `git fetch upstream` — fetched latest upstream changes
- [ ] Mirror branch is identical to upstream (`git log --oneline main..upstream/main` shows no commits)
- [ ] Work branch is rebased on top of updated mirror (`git log --oneline upstream/main..HEAD` shows only your commits)
- [ ] No merge conflict markers in any file (`git grep -n "<<<<<<<<"`)
- [ ] Generated files are up to date (`npm run build` or equivalent)
- [ ] Commit messages follow conventional commits format
- [ ] `git status` shows a clean working tree

---

## Automating Divergence Detection

Add this to your CI pipeline (e.g., GitHub Actions) to detect when your fork falls behind upstream:

```yaml
name: Check upstream divergence

on:
  schedule:
    - cron: '0 9 * * *'   # Daily at 09:00 UTC
  workflow_dispatch:

permissions:
  contents: read

jobs:
  check-divergence:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Add upstream remote
        run: git remote add upstream https://github.com/<ORIGINAL_ORG>/<REPO>.git

      - name: Fetch upstream
        run: git fetch upstream

      - name: Count commits behind upstream
        id: divergence
        run: |
          behind=$(git rev-list --count HEAD..upstream/main)
          echo "behind=$behind" >> "$GITHUB_OUTPUT"
          echo "This fork is $behind commits behind upstream/main"

      - name: Fail if significantly behind
        if: steps.divergence.outputs.behind > 20
        run: |
          echo "::error::Fork is ${{ steps.divergence.outputs.behind }} commits behind upstream. Sync required."
          exit 1
```

---

## Governance

| Role | Responsibility |
|------|---------------|
| Fork owner | Run daily sync routine; maintain upstream remote configuration |
| All contributors | Branch from mirror after sync; never commit directly to mirror branch |
| PR author | Sync and rebase before opening a PR; resolve all conflicts locally |

**Monthly review:** Check the number of conflicts encountered, average time to resolve, and sync frequency. If conflicts are frequent, shorten the sync interval or reduce branch lifespan.
