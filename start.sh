#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Ensure the agent home directory exists and is writable by the container user
mkdir -p .vibe-home
# OpenCode persistence dirs (mounted into the container; must exist before compose up)
mkdir -p \
  .vibe-home/opencode/config \
  .vibe-home/opencode/share \
  .vibe-home/opencode/state \
  .vibe-home/opencode/cache
chmod -R u+rwX .vibe-home

echo "Starting vibe container (build if needed)..."
docker compose up -d --build

echo "Container started. Enter with:  docker compose exec vibe zsh"
