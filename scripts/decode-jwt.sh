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
