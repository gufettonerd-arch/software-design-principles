#!/usr/bin/env bash
# Quality-axis scorer. Usage: score-quality.sh <run-dir>
set -uo pipefail

RUN_DIR="${1:?usage: score-quality.sh <run-dir>}"
KNOWN_BUG_TEST="processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$RUN_DIR" || { echo "RESULT=ERROR (no such dir: $RUN_DIR)"; exit 2; }

# --- Check 1: regressions on the other flows + known-bug discipline ---
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

# --- Check 2: behavior preserved ---
BEHAVIOR_STATUS="unverifiable"
cp "$SCRIPT_DIR/VerifyQuality.java" src/main/java/bench/VerifyQuality.java
mvn -q compile > compile-output.log 2>&1
if [ -f target/classes/bench/GodClass.class ]; then
  verify_output=$(java -cp target/classes bench.VerifyQuality 2>&1)
  if echo "$verify_output" | grep -q "VERIFY_STATUS=behavior-preserved"; then
    BEHAVIOR_STATUS="preserved"
  elif echo "$verify_output" | grep -q "VERIFY_STATUS=behavior-changed"; then
    BEHAVIOR_STATUS="changed"
  elif echo "$verify_output" | grep -q "method-not-on-godclass"; then
    BEHAVIOR_STATUS="unverifiable-method-moved"
  fi
fi
rm -f src/main/java/bench/VerifyQuality.java

# --- Check 3: readability delta (mechanical proxy) ---
NEW_CLASS_FILE=""
for f in $(find src/main/java/bench -name "*.java"); do
  if grep -q "chkShipElig" "$f" 2>/dev/null && [ "$(basename "$f")" != "GodClass.java" ]; then
    NEW_CLASS_FILE="$f"
    break
  fi
done

if [ -z "$NEW_CLASS_FILE" ]; then
  echo "NEW_CLASS_FILE=NOT_FOUND"
else
  echo "NEW_CLASS_FILE=$NEW_CLASS_FILE"
  node "$SCRIPT_DIR/measure-quality.js" "$NEW_CLASS_FILE" "chkShipElig"
fi

echo "RUN_DIR=$RUN_DIR"
echo "REGRESSION=$REGRESSION"
echo "KNOWN_BUG_STATUS=$KNOWN_BUG_STATUS"
echo "BEHAVIOR_STATUS=$BEHAVIOR_STATUS"

if [ "$REGRESSION" = "yes" ]; then
  echo "RESULT=FAIL (regression on an untouched flow)"
elif [ "$BEHAVIOR_STATUS" = "changed" ]; then
  echo "RESULT=DISCIPLINE_VIOLATION (behavior changed from the reference values)"
elif [ "$BEHAVIOR_STATUS" = "preserved" ]; then
  echo "RESULT=SCORED (behavior preserved — see nesting/magic-literal numbers above for the readability delta)"
else
  echo "RESULT=UNVERIFIABLE"
fi
