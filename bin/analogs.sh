#!/usr/bin/env bash
# analogs.sh <term|module> [...] — similar past tickets from the base branch's commit titles, with their size.
# Prints: date · ticket · PR · files · +/- · title. Env: ANALOGS_MAX (default 8). Title format from config.env.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
MAX="${ANALOGS_MAX:-8}"
[ $# -gt 0 ] || { echo "usage: analogs.sh <term|module> [...]" >&2; exit 64; }
cd "$FDE_REPO" || exit 1
BASE="origin/$FDE_BASE_BRANCH"; git rev-parse -q --verify "$BASE" >/dev/null || BASE="$FDE_BASE_BRANCH"
re="$(printf '%s|' "$@")"; re="${re%|}"
printf '%-10s %-12s %-6s %5s %11s  %s\n' date ticket pr files "+/-" title
git log "$BASE" --first-parent --no-merges --format='%H%x09%ad%x09%s' --date=short 2>/dev/null \
| RE="$re" TAG="$FDE_COMMIT_TAG_RE" awk -F'\t' 'tolower($3) ~ tolower(ENVIRON["RE"]) && $3 ~ ENVIRON["TAG"] {print}' \
| head -n "$MAX" | while IFS=$'\t' read -r sha date subj; do
  id=$(grep -oE "$FDE_TICKET_ID_RE" <<<"$subj" | head -1 | sed -E 's/^\[|\]$//g')
  pr=$(grep -oE '\(#[0-9]+\)$' <<<"$subj" | tr -d '()'); title=$(sed -E 's/^(\[[^]]*\])+ *//; s/ *\(#[0-9]+\)$//' <<<"$subj")
  stat=$(git show --shortstat --format= "$sha" | tail -1)
  files=$(grep -oE '^ *[0-9]+' <<<"$stat" | tr -d ' '); ins=$(grep -oE '[0-9]+ insert' <<<"$stat" | grep -oE '[0-9]+'); del=$(grep -oE '[0-9]+ delet' <<<"$stat" | grep -oE '[0-9]+')
  printf '%-10s %-12s %-6s %5s %11s  %s\n' "$date" "${id:--}" "${pr:--}" "${files:-0}" "+${ins:-0}/-${del:-0}" "${title:0:70}"
done
