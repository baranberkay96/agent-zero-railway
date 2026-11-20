# Deploy and Host Agent Zero with Railway

Agent Zero is an open-source, general-purpose AI agent that uses its own Linux environment as a tool: it writes and runs code, works in a terminal, searches the web, remembers what it learns and delegates to sub-agents. This community template runs the official Agent Zero v2 image on Railway with a login and persistent data.

## About Hosting Agent Zero

Agent Zero ships as one self-contained container: the web UI and agent framework, a private SearXNG metasearch instance for web search, a headless browser, a cron daemon and a Python/Node toolchain the agent executes code in. Because the agent's "computer" is the container itself, it does not need Docker-in-Docker or a Docker socket, which makes it a good fit for Railway.

The template turns on Agent Zero's own web login with a generated password and mounts a volume at `/a0/usr`, the folder upstream uses for settings, chats, memory, knowledge, projects, plugins and the agent's working directory. The image is pinned to a release, so a redeploy never changes the version under you.

## Common Use Cases

- Research tasks: search the web, read sources and write a report into the work folder
- Coding and data work: write scripts, install packages, analyse CSV files and produce charts
- Automation: scheduled tasks, MCP tools and other services in your Railway project
- A personal assistant with long-term memory and a knowledge base of your files
- Experimenting with multi-agent setups and custom agent profiles

## Dependencies for Agent Zero Hosting

- An LLM provider key (OpenRouter, Anthropic, OpenAI, Google and many more), entered in Settings or set as a Railway variable
- About 2 GB RAM (Hobby plan or higher)

### Deployment Dependencies

- Agent Zero source and docs: https://github.com/agent0ai/agent-zero
- Docker image: https://hub.docker.com/r/agent0ai/agent-zero
- Project site: https://www.agent-zero.ai
- Template source: https://github.com/baranberkay96/agent-zero-railway

### Implementation Details

| Service | What it runs | Public | Volume |
|---|---|---|---|
| Agent Zero | `agent0ai/agent-zero:v2.16` (pinned by digest) with a start wrapper | yes, port 80 | `/a0/usr` |

**First login.** Open the public URL and sign in with `AUTH_LOGIN` (default `admin`) and `AUTH_PASSWORD` (generated at deploy, in the service's Variables tab). Then open **Settings**, add an API key for your provider and choose the chat and utility models, or set `API_KEY_OPENROUTER`, `API_KEY_ANTHROPIC`, `API_KEY_OPENAI` or `API_KEY_GOOGLE` on Railway before deploying.

**Changing the login.** A login saved later in Settings is stored in `/a0/usr/.env` on the volume and takes precedence over the Railway variables. An empty, too short or too long `AUTH_PASSWORD` never opens the instance: the start log says the login is locked and how to fix it.

**What runs inside.** Agent Zero runs code as root inside its own container. It cannot reach your other Railway services unless you tell it their private addresses, but treat it like a shell you share with an AI: keep the login secret and only give it keys it needs.

**Resources.** RESOURCES_PLACEHOLDER

**Scaling.** One agent instance per service; state lives on the volume, so keep one replica. Give the service more CPU for heavy code execution.

**Upgrading.** The version is pinned in `services/agent-zero/Dockerfile` of the template repo. Back up `/a0/usr` (Settings > Backup), change the tag and digest to a newer release and redeploy. Agent Zero's in-app self-update changes only the running container; a redeploy returns to the pinned version.

### Why Deploy Agent Zero on Railway?

Railway gives Agent Zero HTTPS, a persistent volume and a generated login in one click, without a VPS to secure. The agent gets its own isolated Linux environment, you pay only for what it uses, and you can add databases or other tools to the same project for it to work with.
