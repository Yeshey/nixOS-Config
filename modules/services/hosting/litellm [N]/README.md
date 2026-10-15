# LiteLLM models

Shared model gateway for OpenClaw and other clients.

Production endpoint: `http://127.0.0.1:4000/v1`

Stable aliases:

- `strong-fallback-chain`
- `weak-fallback-chain`

## Model ranking

| Rank | Configured alias | Brief description |
|---:|---|---|
| 1 | `vercelAPI/.Muse Spark 1.3 Contributor` | Contributor variant; match evaluations to this exact variant. |
| 2 | `mylitellmAPI/.gemini-3.8-flash` | Gemini Flash candidate for general agent tasks. |
| 3 | `nvidiaAPI/.deepseek-ai/deepseek-v4-pro` | DeepSeek Pro through NVIDIA. |
| 4 | `nvidiaAPI/.moonshotai/kimi-k3` | Kimi K3 through NVIDIA. |
| 5 | `nvidiaAPI/.z-ai/glm-5.2` | GLM 5.2 through NVIDIA. |
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

## Candidates to investigate

- Qwen 3.8 Max 0902 Next
- MiMo V2.6 Pro
- Muse Glimmer

These are investigation notes, not verified provider IDs. Confirm exact names,
configured-provider support, free quotas, and successful inference before adding.