# NOTICE: Agent Zero v2 Autonomous AI Agent with Its Own Linux Shell template

## Software deployed

- **Agent Zero** by Agent Zero, s.r.o. and contributors, MIT License, https://github.com/agent0ai/agent-zero. Deployed unmodified from the official image `agent0ai/agent-zero:v2.16` (pinned by digest). The image bundles third-party software under their own licences (SearXNG AGPL-3.0, Playwright/Chromium, Python and Node packages), all unmodified.

## Written for this template

- `services/agent-zero/Dockerfile`, `services/agent-zero/railway-start.sh`: login checks and warnings; they call the image's own `/exe/initialize.sh`.
- `README.md`, `TEMPLATE.md`, `template.json`.

## Upstream files checked (read only, 2026-11-20)

- `docker/run/Dockerfile`, `docker/run/fs/exe/initialize.sh`, `docker/run/fs/exe/run_A0.sh`, `docker/run/fs/etc/supervisor/conf.d/supervisord.conf`, `docker/run/fs/ins/copy_A0.sh`, `docker/run/docker-compose.yml`, `helpers/login.py`, `helpers/dotenv.py`, `helpers/settings.py`, `models.py`, `prepare.py`, `api/health.py`, `docs/setup/installation.md`, `docs/setup/vps-deployment.md`, `conf/model_providers.yaml` at tag `v2.16`.

## Market templates reviewed

`agent-zero`, `agent-zero-1`, `agent-zero-quick-start` (configuration only; nothing copied).

## Names and affiliation

Community template, not affiliated with or endorsed by Agent Zero, s.r.o. The icon is Agent Zero's own web UI icon.
