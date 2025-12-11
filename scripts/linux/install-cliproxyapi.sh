#!/bin/bash
#
# CLIProxyAPI-Plus Installation Script for Linux
# Usage:
#   ./install-cliproxyapi.sh              # Auto install
#   ./install-cliproxyapi.sh --prebuilt   # Force prebuilt binary
#   ./install-cliproxyapi.sh --source     # Force build from source
#   ./install-cliproxyapi.sh --skip-oauth # Skip OAuth info
#   ./install-cliproxyapi.sh --force      # Overwrite existing config
#

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

REPO_URL="https://github.com/router-for-me/CLIProxyAPIPlus.git"
RELEASE_API="https://api.github.com/repos/router-for-me/CLIProxyAPIPlus/releases/latest"
CLONE_DIR="$HOME/CLIProxyAPIPlus"
BIN_DIR="$HOME/bin"
CONFIG_DIR="$HOME/.cli-proxy-api"
FACTORY_DIR="$HOME/.factory"
BINARY_NAME="cliproxyapi-plus"

USE_PREBUILT=false; FORCE_SOURCE=false; SKIP_OAUTH=false; FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --prebuilt) USE_PREBUILT=true; shift ;;
        --source) FORCE_SOURCE=true; shift ;;
        --skip-oauth) SKIP_OAUTH=true; shift ;;
        --force) FORCE=true; shift ;;
        *) shift ;;
    esac
done

write_step() { echo -e "\n${CYAN}[*] $1${NC}"; }
write_success() { echo -e "${GREEN}[+] $1${NC}"; }
write_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
write_error() { echo -e "${RED}[-] $1${NC}"; }

echo -e "${MAGENTA}
==============================================
  CLIProxyAPI-Plus Installer for Linux
==============================================
${NC}"

write_step "Checking prerequisites..."

if [ "$USE_PREBUILT" = false ] && [ "$FORCE_SOURCE" = false ]; then
    if command -v go &> /dev/null; then
        write_success "Go found: $(go version)"
    else
        write_warning "Go not installed. Using prebuilt binary."
        USE_PREBUILT=true
    fi
fi

command -v git &> /dev/null || { write_error "Git not installed"; exit 1; }
write_success "Git found"

command -v curl &> /dev/null && DOWNLOAD_CMD="curl" || DOWNLOAD_CMD="wget"
command -v jq &> /dev/null && HAS_JQ=true || HAS_JQ=false

write_step "Creating directories..."
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$FACTORY_DIR"
write_success "Directories ready"

ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH_SUFFIX="linux_amd64" ;;
    aarch64|arm64) ARCH_SUFFIX="linux_arm64" ;;
    *) ARCH_SUFFIX="linux_amd64" ;;
esac

if [ "$USE_PREBUILT" = true ]; then
    write_step "Downloading pre-built binary..."
    TEMP_DIR=$(mktemp -d)
    
    if [ "$HAS_JQ" = true ]; then
        RELEASE_INFO=$(curl -s -H "User-Agent: Bash" "$RELEASE_API")
        DOWNLOAD_URL=$(echo "$RELEASE_INFO" | jq -r ".assets[] | select(.name | contains(\"$ARCH_SUFFIX\")) | .browser_download_url" | head -n1)
    else
        RELEASE_INFO=$(curl -s -H "User-Agent: Bash" "$RELEASE_API")
        DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o "https://[^\"]*${ARCH_SUFFIX}[^\"]*" | head -n1)
    fi
    
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
        write_warning "No prebuilt found, building from source..."
        FORCE_SOURCE=true
    else
        echo "    Downloading..."
        curl -sL -o "$TEMP_DIR/archive.tar.gz" "$DOWNLOAD_URL"
        cd "$TEMP_DIR"
        tar -xzf archive.tar.gz 2>/dev/null || unzip -q archive.tar.gz 2>/dev/null || true
        BINARY_FILE=$(find . -type f -name "cliproxyapi*" ! -name "*.gz" ! -name "*.zip" | head -n1)
        if [ -n "$BINARY_FILE" ]; then
            chmod +x "$BINARY_FILE"
            mv "$BINARY_FILE" "$BIN_DIR/$BINARY_NAME"
            write_success "Binary installed: $BIN_DIR/$BINARY_NAME"
        fi
        rm -rf "$TEMP_DIR"
    fi
fi

if [ "$FORCE_SOURCE" = true ] || [ ! -f "$BIN_DIR/$BINARY_NAME" ]; then
    write_step "Building from source..."
    [ -d "$CLONE_DIR" ] && [ "$FORCE" = true ] && rm -rf "$CLONE_DIR"
    [ ! -d "$CLONE_DIR" ] && git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
    cd "$CLONE_DIR"
    go build -o "$BIN_DIR/$BINARY_NAME" ./cmd/server
    write_success "Binary built: $BIN_DIR/$BINARY_NAME"
fi

write_step "Creating config.yaml..."
CONFIG_PATH="$CONFIG_DIR/config.yaml"
if [ -f "$CONFIG_PATH" ] && [ "$FORCE" = false ]; then
    write_warning "config.yaml exists, skipping"
else
    cat > "$CONFIG_PATH" << EOF
port: 8317
auth-dir: "$CONFIG_DIR"
api-keys:
  - "sk-dummy"
quota-exceeded:
  switch-project: true
  switch-preview-model: true
incognito-browser: true
request-retry: 3
remote-management:
  allow-remote: false
  secret-key: ""
  disable-control-panel: false
EOF
    write_success "config.yaml created"
fi

write_step "Creating .factory/config.json..."
cat > "$FACTORY_DIR/config.json" << 'EOF'
{
  "custom_models": [
    { "model_display_name": "Claude Opus 4.5 Thinking [Antigravity]", "model": "gemini-claude-opus-4-5-thinking", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Sonnet 4.5 [Antigravity]", "model": "gemini-claude-sonnet-4-5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Gemini 2.5 Pro [Gemini]", "model": "gemini-2.5-pro", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Opus 4.5 [Copilot]", "model": "claude-opus-4.5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "GPT-5.1 Codex Max [Codex]", "model": "gpt-5.1-codex-max", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Qwen3 Coder Plus [Qwen]", "model": "qwen3-coder-plus", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Opus 4.5 [Kiro]", "model": "kiro-claude-opus-4.5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" }
  ]
}
EOF
write_success "config.json created with custom models"

write_step "Verifying installation..."
[ -f "$BIN_DIR/$BINARY_NAME" ] && write_success "Binary verified" || { write_error "Binary not found"; exit 1; }

write_step "Configuring PATH..."
SHELL_RC="$HOME/.bashrc"; [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
if ! grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
    echo -e "\n# CLIProxyAPI-Plus\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_RC"
    write_success "Added to PATH in $SHELL_RC"
fi

[ "$SKIP_OAUTH" = false ] && echo -e "${YELLOW}
OAuth Login Commands:
  $BINARY_NAME --config $CONFIG_DIR/config.yaml --login              # Gemini
  $BINARY_NAME --config $CONFIG_DIR/config.yaml --antigravity-login  # Antigravity
  $BINARY_NAME --config $CONFIG_DIR/config.yaml --github-copilot-login
  $BINARY_NAME --config $CONFIG_DIR/config.yaml --codex-login
  $BINARY_NAME --config $CONFIG_DIR/config.yaml --claude-login
  $BINARY_NAME --config $CONFIG_DIR/config.yaml --qwen-login
  $BINARY_NAME --config $CONFIG_DIR/config.yaml --kiro-aws-login
${NC}"

echo -e "${GREEN}
==============================================
  Installation Complete!
==============================================
Binary:  $BIN_DIR/$BINARY_NAME
Config:  $CONFIG_DIR/config.yaml
Droid:   $FACTORY_DIR/config.json

Quick Start:
  source $SHELL_RC
  start-cliproxyapi.sh --background
==============================================
${NC}"
