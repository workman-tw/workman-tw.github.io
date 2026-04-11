#!/usr/bin/env bash
# Send a test message via Telegram Bot API
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOKEN_FILE="${ROOT_DIR}/vaults/tg/token.txt"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Token file not found: $TOKEN_FILE" >&2
  echo "Run 'just decrypt' to reveal secrets first." >&2
  exit 1
fi

TOKEN="$(cat "$TOKEN_FILE" | tr -d '[:space:]')"

if [ -z "$TOKEN" ]; then
  echo "Token file is empty." >&2
  exit 1
fi

API_URL="https://api.telegram.org/bot${TOKEN}"

# Get bot info to verify token
echo "Verifying bot token..."
BOT_INFO="$(curl -sf "${API_URL}/getMe")"
BOT_NAME="$(echo "$BOT_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['first_name'])" 2>/dev/null || echo "unknown")"
echo "Bot: ${BOT_NAME}"

# Get recent updates to find a chat_id
echo ""
echo "Fetching recent chats..."
UPDATES="$(curl -sf "${API_URL}/getUpdates?limit=5")"

CHAT_ID="$(echo "$UPDATES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('result', [])
if not results:
    print('')
else:
    chat = results[-1].get('message', {}).get('chat', {})
    print(chat.get('id', ''))
" 2>/dev/null || echo "")"

if [ -z "$CHAT_ID" ]; then
  echo "No recent chats found."
  echo "Please send a message to the bot first, then run this script again."
  echo ""
  echo "Or specify a chat ID manually:"
  echo "  CHAT_ID=<your_chat_id> $0"
  CHAT_ID="${CHAT_ID:-}"
fi

# Allow override via environment variable
CHAT_ID="${CHAT_ID:-$CHAT_ID}"

if [ -z "$CHAT_ID" ]; then
  exit 1
fi

# Send test message
MESSAGE="[workman-tw.github.io] Test message sent at $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "Sending test message to chat ${CHAT_ID}..."

RESPONSE="$(curl -sf -X POST "${API_URL}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\": ${CHAT_ID}, \"text\": \"${MESSAGE}\"}")"

OK="$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('ok', False))" 2>/dev/null || echo "false")"

if [ "$OK" = "True" ]; then
  echo "Message sent successfully."
else
  echo "Failed to send message:" >&2
  echo "$RESPONSE" >&2
  exit 1
fi
