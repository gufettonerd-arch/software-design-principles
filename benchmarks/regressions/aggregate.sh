#!/usr/bin/env bash
# Aggregation helper for the four regressions-family scorers (score.sh,
# score-notests.sh, score-process.sh, score-quality.sh) — runs one scorer
# across N run directories and prints a compact table, instead of scoring
# each run by hand and copy-pasting the numbers into a report.
#
# Usage: aggregate.sh <scorer-script> <run-dir-1> [<run-dir-2> ...]
# Example: aggregate.sh score.sh /path/to/*/baseline-seed* /path/to/*/with-skill-seed*
#
# Writes each run's full scorer output to <run-dir>/aggregate-output.log
# (so nothing is lost if a field this script doesn't know about matters
# later) and prints only a summary line per run to stdout.
set -uo pipefail

SCORER="${1:?usage: aggregate.sh <scorer-script> <run-dir...>}"
shift

if [ ! -f "$SCORER" ]; then
  echo "No such scorer: $SCORER" >&2
  exit 2
fi

# Fields worth pulling into the summary table if the scorer emits them.
FIELDS="RESULT REGRESSION KNOWN_BUG_STATUS TESTS_WRITTEN_FOR_NEW_FLOW BEHAVIOR_STATUS REFACTOR_NOTE_PRESENT ALL_CHECKPOINTS_CLEAN EXTRACT_BEFORE_DELETE_EVIDENCE INCREMENTAL COMMIT_COUNT MAX_NESTING_DEPTH MAGIC_NUMBER_COUNT MAGIC_STRING_COUNT"

printf "%-45s" "RUN"
for f in $FIELDS; do printf " | %s" "$f"; done
echo ""

for run_dir in "$@"; do
  [ -d "$run_dir" ] || { echo "skip (not a dir): $run_dir" >&2; continue; }
  output=$(bash "$SCORER" "$run_dir" 2>&1)
  echo "$output" > "$run_dir/aggregate-output.log"

  label=$(basename "$(dirname "$run_dir")")/$(basename "$run_dir")
  printf "%-45s" "$label"
  for f in $FIELDS; do
    val=$(echo "$output" | grep "^${f}=" | head -1 | sed "s/^${f}=//")
    printf " | %s" "${val:--}"
  done
  echo ""
done
