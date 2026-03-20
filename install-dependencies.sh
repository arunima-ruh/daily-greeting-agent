#!/bin/bash
# install-dependencies.sh - Install dependencies for daily-greeting-agent
# Non-interactive — safe for automated deployment

set -e

echo "Installing dependencies for Daily Greeting Agent..."

# Use sudo only if not root
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS=$(uname -s)
fi

case "$OS" in
    ubuntu|debian)
        $SUDO apt-get update -qq
        $SUDO apt-get install -y -qq curl jq uuid-runtime lsof
        ;;
    fedora|rhel|centos)
        $SUDO dnf install -y curl jq
        ;;
    alpine)
        $SUDO apk add --no-cache curl jq
        ;;
    *)
        echo "WARNING: Unknown OS ($OS). Install manually: curl, jq"
        ;;
esac

echo "Dependencies installed."
