#!/bin/bash
# test-workflow.sh - Test daily greeting workflow manually

set -e

echo "🧪 Testing Daily Greeting Agent workflow..."
echo

# Load environment
if [ ! -f .env ]; then
  echo "❌ .env file not found"
  echo "Run: cp .env.example .env && edit .env"
  exit 1
fi

source .env

# Step 1: Fetch weather
echo "Step 1: Fetching weather data..."
LOCATION=${WEATHER_LOCATION:-}
if [ -z "$LOCATION" ]; then
  WEATHER_URL="https://wttr.in/?format=j1"
  echo "  Using auto-detected location"
else
  WEATHER_URL="https://wttr.in/${LOCATION}?format=j1"
  echo "  Using location: $LOCATION"
fi

WEATHER_DATA=$(curl -sf "$WEATHER_URL" || echo '{}')
if [ "$WEATHER_DATA" = "{}" ]; then
  echo "  ❌ Failed to fetch weather data"
  exit 1
fi

TEMP=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].temp_C')
CONDITION=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].weatherDesc[0].value')
LOCATION_NAME=$(echo "$WEATHER_DATA" | jq -r '.nearest_area[0].areaName[0].value')

echo "  ✅ Weather: ${TEMP}°C, ${CONDITION} in ${LOCATION_NAME}"
echo

# Step 2: Compose greeting message
echo "Step 2: Composing greeting message..."
HOUR=$(date +%H)
if [ "$HOUR" -lt 12 ]; then
  GREETING="Good morning"
elif [ "$HOUR" -lt 17 ]; then
  GREETING="Good afternoon"
else
  GREETING="Good evening"
fi

MESSAGE="${GREETING}! ☀️

Here's your weather update for ${LOCATION_NAME}:
🌡️ Temperature: ${TEMP}°C
🌤️ Conditions: ${CONDITION}

Have a wonderful day!"

echo "  ✅ Message composed"
echo
echo "  Preview:"
echo "  ┌─────────────────────────────────────────┐"
echo "$MESSAGE" | sed 's/^/  │ /'
echo "  └─────────────────────────────────────────┘"
echo

# Step 3: Send to Telegram (dry-run option)
echo "Step 3: Send to Telegram?"
read -p "  Send message now? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "  Sending to Telegram..."
  
  TELEGRAM_RESPONSE=$(curl -sf -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{
      \"chat_id\": \"${TELEGRAM_CHAT_ID}\",
      \"text\": $(echo "$MESSAGE" | jq -Rs .),
      \"parse_mode\": \"HTML\"
    }" || echo '{"ok":false}')
  
  TELEGRAM_OK=$(echo "$TELEGRAM_RESPONSE" | jq -r '.ok')
  
  if [ "$TELEGRAM_OK" = "true" ]; then
    echo "  ✅ Message sent successfully!"
  else
    echo "  ❌ Failed to send message"
    echo "  Error: $(echo "$TELEGRAM_RESPONSE" | jq -r '.description')"
    exit 1
  fi
else
  echo "  ⏭️  Skipped (dry-run)"
fi

echo
echo "✅ Workflow test complete!"
echo
echo "To deploy:"
echo "  1. Copy files to OpenClaw workspace"
echo "  2. Install cron job: cp cron/daily-greeting.json ~/.openclaw/cron/"
echo "  3. Restart gateway: openclaw gateway restart"
