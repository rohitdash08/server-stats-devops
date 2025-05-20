#!/usr/bin/env bash
# Simple integration tests for server-stats.sh
set -euo pipefail

# Capture output
output=$(bash bin/server-stats.sh)

# Basic checks
if [[ ! $output == *"=== CPU Usage ==="* ]]; then
  echo "CPU section missing" >&2
  exit 1
fi
if [[ ! $output == *"=== Memory Usage ==="* ]]; then
  echo "Memory section missing" >&2
  exit 1
fi
if [[ ! $output == *"=== Disk Usage ==="* ]]; then
  echo "Disk section missing" >&2
  exit 1
fi
if [[ ! $output == *"=== Top 5 by CPU ==="* ]]; then
  echo "Top CPU section missing" >&2
  exit 1
fi
if [[ ! $output == *"=== Top 5 by MEM ==="* ]]; then
  echo "Top MEM section missing" >&2
  exit 1
fi

echo "All sections present"