---
name: review-branch
description: Reviews the current local branch of the product repo (diff vs merge base with the base branch, optionally uncommitted and untracked files) with AC-by-AC conformance when an OpenSpec change is given, then quality against the repo's own conventions. Never posts anything. Invoke as /review-branch [--base <b>] [--change <id>] [--include-uncommitted].
disable-model-invocation: true
---

# /review-branch

`K=~/.config/fde-assistant/kit`. Read `$K/shared/contract.md` and the profile.

**External reviewer.** If `FDE_REVIEW_CMD` is set in `~/.config/fde-assistant/config.env`, run it with the developer's
arguments from the product repo, read the markdown file whose path it prints, and skip to step 4.

1. `D=$(mktemp -d)/review`; run `$K/bin/branch-diff.sh "$D" [--base …] [--include-uncommitted]`.
2. With `--change <id>`: resolve the change folder (`openspec status --change <id> --store <store> --json | jq -r .changeRoot`).
3. Dispatch `fde-reviewer` (foreground) with the diff dir and the change folder path. It is read-only.
4. Show the developer: the conformance table (Implemented / Partial / Missing / Extra), then numbered findings, severity
   first, each with `path:line`; collapse nits to a count unless asked.
5. With a change: save the review to `<change>/reviews/<short-sha>.md`. From `/ship`, return to its triage gate.

Nothing is posted anywhere and no files in the product repo are edited.
