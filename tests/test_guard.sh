#!/usr/bin/env bash
# qa-run-guard with a throwaway config.
cd "$(dirname "$0")/.." || exit 1
export FDE_HOME="$(mktemp -d)"
cat > "$FDE_HOME/config.env" <<'C'
FDE_QA_MCP="workbench"
FDE_QA_RUN_TOOL="run_tests"
FDE_QA_TESTS_ARG="tests"
FDE_QA_DEVICE_ARG="device_id"
FDE_QA_CATEGORY_ARG="category"
FDE_QA_NEVER_RUN="live"
C
pass=0; fail=0
check() { printf '%s' "$3" | hooks/qa-run-guard.sh 2>/dev/null; got=$?
  if [ "$got" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: want $2 got $got"; fi; }
T=mcp__workbench__run_tests
check "no tests"      2 "{\"tool_name\":\"$T\",\"tool_input\":{\"device_id\":\"SIM1\"}}"
check "empty tests"   2 "{\"tool_name\":\"$T\",\"tool_input\":{\"tests\":[],\"device_id\":\"SIM1\"}}"
check "blank test"    2 "{\"tool_name\":\"$T\",\"tool_input\":{\"tests\":[\"\"],\"device_id\":\"SIM1\"}}"
check "no device"     2 "{\"tool_name\":\"$T\",\"tool_input\":{\"tests\":[\"ui/test_a.py\"]}}"
check "live category" 2 "{\"tool_name\":\"$T\",\"tool_input\":{\"tests\":[\"x/test_a.py\"],\"device_id\":\"SIM1\",\"category\":\"Live API\"}}"
check "live path"     2 "{\"tool_name\":\"$T\",\"tool_input\":{\"tests\":[\"live_api/test_post.py\"],\"device_id\":\"SIM1\"}}"
check "ok ui"         0 "{\"tool_name\":\"$T\",\"tool_input\":{\"tests\":[\"ui/test_a.py\"],\"device_id\":\"SIM1\",\"category\":\"UI\"}}"
check "other tool"    0 "{\"tool_name\":\"mcp__workbench__list_tests\",\"tool_input\":{}}"
check "other server"  0 "{\"tool_name\":\"mcp__else__run_tests\",\"tool_input\":{}}"
rm -rf "$FDE_HOME"; echo "qa-run-guard: $pass passed, $fail failed"; [ "$fail" = 0 ]
