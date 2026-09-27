#!/usr/bin/env bash
# Runs the whole test suite headless. Exit code 0 means green.
#   ./tools_dev/run_tests.sh            all tests (unit, integration, solvers)
#   ./tools_dev/run_tests.sh unit       one subfolder of tests/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
GODOT="${GODOT:-./tools_dev/godot.sh}"
mkdir -p qa
python3 tools_dev/build_strings.py >/dev/null 2>&1 || true
# Import first: translations (.translation) and other resources are generated on import.
timeout 300 "$GODOT" --headless --path . --import >qa/import.log 2>&1
DIR="res://tests"
if [ $# -ge 1 ]; then DIR="res://tests/$1"; fi
timeout 900 "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir="$DIR" -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit -glog=1 2>&1 | tee qa/tests.log \
  | grep -E "^(\[Failed\]|  \[Failed\]|FAILED|Totals|Tests|Passing|Failing|Pending|Asserts|Time|---|\*\*\*|res://tests.*[Ff]ail|.*SCRIPT ERROR|.*Parse Error|ERROR)" | head -80
STATUS=${PIPESTATUS[0]}
echo "exit=$STATUS"
exit $STATUS
