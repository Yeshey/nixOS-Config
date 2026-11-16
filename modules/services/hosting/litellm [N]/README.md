# LiteLLM models

Shared model gateway for OpenClaw and other clients.

Production endpoint: `http://127.0.0.1:4000/v1`

Stable aliases:

- `strong-fallback-chain`
- `weak-fallback-chain`

## Policy

Some services, like Vercel, have a free tier where you get $5 every
month. We use those paid models, but under two constraints:

1. **A truly free provider must sit above every paid one.** "Truly
   free" includes external free providers (Google AI Studio, NVIDIA NIM,
   Groq, local Ollama) **and** Vercel `$0/$0` SKUs (models whose
   `pricing.input` and `pricing.output` are both `$0` on the AI Gateway,
   e.g. `nvidia/nemotron-3.5-lightning-free`). Rate limits on free
   models at the top of a chain are expected and acceptable.
2. **Pricing weighs more than capability.** Rank paid models by
   `D = C² / TB4.0`, where `C = 0.8·P_in + 0.2·P_out` ($/1M tokens,
   agentic 4:1 ratio). Lower D is better. `D ≥ 1.0` means opt-in only,
   never in an auto-chain. `D < 0.3` is the sweet spot.

Free models — including Vercel `$0/$0` SKUs — score `D = 0` and are
ranked within their tier by TB4.0 descending.

The weak chain additionally follows a responsive-first objective (see
below), because its job is time-to-first-answer, not peak capability.

## Chain composition

**`strong-fallback-chain`** — capability-first, free before paid:

```
nvidia-deepseek-v4-1-flash      # free, TB 0.2677  (head; NIM AVAILABLE=true)
gemini-3.8-flash                # free, TB 0.197
gemini-3.7-flash                # free, TB 0.1364
vercel-deepseek-v4-1-flash-1017 # paid, TB 0.3384, D 0.043 (single paid slot)
gemini-3.6-flash                # free, TB 0.0707
gemini-3.5-flash                # free, TB 0.0657
gemini-3.5-flash-lite           # free, TB 0.0101
gemini-3.1-flash-lite           # free, TB 0.0051
gemini-3-flash                  # free, no AA (preview)
gemma-4-31b                     # free, no AA (31B dense)
gemma-4-26b                     # free, no AA (MoE 26B/4B)
vercel-nemotron-3-5-lightning-free # $0/$0, TB 0.0051 (graceful tail)
```

GLM-5.3 and GLM-5.3-Flash were removed on 2026-10-26: NIM deprecated
`z-ai/glm-5.3` on 10/27/2026 and `z-ai/glm-5.3-flash` was
`AVAILABLE=false` on NGC.

**`weak-fallback-chain`** — responsive-first, breadth over peak TB,
nothing below `gemini-3.1-flash-lite` (TB 0.0051):

```
gemini-3.8-flash                # free, TB 0.197
gemini-3.7-flash                # free, TB 0.1364
gemini-3.6-flash                # free, TB 0.0707
gemini-3.5-flash                # free, TB 0.0657
gemini-3.5-flash-lite           # free, TB 0.0101
nvidia-deepseek-v4-1-flash      # free, TB 0.2677 (provider diversity)
nvidia-mistral-large            # free, TB 0.2677 (provider diversity)
gemini-3.1-flash-lite           # free, TB 0.0051 (floor)
vercel-deepseek-v4-1-flash-1017 # paid, TB 0.3384, D 0.043 (single paid slot)
vercel-nemotron-3-5-lightning-free # $0/$0, TB 0.0051 (graceful tail)
```

`nvidia-minimax-m3-1-flash` was removed on 2026-10-26 (`AVAILABLE=false`
on NGC) and replaced by `nvidia-mistral-large`, which ties
`nvidia-deepseek-v4-1-flash` at TB 0.2677 and is still callable on NIM.

Both chains use exactly **one paid Vercel model**. The `$0/$0` Vercel SKU
at the tail is not a second paid slot — it costs nothing and only exists
so the chain degrades to *something* rather than erroring out if the paid
call fails.

## Model ranking

Reflects the current config as of 2026-10-26. `TB` is Terminal-Bench 4.0
from Artificial Analysis. `D` is computed from Vercel pricing.

**Free tier** (D = 0; sorted by TB descending):

| # | Alias | Provider | TB4.0 | Notes |
|---:|---|---|---:|---|
| 1 | `nvidia-deepseek-v4-1-flash` | NVIDIA NIM | 0.2677 | Strong-chain head |
| 2 | `nvidia-mistral-large` | NVIDIA NIM | 0.2677 | Tie; weak-chain diversity |
| 3 | `gemini-3.8-flash` | Google AI Studio | 0.197 | Weak-chain entry |
| 4 | `gemini-3.7-flash` | Google AI Studio | 0.1364 | Configured |
| 5 | `gemini-3.6-flash` | Google AI Studio | 0.0707 | Configured |
| 6 | `gemini-3.5-flash` | Google AI Studio | 0.0657 | Configured |
| 7 | `gemini-3.5-flash-lite` | Google AI Studio | 0.0101 | Configured |
| 8 | `gemini-3.1-flash-lite` | Google AI Studio | 0.0051 | Weak-chain floor |
| 9 | `nvidia-muse-glimmer-30b` | NVIDIA NIM | 0.0051 | Opt-in only |
| 10 | `nvidia-nemotron-3-5-lightning` | NVIDIA NIM | 0.0051 | Opt-in only |
| 11 | `vercel-nemotron-3-5-lightning-free` | Vercel ($0/$0) | 0.0051 | Both chains' graceful tail |
| — | `stepfun-ai/step-5-preview` (NIM id) | NVIDIA NIM | 0.3333 | Not configured — PREVIEW, `AVAILABLE=false`, fragile |
| — | `nvidia-gpt-oss-20b` | NVIDIA NIM | 0 (unscored) | Opt-in only |
| — | `gemma-4-31b` | Google AI Studio | no AA match | Opt-in only |
| — | `gemma-4-26b` | Google AI Studio | no AA match | Opt-in only |
| — | `gemini-3-flash` | Google AI Studio | no AA match | Opt-in only |
| — | `mimo-v2.6-9b-hyrulecastle-ollama` | local Ollama | no AA match | Opt-in only |
| — | `minicpm5-2b-ollama` | local Ollama | no AA match | Opt-in only |
| — | `groq-qwen-3-8-27b` | Groq | 0.0556 | Opt-in only — Preview tier, tool-use reliability unverified |
| — | `inceptio-mercury-3` | Inception Labs | no AA match | Opt-in only |

Removed 2026-10-26: `nvidia-glm-5-3` (NIM DEPRECATION 10/27/2026),
`nvidia-glm-5-3-flash` (`AVAILABLE=false`), `nvidia-minimax-m3-1-flash`
(`AVAILABLE=false`).

**Paid tier (Vercel)** — sorted by D ascending:

| # | Alias | Blend $/1M | TB4.0 | D | Notes |
|---:|---|---:|---:|---:|---|
| 1 | `vercel-deepseek-v4-1-flash-1017` | 0.12 | 0.3384 | 0.043 | Single paid slot across both chains |
| 2 | `vercel-muse-spark-1-3-contributor` | 0.12 | 0.3333* | 0.043 | Opt-in only — * inherited from Max (upper bound) |
| — | `vercel-deepseek-v4-1-flash-1017-fast` | 0.96 | 0.3384 | 2.72 | Opt-in only — 8× price over non-fast for identical TB |
| — | `vercel-mimo-v2-5-pro` | 0.365 | **0** | ∞ | Opt-in only — TB=0; superseded by `mimo-v2.6-flash` (not yet configured) |
| — | `vercel-mimo-v2-5` | 0.143 | **0** | ∞ | Opt-in only — TB=0; superseded by `mimo-v2.6-flash` (not yet configured) |
| — | `vercel-kimi-k2-7-code` | 1.56 | 0.0101 | 240 | Opt-in only |
| — | `vercel-morph-v3-large` | 1.10 | no TB | — | Opt-in only — edit-specialist, not chat |

`muse-spark-1.3-contributor` is marked `*`: AA has no `contributor` row,
so its TB is inherited from `Muse Spark 1.3 (Max)`. That is an **upper
bound** on the contributor tier's real capability; verify by measurement
before promoting it into any chain.

## Action required

- **`vercel-deepseek-v4-1-flash-1017-fast` is 8× the price of its non-fast
  sibling for identical TB.** It is currently opt-in only, which is the
correct default. Do not add it to any chain without a specific latency
  justification.
- **`vercel-mimo-v2-5` and `vercel-mimo-v2-5-pro` have TB = 0.** They are
  opt-in only. `mimo-v2.6-flash` (TB 0.2273, blend $0.168, D 0.124) is
  strictly better on both axes and should be added to `model_list` if
  these are ever referenced by real callers.
- **Artificial Analysis legacy API (`/api/v2/data/llms/models`) retires
  2026-11-04.** The current key is Free-tier: the replacement
  `/api/v2/language/models` returns HTTP 403 (Pro required). The `/free`
  variant works but exposes no Terminal-Bench scores. Without a Pro key
  or an alternate TB4.0 source, the weekly `bench-*` scripts lose their
  ranking column after 2026-11-04.
- **`nvidia-mistral-large` is not listed in the NGC catalog** (no
  `AVAILABLE`/`PREVIEW`/`DEPRECATION` flags), so it carries no published
  lifecycle data. It is callable on NIM today. Watch it via
  `bench-nim-deprecation`; if it silently disappears, fall back within the
  weak chain as usual.

## Candidates to investigate

- **`stepfun-ai/step-5-preview`** (NVIDIA NIM, free, TB 0.3333). Preview
  tier and `AVAILABLE=false` on NGC — fragile; do not promote while it
  carries those flags.
- **`vercel-mimo-v2.6-flash`** (Vercel, D 0.124). Beats both current
  `mimo-v2.5` variants on price and capability.
- **`moonshotai/kimi-k2.6`** (NVIDIA NIM, free, TB 0.0051, reasoning).
  Low score; only worth a slot if NIM loses both TB-0.2677 heads.
- **`inclusionai/ling-3.0-flash-sante`** (Vercel, $0/$0 tier, 256K
  context). Worth a look as a second free Vercel tail.

## Weekly maintenance

An automated agent should run `bench-tb-rankings`, `bench-nim-rankings`,
`bench-nim-deprecation`, `bench-vercel-value` once a week, diff against
this file, and open a review PR for:

- New NIM DEPRECATION dates within 14 days — flag for removal from chains.
- New `AVAILABLE=false` on an active chain member — flag for removal.
- New Vercel models with `D < 0.3` — propose as paid-tier candidates.
- New Vercel `$0/$0` SKUs with a TB4.0 score — propose as chain-top
  candidates, above any paid entry.
- Vercel `-fast` SKUs priced >2× their non-fast sibling with identical
  TB — propose swapping to non-fast.
- Paid models with `D ≥ 1.0` — propose moving to opt-in only.

Missing scores mean unknown, not zero. Do not assign TB = 0 to an
unmatched model. Confirm successful inference before recommending a new
entry; the benchmark score alone does not establish that a route works.
Rate-limiting on top-of-chain free entries is expected and is not a
reason to demote them.

**OpenCode** (opencode.ai/zen) offers free models (GLM 5.3, DeepSeek V4
Flash, etc.) but requires the OpenCode client — cannot be used as a
LiteLLM upstream.