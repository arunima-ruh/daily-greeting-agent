---
name: weather-greeting
version: 1.0.0
description: "Fetches current weather via wttr.in and composes a personalized greeting message."
user-invocable: false
metadata:
  openclaw:
    requires:
      bins: [curl, jq, date]
      env: [WEATHER_LOCATION]
---

# Weather Greeting Generator

Fetches current weather conditions and composes a friendly greeting message with weather context.

## Usage

This skill is executed by the agent when the daily greeting cron job triggers. It consists of two steps:

### Step 1: Fetch Weather Data

```bash
# Determine location (use env var or auto-detect)
LOCATION="${WEATHER_LOCATION:-}"

if [ -z "$LOCATION" ]; then
  WEATHER_URL="https://wttr.in/?format=j1"
else
  WEATHER_URL="https://wttr.in/${LOCATION}?format=j1"
fi

# Fetch weather data
curl -sf "$WEATHER_URL" > /tmp/weather.json

# Extract key fields
TEMP=$(jq -r '.current_condition[0].temp_C' /tmp/weather.json)
CONDITION=$(jq -r '.current_condition[0].weatherDesc[0].value' /tmp/weather.json)
LOCATION_NAME=$(jq -r '.nearest_area[0].areaName[0].value' /tmp/weather.json)

# Export for next step
export WEATHER_TEMP="$TEMP"
export WEATHER_CONDITION="$CONDITION"
export WEATHER_LOCATION_NAME="$LOCATION_NAME"
```

### Step 2: Compose Greeting Message

```bash
# Determine time-appropriate greeting
HOUR=$(date +%H)
if [ "$HOUR" -lt 12 ]; then
  GREETING="Good morning"
elif [ "$HOUR" -lt 17 ]; then
  GREETING="Good afternoon"
else
  GREETING="Good evening"
fi

# Select emoji based on condition
CONDITION_LOWER=$(echo "$WEATHER_CONDITION" | tr '[:upper:]' '[:lower:]')
case "$CONDITION_LOWER" in
  *clear*|*sunny*)
    EMOJI="☀️"
    ;;
  *partly*|*scattered*)
    EMOJI="⛅"
    ;;
  *cloud*)
    EMOJI="☁️"
    ;;
  *rain*|*drizzle*)
    EMOJI="🌧️"
    ;;
  *storm*|*thunder*)
    EMOJI="⛈️"
    ;;
  *snow*|*sleet*)
    EMOJI="❄️"
    ;;
  *)
    EMOJI="🌤️"
    ;;
esac

# Add temperature advice
TEMP_INT=$(echo "$WEATHER_TEMP" | cut -d. -f1)
if [ "$TEMP_INT" -lt 0 ]; then
  ADVICE="Bundle up! It's freezing out there."
elif [ "$TEMP_INT" -lt 10 ]; then
  ADVICE="It's chilly—grab a jacket!"
elif [ "$TEMP_INT" -lt 20 ]; then
  ADVICE="Perfect weather for a walk."
elif [ "$TEMP_INT" -lt 30 ]; then
  ADVICE="Nice and warm today!"
else
  ADVICE="Stay cool and hydrated!"
fi

# Compose final message
cat > /tmp/greeting.txt <<EOF
${GREETING}! ${EMOJI}

Here's your weather update for ${WEATHER_LOCATION_NAME}:
🌡️ Temperature: ${WEATHER_TEMP}°C
🌤️ Conditions: ${WEATHER_CONDITION}

${ADVICE}

Have a wonderful day!
EOF

# Output message for agent to send
cat /tmp/greeting.txt
```

## Error Handling

If weather fetch fails, compose a simple greeting without weather data:

```bash
HOUR=$(date +%H)
if [ "$HOUR" -lt 12 ]; then
  GREETING="Good morning"
elif [ "$HOUR" -lt 17 ]; then
  GREETING="Good afternoon"
else
  GREETING="Good evening"
fi

echo "${GREETING}! ☀️"
echo ""
echo "Have a wonderful day!"
```

## Dependencies

- **curl**: HTTP client for wttr.in API
- **jq**: JSON parser for weather data
- **date**: Time/date utilities

## Environment Variables

- `WEATHER_LOCATION` (optional): City name or lat,lon coordinates. If empty, auto-detects based on IP.

## Notes

- wttr.in is rate-limited to ~1000 requests per day (more than enough for daily use)
- No API key required
- Returns data in metric units (Celsius)
- Auto-detection works via IP geolocation (may not be accurate for VPN users)
