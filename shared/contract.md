# Assistant contract (every skill and agent reads this first)

Paths: kit = `~/.config/fde-assistant/kit` · profile = `~/.config/fde-assistant/profile.yaml` · scripts = `<kit>/bin/`.
Read the profile before anything else. If it is missing, stop and tell the developer to run `install.sh`.

**Precedence.** The developer explicitly invoked their personal assistant. If the product repo's agent docs route
multi-stage work to a team pipeline, that one routing rule is superseded for this invocation. Every other rule in the
repo's docs still applies (coding rules, verification rules, docs-maintenance rules). Never start a team pipeline.

**Read, don't copy.** Conventions live in the repo (`profile.repo.knowledge`). Cite them as `<doc> §<section>`; never
paraphrase a convention into an artifact. Read a module's guide when working in it; beyond that, at most one doc
section unless the doc *is* the task (testing rules when writing tests).

**Evidence.** Every claim about code carries a `path:line` you verified by grep in this session. Unknowns are written
`UNKNOWN: <what> — <how to find out>`, never guessed.

**Fast facts.** `<kit>/bin/facts.sh <terms…>` (one grep battery) and `<kit>/bin/analogs.sh <terms|area>` (similar past
tickets with size). Prefer them to ad-hoc grepping.

**Where artifacts go.** Only the OpenSpec store (`FDE_STORE` in config.env; see `shared/store.md`). Never write
planning files into the product repo. A writing skill starts with `<kit>/bin/delta-check.sh snapshot <change>/.delta`
and ends with `delta-check.sh check <change>/.delta`, reporting the result.

**Outward actions need the exact payload confirmed by the developer in the current turn:** tracker writes, commit,
push, PR, attachment downloads, app builds, any QA-workbench run / mock / device change. No AI attribution when
`profile.conventions.ai_attribution` is `never`.

**status.md** (in the change folder) is the resume ledger. Read it with
`grep -E '^(stage|gate|dor|next|pending|tracker):' status.md`. Append one ≤120-char line per transition under `log:`;
decisions are dated one-liners under `decisions:` and are never asked again.
