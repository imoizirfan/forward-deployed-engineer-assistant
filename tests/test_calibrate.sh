#!/usr/bin/env bash
# calibrate.sh: branch mode, deleted-branch fallback, idempotent rows, dry run.
cd "$(dirname "$0")/.." || exit 1; KIT="$PWD"
W="$(mktemp -d)"; R="$W/app"; export FDE_HOME="$W/home"; C="$W/store/openspec/changes"
mkdir -p "$FDE_HOME" "$R" "$C/abc1234-ranges" "$C/archive/2026-01-01-def5678-crash"
printf 'FDE_REPO="%s"\nFDE_BASE_BRANCH="main"\nFDE_STORE_PATH="%s/store"\n' "$R" "$W" > "$FDE_HOME/config.env"
printf 'task-id: abc1234-ranges · ticket: abc1234 · branch: feature/abc1234-ranges · lane: feature\nsize: M (3-5d)\n' > "$C/abc1234-ranges/status.md"
printf 'task-id: def5678-crash\nticket: def5678\nbranch: bug/def5678-gone\nlane: bug\nsize: S\n' > "$C/archive/2026-01-01-def5678-crash/status.md"
cd "$R" && git init -q -b main && git config user.email t@t && git config user.name t
c() { GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -qm "$2"; }
echo a > a.txt && git add -A && c "2026-10-01T10:00:00" "init"
git switch -qc feature/abc1234-ranges
printf '1\n2\n3\n' > b.txt && git add -A && c "2026-10-03T10:00:00" "[FEATURE][abc1234] one"
echo 4 >> b.txt && echo x > c.txt && git add -A && c "2026-10-06T18:00:00" "[FEATURE][abc1234] two"
git switch -q main
echo fix > d.txt && git add -A && c "2026-10-08T09:00:00" "[BUG-FIX][def5678] crash fix (#9)"
cd "$KIT"
pass=0; fail=0; ok() { if eval "$2"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1"; fi; }
T="$W/store/calibration.tsv"
row="$(bin/calibrate.sh --dry-run abc1234-ranges 2>/dev/null)"
ok "dry no file"   '[ ! -f "$T" ]'
ok "branch row"    '[ "$(cut -f1-7 <<<"$row")" = "$(printf "abc1234-ranges\tM (3-5d)\t4\t2\t5\t0\tfeature")" ]'
bin/calibrate.sh abc1234-ranges >/dev/null 2>&1; bin/calibrate.sh abc1234-ranges >/dev/null 2>&1
ok "header"        '[ "$(head -1 "$T" | cut -f1-3)" = "$(printf "id\testimate\tactual_days")" ]'
ok "idempotent"    '[ "$(grep -c "^abc1234-ranges" "$T")" = 1 ]'
row="$(bin/calibrate.sh def5678-crash 2>/dev/null)"
ok "fallback"      '[ "$(cut -f1-7 <<<"$row")" = "$(printf "def5678-crash\tS\t1\t1\t1\t0\tbug")" ]'
ok "two rows"      '[ "$(wc -l < "$T" | tr -d " ")" = 3 ]'
ok "missing id"    '! bin/calibrate.sh nope >/dev/null 2>&1'
rm -rf "$W"; echo "calibrate: $pass passed, $fail failed"; [ "$fail" = 0 ]
