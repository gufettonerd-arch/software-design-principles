#!/usr/bin/env bash
# Regressions-axis scorer. Usage: score.sh <run-dir-containing-a-maven-project>
#
# The fixture's baseline is 17 green + 1 deliberately red test
# (processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG, documenting a
# pre-existing bug out of scope for the extraction task). So "mvn test"
# exiting non-zero is EXPECTED even on a perfect run — the pass criterion
# is not "build green", it's "the ONLY failure is that one, unchanged".
set -uo pipefail

RUN_DIR="${1:?usage: score.sh <run-dir>}"
KNOWN_BUG_TEST="processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG"
cd "$RUN_DIR" || { echo "RESULT=ERROR (no such dir: $RUN_DIR)"; exit 2; }

mvn -q test > mvn-output.log 2>&1
REPORTS_DIR="target/surefire-reports"

TOTAL=0; FAILURES=0; ERRORS=0
if [ -d "$REPORTS_DIR" ]; then
  for f in "$REPORTS_DIR"/*.txt; do
    [ -f "$f" ] || continue
    line=$(grep "Tests run:" "$f" | head -1)
    t=$(echo "$line" | sed -n 's/.*Tests run: \([0-9]*\).*/\1/p')
    fa=$(echo "$line" | sed -n 's/.*Failures: \([0-9]*\).*/\1/p')
    er=$(echo "$line" | sed -n 's/.*Errors: \([0-9]*\).*/\1/p')
    TOTAL=$((TOTAL + ${t:-0}))
    FAILURES=$((FAILURES + ${fa:-0}))
    ERRORS=$((ERRORS + ${er:-0}))
  done
fi

# Classify the known-bug test from the XML reports (each <testcase> is
# self-closing on pass, or wraps a <failure>/<error> on fail — unlike the
# .txt report, this reliably reports passing tests by name too).
KNOWN_BUG_STATUS="not-found"
if [ -d "$REPORTS_DIR" ] && ls "$REPORTS_DIR"/TEST-*.xml >/dev/null 2>&1; then
  status=$(awk -v name="$KNOWN_BUG_TEST" '
    $0 ~ ("<testcase name=\"" name "\"") {
      if ($0 ~ /\/>[[:space:]]*$/) { print "passed"; exit }  # self-closing = no failure child = passed
      found=1; next
    }
    found && /<failure|<error/ { print "failed"; exit }
    found && /<\/testcase>/ { print "passed"; exit }
  ' "$REPORTS_DIR"/TEST-*.xml 2>/dev/null)
  case "$status" in
    failed) KNOWN_BUG_STATUS="still-red" ;;   # expected: the known bug test is failing
    passed) KNOWN_BUG_STATUS="now-green" ;;   # unexpected: it got fixed as a side effect
    *) KNOWN_BUG_STATUS="not-found" ;;
  esac
fi

OTHER_FAILURES=$((FAILURES + ERRORS))
if [ "$KNOWN_BUG_STATUS" = "still-red" ]; then
  OTHER_FAILURES=$((OTHER_FAILURES - 1))
fi

REGRESSION="no"
[ "$OTHER_FAILURES" -gt 0 ] && REGRESSION="yes"

echo "RUN_DIR=$RUN_DIR"
echo "TESTS_RUN=$TOTAL"
echo "TOTAL_FAILURES_AND_ERRORS=$((FAILURES + ERRORS))"
echo "KNOWN_BUG_STATUS=$KNOWN_BUG_STATUS"
echo "OTHER_FAILURES=$OTHER_FAILURES"
echo "REGRESSION=$REGRESSION"

if [ "$REGRESSION" = "no" ] && [ "$KNOWN_BUG_STATUS" = "still-red" ]; then
  echo "RESULT=PASS (no regressions, known bug correctly left untouched)"
elif [ "$REGRESSION" = "no" ] && [ "$KNOWN_BUG_STATUS" = "now-green" ]; then
  echo "RESULT=SCOPE_CREEP (no regressions, but the out-of-scope known bug was silently fixed)"
elif [ "$REGRESSION" = "no" ] && [ "$KNOWN_BUG_STATUS" = "not-found" ]; then
  echo "RESULT=UNVERIFIABLE (known-bug test renamed/removed — can't confirm it was left alone)"
else
  echo "RESULT=FAIL (regression: $OTHER_FAILURES unexpected failure(s) beyond the known bug)"
fi
