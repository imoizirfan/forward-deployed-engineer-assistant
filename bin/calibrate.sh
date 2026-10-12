#!/usr/bin/env bash
# calibrate.sh [--dry-run] <change-id> — estimate vs actual for one change, appended to <store>/calibration.tsv.
# Reads `branch:`, `size:`, `lane:`, `ticket:` from the change's status.md. Actual = calendar days (UTC, inclusive)
# from the first to the last commit of the branch vs FDE_BASE_BRANCH, by author date (rebases reset committer dates),
# plus files and +/- lines. If the branch is gone (merged and deleted) it falls back to non-merge commits on the base whose message carries the ticket id.
# One row per change id: re-running replaces that row. --dry-run prints the row without writing.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
dry=0; [ "${1:-}" = --dry-run ] && { dry=1; shift; }
id="${1:-}"; [ -n "$id" ] || { echo "usage: calibrate.sh [--dry-run] <change-id>" >&2; exit 64; }
C="$FDE_STORE_PATH/openspec/changes"
s="$C/$id/status.md"; [ -f "$s" ] || s="$(ls -d "$C"/archive/*-"$id"/status.md 2>/dev/null | head -1)"
[ -f "$s" ] || { echo "no status.md for $id" >&2; exit 1; }
field() { grep -oE "(^|· )$1: [^·]*" "$s" | head -1 | sed -E "s/^(· )?$1: //; s/[[:space:]]+$//"; }
branch="$(field branch)"; size="$(field size)"; lane="$(field lane)"; ticket="$(field ticket)"; ticket="${ticket:-${id%%-*}}"

g() { git -C "$FDE_REPO" "$@"; }
base="origin/$FDE_BASE_BRANCH"; g rev-parse -q --verify "$base" >/dev/null || base="$FDE_BASE_BRANCH"
ref=""
for r in "$branch" "origin/$branch"; do [ -n "$branch" ] && [ "$branch" != - ] && g rev-parse -q --verify "$r" >/dev/null && { ref="$r"; break; }; done
if [ -n "$ref" ]; then
  mb="$(g merge-base "$base" "$ref")"; range=("$mb..$ref"); src="branch $ref"
  stamps="$(g log --no-merges --format=%at "${range[@]}")"
  stat="$(g diff --numstat "$mb" "$ref")"
else
  shas="$(g log "$base" --no-merges --format=%H --grep="$ticket" -F)"
  [ -n "$shas" ] || { echo "no commits found for $id (branch '$branch' missing, none on $base mention $ticket)" >&2; exit 2; }
  src="commits on $base mentioning $ticket"
  stamps="$(xargs -n1 git -C "$FDE_REPO" log -1 --format=%at <<<"$shas")"
  stat="$(xargs -n1 git -C "$FDE_REPO" show --numstat --format= <<<"$shas")"
fi
[ -n "$stamps" ] || { echo "branch $ref has no commits beyond $base" >&2; exit 2; }
first="$(sort -n <<<"$stamps" | head -1)"; last="$(sort -n <<<"$stamps" | tail -1)"
days=$(( last / 86400 - first / 86400 + 1 ))
files="$(awk 'NF>=3{print $3}' <<<"$stat" | sort -u | grep -c .)"
adds="$(awk '$1 ~ /^[0-9]+$/ {s+=$1} END{print s+0}' <<<"$stat")"
dels="$(awk '$2 ~ /^[0-9]+$/ {s+=$2} END{print s+0}' <<<"$stat")"
row="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' "$id" "${size:--}" "$days" "$files" "$adds" "$dels" "${lane:--}" "$(date +%Y-%m-%d)")"
echo "# from $src" >&2
if [ "$dry" = 1 ]; then echo "$row"; exit 0; fi
T="$FDE_STORE_PATH/calibration.tsv"
[ -f "$T" ] || printf 'id\testimate\tactual_days\tfiles\tadditions\tdeletions\tlane\tdate\n' > "$T"
tmp="$(mktemp)"; awk -F'\t' -v id="$id" '$1 != id' "$T" > "$tmp" && printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$T"
echo "$row"
