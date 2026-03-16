#!/bin/bash
# Start Lightpanda CDP server if not already running
if ! pgrep -f "lightpanda serve" > /dev/null 2>&1; then
  "$HOME/.local/bin/lightpanda" serve --host 127.0.0.1 --port 9222 > /dev/null 2>&1 &
  disown
fi
