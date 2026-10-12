---
name: scope
description: Fast feasibility and impact answers for your product repo during planning or grooming meetings — "can we…", "how big is…", "what does this touch…", "is this doable", or a pasted ticket/list asking for a verdict. Also `/scope sprint <list>` for a pre-meeting table of a whole sprint and `/scope deep <q>` for an unhurried answer. Read-only. Not for implementing, deep grooming or writing specs.
---

# /scope — feasibility & impact (read-only)

Read `~/.config/fde-assistant/kit/shared/contract.md` and the profile. Writes nothing in the product repo; posts nothing.
`K=~/.config/fde-assistant/kit`.

## Modes
- `/scope <question>` (or model-triggered) → **ask** · `/scope <ticket url|id…>` → **ticket**
- `/scope sprint <list url | name>` → **sprint** · `/scope deep <question|ticket>` → **deep**

## ask / ticket — meeting speed
Budget: **≤ 6 tool calls, issued in parallel in one message**, then answer. Target 60–90 s. No doc reading.
1. Pick 2–4 distinctive terms (screen, model, config key, event, endpoint).
2. In parallel: `$K/bin/facts.sh <terms>`; `$K/bin/analogs.sh <terms>`; for tickets the tracker read tool on the
   ticket (and parent) — load tracker tools via ToolSearch in the same message first; at most 2 `Read`s of the top hit;
   and one `grep -i -A3 '<capability or term>' $FDE_STORE_PATH/decisions.md $FDE_STORE_PATH/calibration.tsv` (memory
   from /retro; missing files are fine).
3. Answer with the card. If evidence is thin, say so and offer `/scope deep`.

### Verdict card (≤ 12 lines)
```
**<subject>** — <Doable | Doable with caveats | Needs backend | Needs design | Needs product | Not feasible as stated> · confidence <high|med|low> (<why>)
Size: <S|M|L|XL> (<days>) — analog: <id · files · +/->
Where: <area → screen/service> (<path:line>)
Variants: <who reaches it; differences from real code branches, or "no variant branching">
Data: <API field | config key | hardcoded> — <client-only? server/config change?>
Reuse: <existing component/helper, path>
Depends on: <backend (client already has the endpoint? else "needs backend confirmation") · design · copy · flag>
Blast radius: <shared screens/data>
Ask in the room: 1) … 2) … (≤3 questions that would change the verdict)
```
Memory: with ≥ 5 rows in calibration.tsv add "calibrated: your <S> took a median <n>d (n=<k>)" to the Size line; a
matching decisions.md line becomes one extra line `Past decision: <date> <decision> (<id>)`.
Rules: no claim without a path:line from this session; content driven by remote config or an API is called out (it may
be a data change, not a release).

## sprint — before the meeting
1. Resolve the list (url/id, or by name in `profile.tracker.sprints_folder_id`); fetch its tasks; keep tasks with
   `profile.tracker.task_prefix` (and parents with no platform subtask yet).
2. Dispatch one `fde-scout` per ticket **in parallel, foreground** (one message, many Agent calls).
3. Write `~/.config/fde-assistant/work/sprint-<name>.md` and print:

| Ticket | Verdict | Size | Area | Variants | Key risk | Open Qs | DoR |
|---|---|---|---|---|---|---|---|

Then cross-ticket notes: shared files/areas (conflicts, sequencing), shared backend dependencies, platform-pairing
gaps, total load. Plain markdown.

## deep
One `fde-scout` (foreground) with the question; render the card plus the brief's UNKNOWNS. No call cap; still read-only.
