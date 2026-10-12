#!/usr/bin/env bash
# PreToolUse guard for a QA workbench MCP's "run tests" tool (configured in config.env).
# Blocks (exit 2, reason on stderr) unless the call names explicit tests AND a device, and always blocks
# categories/paths matching FDE_QA_NEVER_RUN (e.g. suites that hit real backends — the developer runs those by hand).
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../bin/fde-env.sh"
input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
run_tool="${FDE_QA_RUN_TOOL:-run_tests}"
case "$tool" in *"${FDE_QA_MCP:-}"*"$run_tool") ;; *) exit 0 ;; esac
T="${FDE_QA_TESTS_ARG:-tests}"; D="${FDE_QA_DEVICE_ARG:-device_id}"; C="${FDE_QA_CATEGORY_ARG:-category}"; NEVER="${FDE_QA_NEVER_RUN:-}"
block() { echo "qa-run-guard: $1" >&2; exit 2; }
n="$(jq -r --arg t "$T" '(.tool_input[$t] // []) | if type=="array" then map(select(type=="string" and length>0)) | length else 0 end' <<<"$input")"
dev="$(jq -r --arg d "$D" '.tool_input[$d] // empty' <<<"$input")"
[ "$n" -gt 0 ] || block "'$T' must list explicit test paths; without it the whole suite runs."
[ -n "$dev" ] || block "'$D' must name one device; without it the run may fan out to every device."
if [ -n "$NEVER" ]; then
  hay="$(jq -r --arg t "$T" --arg c "$C" '[(.tool_input[$c] // ""), ((.tool_input[$t] // [])[]?)] | join(" ")' <<<"$input")"
  grep -qiE "$NEVER" <<<"$hay" && block "this category/path matches FDE_QA_NEVER_RUN ('$NEVER'). The developer runs it by hand."
fi
exit 0
