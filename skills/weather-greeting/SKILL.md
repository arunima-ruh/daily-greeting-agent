---
name: weather-greeting
version: 3.0.0
description: "Fetches current weather and composes a personalized greeting message."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [curl, jq]
      env: [WEATHER_LOCATION]
    tools: [web_search]
---

# Weather Greeting Generator

Fetches current weather conditions and composes a friendly greeting message.

## Usage

### Step 1: Fetch Weather Data

**Primary method — curl to wttr.in:**

```bash
LOCATION="${WEATHER_LOCATION:-}"

if [ -z "$LOCATION" ]; then
  WEATHER_URL="https://wttr.in/?format=j1"
else
  WEATHER_URL="https://wttr.in/${LOCATION}?format=j1"
fi

curl -sf "$WEATHER_URL" > /tmp/weather.json

TEMP=$(jq -r '.current_condition[0].temp_C' /tmp/weather.json)
CONDITION=$(jq -r '.current_condition[0].weatherDesc[0].value' /tmp/weather.json)
LOCATION_NAME=$(jq -r '.nearest_area[0].areaName[0].value' /tmp/weather.json)
```

**If curl fails (exit code != 0, empty response, or connection refused), use fallback:**

```
web_search("current weather in ${WEATHER_LOCATION} temperature celsius conditions today")
```

Parse the search results to extract temperature, conditions, and location name.

**Decision logic:**
1. Try `curl` to `wttr.in` first via exec()
2. If exec() returns error, empty output, or HTTP 000 → use `web_search` as fallback
3. If `web_search` also fails → compose greeting without weather data

### Step 2: Compose Greeting Message

Based on the current time and weather data, build a greeting:

```
Determine greeting based on time:
  Before 12:00 → "Good morning"
  12:00–17:00  → "Good afternoon"
  After 17:00  → "Good evening"

Select emoji based on conditions:
  Clear/Sunny     → ☀️
  Partly cloudy   → ⛅
  Cloudy          → ☁️
  Rain/Drizzle    → 🌧️
  Storm/Thunder   → ⛈️
  Snow            → ❄️
  Default         → 🌤️

Add temperature advice:
  Below 0°C   → "Bundle up! It's freezing out there."
  0–10°C      → "It's chilly—grab a jacket!"
  10–20°C     → "Perfect weather for a walk."
  20–30°C     → "Nice and warm today!"
  Above 30°C  → "Stay cool and hydrated!"
```

Format the final message:

```
{Greeting}! {Emoji}

Here's your weather update for {Location}:
🌡️ Temperature: {Temp}°C
🌤️ Conditions: {Conditions}

{Advice}

Have a wonderful day!
```

### Step 3: Deliver to Telegram

Send the greeting via OpenClaw's message CLI using exec():

```bash
openclaw message send --channel telegram --target "${TELEGRAM_CHAT_ID}" --message "<greeting_text>" --json
```

Check the response for `"ok":true` to confirm delivery.

If sending fails, post the greeting in-chat as fallback.

## Error Handling

```
curl wttr.in → SUCCESS → use weather data
      ↓ FAIL
web_search → SUCCESS → use search results
      ↓ FAIL
Compose greeting WITHOUT weather → still deliver
```

Never skip the greeting. Always deliver something.

## Notes

- Primary: `curl` to `wttr.in` (no API key needed, returns JSON)
- Fallback: `web_search` tool (uses Gemini API key configured in OpenClaw)
- `curl` may be blocked in some sandbox environments (Daytona free tier) — that's when fallback kicks in
- `WEATHER_LOCATION` is optional — defaults to auto-detect if empty
