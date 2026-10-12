#!/usr/bin/env bash
# branch-diff.sh <out-dir> [--base <b>] [--include-uncommitted]
# Writes <out-dir>/branch.diff (merge-base..HEAD, plus working tree and untracked files when asked),
# <out-dir>/commits.txt and <out-dir>/context.json. Untracked files are diffed with `git diff --no-index`;
# the repo's index is never touched (no `git add -N`).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
OUT="${1:?usage: branch-diff.sh <out-dir> [--base b] [--include-uncommitted]}"; shift
BASEB="$FDE_BASE_BRANCH"; UNC=0
while [ $# -gt 0 ]; do case "$1" in --base) BASEB="${2:?}"; shift ;; --include-uncommitted) UNC=1 ;; *) echo "unknown arg $1" >&2; exit 64 ;; esac; shift; done
G() { git -C "$FDE_REPO" "$@"; }
BASEREF="$BASEB"; G rev-parse -q --verify "origin/$BASEB" >/dev/null && BASEREF="origin/$BASEB"
MB="$(G merge-base "$BASEREF" HEAD)"; mkdir -p "$OUT"
if [ "$UNC" = 1 ]; then
  G diff "$MB" > "$OUT/branch.diff"
  G ls-files --others --exclude-standard -z | while IFS= read -r -d '' f; do (cd "$FDE_REPO" && git diff --no-index -- /dev/null "$f" >> "$OUT/branch.diff" || true); done
else
  G diff "$MB" HEAD > "$OUT/branch.diff"
fi
G log --format='%h %s' "$MB"..HEAD > "$OUT/commits.txt"
files=$(grep -c '^diff --git' "$OUT/branch.diff" || true); lines=$(grep -cE '^[+-][^+-]' "$OUT/branch.diff" || true)
printf '{"branch":"%s","base":"%s","mergeBase":"%s","head":"%s","includeUncommitted":%s,"files":%s,"changedLines":%s,"commits":%s}\n' \
  "$(G rev-parse --abbrev-ref HEAD)" "$BASEREF" "$MB" "$(G rev-parse HEAD)" "$([ $UNC = 1 ] && echo true || echo false)" \
  "$files" "$lines" "$(G rev-list --count "$MB"..HEAD)" > "$OUT/context.json"
cat "$OUT/context.json"
