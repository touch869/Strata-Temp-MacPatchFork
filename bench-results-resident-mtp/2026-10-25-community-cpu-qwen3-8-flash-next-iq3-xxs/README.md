# Community benchmark on CPU only

Measured on 2026-10-25 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: CPU only, VRAM not read
- CPU: arm (18 cores, 18 threads); installed RAM: 64.0 GiB; storage: not measured
- OS: Darwin 27.0.0; GPU driver: not read; CUDA: not read
- Strata: project 0.1.44, commit 0675a650; engine 0.1.44-metal
- Background workloads and power limits: not recorded

## Model and configuration

- Model and quantization: qwen3.8-flash-next-iq3_xxs
- Context: 262144 tokens; parallel slots: 1
- Settings: the install's own configuration, unchanged; thinking off for the suite; temperature 0

## Method

Run by `python tools/strata_bench.py --long` against the HTTP API of a Strata server (already running); model loading is not timed. One warm-up chat and a 1K prompt are discarded first. Every prompt starts with a unique tag, so the conversation cache cannot help the fresh-prompt tests.

- short chat: the three questions of `tools/ab_engine.py`, up to 100 new tokens, 3 runs
- 4K / 16K prompts: generated word lists sized by a calibration request, 24 new tokens, 3 fresh prompts each
- agent session: system prompt and four tools, then 5 turns that each add about 1500 words of a project file and continue from the model's own earlier answers (the way agent clients resend a conversation), 64 new tokens per turn, 3 sessions; the cache numbers come from the answer's usage (`cached_tokens`) and timings (`prompt_n`)
- concurrency (when run): N requests sent at the same moment, total tokens over the wall time of the burst, latency over all requests

## Results

| Configuration | Actual prompt tokens | Reused tokens | Generated tokens | Runs | Prompt tok/s median and range | Decode tok/s median and range | TTFT seconds median and range |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 23.0 (9.0-56.0) | 0.64 (0.56-49.91) |
| 4K prompt, fresh | not measured | not measured | 24 cap | 0 | not measured | not measured | not measured |
| 16K prompt, fresh | not measured | not measured | 24 cap | 0 | not measured | not measured | not measured |
| 32K prompt, fresh | not measured | not measured | 24 cap | 0 | not measured | not measured | not measured |
| agent session, follow-up turns | not measured at the last turn | see below | up to 64 | 3 | see below | not measured | not measured |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: not measured; earlier-turn tokens read again per session: 0 (0-0) (earlier turns that the cache did not hold; the 0 (0-0) new tokens of the files are read once); first turn (nothing cached) first token: 13.96 s (9.96-14.58).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 108.9 | 14.576 | 16.0 |

### Skipped and failed

- failed 4K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 4K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 4K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 16K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 16K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 16K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed agent: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed agent: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed agent: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 32K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 32K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}
- failed 32K: {'type': 'server_error', 'message': 'the engine stopped unexpectedly (exit code 5); the next request restarts it'}

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 274 s.
