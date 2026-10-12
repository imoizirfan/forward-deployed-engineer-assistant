---
name: ship
description: Personal executor built on an OpenSpec store — plans (design + tasks), branches, implements via fde-builder, compiles once, pauses for the developer to run it, reconciles, adds tests via fde-tester, reviews via /review-branch, and stops at sign-off with the QA handoff and PR body. Lanes small, feature and bug (from /triage). `/ship archive <id>` after merge. Invoke explicitly only.
disable-model-invocation: true
---

# /ship <id> [--lane small|feature|bug] · /ship archive <id>

Read: `~/.config/fde-assistant/kit/shared/contract.md`, `shared/store.md`, `references/gates.md`, the profile.
`K=~/.config/fde-assistant/kit`. Resume: grep status.md routing lines and continue at `stage`/`gate`.

## Lanes
- **none** — one obvious line: don't use /ship.
- **small** — one sentence of intent, one area, an existing pattern. Create the change if missing: `proposal.md`
  (≤ 15 lines), `design.md` (≤ 10 lines), `tasks.md`; log `skip_specs: true` under decisions.
- **feature** — needs `proposal.md` + `specs/` (from /groom) and `dor: ready`, or the developer says "override DoR" (logged).
- **bug** — needs `diagnosis.md` from /triage with a proven root cause (`stage: ready`), or the developer says
  "override diagnosis" (logged). No specs: the diagnosis is the contract. `design.md` (≤ 15 lines) restates the fix
  and what must not change; tasks start with the regression test. Branch prefix per `profile.conventions.branch`
  with the bug type; commit/PR type `BUG-FIX` (or the repo's equivalent).
- fde-builder returns `SCOPE:` → stop, explain, offer to promote small → feature.

## Flow
1. **Preconditions.** `openspec validate` (feature); proposal has Why / What Changes / Impact / Out of scope;
   bug lane: diagnosis.md has Root cause, Smallest safe fix and Regression test.
   `$K/bin/delta-check.sh snapshot <folder>/.delta`.
2. **Plan.** `fde-scout` brief from the specs, then `design.md` + `tasks.md` from `openspec instructions design|tasks`
   (store rules apply): build order (file → existing file to copy → layer), expected changes marked `(exists)`/`(NEW)`
   after grep, public-interface changes, variant mechanism, flags with a code fallback, test-ID tasks from `qa-cases.md`,
   tests planned. **■ GATE plan** (hard): Approve / Edit / Revise / Cancel.
3. **Branch** from `profile.repo.base_branch` (`git fetch origin <base>` → `git switch -c <name> origin/<base>`), name
   per `profile.conventions.branch`; confirm once. Dirty tree → stop and ask; never stash or discard.
4. **Implement** with `fde-builder` (change id, folder, task range). Then `delta-check.sh check`.
   **4b. Bug lane — regression test first.** Before the builder runs: `fde-tester` Stage A from diagnosis.md, then a
   Stage B dispatch limited to the regression test. Run that one test: it must fail for the diagnosed reason (log the
   failure line). Then the builder applies the fix and the test must pass after the compile in step 5. If it passes
   before the fix, the diagnosis is wrong — stop and go back to /triage.
5. **Compile once** — narrowest target per `profile.repo.knowledge.build_doc`. Errors back to the builder once; the same
   failure twice → stop.
6. **■ CHECKPOINT run** — the developer runs it. Approve / Changes (batched; one builder round + one compile per round)
   / "smoke it for me" (= `/qa run <id> --smoke`). Log each item and decision.
7. **Reconcile** decisions into the delta specs, marked `(DEV <date>)`; validate.
8. **Tests** (default on when there's logic; skip visual-only with the reason logged): `fde-tester` Stage A (specs only)
   → then a separate Stage B dispatch. Run only the new/affected tests, once.
   Bug lane: tests are never skipped, and the order changes — see step 4b.
9. **Review**: `/review-branch --change <id>`. **■ GATE triage** — accept/decline per finding; nits hidden unless asked.
10. **Fix accepted items** (product code → builder; test → tester, citing the scenario). Focused tests + one compile. One round.
11. **■ GATE sign-off** (hard): built vs not built (per AC; bug lane: the diagnosis' fix and regression test, with
    fail-before / pass-after evidence), what actually ran (never claim unrun steps), docs updates;
    the `/qa handoff` text and a PR body from `profile.repo.knowledge.pr_template`, title per `profile.conventions.pr_title`.
    Commit / push / PR only when the developer says so, with the exact message shown first.
12. `stage: done`; commit the store.

## /ship archive <id>
After merge. If the change is behind a flag or the diagnosis has an "After release, watch" section and there is no
`rollout.md`, offer `/release plan <id>` first. Then offer `/retro <id>` (it needs the change before archiving).
Then `openspec archive <id> --store <store> --yes --skip-specs`; commit the store.

Only this main session compiles or runs tests — never the agents, never one build per item.
