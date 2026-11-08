# README

Safe container for vibe coding

> **Security:** see [docs/security_review.md](docs/security_review.md) for the threat model, `rw` mount analysis, and hardening recommendations.

This setup gives you:
- write access limited to the configured project folder
- LLM keys and MCP endpoints via .env
- reliable access to IntelliJ and VS Code MCP servers on the host
- host Oh My Zsh (and plugins like git) reused inside the container
- simple start/stop
- a clean image-based base you can use with agents such as Mistral Vibe, OpenCode, Kilo, etc.

## Pre-requisites

- Install and run `Docker`
- Copy `.env.template` to `.env`, and edit `HOST_PROJECT_DIR`
- For `.oh-my-zsh` (we will expose the host settings to the container) check and edit if necessary your `~/.zshrc`:
  - Do a safe source of `~/.bash_profile` like this: `[[ -f ~/.bash_profile ]] && source ~/.bash_profile`
  - Export of `ZSH` should look like `export ZSH="$HOME/.oh-my-zsh"` or `export ZSH="${ZSH:-$HOME/.oh-my-zsh}"`. Remove any hard-coded `/Users/USER_NAME/.oh-my-zsh`.

## Daily usage

```bash
# Adjust in `docker-compose.yml` ports, which you want to expose. See example inside.

# Start (builds image if Dockerfile or context changed)
./start.sh
# or
docker compose up -d --build

# Enter the sandbox (zsh is the default shell)
docker compose exec vibe zsh

# Inside the container you are already in /workspace (your project).
# OpenCode is preinstalled in the image (PATH is set via .bash_profile).
#
# First-time / provider setup:
#   opencode
#   /connect          # pick provider (Anthropic, OpenAI, xAI, OpenCode Zen, …) and paste API key
#   /models           # choose the active model
#   opencode auth list   # list saved credentials (optional)
#
# Keys from /connect and conversation history persist under .vibe-home/opencode/*
# (mounted into ~/.config|~/.local/share|~/.local/state|~/.cache/opencode) so they
# survive image rebuilds and container recreates. LLM keys in .env are also available.
#
# Other agent CLIs (Kilo, Mistral Vibe, …) are not baked in by default. Add them
# to the Dockerfile the same way as OpenCode (see the comment block there), then
# mount their config/cache dirs under .vibe-home if you need persistence across rebuilds.

# Stop
./stop.sh
# or
docker compose down
```

## Host-side MCP Setup

See related instruction:
- [IntelliJ CE MCP setup](./docs/mcp-setup/intellij.md)
- [VSCode MCP setup](./docs/mcp-setup/vscode.md)
- [Xcode MCP setup](./docs/mcp-setup/xcode.md)

Activate necessary MCP configuration in [./.vibe-home/opencode/config/opencode.jsonc](./.vibe-home/opencode/config/opencode.jsonc) by switch related `enabled` flag to `true`.

## Important extras

| Topic | Recommendation |
|-|-|
| Swift / Xcode | Docker cannot run the real Xcode toolchain. Use related Xcode MCP |
| Git identity | `~/.ssh` is mounted read-only for push/fetch. Set `user.name` / `user.email` inside the container (or via env) if commits should not use the image defaults. |
| Secrets | Never put API keys in the image or in git. Keep using `.env` + `env_file` only; `.env` is already in `.gitignore`. |
| Multiple projects | Point `HOST_PROJECT_DIR` at another tree and recreate/restart the container, or use a separate Compose project directory. |
| Network isolation | The container has internet (needed for LLM APIs). Tighten later with a custom network / firewall if you need it. |
| File ownership | Default process uid is `1000` (`node`). On Docker Desktop (macOS) this is usually fine. On Linux set `UID`/`GID` in `.env` to your host ids if you want bind-mounted files owned by your user. |
| Container restart | `restart: unless-stopped` keeps the sandbox available after Docker daemon restarts. |
| Security | See [docs/security_review.md](docs/security_review.md). Prefer named volumes for package caches; keep `HOST_PROJECT_DIR` narrow. |

## Minimal verification

```bash
# From host – start stack
docker compose down
./start.sh
docker compose exec vibe zsh

# See first characters of your AI key → Key is available inside container
echo $MISTRAL_API_KEY | head -c 8; echo;
# Check that IDEA MCP is accessible from container (first, start IntelliJ and run proxy on host)
curl -s -o /dev/null -w "%{http_code}" http://host.docker.internal:$IDEA_MCP_PORT/sse || true # should kind of hang. Review proxy log on host. Press Ctrl+C for exit.
# Check that VSCode MCP is accessible from container
curl -N -H "Accept: text/event-stream" --max-time 3 "$VSCODE_MCP_URL" 2>/dev/null | head -5; echo "→ exit code: $?"

echo $ZSH                                   # /home/node/.oh-my-zsh
[[ -f $ZSH/oh-my-zsh.sh ]] && echo omz_ok   # should be *omz_ok*
la                                          # alias from bash_profile
type glo                                    # git plugin function
echo $LANG                                  # should be *UTF-8*
```

## Docker compose reference for OpenCode volumes
                      
What OpenCode stores in each directory:

| Mount | Purpose | What's inside |
|----|----|----|
| ~/.config/opencode | Configuration | auth tokens, provider settings, model prefs, keybinds, themes, global config |
| ~/.local/share/opencode | Sessions & data | conversation history, sessions, agent state, conversation |
| ~/.local/state/opencode | Runtime state | model preferences, prompt history, UI state |
| ~/.cache/opencode | Cache | package cache, model downloads, temporary artifacts |
| ~/.opencode/plan | Plans | plan files from Plan mode |

Together these cover everything OpenCode generates that needs to survive container rebuilds

