#!/bin/bash
# check-environment.sh - Validate environment for daily-greeting-agent

set -e

echo "🔍 Checking environment for Daily Greeting Agent..."
echo

# Check required binaries
echo "📦 Checking required binaries..."
MISSING_BINS=()

for bin in curl jq; do
  if ! command -v "$bin" &> /dev/null; then
    echo "  ❌ $bin - NOT FOUND"
    MISSING_BINS+=("$bin")
  else
    VERSION=$(command -v "$bin" && $bin --version 2>&1 | head -n1 || echo "unknown")
    echo "  ✅ $bin - found ($VERSION)"
  fi
done

if [ ${#MISSING_BINS[@]} -gt 0 ]; then
  echo
  echo "❌ Missing binaries: ${MISSING_BINS[*]}"
  echo "Run: ./install-dependencies.sh"
  exit 1
fi

echo

# Check environment variables
echo "🔐 Checking environment variables..."

if [ ! -f .env ]; then
  echo "  ⚠️  .env file not found"
  echo "  Run: cp .env.example .env && edit .env"
  exit 1
fi

source .env

MISSING_VARS=()

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "  ❌ TELEGRAM_BOT_TOKEN - NOT SET"
  MISSING_VARS+=("TELEGRAM_BOT_TOKEN")
else
  echo "  ✅ TELEGRAM_BOT_TOKEN - set"
fi

if [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "  ❌ TELEGRAM_CHAT_ID - NOT SET"
  MISSING_VARS+=("TELEGRAM_CHAT_ID")
else
  echo "  ✅ TELEGRAM_CHAT_ID - set"
fi

if [ -z "$WEATHER_LOCATION" ]; then
  echo "  ℹ️  WEATHER_LOCATION - not set (will auto-detect)"
else
  echo "  ✅ WEATHER_LOCATION - set to: $WEATHER_LOCATION"
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  echo
  echo "❌ Missing required variables: ${MISSING_VARS[*]}"
  echo "Edit .env and set the required values"
  exit 1
fi

echo

# Test API connectivity
echo "🌐 Testing API connectivity..."

# Test wttr.in
echo -n "  Testing wttr.in... "
if curl -sf "https://wttr.in/?format=3" > /dev/null; then
  echo "✅ OK"
else
  echo "❌ FAILED"
  echo "  Cannot reach wttr.in - check internet connection"
  exit 1
fi

# Test Telegram API
echo -n "  Testing Telegram API... "
TELEGRAM_RESPONSE=$(curl -sf "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" || echo '{"ok":false}')
TELEGRAM_OK=$(echo "$TELEGRAM_RESPONSE" | jq -r '.ok')

if [ "$TELEGRAM_OK" = "true" ]; then
  BOT_NAME=$(echo "$TELEGRAM_RESPONSE" | jq -r '.result.username')
  echo "✅ OK (bot: @$BOT_NAME)"
else
  echo "❌ FAILED"
  echo "  Invalid TELEGRAM_BOT_TOKEN or API error"
  exit 1
fi

echo
echo "✅ All checks passed!"
echo
echo "Next steps:"
echo "  1. Run: ./test-workflow.sh (to test manually)"
echo "  2. Deploy to OpenClaw (see README.md)"
