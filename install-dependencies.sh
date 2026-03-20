#!/bin/bash
# install-dependencies.sh - Install dependencies for daily-greeting-agent

set -e

echo "📦 Installing dependencies for Daily Greeting Agent..."
echo

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "❌ Cannot detect OS"
  exit 1
fi

case "$OS" in
  ubuntu|debian)
    echo "Detected: Debian/Ubuntu"
    sudo apt-get update
    sudo apt-get install -y curl jq
    ;;
  fedora|rhel|centos)
    echo "Detected: Fedora/RHEL/CentOS"
    sudo dnf install -y curl jq
    ;;
  arch|manjaro)
    echo "Detected: Arch/Manjaro"
    sudo pacman -S --noconfirm curl jq
    ;;
  alpine)
    echo "Detected: Alpine"
    sudo apk add --no-cache curl jq
    ;;
  *)
    echo "❌ Unsupported OS: $OS"
    echo "Please install manually: curl, jq"
    exit 1
    ;;
esac

echo
echo "✅ Dependencies installed successfully!"
echo
echo "Run: ./check-environment.sh"
