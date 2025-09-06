#!/usr/bin/env bash
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

jwt=$1
if [[ ! -f "$jwt" ]]; then
  echo "Error: File '$jwt' does not exist." >&2
  echo "Usage: $0 <jwt file>"
  exit 1
fi

f1=$(cut -d\. -f1 $1)
echo $f1 | base64 -d | jq
echo ""
