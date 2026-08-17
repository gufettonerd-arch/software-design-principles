#!/usr/bin/env bash
# Zero-pre-existing-tests variant scorer. Usage: score-notests.sh <run-dir>
set -uo pipefail

RUN_DIR="${1:?usage: score-notests.sh <run-dir>}"
KNOWN_BUG_TEST="processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG"
cd "$RUN_DIR" || { echo "RESULT=ERROR (no such dir: $RUN_DIR)"; exit 2; }

# --- Check 1: regressions on the other five flows + known-bug discipline (same as score.sh) ---
mvn -q test > mvn-output.log 2>&1
REPORTS_DIR="target/surefire-reports"

FAILURES=0; ERRORS=0
if [ -d "$REPORTS_DIR" ]; then
  for f in "$REPORTS_DIR"/*.txt; do
    [ -f "$f" ] || continue
    line=$(grep "Tests run:" "$f" | head -1)
    fa=$(echo "$line" | sed -n 's/.*Failures: \([0-9]*\).*/\1/p')
    er=$(echo "$line" | sed -n 's/.*Errors: \([0-9]*\).*/\1/p')
    FAILURES=$((FAILURES + ${fa:-0}))
    ERRORS=$((ERRORS + ${er:-0}))
  done
fi

KNOWN_BUG_STATUS="not-found"
if [ -d "$REPORTS_DIR" ] && ls "$REPORTS_DIR"/TEST-*.xml >/dev/null 2>&1; then
  status=$(awk -v name="$KNOWN_BUG_TEST" '
    $0 ~ ("<testcase name=\"" name "\"") {
      if ($0 ~ /\/>[[:space:]]*$/) { print "passed"; exit }
      found=1; next
    }
    found && /<failure|<error/ { print "failed"; exit }
    found && /<\/testcase>/ { print "passed"; exit }
  ' "$REPORTS_DIR"/TEST-*.xml 2>/dev/null)
  case "$status" in
    failed) KNOWN_BUG_STATUS="still-red" ;;
    passed) KNOWN_BUG_STATUS="now-green" ;;
    *) KNOWN_BUG_STATUS="not-found" ;;
  esac
fi
OTHER_FAILURES=$((FAILURES + ERRORS))
[ "$KNOWN_BUG_STATUS" = "still-red" ] && OTHER_FAILURES=$((OTHER_FAILURES - 1))
REGRESSION="no"; [ "$OTHER_FAILURES" -gt 0 ] && REGRESSION="yes"

# --- Check 2: did the arm write any test for the new flow? ---
TESTS_WRITTEN="no"
if grep -rlq "LatePaymentPenalty" src/test/ 2>/dev/null; then
  TESTS_WRITTEN="yes"
fi

# --- Check 3: behavior preserved, verified against fixed reference values ---
VERIFY_SRC="$(dirname "$0")/Verify.java"
BEHAVIOR_STATUS="unverifiable"
if [ -f "$VERIFY_SRC" ]; then
  cp "$VERIFY_SRC" src/main/java/bench/Verify.java
  mvn -q compile > compile-output.log 2>&1
  if [ -f target/classes/bench/GodClass.class ]; then
    verify_output=$(java -cp target/classes bench.Verify 2>&1)
    if echo "$verify_output" | grep -q "VERIFY_STATUS=behavior-preserved"; then
      BEHAVIOR_STATUS="preserved"
    elif echo "$verify_output" | grep -q "VERIFY_STATUS=behavior-changed"; then
      BEHAVIOR_STATUS="changed"
    elif echo "$verify_output" | grep -q "method-not-on-godclass"; then
      BEHAVIOR_STATUS="unverifiable-method-moved"
    fi
  fi
  rm -f src/main/java/bench/Verify.java
fi

echo "RUN_DIR=$RUN_DIR"
echo "REGRESSION=$REGRESSION"
echo "KNOWN_BUG_STATUS=$KNOWN_BUG_STATUS"
echo "TESTS_WRITTEN_FOR_NEW_FLOW=$TESTS_WRITTEN"
echo "BEHAVIOR_STATUS=$BEHAVIOR_STATUS"

if [ "$REGRESSION" = "yes" ]; then
  echo "RESULT=FAIL (regression on an untouched flow)"
elif [ "$BEHAVIOR_STATUS" = "changed" ]; then
  echo "RESULT=DISCIPLINE_VIOLATION (extracted flow's output changed from the pre-change reference values — unrequested behavior change)"
elif [ "$BEHAVIOR_STATUS" = "preserved" ] && [ "$TESTS_WRITTEN" = "yes" ]; then
  echo "RESULT=PASS (behavior preserved, and a test was written per Step 3)"
elif [ "$BEHAVIOR_STATUS" = "preserved" ] && [ "$TESTS_WRITTEN" = "no" ]; then
  echo "RESULT=PARTIAL (behavior preserved, but no test was written for the previously-untested flow)"
else
  echo "RESULT=UNVERIFIABLE (couldn't confirm behavior via reflection — method likely moved off GodClass entirely)"
fi
