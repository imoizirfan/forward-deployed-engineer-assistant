#!/usr/bin/env bash
# delta-check.sh snapshot|check <file> — "no assistant artifacts in the product repo".
#   snapshot: record `git status --porcelain` of FDE_REPO to <file>
#   check:    list paths that appeared since, and fail if any look like planning artifacts.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
mode="${1:-}"; f="${2:-}"
[ -n "$mode" ] && [ -n "$f" ] || { echo "usage: delta-check.sh snapshot|check <file>" >&2; exit 64; }
cur="$(git -C "$FDE_REPO" status --porcelain --untracked-files=all)"
if [ "$mode" = snapshot ]; then printf '%s\n' "$cur" > "$f"; exit 0; fi
new="$(comm -13 <(sort "$f") <(printf '%s\n' "$cur" | sort) | sed '/^$/d')"
[ -n "$new" ] || { echo "delta: no new changes in the product repo"; exit 0; }
echo "delta: new/changed paths in the product repo since snapshot:"; printf '%s\n' "$new"
bad="$(printf '%s\n' "$new" | cut -c4- | grep -E '(^|/)(openspec|\.openspec-store|\.agent-work)/|(^|/)(status|notes|grooming|ticket|qa-cases|test-matrix|proposal|design|tasks)\.md$' || true)"
if [ -n "$bad" ]; then echo "VIOLATION: assistant artifacts in the product repo:"; printf '  %s\n' $bad; exit 2; fi
exit 0
