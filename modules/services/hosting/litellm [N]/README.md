# LiteLLM models

Shared model gateway for OpenClaw and other clients.

Production endpoint: `http://127.0.0.1:4000/v1`

Stable aliases:

- `strong-fallback-chain`
- `weak-fallback-chain`

Some services, like Vercel, have a free tier where you will get 5$ for free every month. We're using those models even if they cost something in those cases (keeping in mind the cost, preferring -contributor models bc they're cheaper), but their usage is exhausted that month, it can always fallback to another one.

## Model ranking

| Rank | Configured alias | Brief description |
|---:|---|---|
| 1 | `vercelAPI/.Muse Spark 1.3 Contributor` | Contributor variant; match evaluations to this exact variant. |
| 2 | `mylitellmAPI/.gemini-3.8-flash` | Gemini Flash candidate for general agent tasks. |
| 3 | `nvidiaAPI/.z-ai/glm-5.3-flash` | GLM 5.3 Flash through NVIDIA NIM — 320B MoE (18B active), 1M context, multimodal. |
| 4 | `nvidiaAPI/.meta/muse-glimmer-30b` | Muse Glimmer 30B through NVIDIA NIM — multimodal reasoning, tool calling. |
| 5 | `nvidiaAPI/.nvidia/nemotron-3.5-lightning-30b-a3b` | Nemotron 3.5 Lightning through NVIDIA NIM — 30B/3B active, 1M context. |
| 6 | `mylitellmAPI/.gemini-3.7-flash` | Alternative Gemini Flash route. |
| 7 | `mylitellmAPI/.gemini-3.6-flash` | Additional Gemini Flash fallback. |
| 8 | `vercelAPI/.MiMo V2.5 Pro` | MiMo Pro through Vercel. |
| 9 | `vercelAPI/.Kimi K2.7 Code` | Kimi Code variant through Vercel. |
| 10 | `mylitellmAPI/.gemma-4-31b` | Gemma 4 31B route. |
| 11 | `mylitellmAPI/.gemini-3.5-flash` | Earlier Gemini Flash fallback. |
| 12 | `mylitellmAPI/.gemma-4-26b` | Gemma 4 26B route. |
| 13 | `vercelAPI/.MiMo M2.5` | Additional MiMo route through Vercel. |
| 14 | `mylitellmAPI/.gemini-3-flash` | Earlier Gemini Flash route. |
| 15 | `mylitellmAPI/.gemini-3.5-flash-lite` | Flash-Lite candidate for lightweight tasks. |
| 16 | `nvidiaAPI/.openai/gpt-oss-20b` | GPT-OSS 20B through NVIDIA. |
| 17 | `mylitellmAPI/.gemini-3.1-flash-lite` | Additional Flash-Lite fallback. |
| 18 | `vercelAPI/.Morph V3 Large` | Morph V3 Large through Vercel. |

Aliases above identify configuration entries; they do not establish that a route
currently works or remains free.

## Removed models (2026-10-19)

| Alias | Provider | Model ID | Reason |
|---|---|---|---|
| `nvidia-deepseek-v4-pro` | NVIDIA NIM | `deepseek-ai/deepseek-v4-pro` | Deprecated Sep 2026; HTTP 000 timeout. |
| `nvidia-kimi-k3` | NVIDIA NIM | `moonshotai/kimi-k3` | HTTP 410 Gone; end-of-life Oct 15, 2026. Confirmed via NIM API. |
| `nvidia-glm-5-3` | NVIDIA NIM | `z-ai/glm-5.3` | Deprecating 10/27/2026; already timing out. |

## Candidates to investigate

- `deepseek-ai/deepseek-v4.1-flash` — new on NVIDIA NIM, 552B/8B MoE, 1M context, free. Replaces all deprecated DeepSeek V4 variants.
- `nvidia/nemotron-3-ultra-550b-a55b` — flagship free model on NVIDIA NIM, 550B/55B, 1M context, reasoning + tool use.
- `moonshotai/kimi-k3` — confirmed dead. NIM returned 410 Gone: EOL Oct 15, 2026. Also 403 on Vercel free tier.
- `inclusionai/ling-3.0-flash-sante` — free on Vercel AI Gateway (256K context). Note: ling-3.1-flash free promo ended Oct 13.
- Qwen 3.8 Max 0902 Next
- MiMo V2.6 Pro

**Removed from candidates:** `minimaxai/minimax-m2.7` (deprecated on NIM, replaced by MiniMax M3); `convaiinnovations/laya-free` (decision/classification model, not general chat); `inclusionai/ling-3.1-flash` (free promo ended Oct 13 2026).

- `vercel-muse-spark-1-3-contributor` — returns 403 on free Vercel tier (paid model, not free). Removed from strong-fallback-chain entry point.

These are investigation notes, not verified provider IDs. Confirm exact names,
configured-provider support, free quotas, and successful inference before adding.