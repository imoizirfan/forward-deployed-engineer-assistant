---
name: triage
description: Diagnoses a bug or crash in the product repo from evidence — a tracker ticket, a pasted crash stack or log, a screenshot description or plain prose — and writes diagnosis.md (reproduction, root cause with path:line, the change that introduced it, blast radius across variants and languages, the same defect elsewhere, the smallest safe fix, the regression test that proves it) into a new OpenSpec change for `/ship --lane bug`. Read-only on the product repo. Invoke as /triage <ticket|stack|text>.
disable-model-invocation: true
---

# /triage <ticket url|id | pasted stack/log | description>

`K=~/.config/fde-assistant/kit`. Read `$K/shared/contract.md`, `$K/shared/store.md`, the profile, and
`$K/shared/ticket-fetch.md` when given a ticket. Never edit product code here; diagnosis comes before any fix.

1. **Intake.** Ticket → fetch it (with comments; crash links and repro steps often live there). Pasted stack/log →
   keep it verbatim. Note platform, app version, variant, language, device/OS if given.
2. **Change folder.** id = `<ticket>-<slug>` or `bug-<yyyymmdd>-<slug>`. `openspec new change <id> --store <store>`;
   folder from `openspec status --json` `.changeRoot`. Write `ticket.md` (snapshot or the pasted evidence) and
   status.md with `lane: bug`, `stage: diagnosing`. `$K/bin/delta-check.sh snapshot <folder>/.delta`.
3. **Symbols first.** If the stack has only addresses or obfuscated frames, write `UNKNOWN: unsymbolicated frames —
   <how to symbolicate per the repo's build doc>` and work from the readable frames and the description. Never map an
   address to a source line by guesswork.
4. **Evidence, in parallel (one message):**
   - `$K/bin/facts.sh <2-4 terms>` — readable frame symbols, screen names, error strings, keys.
   - `git -C $FDE_REPO log -S'<symbol>' --oneline -15` and, once a suspect line is known,
     `git log -L<start>,<end>:<file> --oneline -5` → the change that introduced or last altered it.
   - `$K/bin/analogs.sh <terms>` → past fixes in the same area.
   - If `profile.monitoring.crash_mcp` is set: load its read tools via ToolSearch and fetch the issue's counts, first
     and last seen version, affected OS/devices, breadcrumbs. Else write `monitoring: not configured`.
   - `fde-scout` (foreground) with a **diagnose** brief: the symptom, the frames, the suspected area; ask for CURRENT,
     VARIANTS, LANGUAGES, BLAST RADIUS and UNKNOWNS for that code path.
5. **Reason to a root cause.** State it only when the evidence chain is complete (trigger → code path → faulty
   line). Otherwise give ranked hypotheses, each with the test that would confirm or kill it. Scan for the same defect
   pattern elsewhere (`git grep` the faulty idiom) — those are part of the blast radius, not part of the fix unless
   the developer says so.
6. **Write `diagnosis.md`:**
```
# Diagnosis — <id>
**Symptom**: <what the user sees> · **Seen in**: <versions / variants / languages / OS> · **Impact**: <counts or UNKNOWN>
## Reproduction (confidence high|med|low)
1. … → expected … / actual …
## Root cause
<one paragraph> — <path:line> · introduced by <sha subject (date)> | UNKNOWN
## Hypotheses (only if root cause is not proven)
| # | Hypothesis | Evidence for/against | How to confirm |
## Blast radius
<variants, languages, shared screens/data; same pattern at path:line …>
## Smallest safe fix
<what changes, where; what must not change (public interfaces, other variants)>
## Regression test
<suite › name — must FAIL before the fix and PASS after; what it asserts>
## After release, watch
<crash issue / event / metric and the threshold that says it is fixed>
## Unknowns
```
7. status.md: `stage: ready` when the root cause is proven (else `blocked` with `pending:` listing what would prove
   it), `size:` from the fix scope, `next: /ship <id> --lane bug`. Add a `waiting:` line if you need something from
   someone (logs, a device, access). Commit the store; `delta-check.sh check`.
8. **Chat:** the symptom line, root cause (or top hypothesis) with path:line, blast radius in one line, the regression
   test, and `next`. Offer — never post — a short tracker comment with the diagnosis via `tracker-write.md`.
