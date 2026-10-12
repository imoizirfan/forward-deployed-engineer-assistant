#!/usr/bin/env bash
# Runs every test. Nothing here touches your real ~/.claude, config or OpenSpec store.
cd "$(dirname "$0")" || exit 1; rc=0
for t in test_*.sh; do echo "== $t"; bash "$t" || rc=1; done; exit $rc
