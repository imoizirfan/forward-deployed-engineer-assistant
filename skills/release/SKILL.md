---
name: release
description: Takes a merged change from PR to production for the FDE Assistant — `plan` writes a rollout plan (flag ramp, variants, metrics with thresholds, rollback triggers, which build carries it), `check` reads crash/analytics signals after launch and recommends hold / continue / roll back, `notes` drafts plain-language release notes for a sprint or range. Never flips a flag, ships a build or posts anything. Invoke as /release plan|check <id> or /release notes <sprint|range>.
disable-model-invocation: true
---

# /release plan <id> · /release check <id> · /release notes <sprint|from..to>

`K=~/.config/fde-assistant/kit`. Read `$K/shared/contract.md`, `$K/shared/store.md` and the profile. Change folder
from `openspec status --change <id> --store <store> --json` `.changeRoot` (archived changes: look under
`changes/archive/*-<id>`). The assistant never flips a flag, uploads a build or changes a console; it says who does.

## plan <id>
1. Read proposal/specs or diagnosis.md, design.md, status.md (`branch:`), and the PR's merge commit:
   `git -C $FDE_REPO log origin/$FDE_BASE_BRANCH --grep='<ticket>' --format='%H %s' -5`.
2. **Carrying build.** If `profile.release.tag_pattern` is set: `git tag --contains <merge sha>` filtered by it →
   the earliest per variant. None yet → "not in a release yet; next release from <base>". Pattern empty → UNKNOWN.
3. **Flags.** `$K/bin/facts.sh <flag key>` for every flag/remote-config key in the diff or design: where it is read,
   the code fallback, which variants read it. No flag → "ships dark: no — on for everyone in the carrying build".
4. Write `rollout.md`:
```
# Rollout — <id>
**Carrying build**: <tag(s) | next release | UNKNOWN> · **Variants**: <list> · **Flag**: <key (fallback <value>) | none>
## Ramp
| Stage | Who flips | Audience | Hold for | Go criteria |
## Watch (thresholds)
| Signal | Where (crash tool / analytics / dashboard) | Baseline | Alarm |
## Rollback
Trigger: <alarm or report> → action: <flag off by <who> | hotfix | revert PR> → expected time to effect
## Comms
<who to tell at each stage: QA, support, PO>
```
   Signals come from the diagnosis' "After release, watch" section, the spec's analytics rows and the crash issue
   (if any). Baselines you can't read are `UNKNOWN — read from <tool> before stage 1`.
5. status.md: log the line, `next: /release check <id> after stage 1`. Commit the store.

## check <id>
1. Read rollout.md. For each Watch row: if `profile.monitoring.crash_mcp` / `analytics_mcp` is set, load its read
   tools (ToolSearch) and fetch the current value for the carrying build/version and the affected variants; else print
   the row as a manual check ("open <tool>, filter <version, variant>, compare to <alarm>").
2. Also look for **new** crash issues in that version whose frames touch files the change modified
   (`git show --stat <merge sha>`).
3. Recommend one: **continue ramp** (all signals inside thresholds) · **hold** (data missing or borderline) ·
   **roll back** (an alarm fired — name the row). Show the evidence table.
4. Log `- <date> /release check: <recommendation> (<one-line reason>)`. When the last ramp stage is done and stable,
   set `stage: released`. Commit the store.

## notes <sprint | from..to>
1. Range: a sprint name → its date window from the tracker list name (e.g. `(dd/mm-dd/mm)`) or ask; `from..to` → git
   refs or dates. Commits: `git log origin/$FDE_BASE_BRANCH --no-merges --format='%h%x09%s' <range>`, filtered by
   `FDE_COMMIT_TAG_RE`; group by ticket id (`FDE_TICKET_ID_RE`).
2. For tickets with a change folder, use proposal "Why"/diagnosis "Symptom" for the wording; otherwise the commit title.
3. Draft `~/.config/fde-assistant/work/release-notes-<label>.md` for `profile.release.notes_audience`:
   **New**, **Improved**, **Fixed**, **Behind a flag (not visible yet)**, each line plain language with the variants
   and languages affected. No file names, no internal ids except ticket ids. Show it in a code block; never post.
