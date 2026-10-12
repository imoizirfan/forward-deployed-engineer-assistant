# Writing to the tracker (the only allowed path)

1. Draft the full text into the change folder `drafts/<kind>-<n>.md`, ending with a plain marker line
   `ref fde:<ticket>:<kind>:v<n>`.
2. Idempotency: read the target's comments; if one already contains that marker, don't post — offer to edit it.
3. Show the exact text and ask: "Post this to <task name>? (yes / edit / no)". Only a plain yes in this turn counts.
4. Post, then immediately record `tracker: comment=<id> marker=<marker>` in status.md.
5. Never: @-mentions, status/assignee/field changes, AI attribution, posting anywhere other than the confirmed task.
