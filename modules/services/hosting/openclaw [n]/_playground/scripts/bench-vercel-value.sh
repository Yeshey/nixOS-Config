#!/usr/bin/env bash
# bench-vercel-value — Vercel AI Gateway × TB4.0 value ranking.
#
# D = (0.8·p_in + 0.2·p_out)² / TB4.0    (lower = better)
#
# Policy reminders:
#   - This ranks the Vercel *paid* pool only. At least one truly free
#     provider (AI Studio, NIM, Groq, local Ollama, or a Vercel $0/$0
#     SKU) must still sit above every entry here in any fallback chain.
#   - Vercel $0/$0 SKUs are listed in a separate section below; they
#     satisfy rule 1 on their own.
#
# See also:
#   bench-tb-rankings      — full TB4.0 rankings (run this first)
#   bench-nim-rankings     — NIM free-tier × TB4.0
#   bench-nim-deprecation  — NIM deprecation schedule
set -euo pipefail

AA_KEY_FILE="${AA_KEY_FILE:-/run/openclaw-secrets/artificial-analysis}"
if [ -z "${AA_KEY:-}" ]; then
  [ -r "$AA_KEY_FILE" ] || { echo "AA key file not readable: $AA_KEY_FILE" >&2; exit 1; }
  AA_KEY=$(cat "$AA_KEY_FILE")
fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

curl -fsS https://ai-gateway.vercel.sh/v1/models > "$TMP/vercel.json"
curl -fsS --connect-timeout 10 --max-time 60 \
  'https://artificialanalysis.ai/api/v2/data/llms/models' \
  -H "x-api-key: $AA_KEY" > "$TMP/aa.json"

# ─── 1. Ranked: matched paid models ────────────────────────────────
jq -nr --slurpfile v "$TMP/vercel.json" --slurpfile a "$TMP/aa.json" '
  def norm:
    ascii_downcase
    | gsub("\\([^)]*\\)"; "")
    | gsub("[^a-z0-9]"; "")
    | sub("(max|xhigh|high|medium|low|reasoning|nonreasoning|contributor)$"; "");

  ($v[0]) as $V | ($a[0]) as $A |

  ($A.data
    | map(select(.name | type == "string"))
    | map({ name, tb: .evaluations.terminalbench_v4_0 })
    | map(select(.tb | type == "number" and . > 0))
    | map(. + { key: (.name | norm) })
    | group_by(.key)
    | map({ key: .[0].key, value: (sort_by(-.tb) | .[0]) })
    | from_entries
  ) as $tb

  | "D\tin$/1M\tout$/1M\tblend\tTB4.0\tvercel_id\taa_name",
    ($V.data
      | map(select(.pricing.input != null and .pricing.output != null))
      | map(select(.id | test("-free$") | not))
      | map({
          id,
          base: (.id | split("/") | last | norm),
          p_in:  ((.pricing.input|tonumber)  * 1000000),
          p_out: ((.pricing.output|tonumber) * 1000000),
          cost:  (((.pricing.input|tonumber)*0.8
                 + (.pricing.output|tonumber)*0.2) * 1000000)
        })
      | map(. + { hit: ($tb[.base] // null) })
      | map(select(.hit != null))
      | map(. + { d: (.cost * .cost) / .hit.tb })
      | sort_by(.d)
      | .[]
      | [ (.d     | (.*1000|round)/1000),
          (.p_in  | (.*10000|round)/10000),
          (.p_out | (.*10000|round)/10000),
          (.cost  | (.*1000|round)/1000),
          (.hit.tb| (.*10000|round)/10000),
          .id,
          (.hit.name + (if (.id | test("-contributor$")) then " *" else "" end)) ]
      | @tsv)
' | column -t -s $'\t'

cat <<'NOTE'

  * matched via `-contributor` tier; TB inherited from the base model's
    Max run. Contributor is materially weaker than Max-tier — treat this
    D as an upper bound on value, not a like-for-like score.
NOTE

# ─── 2. Vercel $0/$0 SKUs ──────────────────────────────────────────
echo
echo "── Vercel \$0/\$0 SKUs (valid rule-1 chain entries) ──"
echo
echo "  These are genuinely free (pricing.input = pricing.output = 0) and"
echo "  may sit at the top of any fallback chain. Rate-limiting is fine —"
echo "  it is not the same as paid. TB inherited from the paid sibling."
echo
jq -nr --slurpfile v "$TMP/vercel.json" --slurpfile a "$TMP/aa.json" '
  def norm:
    ascii_downcase
    | gsub("\\([^)]*\\)"; "")
    | gsub("[^a-z0-9]"; "")
    | sub("(max|xhigh|high|medium|low|reasoning|nonreasoning|contributor)$"; "");

  ($v[0]) as $V | ($a[0]) as $A |

  ($A.data
    | map(select(.name | type == "string"))
    | map({ name, tb: .evaluations.terminalbench_v4_0 })
    | map(select(.tb | type == "number" and . > 0))
    | map(. + { key: (.name | norm) })
    | group_by(.key)
    | map({ key: .[0].key, value: (sort_by(-.tb) | .[0]) })
    | from_entries
  ) as $tb

  | "TB4.0\tvercel_id\taa_name",
    ($V.data
      | map(select(.pricing.input != null and .pricing.output != null))
      | map(select((.pricing.input|tonumber) == 0 and (.pricing.output|tonumber) == 0))
      | map(. + { base: (.id | split("/") | last | norm | sub("free$";"")) })
      | map(. + { hit: ($tb[.base] // null) })
      | sort_by(if .hit then -.hit.tb else 1e6 end)
      | .[]
      | [ (if .hit then (.hit.tb|(.*10000|round)/10000|tostring) else "—" end),
          .id,
          (if .hit then .hit.name else "—" end) ]
      | @tsv)
' | column -t -s $'\t'

# ─── 3. Unmatched Vercel SKUs ───────────────────────────────────────
echo
echo "── Unmatched Vercel SKUs (no AA row after normalization) ──"
echo
jq -nr --slurpfile v "$TMP/vercel.json" --slurpfile a "$TMP/aa.json" '
  def norm:
    ascii_downcase
    | gsub("\\([^)]*\\)"; "")
    | gsub("[^a-z0-9]"; "")
    | sub("(max|xhigh|high|medium|low|reasoning|nonreasoning|contributor)$"; "");

  ($v[0]) as $V | ($a[0]) as $A |

  ($A.data
    | map(select(.name | type == "string"))
    | map(.name | norm)
    | unique) as $keys

  | "in$/1M\tout$/1M\tblend\tvercel_id\tnormalized",
    ($V.data
      | map(select(.pricing.input != null and .pricing.output != null))
      | .[]
      | .id as $id
      | ($id | split("/") | last | norm) as $k
      | select($keys | index($k) | not)
      | [ (((.pricing.input|tonumber)*1000000)  | (.*10000|round)/10000),
          (((.pricing.output|tonumber)*1000000) | (.*10000|round)/10000),
          ((((.pricing.input|tonumber)*0.8 + (.pricing.output|tonumber)*0.2)*1000000)
            | (.*1000|round)/1000),
          $id,
          $k ]
      | @tsv)
' | column -t -s $'\t'