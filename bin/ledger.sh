#!/usr/bin/env bash
# ledger.sh [--all] [--waiting] — one row per change in the OpenSpec store, read from each status.md.
#   default:   id lane stage gate dor size waiting oldest_wait_days last_log next   (TSV with header)
#   --waiting: id who what since age_days                                            (TSV with header)
#   --all:     include archived changes.
# Fields may share a line (`a: x · b: y`) or sit on their own lines. FDE_TODAY=yyyy-mm-dd overrides today (tests).
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
all=0; mode=board
for a in "$@"; do case "$a" in --all) all=1 ;; --waiting) mode=waiting ;; *) echo "usage: ledger.sh [--all] [--waiting]" >&2; exit 64 ;; esac; done
root="$FDE_STORE_PATH/openspec/changes"
[ -d "$root" ] || { echo "no store changes at $root" >&2; exit 1; }

epoch() { date -j -f %Y-%m-%d "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null || echo ""; }
today="$(epoch "${FDE_TODAY:-$(date +%Y-%m-%d)}")"
age() { local e; e="$(epoch "$1")"; [ -n "$e" ] && echo $(( (today - e) / 86400 )) || echo "-"; }

field() { # file key → value of `key: value` at line start or after " · "
  grep -oE "(^|· )$2: [^·]*" "$1" | head -1 | sed -E "s/^(· )?$2: //; s/[[:space:]]+$//"; }
block() { # file key → the "- " lines under `key:` (until the next non-list line)
  awk -v k="$2:" '$0 ~ "^"k {on=1; next} on && /^- / {print substr($0,3); next} on {exit}' "$1"; }

dirs=("$root"/*/)
[ "$all" = 1 ] && dirs+=("$root"/archive/*/)
if [ "$mode" = board ]; then printf 'id\tlane\tstage\tgate\tdor\tsize\twaiting\toldest_wait_days\tlast_log\tnext\n'
else printf 'id\twho\twhat\tsince\tage_days\n'; fi
for d in "${dirs[@]}"; do
  s="$d/status.md"; [ -f "$s" ] || continue
  id="$(basename "$d")"
  waits="$(block "$s" waiting)"
  if [ "$mode" = waiting ]; then
    [ -n "$waits" ] || continue
    while IFS= read -r w; do
      who="$(awk -F' · ' '{print $1}' <<<"$w")"; what="$(awk -F' · ' '{print $2}' <<<"$w")"
      since="$(grep -oE 'since [0-9]{4}-[0-9]{2}-[0-9]{2}' <<<"$w" | cut -c7-)"
      printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$who" "$what" "${since:--}" "$( [ -n "$since" ] && age "$since" || echo -)"
    done <<<"$waits"
    continue
  fi
  n=0; oldest="-"
  if [ -n "$waits" ]; then
    n="$(grep -c . <<<"$waits")"
    first="$(grep -oE 'since [0-9]{4}-[0-9]{2}-[0-9]{2}' <<<"$waits" | cut -c7- | sort | head -1)"
    [ -n "$first" ] && oldest="$(age "$first")"
  fi
  last="$(block "$s" log | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$(field "$s" lane)" "$(field "$s" stage)" "$(field "$s" gate)" \
    "$(field "$s" dor)" "$(field "$s" size)" "$n" "$oldest" "${last:--}" "$(field "$s" next)"
done
