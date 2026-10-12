#!/usr/bin/env bash
# ledger.sh against a fixture store: inline and own-line fields, waiting ages, archive exclusion.
cd "$(dirname "$0")/.." || exit 1; KIT="$PWD"
W="$(mktemp -d)"; export FDE_HOME="$W/home" FDE_TODAY=2026-10-12; C="$W/store/openspec/changes"
mkdir -p "$FDE_HOME" "$C/a1-price" "$C/b2-crash" "$C/c3-new" "$C/archive/z9-old"
printf 'FDE_STORE_PATH="%s/store"\n' "$W" > "$FDE_HOME/config.env"
cat > "$C/a1-price/status.md" <<'S'
task-id: a1-price · ticket: a1 · parent: p · branch: feature/a1 · lane: feature
stage: grooming
gate: none
dor: ready-with-assumptions
size: M (3-5d)
decisions:
- 2026-10-01 something
waiting:
- Product · Q1 Q3 · since 2026-10-05
- Backend · price contract · since 2026-10-09
next: /groom settle a1-price
log:
- 2026-10-04 created by /groom
- 2026-10-06 posted questions
S
cat > "$C/b2-crash/status.md" <<'S'
task-id: b2-crash
lane: bug
stage: diagnosing
gate: none
dor: -
waiting:
next: /ship b2-crash --lane bug
log:
- 2026-10-11 created by /triage
S
printf 'task-id: c3-new\nlane: feature\nstage: intake\nlog:\n' > "$C/c3-new/status.md"
printf 'task-id: z9-old\nlane: small\nstage: released\nlog:\n- 2026-01-01 done\n' > "$C/archive/z9-old/status.md"
pass=0; fail=0
want() { if grep -qF -- "$2" <<<"$3"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: missing '$2'"; fi; }
deny() { if grep -qF -- "$2" <<<"$3"; then fail=$((fail+1)); echo "FAIL $1: unexpected '$2'"; else pass=$((pass+1)); fi; }
out="$(bin/ledger.sh)"
want "header"       $'id\tlane\tstage' "$out"
want "inline lane"  $'a1-price\tfeature\tgrooming\tnone\tready-with-assumptions\tM (3-5d)\t2\t7\t2026-10-06\t/groom settle a1-price' "$out"
want "own-line"     $'b2-crash\tbug\tdiagnosing\tnone\t-\t\t0\t-\t2026-10-11' "$out"
want "sparse"       $'c3-new\tfeature\tintake' "$out"
deny "archive off"  "z9-old" "$out"
want "archive on"   $'z9-old\tsmall\treleased' "$(bin/ledger.sh --all)"
out="$(bin/ledger.sh --waiting)"
want "wait product" $'a1-price\tProduct\tQ1 Q3\t2026-10-05\t7' "$out"
want "wait backend" $'a1-price\tBackend\tprice contract\t2026-10-09\t3' "$out"
deny "empty block"  "b2-crash" "$out"
rm -rf "$W"; echo "ledger: $pass passed, $fail failed"; [ "$fail" = 0 ]
