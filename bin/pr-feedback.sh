#!/usr/bin/env bash
# pr-feedback.sh [pr-number|branch] — what is left to address on an open PR of the product repo, as JSON:
#   {pr:{number,url,title,head,base}, threads:[unresolved review threads], failing_checks:[…], pending_checks:N}
# Read-only. Uses $FDE_GH_CMD (default gh), run inside $FDE_REPO so gh picks the right repository.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/fde-env.sh"
read -ra GH <<<"$FDE_GH_CMD"
cd "$FDE_REPO" || { echo "FDE_REPO not found: $FDE_REPO" >&2; exit 1; }
ref="${1:-}"
pr="$("${GH[@]}" pr view ${ref:+"$ref"} --json number,url,title,headRefName,baseRefName 2>/dev/null)" \
  || { echo "no open PR for '${ref:-current branch}' (or $FDE_GH_CMD is not authenticated for this repo)" >&2; exit 2; }
num="$(jq -r .number <<<"$pr")"; url="$(jq -r .url <<<"$pr")"
owner="$(sed -E 's#https://[^/]+/([^/]+)/.*#\1#' <<<"$url")"; name="$(sed -E 's#https://[^/]+/[^/]+/([^/]+)/.*#\1#' <<<"$url")"

q='query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){pullRequest(number:$number){
  reviewThreads(first:100){nodes{id isResolved isOutdated path line originalLine
    comments(first:30){totalCount nodes{author{login} body createdAt url}}}}}}}'
threads="$("${GH[@]}" api graphql -f query="$q" -F owner="$owner" -F name="$name" -F number="$num" 2>/dev/null)" || threads='{}'
checks="$("${GH[@]}" pr checks "$num" --json name,state,bucket,link 2>/dev/null)" || checks='[]'
[ -n "$checks" ] || checks='[]'

jq -n --argjson pr "$pr" --argjson t "$threads" --argjson c "$checks" '{
  pr: {number: $pr.number, url: $pr.url, title: $pr.title, head: $pr.headRefName, base: $pr.baseRefName},
  threads: [ ($t.data.repository.pullRequest.reviewThreads.nodes // [])[] | select(.isResolved | not) | {
      id, path, line: (.line // .originalLine), outdated: .isOutdated,
      author: .comments.nodes[0].author.login, body: .comments.nodes[0].body, url: .comments.nodes[0].url,
      replies: ((.comments.totalCount // 1) - 1),
      last: {author: .comments.nodes[-1].author.login, body: .comments.nodes[-1].body} } ],
  failing_checks: [ $c[] | select(.bucket == "fail" or .bucket == "cancel") | {name, state, link} ],
  pending_checks: ([ $c[] | select(.bucket == "pending") ] | length) }'
