# Telegram bot operations

# Interactive Telegram operation selector
tg:
	@./scripts/interactive.sh \
		"Send test message::just tg-test"

# Send a test message via Telegram bot
tg-test:
	@./scripts/tg/test-send.sh
