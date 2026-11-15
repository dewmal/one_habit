#!/usr/bin/env bash
# Run the app on a phone or emulator and send chat to the gateway.
#
# Usage: tool/run_dev.sh [gateway-host]
#        tool/run_dev.sh macos    run as a macOS app, gateway on this Mac
#
# Where the gateway URL comes from, first match wins:
#   1. gateway-host argument, e.g. 10.0.2.2 for the Android emulator
#   2. GATEWAY_URL in the project's .env file (copy .env.example)
#   3. this Mac's Wi-Fi address (en0), on port 8080
#
# The gateway must already be running: cd server && go run .
# The AI key stays in server/.env. The app never gets it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"

# Reads KEY=value from the .env file. Prints nothing if it is missing.
env_value() {
  [[ -f "$ENV_FILE" ]] || return 0
  sed -n "s/^$1=//p" "$ENV_FILE" | tail -n 1 | tr -d '\r' \
    | sed -e 's/^"//' -e 's/"$//'
}

DEVICE_ARGS=()
if [[ "${1:-}" == "macos" ]]; then
  URL="http://127.0.0.1:8080/chat"
  DEVICE_ARGS=(-d macos)
elif [[ $# -ge 1 ]]; then
  URL="http://${1}:8080/chat"
elif [[ -n "$(env_value GATEWAY_URL)" ]]; then
  URL="$(env_value GATEWAY_URL)"
else
  URL="http://$(ipconfig getifaddr en0 2>/dev/null || echo 127.0.0.1):8080/chat"
fi
echo "Gateway: ${URL}"

FLUTTER="${FLUTTER:-flutter}"
exec "$FLUTTER" run ${DEVICE_ARGS[@]+"${DEVICE_ARGS[@]}"} \
  --dart-define=GATEWAY_URL="${URL}"
