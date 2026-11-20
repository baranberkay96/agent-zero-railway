# Agent Zero v2 Autonomous AI Agent with Its Own Linux Shell: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Agent Zero v2 Autonomous AI Agent with Its Own Linux Shell** (major version of the pinned v2.16) |
| Description | General-purpose AI agent that writes and runs code in its own container. (72 chars) |
| Category | AI/ML |
| Tags | agent-zero, ai-agent, autonomous-agent, code-execution, llm, openrouter, anthropic, openai, mcp, self-hosted |
| Icon | `https://cdn.jsdelivr.net/gh/agent0ai/agent-zero@2b0b3a4…/webui/public/icon.svg` (200, image/svg+xml) |
| Repo | `baranberkay96/agent-zero-railway`, service root `/services/agent-zero` |

## Feasibility (checked 2026-11-20)

- Licence: MIT (`LICENSE`, Agent Zero s.r.o.; GitHub's detector shows NOASSERTION because of extra contact lines).
- No Docker-in-Docker: the official image is the agent's own runtime (supervisord with the web UI, SearXNG, cron, sshd; code runs inside the container). supervisord runs fine without PID 1.
- Image `agent0ai/agent-zero:v2.16`: amd64 3.20 GB compressed, under the 4 GB Trial/Free cap; our layer adds only scripts and the numpy repair.
- The agent runs code as root inside its own container (README says so); the login is on by default.

## Base market templates (checked 2026-11-20)

- `agent-zero` (16 active): `:latest`, volume `/a0/usr`, `AUTH_LOGIN`/`AUTH_PASSWORD` empty (no login), `RAILWAY_RUN_UID=0`, `A0_SET_*` model settings for Claude.
- `agent-zero-1` (2 active): `:latest`, generated login.
- `agent-zero-quick-start` (1 active): `:latest`, generated login, runtime numpy cleanup in the start command, healthcheck `/api/health`.

### Improvements over market templates

1. Pinned release (tag + index digest) instead of `:latest`.
2. Login on by default with a generated password; fail-closed checks (STANDARD 8.29) and a start-log warning if a login saved in Settings disables it.
3. numpy repair at build time (`fix-numpy.sh`): the v2.16 image mixes files of two numpy releases, `scipy.special` fails and Agent Zero logs `Error in preload: All ufuncs must have type numpy.ufunc` (seen on our first test deploy). Fixed once in the image instead of at every start.
4. Healthcheck `/api/health` with a 900 s window; optional provider keys under the names Agent Zero reads (`API_KEY_<PROVIDER>`).

## Pinned versions

| Component | Reference | Released | Checked |
|---|---|---|---|
| Agent Zero | `agent0ai/agent-zero:v2.16@sha256:0490714bf25bf481ea50d59ead21acec04344cee410a86b4e159908cb92ed8a2` | 2026-11-17 | 2026-11-20 |

## Architecture

```
Browser ──https──► Agent Zero :80 (login, web UI, agents)
                     ├─ SearXNG (localhost, web search)
                     ├─ cron, sshd (inside the container only; sshd root password random per boot)
                     └─ code execution in the same container
Volume /a0/usr: settings.json, .env (keys, login), chats, memory, knowledge, projects, workdir, plugins
```

## Services and variables

| Service | Source | Health | Domain | Volume |
|---|---|---|---|---|
| Agent Zero | repo `/services/agent-zero` | `/api/health`, 900 s | public, 80 | `/a0/usr` |

Variables: `AUTH_LOGIN=admin`, `AUTH_PASSWORD` (`secret(24)` alphanumeric), `PORT=80`, optional `API_KEY_OPENROUTER`, `API_KEY_ANTHROPIC`, `API_KEY_OPENAI`, `API_KEY_GOOGLE`, `TZ=UTC`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS=30`.

## Resource profile (measured on Railway, 2026-11-20)

| Service | Idle RAM | CPU idle |
|---|---|---|
| Agent Zero | 0.82 GB (after boot, before any chat) | ~0.004 vCPU |

Estimated cost idle: ~0.9 GB × $10 + volume ≈ **$9–10/month**; more while the agent works. Minimum plan: **Hobby** (Trial's 1 GB leaves no room for the embedding model and code execution).

## Test results (Railway, pre-publish, 2026-11-20)

RESULTS_PLACEHOLDER

## Verification checklist

- `https://{domain}/api/health` returns JSON.
- `/` redirects to `/login`; sign in with `AUTH_LOGIN`/`AUTH_PASSWORD`.
- Add a provider key in Settings, ask the agent to run `python -c "print(2+2)"`.
- Redeploy: chats and settings remain.

## Open questions

- Agent tasks with a real LLM key were not tested (no key in the test workspace).
- Agent Zero's in-app self-update changes the running container only; a redeploy returns to the pinned image.
