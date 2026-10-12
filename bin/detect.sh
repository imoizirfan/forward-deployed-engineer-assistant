#!/usr/bin/env bash
# detect.sh [repo] — read-only discovery for onboarding. Prints JSON facts about a repo so /fde-setup can propose a
# config instead of guessing. Never writes anything.
set -uo pipefail
R="$(git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null)" || { echo '{"error":"not a git repo"}'; exit 1; }
cd "$R" || exit 1
j() { jq -R -s -c 'split("\n") | map(select(length>0))'; }   # lines → JSON array

# languages by tracked file count (top 6)
langs="$(git ls-files | sed -nE 's/.*\.([A-Za-z0-9]+)$/\1/p' | tr 'A-Z' 'a-z' \
  | grep -E '^(swift|m|kt|java|ts|tsx|js|jsx|py|go|rb|rs|cs|dart|php|scala|c|cc|cpp|vue|svelte)$' \
  | sort | uniq -c | sort -rn | head -6 | awk '{printf "{\"ext\":\"%s\",\"files\":%s}\n",$2,$1}' | jq -s -c .)"

# base branch: origin/HEAD, plus whether develop/main/master exist
head_ref="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
branches="$(for b in develop dev main master trunk; do git rev-parse -q --verify "origin/$b" >/dev/null 2>&1 && echo "$b"; done | j)"
merged_into_develop="$(git rev-parse -q --verify origin/develop >/dev/null 2>&1 && git log origin/develop --merges --since=90.days --oneline 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

# agent / contributor docs that exist
docs="$(for f in AGENTS.md CLAUDE.md .claude/CLAUDE.md CONTRIBUTING.md README.md docs .ai .github/copilot-instructions.md .cursorrules; do [ -e "$f" ] && echo "$f"; done | j)"
module_guides="$(git ls-files '*/AGENTS.md' '*/CLAUDE.md' 2>/dev/null | head -30 | j)"
doc_candidates="$(git ls-files 2>/dev/null | grep -iE '(^|/)(docs?|\.ai)/.*(coding|style|convention|practice|test|build|ci|infra|analytic|architecture).*\.md$' | head -20 | j)"
pr_template="$(git ls-files 2>/dev/null | grep -iE '(^|/)pull_request_template\.md$' | head -1)"

# tests: directories that hold tests
test_dirs="$(git ls-files 2>/dev/null | grep -oE '^(.*/)?(Tests?|tests?|__tests__|spec|androidTest|test)/' | sed -E 's#^.*/((Tests?|tests?|__tests__|spec|androidTest|test)/)$#\1#' | sort | uniq -c | sort -rn | head -5 | awk '{print $2}' | j)"

# commit titles: sample + inferred ticket id shapes
samples="$(git log -n 40 --no-merges --format=%s "origin/${head_ref:-HEAD}" 2>/dev/null || git log -n 40 --no-merges --format=%s)"
bracket_lead="$(grep -cE '^\[' <<<"$samples" || true)"
jira_ids="$(grep -oE '\b[A-Z][A-Z0-9]+-[0-9]+\b' <<<"$samples" | wc -l | tr -d ' ')"
hash_ids="$(grep -oE '\[[a-z0-9]{7,12}\]' <<<"$samples" | grep -E '[0-9]' | wc -l | tr -d ' ')"
gh_refs="$(grep -oE '#[0-9]+' <<<"$samples" | wc -l | tr -d ' ')"
commit_samples="$(head -8 <<<"$samples" | j)"
branch_samples="$(git for-each-ref --sort=-committerdate --count=8 --format='%(refname:short)' refs/remotes/origin 2>/dev/null | sed 's#^origin/##' | grep -v '^HEAD$' | j)"

# variant hints: iOS targets/schemes, Android flavors, env folders
variants="$( { git ls-files '*.xcscheme' 2>/dev/null | sed -E 's#.*/([^/]+)\.xcscheme$#\1#'
               git grep -h -oE 'productFlavors|flavorDimensions' -- '*.gradle' '*.gradle.kts' 2>/dev/null | head -1
               git ls-files 2>/dev/null | grep -oE '(Targets|flavors|tenants|brands|white-?label)/[^/]+/' | sort -u ; } | sort -u | head -20 | j)"
url_schemes="$(git grep -h -A6 'CFBundleURLSchemes' -- '*Info.plist' 2>/dev/null | grep -oE '<string>[a-z][a-z0-9+.-]*</string>' | sed -E 's#</?string>##g' | grep -vE '^(com|fb|https?)' | sort -u | head -12 | j)"

# signal counts for facts sections
cnt() { git grep -I -c -i -E "$1" -- ':!*.lock' 2>/dev/null | awk -F: '{s+=$NF} END{print s+0}'; }
signals="$(jq -n -c --argjson flags "$(cnt 'remoteconfig|remote_config|featureflag|feature_flag|getValue\(for:|isFeatureEnabled|launchdarkly|unleash')" \
  --argjson analytics "$(cnt 'logEvent|\.track\(|analytics\.|mixpanel|amplitude|segment')" \
  --argjson testids "$(cnt 'accessibilityIdentifier|testID|data-testid|testTag')" \
  --argjson i18n "$(cnt 'localized|NSLocalizedString|i18n|t\(\"|getString\(R\.string')" \
  '{flags:$flags, analytics:$analytics, test_ids:$testids, i18n:$i18n}')"

# environment
mcps="$(claude mcp list 2>/dev/null | sed -nE 's/^([A-Za-z0-9_.:-]+): .*/\1/p' | head -20 | j)"
openspec_v="$(command -v openspec >/dev/null && openspec --version 2>/dev/null || echo "")"
gitignored_local="$(git check-ignore -q .claude/settings.local.json && echo true || echo false)"

jq -n -c --arg repo "$R" --arg name "$(basename "$R")" --argjson langs "$langs" --arg head "$head_ref" --argjson branches "$branches" \
  --argjson merges "$merged_into_develop" --argjson docs "$docs" --argjson modules "$module_guides" --argjson doccands "$doc_candidates" \
  --arg prt "$pr_template" --argjson tests "$test_dirs" --argjson cs "$commit_samples" --argjson bs "$branch_samples" \
  --argjson bl "$bracket_lead" --argjson jira "$jira_ids" --argjson hashid "$hash_ids" --argjson ghr "$gh_refs" \
  --argjson variants "$variants" --argjson schemes "$url_schemes" --argjson signals "$signals" --argjson mcps "$mcps" \
  --arg os "$openspec_v" --argjson gi "$gitignored_local" '
{repo:$repo, name:$name, languages:$langs,
 base_branch:{origin_head:$head, present:$branches, develop_merges_90d:$merges},
 docs:{present:$docs, module_guides:$modules, candidates:$doccands, pr_template:$prt},
 tests:{dirs:$tests},
 commits:{samples:$cs, bracket_prefixed:$bl, jira_style_ids:$jira, hash_style_ids:$hashid, github_refs:$ghr, recent_branches:$bs},
 variants:{hints:$variants, url_schemes:$schemes},
 signals:$signals,
 env:{mcp_servers:$mcps, openspec:$os, settings_local_gitignored:$gi}}'
