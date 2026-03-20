# ☀️ Daily Greeting Agent

An OpenClaw-native agent that sends a friendly daily greeting with weather updates to Telegram at 11:00 AM IST.

## Features

- 🌤️ Fetches current weather via wttr.in (no API key required)
- 💬 Sends personalized greeting messages to Telegram
- ⏰ Scheduled daily at 11:00 AM IST (5:30 AM UTC)
- 🎯 Fully OpenClaw-native (no external orchestrators)

## Quick Start

### Prerequisites

- OpenClaw Gateway installed and running
- Telegram bot token and chat ID
- `curl` and `jq` installed

### Installation

1. **Validate environment:**
   ```bash
   chmod +x check-environment.sh install-dependencies.sh test-workflow.sh
   ./check-environment.sh
   ```

2. **Install dependencies (if needed):**
   ```bash
   ./install-dependencies.sh
   ```

3. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your values:
   # - TELEGRAM_BOT_TOKEN (required)
   # - TELEGRAM_CHAT_ID (required)
   # - WEATHER_LOCATION (optional, defaults to auto-detect)
   ```

4. **Test manually:**
   ```bash
   source .env
   ./test-workflow.sh
   ```

5. **Deploy to OpenClaw:**
   ```bash
   # Copy agent files to your OpenClaw workspace
   cp -r workspace/* ~/.openclaw/workspace/
   cp -r skills/* ~/.openclaw/workspace/skills/
   cp openclaw.json ~/.openclaw/
   
   # Install cron job
   cp cron/daily-greeting.json ~/.openclaw/cron/
   
   # Restart gateway to load new config
   openclaw gateway restart
   ```

## Architecture

This agent follows OpenClaw-native patterns:

- **Skills**: Inline bash/python in SKILL.md (no separate run.py files)
- **Orchestration**: Lobster workflow + OpenClaw cron
- **Delivery**: Built-in `message()` tool (not stubs)
- **Execution**: Agent reads SKILL.md and executes via exec() tool

## Files

```
daily-greeting-agent/
├── README.md                    # This file
├── openclaw.json                # Agent configuration
├── .env.example                 # Environment template
├── .gitignore                   # Git ignore rules
├── check-environment.sh         # Environment validator
├── install-dependencies.sh      # Dependency installer
├── test-workflow.sh             # Manual workflow tester
├── cron/
│   └── daily-greeting.json      # OpenClaw cron schedule
├── workflows/
│   └── main.yaml                # Lobster workflow definition
├── workspace/
│   ├── SOUL.md                  # Agent persona & orchestration
│   └── IDENTITY.md              # Agent identity
└── skills/
    └── weather-greeting/
        └── SKILL.md             # Weather fetching & message composition
```

## Customization

### Change Schedule

Edit `cron/daily-greeting.json`:
```json
{
  "schedule": {
    "expr": "30 5 * * *"  // Change cron expression
  }
}
```

### Customize Greeting

Edit `skills/weather-greeting/SKILL.md` to modify the greeting message format.

### Change Location

Set `WEATHER_LOCATION` in `.env`:
```bash
WEATHER_LOCATION="London"
WEATHER_LOCATION="40.7128,-74.0060"  # Lat,Lon
```

## Troubleshooting

### "Command not found: curl"
Run: `./install-dependencies.sh`

### "Telegram API error"
- Verify `TELEGRAM_BOT_TOKEN` is correct
- Verify `TELEGRAM_CHAT_ID` is correct
- Check bot has permission to send messages to the chat

### "Weather fetch failed"
- Check internet connectivity
- Try setting `WEATHER_LOCATION` explicitly in `.env`

### Cron job not triggering
```bash
# Check OpenClaw logs
journalctl -u openclaw -f

# Verify cron job is loaded
ls ~/.openclaw/cron/
```

## Support

For issues or questions:
- OpenClaw Docs: https://docs.openclaw.com
- GitHub Issues: https://github.com/your-org/daily-greeting-agent
