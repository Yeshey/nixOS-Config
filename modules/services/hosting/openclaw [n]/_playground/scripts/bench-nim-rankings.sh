#!/usr/bin/env bash
# bench-nim-rankings — NIM (free tier) × Terminal-Bench 4.0.
#
# Every model on integrate.api.nvidia.com is free-tier (rate-limited,
# no per-token billing). So this whole list is the free list — there is
# no cost column because there is no cost. Ranks NIM by TB4.0.
#
# See also:
#   bench-tb-rankings      — full TB4.0 rankings, no provider join (run first)
#   bench-nim-deprecation  — NIM deprecation schedule (what dies, and when)
#   bench-vercel-value     — Vercel AI Gateway value ranking (D = cost² / TB)
set -euo pipefail

AA_KEY_FILE="${AA_KEY_FILE:-/run/openclaw-secrets/artificial-analysis}"
if [ -z "${AA_KEY:-}" ]; then
  [ -r "$AA_KEY_FILE" ] || { echo "AA key file not readable: $AA_KEY_FILE" >&2; exit 1; }
  AA_KEY=$(cat "$AA_KEY_FILE")
fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

curl -fsS https://integrate.api.nvidia.com/v1/models > "$TMP/nim.json"
curl -fsS https://artificialanalysis.ai/api/v2/data/llms/models \
  -H "x-api-key: $AA_KEY" > "$TMP/aa.json"

jq -nr --slurpfile n "$TMP/nim.json" --slurpfile a "$TMP/aa.json" '
  def norm:
    ascii_downcase | gsub("\\([^)]*\\)";"") | gsub("[^a-z0-9]";"")
    | sub("(max|xhigh|high|medium|low|reasoning|nonreasoning|contributor)$";"");

  ($a[0].data
    | map(select(.name|type=="string"))
    | map({name, tb: .evaluations.terminalbench_v4_0})
    | map(select(.tb|type=="number" and .>0))
    | map(. + {key:(.name|norm)})
    | group_by(.key) | map(sort_by(-.tb)|.[0])
  ) as $aa

  | [ $n[0].data[]
      | .id as $id
      | ($id|split("/")|last|norm) as $k
      | (([ $aa[] | select(.key == $k) ] | first)
         // ([ $aa[]
               | select((.key|startswith($k)) or (.key as $ak | $k | startswith($ak)))
             ] | sort_by(.key|length) | last)) as $hit
      | {tb: ($hit.tb // -1), id: $id, name: ($hit.name // "(no AA match)")}
    ]
  | sort_by(-.tb)
  | "TB4.0\tnim_id\taa_name",
    (.[] | [ (if .tb < 0 then "—" else (.tb|(.*10000|round)/10000|tostring) end),
             .id, .name ] | @tsv)
' | column -t -s $'\t'