#!/bin/bash
set -e

# Start Xvfb for headful rendering
Xvfb :99 -screen 0 1280x720x16 &

## Initialize tracker
#AUTO_INIT=${VIBE_TICKER_AUTO_INIT:-"yes"}
#if [ ! -f /workspace/vibe-ticket-tracker.jsonc ] && [ "$AUTO_INIT" = "yes" ]; then
#  echo "Initializing..."
#  vibe-ticket-tracker init --port 61000 <<< $'\n\ny\ny\n'  # default port, default skill, yes MCP, yes agents
#fi

# Start tracker only if config exists
if [ -f /workspace/vibe-ticket-tracker.jsonc ]; then
  vibe-ticket-tracker start --port 61000 > /workspace/vibe-ticket-tracker.log 2>&1 &
  echo $! > /workspace/vibe-ticket-tracker.pid
  echo "Vibe Ticket Tracker started (PID: $(cat /workspace/vibe-ticket-tracker.pid))"
  echo "UI: http://localhost:61000"
else
  echo "No vibe-ticket-tracker config found — skipping."
fi

# Keep container alive; exit if tracker or Xvfb dies
wait



