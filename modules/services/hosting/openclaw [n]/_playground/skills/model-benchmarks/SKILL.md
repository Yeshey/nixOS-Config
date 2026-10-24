---
name: model-benchmarks
description: Fetch current model rankings from BenchLM, Artificial Analysis, NVIDIA NIM, and Vercel AI Gateway when comparing models or maintaining LiteLLM.
---

Use curl and jq. Read the Artificial Analysis key from
`/run/openclaw-secrets/artificial-analysis`. Never print or copy the key.

Every command below assumes:

```bash
AA_KEY=$(cat /run/openclaw-secrets/artificial-analysis)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT