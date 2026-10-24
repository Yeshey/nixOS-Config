
```markdown
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
   free" includes both external free providers (Google AI Studio,
   NVIDIA NIM, Cerebras, local Ollama) **and** Vercel `-free` SKUs
   (models whose `pricing.input` and `pricing.output` are both `$0` on
   the AI Gateway, e.g. `nvidia/nemotron-3.5-lightning-free`). Rate
   limits on free models at the top of a chain are expected and
   acceptable.
2. **Pricing weighs more than capability.** Rank paid models by
   `D = C² / TB4.0`, where `C = 0.8·P_in + 0.2·P_out` ($/1M tokens,
   agentic 4:1 ratio). Lower D is better. `D ≥ 1.0` means opt-in only,
   never in an auto-chain. `D < 0.3` is the sweet spot.

Free models score `D = 0` (cost is zero) and are ranked within their
tier by TB4.0 descending.

## Model ranking

Reflects the current config as of 2026-10-24. `TB` is Terminal-Bench 4.0
from Artificial Analysis. `D` is computed from Vercel pricing.

**Free tier** (D = 0; sorted by TB descending):

| # | Alias | Provider | TB4.0 | Notes |
|---:|---|---|---:|---|
| 1 | `nvidiaAPI/.z-ai/glm-5.3` | NVIDIA NIM | 0.4192 | ⚠ DEPRECATION **10/27/2026** — remove now |
| 2 | `nvidiaAPI/.stepfun-ai/step-5-preview` | NVIDIA NIM | 0.3333 | Candidate, not yet configured |
| 3 | `nvidiaAPI/.z-ai/glm-5.3-flash` | NVIDIA NIM | 0.3283 | ⚠ `AVAILABLE=false` on NGC — remove |
| 4 | `nvidiaAPI/.deepseek-ai/deepseek-v4.1-flash` | NVIDIA NIM | 0.2677 | 🆕 Candidate — replaces deprecated GLM pair |
| 5 | `nvidiaAPI/.mistralai/mistral-large` | NVIDIA NIM | 0.2677 | Candidate |
| 6 | `nvidiaAPI/.minimaxai/minimax-m3.1-flash` | NVIDIA NIM | 0.2576 | Candidate |
| 7 | `mylitellmAPI/.gemini-3.8-flash` | Google AI Studio | 0.197 | Configured |
| 8 | `mylitellmAPI/.gemini-3.7-flash` | Google AI Studio | 0.1364 | Configured |
| 9 | `mylitellmAPI/.gemini-3.6-flash` | Google AI Studio | 0.0707 | Configured (weak-chain entry) |
| 10 | `mylitellmAPI/.gemini-3.5-flash` | Google AI Studio | 0.0657 | Configured |
| 11 | `mylitellmAPI/.cerebras-qwen-3.8-27b` | Cerebras | 0.0556 | Configured |
| 12 | `mylitellmAPI/.gemini-3.5-flash-lite` | Google AI Studio | 0.0101 | Configured |
| 13 | `mylitellmAPI/.gemini-3.1-flash-lite` | Google AI Studio | 0.0051 | Configured |
| 14 | `nvidiaAPI/.meta/muse-glimmer-30b` | NVIDIA NIM | 0.0051 | Configured |
| 15 | `nvidiaAPI/.nvidia/nemotron-3.5-lightning-30b-a3b` | NVIDIA NIM | 0.0051 | Configured |
| — | `nvidiaAPI/.openai/gpt-oss-20b` | NVIDIA NIM | 0 (unscored) | Configured; TB4.0 = 0, weak tail |
| — | `mylitellmAPI/.gemma-4-31b` | Google AI Studio | no AA match | Configured |
| — | `mylitellmAPI/.gemma-4-26b` | Google AI Studio | no AA match | Configured |
| — | `mylitellmAPI/.gemini-3-flash` | Google AI Studio | no AA match | Configured |
| — | `ollama/.mimo-v2.6-9b` | local Ollama | no AA match | Configured; not in any chain |

**Paid tier (Vercel)** — sorted by D ascending:

| # | Alias | Blend $/1M | TB4.0 | D | Notes |
|---:|---|---:|---:|---:|---|
| 1 | `vercelAPI/.deepseek-v4.1-flash-1017` | 0.12 | 0.3384 | 0.043 | 🆕 Best value; swap in place of `-fast` |
| 2 | `vercelAPI/.muse-spark-1.3-contributor` | 0.12 | 0.3333* | 0.043 | ⚠ Violates rule 1 as strong-chain entry; * inherited from Max |
| 3 | `vercelAPI/.mimo-v2.6-flash` | 0.168 | 0.2273 | 0.124 | 🆕 Strong cheap candidate |
| 4 | `vercelAPI/.minimax-m3.1-flash` | 0.24 | 0.2576 | 0.224 | 🆕 Strong candidate |
| 5 | `vercelAPI/.gpt-6-luna` | 0.18 | 0.1263 | 0.257 | Below the cutoff but usable |
| 6 | `vercelAPI/.ling-3.1-flash` | 0.42 | 0.3333 | 0.529 | Only if above are exhausted |
| 7 | `vercelAPI/.mimo-v2.6-pro` | 0.522 | 0.3485 | 0.782 | Best Vercel TB but 4× the cost of `mimo-v2.6-flash` |
| — | `vercelAPI/.deepseek-v4.1-flash-1017-fast` | 0.96 | 0.3384 | 2.72 | ⚠ 8× premium over non-fast for identical TB |
| — | `vercelAPI/.mimo-v2.5-pro` | 0.365 | **0** | ∞ | ⚠ TB=0. Remove; replaced by `mimo-v2.6-flash` |
| — | `vercelAPI/.mimo-v2.5` | 0.143 | **0** | ∞ | ⚠ TB=0. Remove |
| — | `vercelAPI/.kimi-k2.7-code` | 1.56 | 0.0101 | 240 | ⚠ Opt-in only; not a chain member |

`muse-spark-1.3-contributor` is deliberately marked `*`: AA has no
`contributor` row, so its TB is inherited from `Muse Spark 1.3 (Max)`.
That is an **upper bound** on the contributor tier's real capability;
verify by measurement before treating it as a like-for-like top-of-tier.


**OpenCode** (opencode.ai/zen) offers free models (GLM 5.3, DeepSeek V4
Flash, etc.) but requires the OpenCode client — cannot be used as a
LiteLLM upstream.