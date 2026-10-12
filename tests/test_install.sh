#!/usr/bin/env bash
# install.sh in a sandbox: fake HOME, Claude dir and repo. Never touches real settings or OpenSpec.
cd "$(dirname "$0")/.." || exit 1; KIT="$PWD"
S="$(mktemp -d)"; export HOME="$S/home" CLAUDE_CONFIG_DIR="$S/home/.claude" FDE_HOME="$S/home/.config/fde-assistant" FDE_SKIP_OPENSPEC=1
mkdir -p "$HOME" "$CLAUDE_CONFIG_DIR"; echo '{"model":"sonnet","hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"/x"}]}]}}' > "$CLAUDE_CONFIG_DIR/settings.json"
pass=0; fail=0; ok() { if eval "$2"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1"; fi; }
./install.sh >/dev/null 2>&1
ok "config created"   '[ -f "$FDE_HOME/config.env" ] && [ -f "$FDE_HOME/profile.yaml" ] && [ -f "$FDE_HOME/facts.tsv" ]'
ok "kit link"         '[ "$(readlink "$FDE_HOME/kit")" = "$KIT" ]'
ok "skills linked"    '[ -L "$CLAUDE_CONFIG_DIR/skills/fde-setup" ] && [ -L "$CLAUDE_CONFIG_DIR/skills/groom" ] && [ -L "$CLAUDE_CONFIG_DIR/agents/fde-reviewer.md" ]'
ok "telemetry env"    '[ "$(jq -r .env.OPENSPEC_TELEMETRY "$CLAUDE_CONFIG_DIR/settings.json")" = 0 ]'
ok "user hook kept"   '[ "$(jq -r ".hooks.PreToolUse[0].matcher" "$CLAUDE_CONFIG_DIR/settings.json")" = Bash ]'
ok "model kept"       '[ "$(jq -r .model "$CLAUDE_CONFIG_DIR/settings.json")" = sonnet ]'
# configure a QA MCP + suppression, reinstall twice → exactly one guard hook, idempotent
printf 'FDE_QA_MCP="workbench"\nFDE_SUPPRESS_SKILLS="mission"\nFDE_REPO="%s/none"\n' "$S" >> "$FDE_HOME/config.env"
./install.sh >/dev/null 2>&1; cp "$CLAUDE_CONFIG_DIR/settings.json" "$S/a.json"; ./install.sh >/dev/null 2>&1
ok "idempotent"       'diff -q <(jq -S . "$S/a.json") <(jq -S . "$CLAUDE_CONFIG_DIR/settings.json") >/dev/null'
ok "one guard"        '[ "$(jq "[.hooks.PreToolUse[] | select(.matcher==\"mcp__workbench__run_tests\")] | length" "$CLAUDE_CONFIG_DIR/settings.json")" = 1 ]'
ok "suppressed"       '[ "$(jq -r .skillOverrides.mission "$CLAUDE_CONFIG_DIR/settings.json")" = user-invocable-only ]'
# a real (non-symlink) skill dir with our name is never overwritten
rm "$CLAUDE_CONFIG_DIR/skills/qa"; mkdir "$CLAUDE_CONFIG_DIR/skills/qa"; ./install.sh >/dev/null 2>&1
ok "no clobber"       '[ -d "$CLAUDE_CONFIG_DIR/skills/qa" ] && [ ! -L "$CLAUDE_CONFIG_DIR/skills/qa" ]'
./install.sh --uninstall >/dev/null 2>&1
ok "unlinked"         '[ ! -e "$CLAUDE_CONFIG_DIR/skills/groom" ]'
ok "guard removed"    '[ "$(jq "[.hooks.PreToolUse[]? | select(.matcher==\"mcp__workbench__run_tests\")] | length" "$CLAUDE_CONFIG_DIR/settings.json")" = 0 ]'
ok "override removed" '[ "$(jq -r ".skillOverrides.mission // \"gone\"" "$CLAUDE_CONFIG_DIR/settings.json")" = gone ]'
ok "user hook kept 2" '[ "$(jq -r ".hooks.PreToolUse[0].matcher" "$CLAUDE_CONFIG_DIR/settings.json")" = Bash ]'
ok "config kept"      '[ -f "$FDE_HOME/profile.yaml" ]'
# project switching: symlinked config files are honoured by the scripts
mkdir -p "$FDE_HOME/projects/p2"; printf 'FDE_REPO="/tmp/p2-repo"\n' > "$FDE_HOME/projects/p2/config.env"
rm -f "$FDE_HOME/config.env"; ln -s "$FDE_HOME/projects/p2/config.env" "$FDE_HOME/config.env"
ok "symlinked config" '[ "$(bash -c "source $KIT/bin/fde-env.sh; echo \$FDE_REPO")" = /tmp/p2-repo ]'
rm -rf "$S"; echo "install: $pass passed, $fail failed"; [ "$fail" = 0 ]
