---
name: fde
description: Status board for the FDE Assistant across every ticket in the OpenSpec store — what is at which stage and gate, who you are waiting on and for how long, and a weekly stakeholder update drafted from the ledgers. Use for /fde, /fde board, /fde waiting, /fde update, or "what's on my plate", "what am I blocked on", "write my weekly update". Read-only; never posts or sends anything.
---

# /fde — board · waiting · update

`K=~/.config/fde-assistant/kit`. Read `$K/shared/contract.md` and the profile. All data comes from
`$K/bin/ledger.sh` (status.md of every change) plus git; never re-derive what a status.md already records.

## /fde (or /fde board)
1. `$K/bin/ledger.sh`. Sort: changes at a gate first (the developer owes a decision), then by `oldest_wait_days`
   descending, then by `last_log` oldest first.
2. Print one table:

| Change | Lane | Stage | Gate | Waiting on (oldest) | Last activity | Next |
|---|---|---|---|---|---|---|

3. Below it, at most three one-line nudges: a gate waiting on the developer, a dependency older than
   `FDE_STALE_DAYS`, a change with no activity for 7+ days ("still active? archive or block it").

## /fde waiting
1. `$K/bin/ledger.sh --waiting`; group by `who`, oldest first, with ages.
2. For each line older than `FDE_STALE_DAYS`, draft a short, polite nudge the developer can paste (what is needed,
   why it blocks, the date asked; no @-mentions). Show drafts in chat. Never send or post them.

## /fde update [--since 7d]
Draft the developer's weekly update for their lead or PO.
1. Window: `--since` (default 7 days). Sources, in this order:
   - `ledger.sh --all` and the `log:` lines dated inside the window in each change's status.md;
   - merged commits in the window: `git -C $FDE_REPO log origin/$FDE_BASE_BRANCH --since=<window> --format='%s'`,
     keeping titles that match `FDE_COMMIT_TAG_RE`.
2. Write `~/.config/fde-assistant/work/update-<yyyy-mm-dd>.md` and show it in chat inside a code block:
```
Update — <date range>
Shipped: <ticket title in plain words> (one line each; released ones first)
In progress: <ticket> — <stage>, next: <plain next step>
Blocked on: <who> — <what> (since <date>)
Risks: <only real ones with a reason>
Next week: <top 3>
```
Plain language: no file paths, change ids only where the reader knows them (ticket ids). Keep it to one phone screen.
Nothing is posted; the developer pastes it.
