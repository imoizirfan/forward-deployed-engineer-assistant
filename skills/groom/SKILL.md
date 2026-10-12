---
name: groom
description: Personal ticket groomer. Turns a tracker ticket (+ parent spec, sibling platform tickets, comments) into an OpenSpec change with a Definition-of-Ready verdict, a question table with recommended answers, evidence-backed gaps, an analytics draft and draft acceptance criteria. Sub-modes `post` (draft one tracker comment, post only on confirm) and `settle` (fold answers back in). Invoke as /groom <ticket>, /groom post <id>, /groom settle <id>.
disable-model-invocation: true
---

# /groom

Read: `~/.config/fde-assistant/kit/shared/contract.md`, `shared/store.md`, `shared/ticket-fetch.md`,
`shared/tracker-write.md` (post/settle only), `references/gap-checklist.md`. Store id = `FDE_STORE` from
`~/.config/fde-assistant/config.env`; pass `--store <id>` always. `K=~/.config/fde-assistant/kit`.

## /groom <ticket url|id>
1. **Fetch** per ticket-fetch.md — task, parent, siblings, **all comments**, attachment list. Offer downloads only.
2. **Change folder.** id = `<ticket>-<slug>` (2–4 words). If it exists, resume from status.md. Else
   `openspec new change <id> --store <store>`; folder = `.changeRoot` from `openspec status --json`. Write `ticket.md`
   and `status.md` (skeleton in store.md). `$K/bin/delta-check.sh snapshot <folder>/.delta`.
3. **Reality check.** Dispatch `fde-scout` (foreground) with the title and the spec's key nouns; in parallel run
   `facts.sh` on the 2–3 most specific terms. The code is ground truth for the ticket's claims.
4. **Gap analysis.** Walk every dimension of the checklist. A gap counts only with evidence (ticket quote or
   path:line) and an "effect if ignored". Decisions already made in comments are recorded as answered, with author and date.
5. **Drafts.**
   - `proposal.md` and `specs/<capability>/spec.md` from `openspec instructions proposal|specs --change <id> --store <store> --json`
     (store rules: behaviour-titled requirements, `**AC**: AC-n`, `(ASSUMPTION Qn)`, GIVEN/WHEN/THEN tagged
     `[variant, language]`, explicit out of scope, analytics row). Capabilities from `profile.capabilities`.
   - `grooming.md`:
     ```
     # Grooming — <id>
     **DoR**: not-ready | ready-with-assumptions | ready — <why>
     ## Questions
     | Q | Question | Why it matters | Recommended answer | Blocking | Owner | Status |
     ## Gaps (evidence)
     | # | Gap | Evidence | Effect if ignored |
     ## Analytics draft   (event · trigger · params · dedupe · destinations — per the repo's analytics doc; or "none — confirm")
     ## Size & analogs
     ## Risks
     ## Out of scope (proposed)
     ```
   DoR: `ready` = no blocking Qs; `ready-with-assumptions` = every blocking Q has a recommended answer; else `not-ready`.
6. `openspec validate <id> --store <store>`; fix format errors. Update status.md; commit the store; run
   `delta-check.sh check`.
7. **Chat output only:** the DoR line, blocking questions (id + question + recommended answer), the folder path, and
   "next: /groom post <id>".

## /groom post <id>
Draft ONE comment for where the spec lives (`profile.tracker.spec_lives_on`), grouped by owner:
```
Grooming questions — <ticket>
Product: Q1 … (recommended: …)
Design: …
Backend: …
Proposed acceptance criteria: AC-1 … (one line each)
Proposed out of scope: …
ref fde:<ticket>:groom:v<n>
```
Plain language, no file paths, no @-mentions. Then follow tracker-write.md exactly.

## /groom settle <id>
1. Read replies to the recorded comment plus answers the developer gives in chat; quote each with author.
2. Update the Q-table, add dated `decisions:` lines, rewrite affected ACs (drop `(ASSUMPTION Qn)` when answered).
3. Recompute DoR; when ready set `stage: ready`, `next: /qa cases <id>`. Validate; commit the store.
4. Offer (don't post) a short "final ACs" comment via tracker-write.md.
