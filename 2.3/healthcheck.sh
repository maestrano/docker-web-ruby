#!/bin/bash
# This script must exit with:
# 0 on success
# 1 on error

# Abort if no healthcheck
[ "$NO_HEALTHCHECK" == "true" ] && exit 0

if [ -f /app/.healthcheck ]; then
  bash /app/.healthcheck || exit 1
else
  curl -f http://localhost/ || exit 1
fi
