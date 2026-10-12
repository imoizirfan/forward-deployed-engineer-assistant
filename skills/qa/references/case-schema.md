# Test case schema

Columns (markdown table and CSV, same order):
`TC | AC | Title | Priority | Type | Variants | Language | Preconditions | Steps | Expected | Automation | Test IDs needed`

- **TC**: `TC-1…`, stable once written; append, never renumber.
- **AC**: `AC-n`, or `regression` / `—`.
- **Priority**: P0 release blocker · P1 AC edge / main regression · P2 nice to have.
- **Type**: functional · negative · edge · regression · analytics · RTL · a11y.
- **Variants**: a behaviour class from the profile or explicit codes.
- **Language**: per `profile.variants[*].languages`, or `both`/`all`.
- **Steps**: numbered, screens named as the app shows them; deep link if one exists.
- **Expected**: observable; for numbers say which digits/format, for RTL the reading order.
- **Automation**: `Workbench UI` (QA-workbench UI assertion; needs stable test IDs) · `Mocked` (workbench with a bound
  mock) · `Live (manual)` (real backend; the developer runs it) · `Sim-run` (/qa run with screenshots) ·
  `Unit` (name the test) · `Manual — <reason>`.
- **Test IDs needed**: existing identifiers, or `MISSING: <element>` (feeds "Automation needs").

Coverage floor: each AC × each affected language × each variant class that reaches it, at least once; one regression
case per shared surface; one analytics case per event touched (or "Analytics: none" noted).
