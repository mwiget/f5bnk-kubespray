#!/usr/bin/env bash
#
# Unlock login.keychain-db on macOS if running there,
# otherwise exit silently.

KEYCHAIN=~/Library/Keychains/login.keychain-db
#security show-keychain-info "$KEYCHAIN" 2>&1
#exit

# Check for macOS (Darwin)
if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "security unlock-keychain $KEYCHAIN ..."
  if security show-keychain-info "$KEYCHAIN" 2>&1 | grep -q "not allowed"; then
    security unlock-keychain "$KEYCHAIN"
  fi
else
  echo "not running on OSX"
fi

exit 0
