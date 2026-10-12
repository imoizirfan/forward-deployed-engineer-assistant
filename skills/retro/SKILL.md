---
name: retro
description: The FDE Assistant's learning loop. `/retro <id>` after a change merges records estimate vs actual (calibration.tsv), copies its dated product decisions into the store's decision memory and captures platform friction; `/retro sprint` summarises estimate accuracy and recurring friction and drafts a note for the platform or team lead. /scope reads the results to calibrate sizes and recall past decisions. Writes only to the store; never posts. Invoke as /retro <id> or /retro sprint [name].
disable-model-invocation: true
---

# /retro <id> · /retro sprint [name]

`K=~/.config/fde-assistant/kit`. Read `$K/shared/contract.md`, `$K/shared/store.md` and the profile. Store root =
`FDE_STORE_PATH`. Run before `/ship archive` when possible (archived changes work too).

## /retro <id>
1. **Calibrate.** `$K/bin/calibrate.sh <id>` → show the row (estimate vs actual days, files, +/-). If status.md has
   no `size:`, say so; the row still records the actual.
2. **Decision memory.** Take the dated lines under `decisions:` in status.md (and `(DEV <date>)` reconciliations in
   the specs). Append them to `$FDE_STORE_PATH/decisions.md` under `## <capability>` (from the spec folder name or
   `profile.capabilities`; else `## general`), each as `- <date> <decision> — <id> (<who>)`. Skip lines already
   present (same date and text).
3. **One question** (AskUserQuestion, free text allowed): "What slowed this down that the platform or process could
   fix?" with 3 options drawn from evidence (the longest gap between commits and what happened then in `log:`;
   repeated build or CI failures; review rounds) plus "Nothing notable". Append the answer to
   `$FDE_STORE_PATH/platform-feedback.md` as `- <date> <id>: <answer>`.
4. Log `- <date> /retro: est <size> vs <n>d actual` in status.md. Commit the store.

## /retro sprint [name]
1. Window: the sprint's dates (from the tracker list name, or ask). Rows from `calibration.tsv` dated in it, plus all
   rows for the overall trend.
2. **Estimate accuracy:** a table per size bucket (first token of `estimate`): `| Size | n | median actual days |
   range | your stated range |`. Call out a bucket only with n ≥ 3.
3. **Friction:** group `platform-feedback.md` lines in the window by theme; recurring themes (≥ 2) first.
4. Draft `~/.config/fde-assistant/work/retro-<name>.md`: accuracy table, top friction themes with the change ids as
   evidence, and a short note to the platform/team lead proposing at most 3 concrete fixes. Show it; never post.

## How /scope uses this
`calibration.tsv` with ≥ 5 rows → the verdict card's Size line adds "calibrated: your <S> took a median <n>d (n=<k>)".
`decisions.md` lines under the matching capability → one "Past decision:" line on the card.
