#!/bin/bash

jwt=$1
if [[ ! -f "$jwt" ]]; then
  echo "Error: File '$jwt' does not exist." >&2
  echo "Usage: $0 <jwt file>"
  exit 1
fi

f1=$(cut -d\. -f1 $1)
echo $f1 | base64 -d
echo ""
echo ""

f2=$(cut -d\. -f2 $1)
decoded=$(echo $f2 | base64 -d)
echo $decoded
echo ""

# Extract and print
iat=$(echo "$decoded" | jq -r '.iat')
f5_sat=$(echo "$decoded" | jq -r '.f5_sat')

echo "iat    (UTC): $(date -u -d "@$iat")"
echo "f5_sat (UTC): $(date -u -d "@$f5_sat")"

now=$(date +%s)
echo ""
if (( f5_sat < now )); then
  echo "ERROR: jwt token has expired!"
  exit 2
fi
