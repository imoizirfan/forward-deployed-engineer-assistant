---
name: qa
description: Personal QA specialist. `/qa cases <id>` writes test cases from an OpenSpec change before implementation; `/qa run <id> [TC…]` executes cases on a simulator/emulator/browser with screenshots; `/qa automate <id> [TC…]` turns cases into tests in a QA-workbench MCP (save + run on one device); `/qa handoff <id|branch>` writes a short paste-to-QA message. Invoke explicitly only.
disable-model-invocation: true
---

# /qa

Read: `~/.config/fde-assistant/kit/shared/contract.md`, `shared/store.md`, `references/case-schema.md`, the profile
(`qa:` section). Change folder from `openspec status --change <id> --store <store> --json | jq -r .changeRoot`.

## /qa cases <id>
Precondition: specs exist (ideally `stage: ready`; otherwise warn the cases rest on assumptions).
1. Read `specs/**/spec.md`, `grooming.md` (open Qs, out of scope), `ticket.md`.
2. **Variant behaviour classes from code:** `facts.sh` on the touched screen/data → which variants reach it and where
   code, folders or per-variant config defaults diverge. One representative per class; start from
   `profile.behaviour_classes`, adjust to evidence.
3. Write cases per the schema: every AC ≥ 1 functional case; negative/edge (empty config, long values, offline);
   RTL/number formats per language; regression per shared surface; analytics (unit via `profile.qa.mock_trackers`,
   e2e manual unless the workbench exposes analytics).
4. Write `qa-cases.md` (table + **Automation needs** = elements lacking a UI test identifier, checked against
   `profile.qa.locator_catalog` and the screen's source) and `qa-cases.csv`.
5. Update status.md, commit the store. Chat: counts by priority/type/automation, automation needs, path.

## /qa run <id> [TC…] [--smoke]
Runner from `profile.qa.runner`. Ask once: variant/build scheme, device, cases. Build only on yes.
1. If a QA workbench is configured and it proxies traffic, check its network status first; never build while it holds
   the machine proxy. Use a different device than the workbench drives.
2. iOS: Simulator MCP `build` → `control attach` (so the developer can watch) → `launch`. Android/browser: the
   available emulator or browser tools.
3. Per case: deep link (`profile.variants[*].deep_link_scheme`) or taps; screenshot each expected-result step into
   `qa-runs/<date>/<TC>-<step>.png`; API expectations via the workbench's traffic tools if present, else "API not verified".
4. `| TC | Result (pass/fail/blocked) | Evidence | Note |` → `qa-runs/<date>/results.md` and chat. `--smoke` = P0 only, one class.

## /qa automate <id> [TC…]
Needs `profile.qa.mcp.name`. Tool names come from `profile.qa.mcp.tools`.
1. `~/.config/fde-assistant/kit/bin/mcp-check.sh` must print `healthy`; otherwise show its fix and stop.
2. List devices → pick one simulator/emulator; confirm with the developer once.
3. Per case (Automation = Workbench UI or Mocked; never anything in `never_run_categories`):
   - Prefer a recording (it carries locators and the suite's house rules — follow them exactly).
   - Else use the nearest existing test as exemplar and locators from the catalog; mark the file DRAFT.
   - Save (fix every validator finding), then run with explicit test paths and that device id. The `qa-run-guard`
     hook blocks anything broader. **Max 2 attempts**, changing the test between them. Then fetch the report.
4. Record test path, attempts, result in `qa-cases.md`.

## /qa handoff <id|branch>
If `profile.repo.knowledge.qa_handoff_format` is set, read that file now and follow it exactly. Otherwise:
one message, fits a phone screen, layman language (no file/class names), in a code block:
```
[FEATURE | BUG FIX | REFACTORING] <Short title>

*Impacted areas*
- <existing screen/flow> – <how>

*What to test*
1. <where to tap / what to do> → <what should happen>   [TC-n]
```
Inputs: branch diff vs base, plus `qa-cases.md`, out of scope and declined review findings when a change exists.
Output only; write nothing; send nothing.
