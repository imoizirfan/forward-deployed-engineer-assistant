#!/usr/bin/env bash
# mcp-check.sh [name] — is an HTTP MCP server registered in Claude Code and answering? Default name: $FDE_QA_MCP.
# Prints one state (healthy | not registered | server off | stale token | unexpected) and the fix. Never prints tokens.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
name="${1:-${FDE_QA_MCP:-}}"; [ -n "$name" ] || { echo "usage: mcp-check.sh <mcp-name> (or set FDE_QA_MCP)"; exit 64; }
info="$(claude mcp get "$name" 2>/dev/null)" || {
  echo "STATE: not registered"
  echo "FIX: claude mcp add --transport http --scope local $name http://127.0.0.1:<port>/mcp --header \"Authorization: Bearer <token>\""; exit 3; }
url="$(grep -oE 'https?://[^ "]+' <<<"$info" | head -1)"
auth="$(grep -oE 'Authorization: *Bearer [^ "]+' <<<"$info" | head -1)"
[ -n "$url" ] || { echo "STATE: unexpected — '$name' is registered but has no HTTP URL (stdio servers can't be probed)"; exit 4; }
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -X POST "$url" -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' ${auth:+-H "$auth"} -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}')"
case "$code" in
  200) echo "STATE: healthy ($url)"; exit 0 ;;
  401|403) echo "STATE: stale token ($code)"; echo "FIX: claude mcp remove $name -s local, then add it again with the current token"; exit 2 ;;
  000) echo "STATE: server off ($url refused)"; echo "FIX: start the server (check its app's settings), then re-run"; exit 1 ;;
  *) echo "STATE: unexpected HTTP $code from $url"; exit 4 ;;
esac
