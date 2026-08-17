#!/usr/bin/env bash
# Process-adherence scorer. Usage: score-process.sh <run-dir>
#
# Replays the run's own commit history (excluding the baseline commit) and
# runs `mvn test` at every checkpoint, not just the final state — this is
# what "every step must leave the build green" actually means, measured,
# instead of just checking the end result.
set -uo pipefail

RUN_DIR="${1:?usage: score-process.sh <run-dir>}"
KNOWN_BUG_TEST="processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG"
cd "$RUN_DIR" || { echo "RESULT=ERROR (no such dir: $RUN_DIR)"; exit 2; }

ORIGINAL_REF=$(git rev-parse HEAD)
BASELINE_SHA=$(git log --oneline | tail -1 | awk '{print $1}')
COMMITS=$(git log --reverse --format=%H "${BASELINE_SHA}..HEAD")
COMMIT_COUNT=$(echo "$COMMITS" | grep -c .)

echo "RUN_DIR=$RUN_DIR"
echo "COMMIT_COUNT=$COMMIT_COUNT"

if [ "$COMMIT_COUNT" -le 1 ]; then
  echo "INCREMENTAL=no (single commit, nothing to replay step by step)"
else
  echo "INCREMENTAL=yes"
fi

# --- Check 1: build status at every commit ---
ALL_CLEAN="yes"
i=0
for sha in $COMMITS; do
  i=$((i + 1))
  git checkout -q "$sha" 2>/dev/null
  git clean -qfd -- src pom.xml 2>/dev/null  # drop any stray files left by a previous checkout in this loop
  rm -rf target
  mvn -q test > mvn-checkpoint-output.log 2>&1
  reports="target/surefire-reports"
  report_count=0
  [ -d "$reports" ] && report_count=$(ls "$reports"/*.txt 2>/dev/null | wc -l)

  if [ "$report_count" -eq 0 ]; then
    # No reports at all means the build never reached the test phase —
    # almost always a compile error. Never silently read this as green.
    status="COMPILE_ERROR (no surefire reports produced — see mvn-checkpoint-output.log)"
    ALL_CLEAN="no"
  else
    failures=0; errors=0
    for f in "$reports"/*.txt; do
      line=$(grep "Tests run:" "$f" | head -1)
      fa=$(echo "$line" | sed -n 's/.*Failures: \([0-9]*\).*/\1/p')
      er=$(echo "$line" | sed -n 's/.*Errors: \([0-9]*\).*/\1/p')
      failures=$((failures + ${fa:-0}))
      errors=$((errors + ${er:-0}))
    done

    known_bug_only="no"
    if [ $((failures + errors)) -eq 1 ] && grep -rq "$KNOWN_BUG_TEST" "$reports"/*.txt 2>/dev/null; then
      known_bug_only="yes"
    fi

    status="GREEN"
    if [ $((failures + errors)) -gt 0 ]; then
      if [ "$known_bug_only" = "yes" ]; then
        status="RED-EXPECTED (only the known bug)"
      else
        status="RED (genuine failure at this checkpoint)"
        ALL_CLEAN="no"
      fi
    fi
  fi
  msg=$(git log -1 --format=%s "$sha")
  echo "COMMIT_${i}=${sha:0:8} \"$msg\" -> $status"
done

git checkout -q "$ORIGINAL_REF" 2>/dev/null
rm -rf target

echo "ALL_CHECKPOINTS_CLEAN=$ALL_CLEAN"

# --- Check 2: extract-before-delete evidence ---
EXTRACT_BEFORE_DELETE="no"
i=0
LAST_SHA=$(echo "$COMMITS" | tail -1)
for sha in $COMMITS; do
  i=$((i + 1))
  [ "$sha" = "$LAST_SHA" ] && [ "$COMMIT_COUNT" -gt 1 ] && continue  # only check commits before the last
  if git show "$sha:src/main/java/bench/LoyaltyBonusService.java" > /dev/null 2>&1; then
    old_body=$(git show "$sha:src/main/java/bench/GodClass.java" 2>/dev/null | sed -n '/calculateLoyaltyBonus/,/^    }/p' | wc -l)
    if [ "$old_body" -gt 4 ]; then
      EXTRACT_BEFORE_DELETE="yes"
      break
    fi
  fi
done
echo "EXTRACT_BEFORE_DELETE_EVIDENCE=$EXTRACT_BEFORE_DELETE"

# --- Check 3: REFACTOR NOTE with removal criterion, final state ---
REFACTOR_NOTE="no"
if grep -rq "REFACTOR NOTE" src/main/java/bench/ 2>/dev/null; then
  REFACTOR_NOTE="yes"
fi
echo "REFACTOR_NOTE_PRESENT=$REFACTOR_NOTE"

if [ "$ALL_CLEAN" = "yes" ] && [ "$COMMIT_COUNT" -gt 1 ]; then
  echo "RESULT=PASS (incremental, every checkpoint clean)"
elif [ "$ALL_CLEAN" = "no" ]; then
  echo "RESULT=FAIL (at least one intermediate commit broke something beyond the known bug)"
else
  echo "RESULT=NOT_INCREMENTAL (single commit — can't verify step-by-step discipline, only the end state)"
fi
