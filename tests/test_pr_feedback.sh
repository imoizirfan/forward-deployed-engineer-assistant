#!/usr/bin/env bash
# pr-feedback.sh with a stub gh: unresolved threads only, failing/pending checks, FDE_GH_CMD with a prefix.
cd "$(dirname "$0")/.." || exit 1; KIT="$PWD"
W="$(mktemp -d)"; export FDE_HOME="$W/home"; mkdir -p "$FDE_HOME" "$W/repo" "$W/bin"
cat > "$W/bin/gh" <<'G'
#!/usr/bin/env bash
echo "$GH_MARK $*" >> "$GH_LOG"
case "$1 $2" in
  "pr view") echo '{"number":42,"url":"https://github.com/acme/app/pull/42","title":"[FEATURE][abc1234] Ranges","headRefName":"feature/abc1234-ranges","baseRefName":"develop"}' ;;
  "api graphql") cat <<'J'
{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[
 {"id":"T1","isResolved":false,"isOutdated":false,"path":"Sources/Home/Chip.swift","line":12,"originalLine":12,
  "comments":{"totalCount":2,"nodes":[{"author":{"login":"rev1"},"body":"Use the theme token here","createdAt":"2026-10-10","url":"u1"},
                                      {"author":{"login":"me"},"body":"Will do","createdAt":"2026-10-11","url":"u2"}]}},
 {"id":"T2","isResolved":true,"isOutdated":false,"path":"Sources/Home/Old.swift","line":3,"originalLine":3,
  "comments":{"totalCount":1,"nodes":[{"author":{"login":"rev2"},"body":"done already","createdAt":"2026-10-09","url":"u3"}]}},
 {"id":"T3","isResolved":false,"isOutdated":true,"path":"Sources/Home/Gone.swift","line":null,"originalLine":7,
  "comments":{"totalCount":1,"nodes":[{"author":{"login":"rev2"},"body":"Why optional?","createdAt":"2026-10-09","url":"u4"}]}}]}}}}}
J
  ;;
  "pr checks") echo '[{"name":"build","state":"FAILURE","bucket":"fail","link":"l1"},{"name":"lint","state":"SUCCESS","bucket":"pass","link":"l2"},{"name":"tests","state":"IN_PROGRESS","bucket":"pending","link":"l3"}]' ;;
esac
G
chmod +x "$W/bin/gh"
export PATH="$W/bin:$PATH" GH_LOG="$W/gh.log"
printf 'FDE_REPO="%s/repo"\nFDE_GH_CMD="env GH_MARK=work gh"\n' "$W" > "$FDE_HOME/config.env"
pass=0; fail=0; ok() { if eval "$2"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1"; fi; }
out="$(bin/pr-feedback.sh 42)"
ok "pr"          '[ "$(jq -r .pr.number <<<"$out")" = 42 ] && [ "$(jq -r .pr.base <<<"$out")" = develop ]'
ok "unresolved"  '[ "$(jq -r "[.threads[].id] | join(\",\")" <<<"$out")" = "T1,T3" ]'
ok "first+last"  '[ "$(jq -r ".threads[0].author + \"|\" + .threads[0].last.author + \"|\" + (.threads[0].replies|tostring)" <<<"$out")" = "rev1|me|1" ]'
ok "outdated"    '[ "$(jq -r ".threads[1].outdated, .threads[1].line" <<<"$out" | tr "\n" " ")" = "true 7 " ]'
ok "failing"     '[ "$(jq -r "[.failing_checks[].name] | join(\",\")" <<<"$out")" = build ]'
ok "pending"     '[ "$(jq -r .pending_checks <<<"$out")" = 1 ]'
ok "gh prefix"   'grep -q "^work pr view 42" "$GH_LOG"'
ok "repo vars"   'grep -q "owner=acme" "$GH_LOG" && grep -q "name=app" "$GH_LOG"'
rm -rf "$W"; echo "pr-feedback: $pass passed, $fail failed"; [ "$fail" = 0 ]
