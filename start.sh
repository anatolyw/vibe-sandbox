#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Ensure the agent home directory exists and is writable by the container user
mkdir -p .vibe-home
chmod -R u+rwX .vibe-home

docker compose up -d
echo "Container started. Enter with:  docker compose exec vibe bash"
