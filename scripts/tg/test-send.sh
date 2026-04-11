#!/usr/bin/env bash
#
# test-send.sh — Send a test message via Telegram Bot API
#
# DESCRIPTION
#   Reads the bot token from vaults/tg/token.txt, verifies the bot identity,
#   auto-detects a chat ID from recent messages, and sends a test message.
#
#   The token file contains a standard Telegram Bot API token in the format:
#     <bot_id>:<secret_key>
#   For example: 123456789:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw
#
# USAGE
#   ./scripts/tg/test-send.sh                 # auto-detect chat from recent messages
#   CHAT_ID=123456789 ./scripts/tg/test-send.sh   # specify chat ID explicitly
#   just tg-test                              # run via just command
#
# PREREQUISITES
#   - vaults/tg/token.txt must exist (run 'just decrypt' if encrypted)
#   - curl and python3 must be available
#   - The bot must have received at least one message for auto-detect to work
#     (send any message to the bot in Telegram first)
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

# Read token — the file contains the full bot token (bot_id:secret_key)
TOKEN="$(tr -d '[:space:]' < "$TOKEN_FILE")"

if [ -z "$TOKEN" ]; then
  echo "Error: token file is empty." >&2
  exit 1
fi

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

# --- Resolve chat ID ---
# Allow explicit override via CHAT_ID environment variable
if [ -z "${CHAT_ID:-}" ]; then
  echo ""
  echo "Auto-detecting chat ID from recent messages..."
  UPDATES="$(curl -sf "${API_URL}/getUpdates?limit=10")"

  CHAT_ID="$(echo "$UPDATES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('result', [])
# Walk updates from newest to oldest, pick first message with a chat
for update in reversed(results):
    msg = update.get('message') or update.get('channel_post') or {}
    chat = msg.get('chat', {})
    cid = chat.get('id')
    if cid:
        title = chat.get('title') or chat.get('first_name') or str(cid)
        print(cid)
        print(f'Chat: {title}', file=sys.stderr)
        break
else:
    print('')
" 2>&1 1>/dev/null | head -1)"

  # Re-run to get just the chat_id on stdout
  CHAT_ID="$(echo "$UPDATES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for update in reversed(data.get('result', [])):
    msg = update.get('message') or update.get('channel_post') or {}
    cid = msg.get('chat', {}).get('id')
    if cid:
        print(cid)
        break
else:
    print('')
")"

  if [ -z "$CHAT_ID" ]; then
    echo "No recent chats found." >&2
    echo "Please send a message to the bot first, then run this script again." >&2
    echo "" >&2
    echo "Or specify a chat ID manually:" >&2
    echo "  CHAT_ID=<your_chat_id> $0" >&2
    exit 1
  fi
  echo "Detected chat ID: ${CHAT_ID}"
fi

# --- Send test message ---
MESSAGE="[workman-tw.github.io] Test message at $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "Sending to chat ${CHAT_ID}..."

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
