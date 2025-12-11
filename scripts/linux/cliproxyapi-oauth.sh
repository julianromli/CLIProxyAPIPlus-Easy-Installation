#!/bin/bash
#
# CLIProxyAPI-Plus OAuth Login Helper for Linux
# Usage:
#   ./cliproxyapi-oauth.sh              # Interactive menu
#   ./cliproxyapi-oauth.sh --all        # Login to all
#   ./cliproxyapi-oauth.sh --gemini     # Gemini only
#   ./cliproxyapi-oauth.sh --copilot    # GitHub Copilot
#

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

CONFIG="$HOME/.cli-proxy-api/config.yaml"
BINARY="$HOME/bin/cliproxyapi-plus"

[ ! -f "$BINARY" ] && echo -e "${RED}[-] Binary not found. Run install-cliproxyapi.sh${NC}" && exit 1

declare -A FLAGS=(
    ["gemini"]="--login"
    ["antigravity"]="--antigravity-login"
    ["copilot"]="--github-copilot-login"
    ["codex"]="--codex-login"
    ["claude"]="--claude-login"
    ["qwen"]="--qwen-login"
    ["iflow"]="--iflow-login"
    ["kiro"]="--kiro-aws-login"
)

declare -A NAMES=(
    ["gemini"]="Gemini CLI"
    ["antigravity"]="Antigravity"
    ["copilot"]="GitHub Copilot"
    ["codex"]="Codex"
    ["claude"]="Claude"
    ["qwen"]="Qwen"
    ["iflow"]="iFlow"
    ["kiro"]="Kiro (AWS)"
)

ORDER=("gemini" "antigravity" "copilot" "codex" "claude" "qwen" "iflow" "kiro")

run_login() {
    local key="$1"
    echo -e "\n${CYAN}[*] Logging in to ${NAMES[$key]}...${NC}"
    "$BINARY" --config "$CONFIG" "${FLAGS[$key]}"
    [ $? -eq 0 ] && echo -e "${GREEN}[+] ${NAMES[$key]} login completed!${NC}" || echo -e "${YELLOW}[!] ${NAMES[$key]} may have issues${NC}"
}

LOGIN_ALL=false
SELECTED=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --all|-a) LOGIN_ALL=true; shift ;;
        --gemini) SELECTED+=("gemini"); shift ;;
        --antigravity) SELECTED+=("antigravity"); shift ;;
        --copilot) SELECTED+=("copilot"); shift ;;
        --codex) SELECTED+=("codex"); shift ;;
        --claude) SELECTED+=("claude"); shift ;;
        --qwen) SELECTED+=("qwen"); shift ;;
        --iflow) SELECTED+=("iflow"); shift ;;
        --kiro) SELECTED+=("kiro"); shift ;;
        *) shift ;;
    esac
done

if [ "$LOGIN_ALL" = true ] || [ ${#SELECTED[@]} -gt 0 ]; then
    echo -e "${MAGENTA}=== CLIProxyAPI-Plus OAuth Login ===${NC}"
    if [ "$LOGIN_ALL" = true ]; then
        for key in "${ORDER[@]}"; do run_login "$key"; done
    else
        for key in "${SELECTED[@]}"; do run_login "$key"; done
    fi
else
    echo -e "${MAGENTA}
==========================================
  CLIProxyAPI-Plus OAuth Login Menu
==========================================
${NC}"
    echo -e "${YELLOW}Available providers:${NC}"
    for i in "${!ORDER[@]}"; do echo "  $((i+1)). ${NAMES[${ORDER[$i]}]}"; done
    echo "  A. Login to ALL"
    echo "  Q. Quit"
    
    while true; do
        read -p "Select [1-8, A, Q]: " choice
        [[ "$choice" =~ ^[Qq]$ ]] && echo "Bye!" && break
        [[ "$choice" =~ ^[Aa]$ ]] && { for k in "${ORDER[@]}"; do run_login "$k"; done; break; }
        [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le 8 ] && run_login "${ORDER[$((choice-1))]}"
    done
fi

echo -e "${GREEN}
==========================================
  Auth files saved in: $HOME/.cli-proxy-api
==========================================
${NC}"
