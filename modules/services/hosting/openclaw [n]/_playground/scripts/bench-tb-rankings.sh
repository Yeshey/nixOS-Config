#!/usr/bin/env bash
# bench-tb-rankings — full Artificial Analysis Terminal-Bench 4.0 rankings.
#
# Source of truth for bench-nim-rankings, bench-nim-deprecation and
# bench-vercel-value. Run this first when you want every scored model in
# one list, no provider join, no pricing, no D formula.
#
# Columns:
#   TB4.0  Terminal-Bench 4.0 score (0..1)
#   intel  Artificial Analysis Intelligence Index
#   name   Human-readable AA model name
#
# Benchmark: Terminal-Bench 4.0
# Source:    https://artificialanalysis.ai
set -euo pipefail

AA_KEY_FILE="${AA_KEY_FILE:-/run/openclaw-secrets/artificial-analysis}"
if [ -z "${AA_KEY:-}" ]; then
  [ -r "$AA_KEY_FILE" ] || { echo "AA key file not readable: $AA_KEY_FILE" >&2; exit 1; }
  AA_KEY=$(cat "$AA_KEY_FILE")
fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

curl -fsS --connect-timeout 10 --max-time 60 \
  'https://artificialanalysis.ai/api/v2/data/llms/models' \
  -H "x-api-key: $AA_KEY" > "$TMP/aa.json"

jq -r '
  "TB4.0\tintel\tname",
  (.data
    | map(select(.name | type == "string"))
    | map({
        name,
        tb:    .evaluations.terminalbench_v4_0,
        intel: .evaluations.artificial_analysis_intelligence_index
      })
    | map(select(.tb | type == "number" and . > 0))
    | sort_by(-.tb)
    | .[]
    | [(.tb|(.*10000|round)/10000|tostring),
       (if .intel then (.intel|(.*10|round)/10|tostring) else "—" end),
       .name]
    | @tsv)
' "$TMP/aa.json" | column -t -s $'\t'