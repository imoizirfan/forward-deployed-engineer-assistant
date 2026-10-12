---
name: fde-setup
description: Onboarding for the FDE Assistant — inspects the current repo, asks only what it cannot detect, and writes the personal config (config.env, profile.yaml, facts.tsv) under ~/.config/fde-assistant, then installs and smoke-tests. Use when the user says "set up the FDE assistant", "onboard this repo", "configure fde", runs /fde-setup, or /fde-setup switch <project> / list. Not for grooming or building tickets.
---

# /fde-setup — configure the assistant for a project

Goal: a working setup in one short session, with every value either **detected with evidence** or **chosen by the
user**. Nothing is written until the user approves the exact files. Nothing is written inside the product repo except
the optional gitignored `.claude/settings.local.json` that install.sh manages.

`K=~/.config/fde-assistant/kit` (missing → tell the user to clone the repo and run `./install.sh` first, then stop).
`H=~/.config/fde-assistant`. Projects live in `$H/projects/<name>/`; the active one is wired in by symlinks
`$H/config.env`, `$H/profile.yaml`, `$H/facts.tsv` → `projects/<name>/…`.

## Modes
- `/fde-setup` → onboard the current repo (or the path given).
- `/fde-setup list` → `ls $H/projects`, mark the active one (`readlink $H/profile.yaml`).
- `/fde-setup switch <name>` → repoint the three symlinks to `projects/<name>/`, run `$K/install.sh`, then
  `$K/install.sh --check`. Done.

## Onboard

### 1. Discover (no questions yet)
- Repo = `git rev-parse --show-toplevel` of the cwd (or the given path). Not a git repo → ask for the path.
- Run `$K/bin/detect.sh <repo>` and read the JSON. Facts it gives: languages, base-branch candidates, agent/contributor
  docs and module guides, doc candidates, PR template, test dirs, commit samples and id style, variant hints and URL
  schemes, signal counts (flags/analytics/test ids/i18n), registered MCP servers, OpenSpec, whether
  `.claude/settings.local.json` is gitignored.
- Read only headings of the root guide and doc candidates (`grep -n '^#' <file>`) to map: coding rules, testing rules,
  build instructions, analytics conventions (record as `<file> §<heading>` when a section, not a file, holds it).
- If the repo has its own agent pipeline skills in `.claude/skills/` or its root guide routes work to a team
  pipeline, note their names (candidates for `FDE_SUPPRESS_SKILLS` so they don't auto-trigger).
- Existing project config in `$H/projects/<name>/` → load it; this run updates it.

### 2. Propose, then ask only the gaps
Build a draft for every key in `$K/templates/config.env.example` and `$K/templates/profile.example.yaml`.
Derive, don't ask, when evidence is clear:
- base branch: `develop` if it exists and receives merges, else origin HEAD.
- `FDE_SRC_GLOBS` from languages; `FDE_TEST_PATTERN` from test dirs; excludes from build/vendor dirs present.
- ticket-id regex from commit samples (hash-style `[a1b2c3d]`, Jira `ABC-123`, or GitHub `#123`); branch and commit
  conventions from samples (`feature/<ticket>-<slug>` etc.).
- variants from scheme/target/flavor hints and URL schemes (strip helper targets: extensions, scaffolds, tests).
- docs mapping from step 1.
- `release.tag_pattern` from `release_tags` (e.g. `release_us_v2.4.0` → `^release_[a-z]+_v[0-9]+\.[0-9]+\.[0-9]+$`); none → empty.
- `monitoring.crash_mcp` / `analytics_mcp` and `intake.chat_mcp` from `env.mcp_servers` when exactly one server
  clearly fits (crash: firebase/crashlytics/sentry/bugsnag; analytics: firebase/amplitude/mixpanel; chat:
  slack/teams). Several candidates → ask; none → leave empty (those features fall back to manual checklists).
- `FDE_GH_CMD`: `gh` if `gh auth status` succeeds for the repo's host and `gh repo view` works inside the repo;
  otherwise ask which command reaches it (e.g. an `env GH_CONFIG_DIR=… gh` prefix for a second account).

Ask with **AskUserQuestion** (≤ 4 questions per call, recommended option first, label "(Recommended)") only for:
1. **Tracker** — options from detected MCP servers (ClickUp, Linear, Jira/Atlassian, …) + "None". With ClickUp
   connected, offer to look up ids: call its hierarchy tool and let the user pick the space and the sprints folder.
   Ask for a platform task prefix only if commit/branch samples or tickets suggest one.
2. **Variants** — confirm the detected list (multiSelect) when there is more than one candidate.
3. **QA** — runner (iOS simulator / Android emulator / browser / none) and whether one of the MCP servers is a QA
   workbench (then which tool runs tests, and which suites must never be run by the assistant, e.g. live-backend ones).
4. **Store location** — default `~/fde-specs/<name>`; offer a private-git option.
Anything still uncertain gets a sensible default plus a `# TODO(confirm): …` comment, not another question.

### 3. Tune facts.tsv against the real repo
Start from `$K/templates/facts.example.tsv`, adapt pathspecs and filters to the stack (e.g. Swift: `getValue(for:`,
`accessibilityIdentifier`; Android: `BuildConfig`, `testTag`; web: `data-testid`). For each section, test it with
`FDE_HOME=$H/projects/<name> $K/bin/facts.sh <a term found in that category>` and drop sections that return nothing.
Pick the probe terms from real code (`git grep -m3 -i <keyword>`), not invented ones.

### 4. Show, confirm, write
Show the three files (or a diff against the existing ones) in full, in chat. Ask: "Write these to
`$H/projects/<name>/` and make it the active project? (yes / edit / no)". On yes:
- `mkdir -p $H/projects/<name>`; back up any existing file to `*.bak`; write the three files.
- Replace `$H/config.env`, `$H/profile.yaml`, `$H/facts.tsv` with symlinks to them (if they are regular files from an
  earlier install, move them into `$H/projects/<previous-name>/` first, reading FDE_REPO to name it).
- Never write secrets: tokens belong in `claude mcp add --header …` or the OS keychain, never in these files.

### 5. Install and smoke-test
- `$K/install.sh` then `$K/install.sh --check`; show the output.
- Smoke: `$K/bin/facts.sh <a term from the newest feature commit>` (expect source hits); `$K/bin/analogs.sh <same term>`
  (expect ≥1 row, which proves the commit-title regex); `$K/bin/mcp-check.sh` if a QA MCP was configured.
- Report: what was detected (with evidence), what the user chose, what's left as `TODO(confirm)`, and the next
  commands to try: `/scope <a question>`, `/groom <ticket>`, `/fde` (board) and `/pr-feedback` on an open PR. Remind them to restart Claude Code if skills were just linked.
