#!/bin/bash
#
# Example
#
# $  ./scripts/decode-jwt.sh ~/.jwt                                                                            
# {
#   "alg": "RS512",
#   "typ": "JWT",
#   "kid": "v1",
#   "jku": "https://product-tst.apis.f5networks.net/ee/v1/keys/jwks"
# }
# 
# {
#  "sub": "TST-........-....-....-....-............",
#  "iat": 1748749444,
#  "iss": "F5 Inc.",
#  "aud": "urn:f5:teem",
#  "jti": "........-....-....-....-............",
#  "f5_order_type": "paid",
#  "f5_sat": 1780185600
#}
#
#iat    (UTC): Sun Jun  1 03:44:04 AM UTC 2025
#f5_sat (UTC): Sun May 31 12:00:00 AM UTC 2026
#

jwt=$1
if [[ ! -f "$jwt" ]]; then
  echo "Error: File '$jwt' does not exist." >&2
  echo "Usage: $0 <jwt file>"
  exit 1
fi

f1=$(cut -d\. -f1 $1)
echo $f1 | base64 -d | jq
echo ""

f2=$(cut -d\. -f2 $1)
decoded=$(echo $f2 | base64 -d)
echo $decoded | jq
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
