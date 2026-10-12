#!/usr/bin/env bash
# Sourced by every script: loads ~/.config/fde-assistant/config.env (or $FDE_HOME/config.env) with safe defaults.
FDE_HOME="${FDE_HOME:-$HOME/.config/fde-assistant}"
# shellcheck disable=SC1091
[ -f "$FDE_HOME/config.env" ] && source "$FDE_HOME/config.env"
: "${FDE_REPO:=$PWD}" "${FDE_BASE_BRANCH:=main}" "${FDE_STORE:=fde}" "${FDE_STORE_PATH:=$HOME/fde-specs}"
: "${FDE_SRC_GLOBS:=*.swift *.kt *.ts *.tsx *.js *.py *.go *.java *.rb}"
: "${FDE_TEST_PATTERN:=(^|/)(Tests?|test|__tests__|spec)/}"
: "${FDE_EXCLUDE:=:!*/node_modules/* :!*/vendor/* :!*.lock}"
[ -n "${FDE_COMMIT_TAG_RE:-}" ] || FDE_COMMIT_TAG_RE='^\['
[ -n "${FDE_TICKET_ID_RE:-}" ] || FDE_TICKET_ID_RE='\[([A-Za-z]+-?[0-9]+|[a-z0-9]{7,12})\]'
: "${FDE_FACTS_FILE:=$FDE_HOME/facts.tsv}"
export OPENSPEC_TELEMETRY=0
