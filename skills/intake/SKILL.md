---
name: intake
description: Turns a raw request that has no ticket yet — a chat thread URL, pasted messages, meeting notes, an email or a screenshot description — into a drafted tracker ticket with problem, proposed scope, out of scope, affected variants, top open questions and a quick feasibility line, inside a new OpenSpec change. Creates the tracker task only after the developer approves the exact title, body and list. Invoke as /intake <thread url | pasted text>.
disable-model-invocation: true
---

# /intake <thread url | pasted text | notes>

`K=~/.config/fde-assistant/kit`. Read `$K/shared/contract.md`, `$K/shared/store.md`, `$K/shared/tracker-write.md`
("Creating a task") and the profile.

1. **Read the source.** A chat URL with `profile.intake.chat_mcp` set → load its read tools (ToolSearch) and fetch
   the thread with replies. No chat MCP → ask the developer to paste it. Images → describe only what's visible.
   Keep who said what, with dates; requests often change mid-thread — the latest agreed version wins, earlier ones
   go under "Superseded".
2. **Is there already a ticket?** Search the tracker (read tools) for 2–3 key terms. A likely match → show it and ask
   "Use <task> instead?" before drafting anything.
3. **Change folder.** id = `intake-<yyyymmdd>-<slug>`; `openspec new change <id> --store <store>`; status.md with
   `stage: intake`. Save the raw source as `source.md`. `$K/bin/delta-check.sh snapshot <folder>/.delta`.
4. **Quick reality check** (≤ 4 calls, parallel): `$K/bin/facts.sh <terms>`, `$K/bin/analogs.sh <terms>`. This is
   a /scope-speed check, not a deep dive.
5. **Draft `drafts/ticket-1.md`:**
```
Title: <imperative, ≤ 70 chars, per the tracker's naming style seen in recent tasks>
List: <profile.intake.default_list or the current sprint list> (<id>)
---
Problem: <in the requester's words, quoted with name and date>
Proposed scope: <bullets>
Out of scope: <bullets>
Variants / languages: <from profile.variants, what the request implies; "UNKNOWN — confirm" when not said>
Open questions:
1. <top questions only, ≤ 5, from the groom gap checklist headings: scope edges, variants, states, analytics, flag, backend>
Feasibility: <Doable | Doable with caveats | Needs backend | Needs design | Needs product> · size <S|M|L|XL> — <where, path:line>
Source: <thread link or "pasted by <developer> on <date>">
ref fde:<id>:intake:v1
```
   Plain language for product readers: no file paths in the body except the feasibility line.
6. status.md: `size:`, `next: create the task or /groom`, a `waiting:` line if a question must go back to the requester.
   Commit the store; `delta-check.sh check`.
7. **Chat:** the draft in a code block, then "Create this task in <list>? (yes / edit / no)". Only on a plain yes in
   this turn: create per tracker-write.md, record `tracker: task=<id>`, rename nothing, and say
   `next: /groom <task id>` (grooming creates its own change; this intake folder stays as the source record).
