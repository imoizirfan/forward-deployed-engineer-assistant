# Gates

| Gate | Hard? | Shown | Options | Logged |
|---|---|---|---|---|
| plan | hard | design summary (build order, expected changes, public-surface changes, tests), tasks | Approve / Edit / Revise / Cancel | `gate: plan → approved <date>` |
| run | checkpoint | what changed, how to see it (scheme, screen path, deep link), compile result | Approve / Changes / Smoke it for me | each change item + decision |
| triage | hard | numbered findings (severity, path:line, one line) | accept/decline per item; "show nits" | declined items with reason |
| signoff | hard | built vs not built, ran vs not ran, docs updates, handoff text, PR body | Commit / Commit+push / Commit+push+PR / Not yet | final decision |

A gate is only passed by the developer's words in the current turn. "Looks good" at a gate = approve that gate only.
Never combine two gates into one question.
