#!/bin/bash
# get-dpu-nodes.sh
# Usage: ./get-dpu-nodes.sh inventory.yaml

inv_file="$1"

if [[ -z "$inv_file" || ! -f "$inv_file" ]]; then
  echo "Usage: $0 <inventory.yaml>"
  exit 1
fi

# Use yq if available (preferred)
if command -v yq >/dev/null 2>&1; then
  yq eval '.. | select(has("hosts")) | .hosts | keys | .[]' "$inv_file" \
    | grep -- '-dpu$' | sort -u
else
  # Fallback: grep/awk parse
  grep -E '^[[:space:]]*[A-Za-z0-9._-]+-dpu:' "$inv_file" \
    | sed -E 's/^[[:space:]]*([A-Za-z0-9._-]+-dpu):.*$/\1/' \
    | sort -u
fi
