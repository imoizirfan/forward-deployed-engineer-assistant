#!/usr/bin/env bash
# facts.sh / analogs.sh / delta-check.sh / branch-diff.sh against a generated fixture repo.
cd "$(dirname "$0")/.." || exit 1; KIT="$PWD"
W="$(mktemp -d)"; R="$W/app"; export FDE_HOME="$W/home"; mkdir -p "$R/Sources/Price Range" "$R/Sources/Home" "$R/Tests" "$FDE_HOME"
cat > "$FDE_HOME/config.env" <<C
FDE_REPO="$R"
FDE_BASE_BRANCH="main"
FDE_SRC_GLOBS="*.swift *.ts"
C
cp templates/facts.example.tsv "$FDE_HOME/facts.tsv"
cd "$R" && git init -q -b main && git config user.email t@t && git config user.name t
printf 'enum Constant {\n  static let budgetKey = "BudgetRanges"\n}\n' > "Sources/Home/HomeViewModel.swift"
printf 'let x = remoteConfig.getValue(for: Constant.budgetKey)\ntracker.track("click_budget")\n' > "Sources/Home/HomeLoader.swift"
printf 'struct PriceRangeChip {}\n' > "Sources/Price Range/PriceRangeChip.swift"
printf 'func testBudget() { _ = "BudgetRanges" }\n' > Tests/HomeTests.swift
git add -A && git commit -qm "[FEATURE][abc1234] Add budget ranges (#12)"
echo 'x' > Sources/Home/new.swift && git add -A && git commit -qm "[BUG-FIX][abc9999] Fix budget crash (#13)"
cd "$KIT"
pass=0; fail=0
want() { if grep -qF "$2" <<<"$3"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: missing '$2'"; fi; }
out="$(bin/facts.sh BudgetRanges)"
want "hits"        "Sources/Home/HomeViewModel.swift" "$out"
want "const hop"   "HomeLoader.swift:1" "$out"
want "flags"       "Feature flags" "$(bin/facts.sh budgetKey)"
want "tests"       "Tests/HomeTests.swift" "$out"
out="$(bin/facts.sh PriceRange)"
want "spaced path" "Sources/Price Range/PriceRangeChip.swift" "$out"
out="$(bin/analogs.sh budget)"
want "analog id"   "abc1234" "$out"
want "analog pr"   "#13" "$out"
bin/delta-check.sh snapshot "$W/snap"; echo y > "$R/Sources/Home/edit.swift"
out="$(bin/delta-check.sh check "$W/snap")"; want "delta src" "edit.swift" "$out"
mkdir -p "$R/openspec"; echo z > "$R/openspec/x.md"
bin/delta-check.sh check "$W/snap" >/dev/null; [ $? = 2 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL delta violation not caught"; }
rm -rf "$R/openspec" "$R/Sources/Home/edit.swift"
cd "$R" && git switch -q -c feature/abc5555-x HEAD~1 && echo 'n' > Sources/Home/b.swift && git add -A && git commit -qm wip && echo u > "untracked file.swift"; cd "$KIT"
idx_before="$(git -C "$R" diff --cached --name-only)"
out="$(bin/branch-diff.sh "$W/rv" --include-uncommitted)"
want "branch ctx"  '"commits":1' "$out"
want "untracked"   "untracked file.swift" "$(cat "$W/rv/branch.diff")"
[ "$(git -C "$R" diff --cached --name-only)" = "$idx_before" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL index touched"; }
out="$(bin/detect.sh "$R")"
want "detect lang"   '"ext":"swift"' "$out"
want "detect ids"    '"hash_style_ids":1' "$out"
jq -e . >/dev/null <<<"$out" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL detect json"; }
rm -rf "$W"; echo "scripts: $pass passed, $fail failed"; [ "$fail" = 0 ]
