# Forward Deployed Engineer Assistant

A personal AI team for [Claude Code](https://claude.com/claude-code) that covers a ticket end to end:
**request → is it feasible → is it ready → what do we test → build it → review it → address feedback → roll it out → learn.**
Bugs get their own path: **diagnose → fix with a regression test first.**

It works on any git repo. Everything specific to your product lives in your own config
(`~/.config/fde-assistant/`), and every ticket artifact lives in a separate local
[OpenSpec](https://github.com/Fission-AI/OpenSpec) store, so nothing is ever added to your product repo except the code you ship.

| Command | Use it when | Writes |
|---|---|---|
| `/fde-setup` | first run in a repo, or switching projects | your config in `~/.config/fde-assistant` |
| `/scope <question or ticket>` | someone asks "can we… / how big is…" in a meeting | nothing |
| `/scope sprint <list>` | the day before sprint planning | a table in chat |
| `/groom <ticket>` | a ticket is about to be picked up | spec, questions, gaps, ACs in the store |
| `/groom post <id>` · `/groom settle <id>` | asking product, then folding answers back | one tracker comment, **only after you say yes** |
| `/qa cases <id>` | before implementation | test cases (md + csv) |
| `/qa run <id>` · `/qa automate <id>` | checking on a simulator · writing workbench tests | screenshots · tests |
| `/qa handoff <id>` | the build is ready for QA | a message to paste |
| `/ship <id>` | building it, with gates where you decide | code + tests on a branch |
| `/review-branch [--change <id>]` | before opening a PR | a review (nothing posted) |
| `/intake <thread or text>` | a request arrives with no ticket | a drafted ticket; creates it **only after you say yes** |
| `/triage <ticket, stack or text>` | a bug or crash report | a diagnosis: repro, root cause, blast radius, regression test |
| `/ship <id> --lane bug` | fixing a diagnosed bug | regression test first, then the fix |
| `/pr-feedback [pr]` | reviewers commented or CI failed on your PR | fixes + reply drafts; posts **only after you say yes** |
| `/release plan\|check <id>` · `/release notes <sprint>` | after merge · after launch · release day | rollout plan · hold/continue/roll back · notes |
| `/fde` · `/fde waiting` · `/fde update` | what's on my plate · who am I blocked on · weekly update | nothing / a draft |
| `/retro <id>` · `/retro sprint` | after merge · end of sprint | estimate vs actual, decision memory, friction notes |

Agents (spawned by the skills): `fde-scout` (read-only impact brief), `fde-builder` (implements), `fde-tester`
(test matrix from the spec, then tests), `fde-reviewer` (conformance + quality review).

## Install

Needs: Claude Code, `git`, `jq`, and for `/groom /qa /ship` OpenSpec (`npm i -g @fission-ai/openspec`).
Optional: a tracker MCP (ClickUp, Linear, Jira…), a simulator/emulator MCP, a QA-workbench MCP, a crash/analytics
MCP (for `/triage` and `/release check`), a chat MCP (for `/intake` from a thread URL), and `gh` (for `/pr-feedback`).

```bash
git clone https://github.com/imoizirfan/forward-deployed-engineer-assistant.git
cd forward-deployed-engineer-assistant
./install.sh
```

## Onboard your project (`/fde-setup`)

Restart Claude Code, open it **in your product repo**, and run:

```
/fde-setup
```

The session inspects the repo first (`bin/detect.sh`: languages, base branch, agent/contributor docs, test folders,
commit and branch style, build variants, deep-link schemes, connected MCP servers), proposes every value with the
evidence behind it, and asks you only what it can't detect — usually your tracker space, which variants matter, and
your QA setup. It tunes the search sections against your real code, shows you the three files, and writes them only
after you say yes. Then it installs, runs `./install.sh --check`, and smoke-tests the scripts on a recent commit.

Your config lives outside every repo, one folder per project:

```
~/.config/fde-assistant/
  projects/<name>/config.env     # repo path, base branch, store, optional QA MCP
  projects/<name>/profile.yaml   # docs map, variants, languages, conventions, tracker ids
  projects/<name>/facts.tsv      # search sections tuned to your stack
  config.env, profile.yaml, facts.tsv → symlinks to the active project
```

More than one project: run `/fde-setup` in each repo, then `/fde-setup list` and `/fde-setup switch <name>`.
Prefer doing it by hand? Copy the files from `templates/`, edit them, and run `./install.sh`.

`./install.sh --check` shows what is set up and what is missing. Uninstall with `./install.sh --uninstall`
(keeps your config and store).

## Use it end to end

```
/intake <slack thread url | pasted text>  # no ticket yet → drafted ticket (created only on "yes")
/scope https://app.clickup.com/t/<id>     # verdict card: doable? size? what to ask in the room
/groom <id>                               # → DoR verdict + blocking questions (folder path printed)
/groom post <id>                          # shows the comment; posts only when you say "yes"
/groom settle <id>                        # after product answers
/qa cases <id>                            # test cases + "elements missing test ids"
/ship <id>                                # plan gate → branch → build → you run it → tests → review → sign-off gate
/qa handoff <id>                          # message for QA
/pr-feedback                              # reviewers commented / CI failed → triage, fix, reply on "yes"
/release plan <id>                        # after merge: ramp, thresholds, rollback, which build carries it
/release check <id>                       # after launch: hold / continue / roll back
/retro <id>                               # estimate vs actual, decisions remembered
/ship archive <id>
```

Bug path: `/triage <crash or ticket>` → `/ship <id> --lane bug` → `/release check <id>`.
Any time: `/fde` (board), `/fde waiting` (who you're blocked on, with nudge drafts), `/fde update` (weekly update).

`<id>` is the change id `/groom` prints, e.g. `abc123-price-labels`. Every step reads and updates `status.md` in the
change folder, so you can stop anywhere and pick up later in a new session.

## Use just one part

- **Meetings only:** `/fde-setup`, then `/scope`. No OpenSpec needed.
- **Grooming only:** `/groom` (+ `post`/`settle`). Hand the spec to whoever builds it.
- **Test cases only:** `/groom` then `/qa cases`.
- **Review only:** `/review-branch` on any branch; add `--change <id>` to check it against the spec's acceptance criteria.
  `FDE_REVIEW_CMD` lets you plug in your own reviewer script instead.
- **Bugs only:** `/triage` gives a diagnosis you can hand to anyone; `/ship --lane bug` if you fix it yourself.
- **PR follow-through only:** `/pr-feedback` on any open PR (`FDE_GH_CMD` if your work GitHub isn't the default `gh`).
- **Status and updates only:** `/fde`, `/fde update` — they read the `status.md` ledgers the other skills keep.
- **Scripts on their own:** `~/.config/fde-assistant/kit/bin/facts.sh <term>` (where does this live?) and
  `analogs.sh <term>` (similar past tickets and their size), `ledger.sh` (every change's stage),
  `pr-feedback.sh [pr]` (unresolved threads and failing checks as JSON), `calibrate.sh <id>` (estimate vs actual).

## Safety rails

- Tracker comments and new tasks, PR replies, commits, pushes, PRs, downloads, app builds and test runs happen only
  after you approve the exact payload in that turn. Nothing ever flips a feature flag, resolves a review thread or merges. No AI attribution in commits/PRs (configurable).
- OpenSpec's default store is set to yours, so it can never create `openspec/` inside your product repo; every writing
  skill checks the repo's `git status` before and after.
- `/ship` stops at hard gates (plan, triage, sign-off) and a checkpoint where you run the build yourself.
- With a QA-workbench MCP configured, a hook blocks test runs that don't name explicit tests and one device, and any
  category matching `FDE_QA_NEVER_RUN` (e.g. suites that hit real backends).
- Your profile and store hold your company's information. Keep them local (or in a private repo); never commit them here.

## Develop

```bash
tests/run.sh     # sandboxed: never touches your real ~/.claude, config or store
```

MIT licensed.
