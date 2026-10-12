#!/usr/bin/env bash
# facts.sh <term> [term...] — one git-grep battery over the product repo, grouped by kind. Always fresh; no index.
# Built-in sections, then the extra sections from $FDE_FACTS_FILE (see templates/facts.example.tsv).
# Env: FACTS_CAP (lines per section, default 12). Repo/globs from config.env.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
CAP="${FACTS_CAP:-12}"
[ $# -gt 0 ] || { echo "usage: facts.sh <term> [term...]" >&2; exit 64; }
cd "$FDE_REPO" || { echo "FDE_REPO not found: $FDE_REPO" >&2; exit 1; }
read -r -a SRC <<<"$FDE_SRC_GLOBS"; read -r -a EXCL <<<"$FDE_EXCLUDE"
pat=(); for t in "$@"; do pat+=(-e "$t"); done
g() { git grep -n -I -i -F "${pat[@]}" -- "$@" "${EXCL[@]}" 2>/dev/null; }
count_files() { cut -d: -f1 | sort | uniq -c | sort -rn | sed -E 's/^ *([0-9]+) (.*)$/\1\t\2/' | awk -F'\t' '{printf "%4d  %s\n",$1,$2}'; }
section() {
  local title="$1" body n; body="$(cat)"; n=$(printf '%s' "$body" | grep -c . || true)
  [ "$n" -gt 0 ] || return 0
  printf '\n## %s (%s)\n' "$title" "$n"; printf '%s\n' "$body" | head -n "$CAP" | cut -c1-220
  [ "$n" -le "$CAP" ] || printf '… %s more\n' "$((n-CAP))"
}
echo "# facts: $* @ $(git rev-parse --abbrev-ref HEAD 2>/dev/null) $(git rev-parse --short HEAD 2>/dev/null)"

g "${SRC[@]}" | grep -Ev "$FDE_TEST_PATTERN" | count_files | section "Source files by hits"
git ls-files -- "${SRC[@]}" "${EXCL[@]}" 2>/dev/null | grep -i -F "${pat[@]}" | grep -Ev "$FDE_TEST_PATTERN" | section "Source files whose path matches"
# Second hop: identifiers assigned a string containing the term (config keys, event names) → their usages.
consts="$(g "${SRC[@]}" | cut -d: -f3- | grep -oE '[A-Za-z_][A-Za-z0-9_]*[[:space:]]*(:[^=]{1,40})?=[[:space:]]*["'\'']' \
          | sed -E 's/^([A-Za-z_][A-Za-z0-9_]*).*/\1/' | grep -vE '^(let|var|val|const|static|final|public|private|value|name|key|id)$' | sort -u | head -8)"
if [ -n "$consts" ]; then
  for c in $consts; do git grep -n -w -I "$c" -- "${SRC[@]}" "${EXCL[@]}" 2>/dev/null | grep -vE "\b$c[[:space:]]*(:[^=]{1,40})?=[[:space:]]*[\"']"; done \
    | section "Uses of identifiers holding it ($(echo $consts | tr '\n' ' '))"
fi
if [ -f "$FDE_FACTS_FILE" ]; then
  while IFS=$'\t' read -r title specs filter mode; do
    case "$title" in \#*|"") continue ;; esac
    read -r -a ps <<<"$specs"
    case "${mode:-lines}" in
      files) git grep -l -i -F "${pat[@]}" -- "${ps[@]}" "${EXCL[@]}" 2>/dev/null | section "$title" ;;
      count) g "${ps[@]}" | { [ -n "$filter" ] && grep -iE "$filter" || cat; } | count_files | section "$title" ;;
      *)     g "${ps[@]}" | { [ -n "$filter" ] && grep -iE "$filter" || cat; } | section "$title" ;;
    esac
  done < "$FDE_FACTS_FILE"
fi
g "${SRC[@]}" | grep -E "$FDE_TEST_PATTERN" | count_files | section "Tests touching it"
exit 0
