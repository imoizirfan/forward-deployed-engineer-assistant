# Writing to the tracker (the only allowed path)

1. Draft the full text into the change folder `drafts/<kind>-<n>.md`, ending with a plain marker line
   `ref fde:<ticket>:<kind>:v<n>`.
2. Idempotency: read the target's comments; if one already contains that marker, don't post — offer to edit it.
3. Show the exact text and ask: "Post this to <task name>? (yes / edit / no)". Only a plain yes in this turn counts.
4. Post, then immediately record `tracker: comment=<id> marker=<marker>` in status.md.
5. Never: @-mentions, status/assignee/field changes, AI attribution, posting anywhere other than the confirmed task.

## Creating a task (only /intake)
Same rules, different payload. Draft `drafts/ticket-<n>.md` with the exact title, the exact body and the target list
(name and id). Show all three and ask "Create this task in <list>? (yes / edit / no)". Before creating, search the
list for the same title; if found, offer to link it instead. On yes, create it with title and body only — no
assignee, status, priority, tags or custom fields — then record `tracker: task=<id>` in status.md.
