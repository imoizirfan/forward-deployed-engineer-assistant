# Fetching a ticket

Use the tracker MCP named in `profile.tracker.mcp` (kind in `profile.tracker.kind`); load its read tools with
ToolSearch first. For ClickUp, e.g.
`ToolSearch select:mcp__plugin_productivity_clickup__clickup_get_task,mcp__plugin_productivity_clickup__clickup_get_task_comments,mcp__plugin_productivity_clickup__clickup_get_threaded_comments`.
Other trackers: the equivalent get-issue / comments tools; the steps below don't change. `kind: none` → ask the developer to paste the ticket text.

1. Get the task with description, custom fields, attachments and subtasks.
2. If `profile.tracker.spec_lives_on` is `parent` and the task has a parent, fetch the parent the same way — the spec
   is there. Identify siblings by `profile.tracker.sibling_prefixes`; fetch their description and status.
3. Comments on the task and the parent, plus threaded replies. Design links often live in comments.
   **Comments frequently contain decisions that change scope — never skip them.**
4. Attachments: list name, type, size. Do not download; offer "Download <name> (<size>)? (y/n)".
5. Design: if a design-tool MCP is connected, read the linked frames; else record `design: not inspected`.

Flag contradictions, don't resolve them: fields vs title, a "not needed" field vs what the code does, empty test-case
field, status already past grooming.

Snapshot (`ticket.md` in the change folder):
```
# <id> <title>
**Ticket**: <url> **Parent**: <id> <title> **Siblings**: <id status…> **Status**: <status> **Sprint**: <list>
**Fields**: <name>=<value> · …
## Spec (verbatim or faithful summary)
## Task description (if different)
## Comments (author · date · text)
## Attachments (name · size · downloaded?)
## Contradictions spotted
```
