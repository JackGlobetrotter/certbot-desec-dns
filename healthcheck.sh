#!/bin/sh
STATUS_FILE="/app/status"

echo "Running healthcheck at $(date)" >&2

if [ ! -f "$STATUS_FILE" ]; then
  echo "Status file $STATUS_FILE not found" >&2
  exit 1
fi

CONTENT=$(cat "$STATUS_FILE" 2>/dev/null)
echo "Status file content: '$CONTENT'" >&2

if [ "$CONTENT" = "healthy" ]; then
  echo "Health check passed" >&2
  exit 0
else
  echo "Health check failed" >&2
  exit 1
fi
