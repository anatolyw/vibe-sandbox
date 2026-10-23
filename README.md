# README

## Pre-requisites

Install and run `Docker`

## Daily usage

```bash
# Start
./start.sh
# or
docker compose up -d

# Enter the sandbox
docker compose exec vibe bash

# Inside the container you are already in /workspace (your project)
# Install / run your preferred agent, e.g.:
#   npm i -g @kilocode/cli && kilo
#   or curl -fsSL https://opencode.ai/install | bash && opencode
#   or the Mistral Vibe one-liner

# Stop
./stop.sh
# or
docker compose down
```

## MCP Setup

#### IntelliJ CE MCP setup (host side)

1. In IntelliJ IDEA Community Edition (2025.2+): **Settings → Tools → MCP Server → enable Enable MCP Server**.
1. Click **Copy SSE Config** or **Copy HTTP Stream Config**. Note the port (usually starts at `64342`).
1. Put that port into `.env` as `IDEA_MCP_PORT`.
1. (Recommended for Docker) In **Settings → Build, Execution, Deployment → Debugger** enable **Can accept external connections** so the MCP server is reachable from the container via `host.docker.internal`.

#### Host-side setup for VSCode

1. Install the extension: **VSCode MCP Server** by Semantic Workbench Team (`SemanticWorkbenchTeam.mcp-server-vscode`).
2. It starts automatically (default port `6010`).
3. To change the port:
  - Command Palette → `Set MCP Server Port`, or
  - Settings → search `mcpServer.port`.
4. Put the actual port into `.env` as `VSCODE_MCP_PORT`.
5. No extra “accept external connections” toggle is required (unlike IntelliJ’s debugger setting), but the server must be running while the container is up.

#### Usage inside container

Inside the container the agent can then use:

```text
$VSCODE_MCP_URL          → http://host.docker.internal:6010/sse
$IDEA_MCP_URL            → http://host.docker.internal:64342/sse
$IDEA_MCP_STREAM_URL     → http://host.docker.internal:64342/stream
```

(with the optional `IJ_MCP_SERVER_PROJECT_PATH` header if your client needs it).

## Important extras you may have forgotten

| Topic | Recommendation |
|-|-|
| Git identity / SSH | Mount `~/.ssh` read-only if you need `git push`, or use HTTPS + token via env. Prefer not mounting the whole home. |
| Node / package caches | Optional volume for faster installs: `- node_modules_cache:/root/.npm` (or pnpm/yarn). |
| Swift / Xcode | Docker cannot run the real Xcode toolchain. Keep iOS builds on the host; use the container only for TS/Java/Kotlin/agent logic. |
| Gradle / Maven caches | Optional: mount `~/.gradle` or `~/.m2` if you want faster Java/Kotlin builds inside the container. |
| Network isolation | By default the container has internet (needed for LLM APIs). If you want stricter control, add a custom network + firewall rules later. |
| User ID mismatch | On Linux, file ownership can become root. Add `user: "${UID}:${GID}"` if it bothers you. |
| Secrets | Never put API keys in the image or in git. `.env` + `env_file` is the right pattern. |
| Multiple projects | Change `HOST_PROJECT_DIR` in `.env` and recreate the container, or use separate Compose projects. |
| Agent config persistence | The `vibe-home` volume keeps `~/.config`, history, etc. across restarts. |

## Minimal verification

```bash
# From host
docker compose up -d
# See first characters of your AI key → Key is available inside container
docker compose exec vibe bash -c 'echo $MISTRAL_API_KEY | head -c 8; echo;'
# Check that IDEA MCP is accessible from container
docker compose exec vibe bash -c 'curl -s -o /dev/null -w "%{http_code}" http://host.docker.internal:$IDEA_MCP_PORT/sse || true'
# Check that VSCode MCP is accessible from container
docker compose exec vibe bash -c 'curl -N -H "Accept: text/event-stream" --max-time 3 "$VSCODE_MCP_URL" 2>/dev/null | head -5; echo "→ exit code: $?"'
```

You should see the beginning of your key and (if IntelliJ MCP is running) an HTTP response.

This gives you:

- write access limited to the configured project folder
- all LLM keys and MCP endpoints via `.env`
- reliable access to IntelliJ’s MCP server on the host
- simple start/stop commands
- a clean base you can later switch to any of the CLIs we discussed (Mistral Vibe, OpenCode, Kilo, etc.)