#!/bin/bash
#
# CLIProxyAPI-Plus Uninstaller for Linux
# Usage:
#   ./uninstall-cliproxyapi.sh              # Keep auth files
#   ./uninstall-cliproxyapi.sh --all        # Remove everything
#   ./uninstall-cliproxyapi.sh --force      # No confirmation
#

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

BIN_DIR="$HOME/bin"
CONFIG_DIR="$HOME/.cli-proxy-api"
CLONE_DIR="$HOME/CLIProxyAPIPlus"
FACTORY_CONFIG="$HOME/.factory/config.json"

REMOVE_ALL=false; FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all|-a) REMOVE_ALL=true; shift ;;
        --force|-f) FORCE=true; shift ;;
        *) shift ;;
    esac
done

echo -e "${RED}
==========================================
  CLIProxyAPI-Plus Uninstaller
==========================================
${NC}"

echo -e "${CYAN}[*] Scanning installation...${NC}"

# Stop server first
PID=$(pgrep -f "cliproxyapi-plus" 2>/dev/null | head -n1)
[ -n "$PID" ] && echo -e "${CYAN}[*] Stopping server...${NC}" && kill "$PID" 2>/dev/null

echo -e "\n${RED}[!] Will be REMOVED:${NC}"
[ -f "$BIN_DIR/cliproxyapi-plus" ] && echo "    - Binary: $BIN_DIR/cliproxyapi-plus"
[ -d "$CLONE_DIR" ] && echo "    - Source: $CLONE_DIR"
[ -f "$CONFIG_DIR/config.yaml" ] && echo "    - Config: $CONFIG_DIR/config.yaml"
[ -d "$CONFIG_DIR/logs" ] && echo "    - Logs: $CONFIG_DIR/logs"

if [ "$REMOVE_ALL" = false ]; then
    echo -e "\n${GREEN}[*] Will be KEPT:${NC}"
    ls "$CONFIG_DIR"/*.json 2>/dev/null | while read f; do echo "    - Auth: $f"; done
    echo -e "    ${YELLOW}Use --all to remove everything${NC}"
fi

if [ "$FORCE" = false ]; then
    read -p "Are you sure? [y/N] " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && echo -e "${YELLOW}Cancelled${NC}" && exit 0
fi

echo -e "\n${CYAN}[*] Removing...${NC}"

rm -f "$BIN_DIR/cliproxyapi-plus" "$BIN_DIR/cliproxyapi-plus.old" && echo -e "${GREEN}[+] Binary removed${NC}"
rm -rf "$CLONE_DIR" && echo -e "${GREEN}[+] Source removed${NC}"
rm -f "$CONFIG_DIR/config.yaml" "$CONFIG_DIR/server.pid" && echo -e "${GREEN}[+] Config removed${NC}"
rm -rf "$CONFIG_DIR/logs" && echo -e "${GREEN}[+] Logs removed${NC}"

if [ "$REMOVE_ALL" = true ]; then
    rm -f "$CONFIG_DIR"/*.json && echo -e "${GREEN}[+] Auth files removed${NC}"
    rmdir "$CONFIG_DIR" 2>/dev/null
fi

# Clear custom_models from factory config
if [ -f "$FACTORY_CONFIG" ] && command -v jq &>/dev/null; then
    jq '.custom_models = []' "$FACTORY_CONFIG" > "$FACTORY_CONFIG.tmp" && mv "$FACTORY_CONFIG.tmp" "$FACTORY_CONFIG"
    echo -e "${GREEN}[+] Cleared custom_models from Droid config${NC}"
fi

echo -e "${GREEN}
==========================================
  Uninstall Complete!
==========================================
${NC}"
