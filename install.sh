#!/usr/bin/env bash
# FDE Assistant installer (idempotent).
#   ./install.sh              set up ~/.config/fde-assistant, link skills + agents into ~/.claude, merge settings, set up the store
#   ./install.sh --check      show what is installed and what is missing; changes nothing
#   ./install.sh --uninstall  remove links and the settings entries this installer added (your config and store are kept)
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
FDE_HOME="${FDE_HOME:-$HOME/.config/fde-assistant}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK="$FDE_HOME/kit/hooks/qa-run-guard.sh"
STATE="$FDE_HOME/.installed.json"   # what this installer added to settings.json, so uninstall removes only that
SKILLS=(fde-setup scope groom qa ship review-branch triage release intake fde pr-feedback retro)
AGENTS=(fde-scout fde-builder fde-tester fde-reviewer)
say() { printf '%s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1; }

load_config() { # shellcheck disable=SC1091
  source "$KIT/bin/fde-env.sh"; }

backup() { [ -f "$1" ] || return 0; mkdir -p "$CLAUDE_DIR/backups"; cp "$1" "$CLAUDE_DIR/backups/$(basename "$1").fde-$(date +%Y%m%d%H%M%S)"; }
edit_json() { local f="$1" filter="$2" tmp; shift 2; [ -f "$f" ] || echo '{}' > "$f"; tmp="$(mktemp)"; jq "$@" "$filter" "$f" > "$tmp" && mv "$tmp" "$f"; }

link() { # src dst — refuse to replace a real file/dir that is not ours
  if [ -e "$2" ] && [ ! -L "$2" ]; then say "  SKIP $2 exists and is not a symlink (rename it to install ours)"; return; fi
  ln -sfn "$1" "$2"
}

check() {
  load_config; local ok=1
  say "FDE Assistant — check"
  [ -L "$FDE_HOME/kit" ] && say "  kit       → $(readlink "$FDE_HOME/kit")" || { say "  kit       MISSING ($FDE_HOME/kit)"; ok=0; }
  for f in config.env profile.yaml facts.tsv; do [ -f "$FDE_HOME/$f" ] && say "  $f ok$( [ -L "$FDE_HOME/$f" ] && echo " → $(readlink "$FDE_HOME/$f")")" || { say "  $f MISSING"; ok=0; }; done
  grep -q 'your-app' "$FDE_HOME/profile.yaml" 2>/dev/null && { say "  profile still has template values — run /fde-setup"; ok=0; }
  for s in "${SKILLS[@]}"; do [ -L "$CLAUDE_DIR/skills/$s" ] || { say "  skill $s not linked"; ok=0; }; done
  for a in "${AGENTS[@]}"; do [ -L "$CLAUDE_DIR/agents/$a.md" ] || { say "  agent $a not linked"; ok=0; }; done
  [ -d "$FDE_REPO/.git" ] && say "  repo      $FDE_REPO" || { say "  repo      NOT FOUND: $FDE_REPO (edit FDE_REPO in config.env)"; ok=0; }
  if need openspec; then
    say "  openspec  $(openspec --version 2>/dev/null) · defaultStore=$(openspec config get defaultStore 2>/dev/null || echo unset)"
  else say "  openspec  not installed (needed by /groom /qa /ship): npm i -g @fission-ai/openspec"; ok=0; fi
  need jq || { say "  jq missing"; ok=0; }
  [ -n "${FDE_QA_MCP:-}" ] && say "  qa mcp    $FDE_QA_MCP (guard on mcp__${FDE_QA_MCP}__${FDE_QA_RUN_TOOL:-run_tests})" || say "  qa mcp    none configured (optional)"
  for k in crash_mcp analytics_mcp chat_mcp; do
    v="$(sed -nE "s/^[[:space:]]*$k:[[:space:]]*\"?([^\"#]*)\"?.*/\1/p" "$FDE_HOME/profile.yaml" 2>/dev/null | head -1 | sed 's/[[:space:]]*$//')"
    [ -n "$v" ] && say "  $k $v" || say "  $k none (optional)"
  done
  need "${FDE_GH_CMD%% *}" && say "  gh        $FDE_GH_CMD" || say "  gh        '$FDE_GH_CMD' not found (needed by /pr-feedback)"
  [ "$ok" = 1 ] && say "OK" || { say "Some items need attention."; return 1; }
}

uninstall() {
  for s in "${SKILLS[@]}"; do [ -L "$CLAUDE_DIR/skills/$s" ] && rm "$CLAUDE_DIR/skills/$s" && say "unlinked skill $s"; done
  for a in "${AGENTS[@]}"; do [ -L "$CLAUDE_DIR/agents/$a.md" ] && rm "$CLAUDE_DIR/agents/$a.md" && say "unlinked agent $a"; done
  if [ -f "$SETTINGS" ]; then backup "$SETTINGS"
    prev="$( [ -f "$STATE" ] && jq -c '.suppressed // []' "$STATE" || echo '[]')"
    edit_json "$SETTINGS" '
      reduce $prev[] as $s (.; del(.skillOverrides[$s]))
      | if .skillOverrides == {} then del(.skillOverrides) else . end
      | del(.env.OPENSPEC_TELEMETRY) | if .env == {} then del(.env) else . end
      | if .hooks.PreToolUse then .hooks.PreToolUse |= map(select(([.hooks[]?.command] | index($hook)) | not)) else . end
      | if (.hooks.PreToolUse // [1]) == [] then del(.hooks.PreToolUse) else . end
      | if .hooks == {} then del(.hooks) else . end' --arg hook "$HOOK" --argjson prev "$prev"
    rm -f "$STATE"; say "settings entries removed"; fi
  [ -L "$FDE_HOME/kit" ] && rm "$FDE_HOME/kit"
  say "Kept: $FDE_HOME (config/profile) and your OpenSpec store. Delete them yourself if you want them gone."
}

case "${1:-}" in --check) check; exit $? ;; --uninstall) uninstall; exit 0 ;; "") ;; *) say "usage: $0 [--check|--uninstall]"; exit 64 ;; esac
need jq || { say "jq is required (brew install jq)"; exit 1; }

# 1. personal config home (never inside a repo)
mkdir -p "$FDE_HOME/work"
ln -sfn "$KIT" "$FDE_HOME/kit"
[ -f "$FDE_HOME/config.env" ]   || { cp "$KIT/templates/config.env.example" "$FDE_HOME/config.env"; say "created $FDE_HOME/config.env (template — /fde-setup fills it in)"; }
[ -f "$FDE_HOME/profile.yaml" ] || { cp "$KIT/templates/profile.example.yaml" "$FDE_HOME/profile.yaml"; say "created $FDE_HOME/profile.yaml (template)"; }
[ -f "$FDE_HOME/facts.tsv" ]    || { cp "$KIT/templates/facts.example.tsv" "$FDE_HOME/facts.tsv"; say "created $FDE_HOME/facts.tsv (template)"; }
load_config

# 2. skills + agents
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"
for s in "${SKILLS[@]}"; do link "$KIT/skills/$s" "$CLAUDE_DIR/skills/$s"; done
for a in "${AGENTS[@]}"; do link "$KIT/agents/$a.md" "$CLAUDE_DIR/agents/$a.md"; done
say "linked skills: ${SKILLS[*]} · agents: ${AGENTS[*]}"

# 3. user settings: telemetry off, optional skill suppression, optional QA run guard
backup "$SETTINGS"
suppress="$(printf '%s\n' ${FDE_SUPPRESS_SKILLS:-} | jq -R . | jq -sc 'map(select(length>0))')"
matcher=""; [ -n "${FDE_QA_MCP:-}" ] && matcher="mcp__${FDE_QA_MCP}__${FDE_QA_RUN_TOOL:-run_tests}"
prev="$( [ -f "$STATE" ] && jq -c '.suppressed // []' "$STATE" || echo '[]')"
edit_json "$SETTINGS" '
  reduce $prev[] as $s (.; del(.skillOverrides[$s]))
  | .env.OPENSPEC_TELEMETRY = "0"
  | reduce $sup[] as $s (.; .skillOverrides[$s] = "user-invocable-only")
  | if .skillOverrides == {} then del(.skillOverrides) else . end
  | .hooks.PreToolUse = ((.hooks.PreToolUse // []) | map(select(([.hooks[]?.command] | index($hook)) | not))
      + (if $m == "" then [] else [{"matcher": $m, "hooks": [{"type": "command", "command": $hook}]}] end))
  | if (.hooks.PreToolUse | length) == 0 then del(.hooks.PreToolUse) else . end
  | if (.hooks // {}) == {} then del(.hooks) else . end' --arg hook "$HOOK" --arg m "$matcher" --argjson sup "$suppress" --argjson prev "$prev"
jq -n --argjson sup "$suppress" '{suppressed: $sup}' > "$STATE"
say "merged $SETTINGS"

# 4. product repo: no AI attribution (only into a gitignored settings.local.json)
if [ "${FDE_NO_AI_ATTRIBUTION:-1}" = 1 ] && [ -d "$FDE_REPO/.git" ]; then
  if git -C "$FDE_REPO" check-ignore -q .claude/settings.local.json; then
    mkdir -p "$FDE_REPO/.claude"; backup "$FDE_REPO/.claude/settings.local.json"
    edit_json "$FDE_REPO/.claude/settings.local.json" '.attribution = {"commit": "", "pr": ""}'
    say "attribution off in $FDE_REPO/.claude/settings.local.json (gitignored)"
  else say "note: $FDE_REPO/.claude/settings.local.json is not gitignored there — attribution setting skipped"; fi
fi

# 5. OpenSpec store (local only) + default store, so openspec never writes into the product repo
if grep -q 'your-app' "$FDE_HOME/profile.yaml" 2>/dev/null; then
  say "store: skipped until the project is configured (/fde-setup)"
elif [ "${FDE_SKIP_OPENSPEC:-0}" != 1 ] && need openspec; then
  if ! openspec store list 2>/dev/null | grep -qw "$FDE_STORE"; then
    openspec store setup "$FDE_STORE" --path "$FDE_STORE_PATH" >/dev/null
    cp "$KIT/templates/store-config.yaml" "$FDE_STORE_PATH/openspec/config.yaml"
    git -C "$FDE_STORE_PATH" add -A >/dev/null 2>&1 && git -C "$FDE_STORE_PATH" commit -qm "FDE Assistant store config" >/dev/null 2>&1 || true
    say "created OpenSpec store $FDE_STORE at $FDE_STORE_PATH"
  fi
  [ "$(openspec config get defaultStore 2>/dev/null)" = "$FDE_STORE" ] || openspec config set defaultStore "$FDE_STORE" >/dev/null
  say "openspec defaultStore = $FDE_STORE"
else say "openspec not found — install it for /groom /qa /ship: npm i -g @fission-ai/openspec, then re-run"; fi

say "Done. Restart Claude Code, open it in your product repo and run /fde-setup to configure it (or edit $FDE_HOME/*.{env,yaml,tsv} by hand)."
