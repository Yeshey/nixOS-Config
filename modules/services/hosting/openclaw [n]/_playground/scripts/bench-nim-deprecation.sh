#!/usr/bin/env bash
# bench-nim-deprecation — NIM deprecation schedule (source: NGC catalog API).
#
# Answers: which NIM models are flagged PREVIEW, AVAILABLE=false, or have
# a published DEPRECATION date. Sorted by deprecation date, soonest first.
# The `callable` column is ground truth from /v1/models — `callable=no`
# means a config entry returns HTTP 410 right now.
#
# See also:
#   bench-tb-rankings     — full TB4.0 rankings (run this first)
#   bench-nim-rankings    — NIM × TB4.0 (which free NIMs are strongest)
#   bench-vercel-value    — Vercel AI Gateway value ranking
set -euo pipefail

AA_KEY_FILE="${AA_KEY_FILE:-/run/openclaw-secrets/artificial-analysis}"
if [ -z "${AA_KEY:-}" ]; then
  [ -r "$AA_KEY_FILE" ] || { echo "AA key file not readable: $AA_KEY_FILE" >&2; exit 1; }
  AA_KEY=$(cat "$AA_KEY_FILE")
fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

: > "$TMP/ngc.jsonl"
for p in 0 1; do
  curl -fsSG 'https://api.ngc.nvidia.com/v2/search/catalog/resources/ENDPOINT' \
    --data-urlencode "q={\"query\":\"*\",\"page\":$p,\"pageSize\":100}" \
    >> "$TMP/ngc.jsonl"
  echo >> "$TMP/ngc.jsonl"
done

curl -fsS https://integrate.api.nvidia.com/v1/models > "$TMP/nim.json"
curl -fsS https://artificialanalysis.ai/api/v2/data/llms/models \
  -H "x-api-key: $AA_KEY" > "$TMP/aa.json"

jq -nr --slurpfile ngc "$TMP/ngc.jsonl" \
       --slurpfile nim "$TMP/nim.json" \
       --slurpfile aa  "$TMP/aa.json" '
  def norm:
    ascii_downcase | gsub("\\([^)]*\\)";"") | gsub("[^a-z0-9]";"")
    | sub("(max|xhigh|high|medium|low|reasoning|nonreasoning|contributor)$";"");

  ($aa[0].data
    | map(select(.name|type=="string"))
    | map({name, tb: .evaluations.terminalbench_v4_0})
    | map(select(.tb|type=="number" and .>0))
    | map(. + {key:(.name|norm)})
    | group_by(.key) | map(sort_by(-.tb)|.[0])
    | map({(.key): .tb}) | add // {}
  ) as $tb |

  ($nim[0].data | map(.id)) as $live |

  ([ $ngc[] | .results[]?.resources[]? ] | unique_by(.resourceId)) as $res |

  [ $res[]
    | . as $r
    | ([.attributes[]? | select(.key=="DEPRECATION") | .value] | first) as $dep
    | ([.attributes[]? | select(.key=="AVAILABLE")   | .value] | first) as $avail
    | ([.attributes[]? | select(.key=="PREVIEW")     | .value] | first) as $prev
    | select($dep != null or $avail == "false" or $prev == "true")
    | ($r.name | norm) as $k
    | { name:  $r.name,
        rid:   $r.resourceId,
        dep:   $dep,
        avail: $avail,
        prev:  $prev,
        tb:    ($tb[$k] // null),
        live:  ([ $live[] | select((split("/")|last|norm) == $k) ] | length > 0),
        epoch: (if $dep then ($dep | strptime("%m/%d/%Y") | mktime) else null end) }
  ]
  | sort_by(.epoch // 9e9)
  | "DEPRECATION\tdays_left\tAVAILABLE\tPREVIEW\tTB4.0\tcallable\tname\tnim_id",
    (.[]
      | [ (.dep // "—"),
          (if .epoch then ((.epoch - now)/86400 | floor | tostring) else "—" end),
          (.avail // "—"), (.prev // "—"),
          (if .tb then (.tb|(.*10000|round)/10000|tostring) else "—" end),
          (if .live then "yes" else "no" end),
          .name, .rid ] | @tsv)
' | column -t -s $'\t'