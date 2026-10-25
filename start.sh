#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Ensure the agent home directory exists and is writable by the container user
mkdir -p .vibe-home
chmod -R u+rwX .vibe-home

echo "Starting vibe container (build if needed)..."
docker compose up -d --build

echo "Container started. Enter with:  docker compose exec vibe zsh"
