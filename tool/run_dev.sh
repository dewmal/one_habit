#!/usr/bin/env bash
# Run the app on a phone or emulator and send chat to the gateway on this Mac.
#
# Usage: tool/run_dev.sh [gateway-host]
#   gateway-host defaults to this Mac's Wi-Fi address (en0).
#   Use 10.0.2.2 for the Android emulator (it reaches the Mac as 10.0.2.2).
#
# The gateway must already be running: cd server && go run .
# The AI key stays in server/.env. The app never gets it.
set -euo pipefail

HOST="${1:-$(ipconfig getifaddr en0 2>/dev/null || echo 127.0.0.1)}"
URL="http://${HOST}:8080/chat"
echo "Gateway: ${URL}"

FLUTTER="${FLUTTER:-flutter}"
exec "$FLUTTER" run --dart-define=GATEWAY_URL="${URL}"
