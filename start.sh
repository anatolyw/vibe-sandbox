#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Ensure the agent home directory exists and is writable by the container user
mkdir -p .vibe-home
chmod -R u+rwX .vibe-home

# Rebuild image only when Dockerfile (or build context) changed
echo "Building vibe image (if needed)..."
docker compose build

echo "Starting container..."
docker compose up -d

echo "Container started. Enter with:  docker compose exec vibe bash"
