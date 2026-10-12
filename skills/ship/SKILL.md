---
name: ship
description: Personal executor built on an OpenSpec store — plans (design + tasks), branches, implements via fde-builder, compiles once, pauses for the developer to run it, reconciles, adds tests via fde-tester, reviews via /review-branch, and stops at sign-off with the QA handoff and PR body. Lanes small and feature. `/ship archive <id>` after merge. Invoke explicitly only.
disable-model-invocation: true
---

# /ship <id> [--lane small|feature] · /ship archive <id>

Read: `~/.config/fde-assistant/kit/shared/contract.md`, `shared/store.md`, `references/gates.md`, the profile.
`K=~/.config/fde-assistant/kit`. Resume: grep status.md routing lines and continue at `stage`/`gate`.

## Lanes
- **none** — one obvious line: don't use /ship.
- **small** — one sentence of intent, one area, an existing pattern. Create the change if missing: `proposal.md`
  (≤ 15 lines), `design.md` (≤ 10 lines), `tasks.md`; log `skip_specs: true` under decisions.
- **feature** — needs `proposal.md` + `specs/` (from /groom) and `dor: ready`, or the developer says "override DoR" (logged).
- fde-builder returns `SCOPE:` → stop, explain, offer to promote small → feature.

## Flow
1. **Preconditions.** `openspec validate` (feature); proposal has Why / What Changes / Impact / Out of scope.
   `$K/bin/delta-check.sh snapshot <folder>/.delta`.
2. **Plan.** `fde-scout` brief from the specs, then `design.md` + `tasks.md` from `openspec instructions design|tasks`
   (store rules apply): build order (file → existing file to copy → layer), expected changes marked `(exists)`/`(NEW)`
   after grep, public-interface changes, variant mechanism, flags with a code fallback, test-ID tasks from `qa-cases.md`,
   tests planned. **■ GATE plan** (hard): Approve / Edit / Revise / Cancel.
3. **Branch** from `profile.repo.base_branch` (`git fetch origin <base>` → `git switch -c <name> origin/<base>`), name
   per `profile.conventions.branch`; confirm once. Dirty tree → stop and ask; never stash or discard.
4. **Implement** with `fde-builder` (change id, folder, task range). Then `delta-check.sh check`.
5. **Compile once** — narrowest target per `profile.repo.knowledge.build_doc`. Errors back to the builder once; the same
   failure twice → stop.
6. **■ CHECKPOINT run** — the developer runs it. Approve / Changes (batched; one builder round + one compile per round)
   / "smoke it for me" (= `/qa run <id> --smoke`). Log each item and decision.
7. **Reconcile** decisions into the delta specs, marked `(DEV <date>)`; validate.
8. **Tests** (default on when there's logic; skip visual-only with the reason logged): `fde-tester` Stage A (specs only)
   → then a separate Stage B dispatch. Run only the new/affected tests, once.
9. **Review**: `/review-branch --change <id>`. **■ GATE triage** — accept/decline per finding; nits hidden unless asked.
10. **Fix accepted items** (product code → builder; test → tester, citing the scenario). Focused tests + one compile. One round.
11. **■ GATE sign-off** (hard): built vs not built (per AC), what actually ran (never claim unrun steps), docs updates;
    the `/qa handoff` text and a PR body from `profile.repo.knowledge.pr_template`, title per `profile.conventions.pr_title`.
    Commit / push / PR only when the developer says so, with the exact message shown first.
12. `stage: done`; commit the store.

## /ship archive <id>
After merge: `openspec archive <id> --store <store> --yes --skip-specs`; commit the store.

Only this main session compiles or runs tests — never the agents, never one build per item.
