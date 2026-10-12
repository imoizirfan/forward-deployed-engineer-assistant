---
name: pr-feedback
description: Follows through on the developer's own open PR in the product repo — collects unresolved review threads and failing checks, classifies each (fix / answer / disagree / out of scope; CI product / test / flaky / infra), lets the developer triage, applies accepted fixes via fde-builder, and drafts one reply per thread. Commit, push and every reply happen only after the developer approves the exact text. Invoke as /pr-feedback [pr-number|branch].
disable-model-invocation: true
---

# /pr-feedback [pr-number | branch]

`K=~/.config/fde-assistant/kit`. Read `$K/shared/contract.md` and the profile. GitHub calls go through `FDE_GH_CMD`
(config.env), never a bare `gh` when that is set.

1. **Collect.** `$K/bin/pr-feedback.sh <arg>` (no arg = current branch of `FDE_REPO`). Find the change folder by the
   ticket id in the PR title/branch (`FDE_TICKET_ID_RE`) → `openspec list --store <store>`; none is fine.
   Make sure the local branch is the PR head and clean: `git -C $FDE_REPO status --porcelain` empty and
   `git rev-parse --abbrev-ref HEAD` = `pr.head`; else stop and ask. Never stash, reset or discard.
   `$K/bin/delta-check.sh snapshot <folder or work dir>/.delta`.
2. **Classify every unresolved thread** (read the code at `path:line` on the head; outdated threads: check whether the
   current code already addresses them):
   - **fix** — the reviewer is right; one line on the change needed.
   - **answer** — a question or misunderstanding; the reply explains with `path:line` evidence.
   - **disagree** — you think the code is right; give the reason and cite the repo's convention (`<doc> §<section>`).
     Never disagree without evidence.
   - **out of scope** — valid but not this ticket; propose a follow-up ticket.
   - **already addressed** — outdated thread fixed by a later commit; reply with the commit.
3. **Classify every failing check:** read its log (`<gh> run view <id> --log-failed`, last ~80 lines) → **product**
   (our code broke it) · **test** (a test needs updating for intended behaviour) · **flaky** (passes on rerun / unrelated
   area; cite evidence) · **infra/process** (gates, tokens, runners, tracker status gates — not fixable in code; say who owns it).
4. **■ GATE triage** — one numbered table: `# | Thread/check | Class | Proposed action | Reply draft (first line)`.
   The developer accepts, edits or declines per item. Nothing happens before this.
5. **Fix accepted items.** Product code → `fde-builder` with the thread text, `path:line` and the change folder if
   any. Tests → `fde-tester` Stage B limited to that test. Then one compile (narrowest target per the build doc) and
   only the affected tests. `delta-check.sh check`.
6. **Replies.** One per thread: plain, specific, no @-mentions, no AI attribution; "fix" replies name what changed
   (filled in with the commit sha after pushing). Keep each to 1–3 lines.
7. **Outward actions, each confirmed with the exact payload in this turn, in order:**
   a. commit (message per `profile.conventions.commit`) → b. push → c. the replies (show all; the developer may approve
   all or some) via `<gh> api graphql` `addPullRequestReviewThreadReply` → d. optionally a check rerun
   (`<gh> run rerun <id> --failed`) for items classified flaky. Never resolve threads (the reviewer does), never
   request reviewers, never merge.
8. Log to status.md if there is a change: `- <date> /pr-feedback: <n> fixed, <n> answered, <n> declined`; add
   `waiting:` `- <reviewer> · re-review PR #<n> · since <date>` after pushing.
