#!/bin/bash
# Kill orphaned Serena processes older than 4 hours
pkill -f "serena start-mcp-server" 2>/dev/null || true
pkill -f "typescript-language-server" 2>/dev/null || true
pkill -f "bash-language-server" 2>/dev/null || true
# Clean old Serena logs (>7 days)
find ~/.serena/logs/ -mtime +7 -delete 2>/dev/null || true
