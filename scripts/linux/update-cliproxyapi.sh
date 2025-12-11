#!/bin/bash
#
# CLIProxyAPI-Plus Update Script for Linux
# Usage:
#   ./update-cliproxyapi.sh              # Auto update
#   ./update-cliproxyapi.sh --prebuilt   # Force prebuilt
#   ./update-cliproxyapi.sh --force      # Force rebuild
#

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

REPO_URL="https://github.com/router-for-me/CLIProxyAPIPlus.git"
RELEASE_API="https://api.github.com/repos/router-for-me/CLIProxyAPIPlus/releases/latest"
CLONE_DIR="$HOME/CLIProxyAPIPlus"
BIN_DIR="$HOME/bin"
CONFIG_DIR="$HOME/.cli-proxy-api"
BINARY_NAME="cliproxyapi-plus"
BINARY_PATH="$BIN_DIR/$BINARY_NAME"

USE_PREBUILT=false; FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --prebuilt) USE_PREBUILT=true; shift ;;
        --force) FORCE=true; shift ;;
        *) shift ;;
    esac
done

echo -e "${MAGENTA}
==============================================
  CLIProxyAPI-Plus Updater
==============================================
${NC}"

echo -e "${CYAN}[*] Checking current installation...${NC}"
[ ! -f "$BINARY_PATH" ] && echo -e "${RED}[-] Binary not found. Run install first.${NC}" && exit 1
echo "    Current: $(stat -c %y "$BINARY_PATH" 2>/dev/null | cut -d' ' -f1)"

ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH_SUFFIX="linux_amd64" ;;
    aarch64|arm64) ARCH_SUFFIX="linux_arm64" ;;
    *) ARCH_SUFFIX="linux_amd64" ;;
esac

if [ "$USE_PREBUILT" = false ] && [ -d "$CLONE_DIR" ]; then
    echo -e "${CYAN}[*] Updating from source...${NC}"
    cd "$CLONE_DIR"
    git fetch origin main 2>/dev/null || git fetch origin master
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master)
    
    [ "$LOCAL" = "$REMOTE" ] && [ "$FORCE" = false ] && echo -e "${GREEN}[+] Already up to date!${NC}" && exit 0
    
    git pull origin main --rebase 2>/dev/null || git reset --hard origin/main 2>/dev/null || git reset --hard origin/master
    go build -o "$BINARY_PATH" ./cmd/server
    echo -e "${GREEN}[+] Binary rebuilt${NC}"
else
    echo -e "${CYAN}[*] Downloading prebuilt...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    if command -v jq &>/dev/null; then
        DOWNLOAD_URL=$(curl -s "$RELEASE_API" | jq -r ".assets[] | select(.name | contains(\"$ARCH_SUFFIX\")) | .browser_download_url" | head -n1)
    else
        DOWNLOAD_URL=$(curl -s "$RELEASE_API" | grep -o "https://[^\"]*${ARCH_SUFFIX}[^\"]*" | head -n1)
    fi
    
    [ -z "$DOWNLOAD_URL" ] && echo -e "${RED}[-] No binary found${NC}" && exit 1
    
    curl -sL -o "$TEMP_DIR/archive.tar.gz" "$DOWNLOAD_URL"
    cd "$TEMP_DIR"
    tar -xzf archive.tar.gz 2>/dev/null || unzip -q archive.tar.gz 2>/dev/null || true
    
    BINARY_FILE=$(find . -type f -name "cliproxyapi*" ! -name "*.gz" ! -name "*.zip" | head -n1)
    [ -n "$BINARY_FILE" ] && cp "$BINARY_PATH" "$BINARY_PATH.old" 2>/dev/null; chmod +x "$BINARY_FILE"; mv "$BINARY_FILE" "$BINARY_PATH"
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}[+] Binary updated${NC}"
fi

echo -e "${GREEN}
==============================================
  Update Complete!
==============================================
Binary:  $BINARY_PATH
Config:  $CONFIG_DIR/config.yaml (preserved)
Auth:    $CONFIG_DIR/*.json (preserved)
==============================================
${NC}"
