#!/usr/bin/env bash
#
# test-send.sh — Send a test message via Telegram Bot API
#
# DESCRIPTION
#   Reads the bot token from vaults/tg/token.txt and sends a test message.
#
#   The token file contains a Telegram Bot API token in the format:
#     <chat_id>:<secret_key>
#   The chat_id (the number before the colon) is used as the message recipient.
#   The full string is used as the bot authentication token.
#
# USAGE
#   ./scripts/tg/test-send.sh       # send test message
#   just tg-test                     # run via just command
#
# PREREQUISITES
#   - vaults/tg/token.txt must exist (run 'just decrypt' if encrypted)
#   - curl and python3 must be available
#
# EXIT CODES
#   0 — message sent successfully
#   1 — token file missing, empty, or send failure
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOKEN_FILE="${ROOT_DIR}/vaults/tg/token.txt"

# --- Validate token file ---
if [ ! -f "$TOKEN_FILE" ]; then
  echo "Error: token file not found at $TOKEN_FILE" >&2
  echo "Run 'just decrypt' to reveal secrets first." >&2
  exit 1
fi

# Read token — format is <chat_id>:<secret_key>
TOKEN="$(tr -d '[:space:]' < "$TOKEN_FILE")"

if [ -z "$TOKEN" ]; then
  echo "Error: token file is empty." >&2
  exit 1
fi

# Extract chat_id from the token (the number before the colon)
CHAT_ID="${TOKEN%%:*}"
API_URL="https://api.telegram.org/bot${TOKEN}"

# --- Verify bot identity ---
echo "Verifying bot token..."
if ! BOT_INFO="$(curl -sf "${API_URL}/getMe")"; then
  echo "Error: failed to reach Telegram API. Check your token or network." >&2
  exit 1
fi

BOT_NAME="$(echo "$BOT_INFO" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not data.get('ok'):
    print('invalid token')
else:
    r = data['result']
    print(f\"{r['first_name']} (@{r.get('username', 'N/A')})\")
" 2>/dev/null || echo "unknown")"
echo "Bot: ${BOT_NAME}"
echo "Chat ID: ${CHAT_ID}"

# --- Send test message ---
MESSAGE="[workman-tw.github.io] Test message at $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "Sending test message..."

RESPONSE="$(curl -sf -X POST "${API_URL}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\": ${CHAT_ID}, \"text\": \"${MESSAGE}\"}")"

OK="$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('ok', False))")"

if [ "$OK" = "True" ]; then
  echo "Message sent successfully."
else
  echo "Failed to send message:" >&2
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE" >&2
  exit 1
fi
