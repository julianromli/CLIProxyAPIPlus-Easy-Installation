#!/usr/bin/env bash
#
# CLIProxyAPI-Plus Installation Script for Linux/macOS
#
# Complete one-click installer that sets up CLIProxyAPI-Plus for Factory Droid.
# - Clones or downloads pre-built binary
# - Configures ~/.cli-proxy-api/config.yaml
# - Updates ~/.factory/config.json with custom models
# - Provides OAuth login prompts
#
# Author: Auto-generated
# Repo: https://github.com/router-for-me/CLIProxyAPIPlus

set -e

REPO_URL="https://github.com/router-for-me/CLIProxyAPIPlus.git"
RELEASE_API="https://api.github.com/repos/router-for-me/CLIProxyAPIPlus/releases/latest"
CLONE_DIR="$HOME/CLIProxyAPIPlus"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.cli-proxy-api"
FACTORY_DIR="$HOME/.factory"
BINARY_NAME="cliproxyapi-plus"

USE_PREBUILT=false
SKIP_OAUTH=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --use-prebuilt) USE_PREBUILT=true; shift ;;
        --skip-oauth) SKIP_OAUTH=true; shift ;;
        --force) FORCE=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo_step() { echo -e "\n${CYAN}[*] $1${NC}"; }
echo_success() { echo -e "${GREEN}[+] $1${NC}"; }
echo_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
echo_error() { echo -e "${RED}[-] $1${NC}"; }

echo -e "${MAGENTA}"
cat << "EOF"
==============================================
  CLIProxyAPI-Plus Installer for Droid CLI
==============================================
EOF
echo -e "${NC}"

# Detect OS and architecture
echo_step "Detecting system..."
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo_success "Detected: $OS/$ARCH"

# Check prerequisites
echo_step "Checking prerequisites..."

# Check Go (only if not using prebuilt)
if [ "$USE_PREBUILT" = false ]; then
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version)
        echo_success "Go found: $GO_VERSION"
    else
        echo_warning "Go is not installed. Switching to prebuilt binary mode."
        USE_PREBUILT=true
    fi
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo_success "Git found: $GIT_VERSION"
else
    echo_error "Git is not installed. Please install Git first."
    exit 1
fi

# Check curl or wget
if command -v curl &> /dev/null; then
    DOWNLOADER="curl"
    echo_success "curl found"
elif command -v wget &> /dev/null; then
    DOWNLOADER="wget"
    echo_success "wget found"
else
    echo_error "Neither curl nor wget is installed. Please install one of them."
    exit 1
fi

# Create directories
echo_step "Creating directories..."
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$FACTORY_DIR"
echo_success "Directories ready"

# Install binary
if [ "$USE_PREBUILT" = true ]; then
    echo_step "Downloading pre-built binary from GitHub Releases..."

    # Get latest release info
    if [ "$DOWNLOADER" = "curl" ]; then
        RELEASE_JSON=$(curl -sL "$RELEASE_API")
    else
        RELEASE_JSON=$(wget -qO- "$RELEASE_API")
    fi

    # Find the appropriate asset
    ASSET_NAME="${OS}_${ARCH}.tar.gz"
    DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep -o "https://.*${ASSET_NAME}" | head -1)

    if [ -z "$DOWNLOAD_URL" ]; then
        echo_error "Could not find $ASSET_NAME in latest release"
        exit 1
    fi

    echo "    Downloading $(basename "$DOWNLOAD_URL")..."
    TMP_DIR=$(mktemp -d)
    TMP_FILE="$TMP_DIR/cliproxyapi-plus.tar.gz"

    if [ "$DOWNLOADER" = "curl" ]; then
        curl -sL "$DOWNLOAD_URL" -o "$TMP_FILE"
    else
        wget -q "$DOWNLOAD_URL" -O "$TMP_FILE"
    fi

    echo "    Extracting..."
    tar -xzf "$TMP_FILE" -C "$TMP_DIR"

    # Find the binary (might be in subdirectory or with different name)
    BINARY_PATH=$(find "$TMP_DIR" -type f \( -name "cliproxyapi-plus" -o -name "cli-proxy-api-plus" -o -name "server" \) | head -1)

    if [ -z "$BINARY_PATH" ]; then
        echo_error "Could not find binary in extracted archive"
        echo "    Contents of archive:"
        find "$TMP_DIR" -type f
        rm -rf "$TMP_DIR"
        exit 1
    fi

    cp "$BINARY_PATH" "$BIN_DIR/$BINARY_NAME"
    chmod +x "$BIN_DIR/$BINARY_NAME"
    rm -rf "$TMP_DIR"

    echo_success "Binary installed: $BIN_DIR/$BINARY_NAME"
else
    echo_step "Building from source..."

    # Clone or update repo
    if [ -d "$CLONE_DIR" ]; then
        if [ "$FORCE" = true ] || [ ! -f "$CLONE_DIR/go.mod" ]; then
            echo "    Removing existing clone..."
            rm -rf "$CLONE_DIR"
            echo "    Cloning repository..."
            git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
        fi
    else
        echo "    Cloning repository..."
        git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
    fi

    echo "    Building binary..."
    cd "$CLONE_DIR"
    go build -o "$BIN_DIR/$BINARY_NAME" ./cmd/server
    cd - > /dev/null

    chmod +x "$BIN_DIR/$BINARY_NAME"
    echo_success "Binary built: $BIN_DIR/$BINARY_NAME"
fi

# Create config.yaml
echo_step "Configuring ~/.cli-proxy-api/config.yaml..."
CONFIG_PATH="$CONFIG_DIR/config.yaml"

if [ -f "$CONFIG_PATH" ] && [ "$FORCE" = false ]; then
    echo_warning "config.yaml already exists, skipping (use --force to overwrite)"
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
    echo_success "config.yaml created"
fi

# Update .factory/config.json
echo_step "Updating ~/.factory/config.json..."
FACTORY_CONFIG="$FACTORY_DIR/config.json"

cat > "$FACTORY_CONFIG" << 'EOF'
{
  "custom_models": [
    { "model_display_name": "Claude Opus 4.5 Thinking [Antigravity]", "model": "gemini-claude-opus-4-5-thinking", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Sonnet 4.5 Thinking [Antigravity]", "model": "gemini-claude-sonnet-4-5-thinking", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Sonnet 4.5 [Antigravity]", "model": "gemini-claude-sonnet-4-5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Gemini 3 Pro [Antigravity]", "model": "gemini-3-pro-preview", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "GPT OSS 120B [Antigravity]", "model": "gpt-oss-120b-medium", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Opus 4.5 [Copilot]", "model": "claude-opus-4.5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "GPT-5 Mini [Copilot]", "model": "gpt-5-mini", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Grok Code Fast 1 [Copilot]", "model": "grok-code-fast-1", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Gemini 2.5 Pro [Gemini]", "model": "gemini-2.5-pro", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Gemini 3 Pro Preview [Gemini]", "model": "gemini-3-pro-preview", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "GPT-5.1 Codex Max [Codex]", "model": "gpt-5.1-codex-max", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Qwen3 Coder Plus [Qwen]", "model": "qwen3-coder-plus", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "GLM 4.6 [iFlow]", "model": "glm-4.6", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Minimax M2 [iFlow]", "model": "minimax-m2", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Opus 4.5 [Kiro]", "model": "kiro-claude-opus-4.5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Sonnet 4.5 [Kiro]", "model": "kiro-claude-sonnet-4.5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Sonnet 4 [Kiro]", "model": "kiro-claude-sonnet-4", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" },
    { "model_display_name": "Claude Haiku 4.5 [Kiro]", "model": "kiro-claude-haiku-4.5", "base_url": "http://localhost:8317/v1", "api_key": "sk-dummy", "provider": "openai" }
  ]
}
EOF

MODEL_COUNT=$(grep -c "model_display_name" "$FACTORY_CONFIG")
echo_success "config.json updated with $MODEL_COUNT custom models"

# Verify installation
echo_step "Verifying installation..."
if [ -f "$BIN_DIR/$BINARY_NAME" ]; then
    FILE_SIZE=$(du -h "$BIN_DIR/$BINARY_NAME" | cut -f1)
    echo_success "Binary verification passed ($FILE_SIZE)"
else
    echo_error "Binary not found at $BIN_DIR/$BINARY_NAME"
    exit 1
fi

# Add ~/.local/bin to PATH if not already
echo_step "Configuring PATH..."
SHELL_RC=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.profile"
fi

PATH_EXPORT="export PATH=\"\$HOME/.local/bin:\$PATH\""

if grep -q ".local/bin" "$SHELL_RC" 2>/dev/null; then
    echo_success "$BIN_DIR already in PATH"
    PATH_ADDED=false
else
    echo "" >> "$SHELL_RC"
    echo "# Added by CLIProxyAPI-Plus installer" >> "$SHELL_RC"
    echo "$PATH_EXPORT" >> "$SHELL_RC"
    echo_success "Added $BIN_DIR to PATH in $SHELL_RC"
    PATH_ADDED=true
fi

# Copy helper scripts
echo_step "Installing helper scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in start-cliproxyapi.sh cliproxyapi-oauth.sh update-cliproxyapi.sh uninstall-cliproxyapi.sh gui-cliproxyapi.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        SCRIPT_BASENAME=$(basename "$script" .sh)
        cp "$SCRIPT_DIR/$script" "$BIN_DIR/$SCRIPT_BASENAME"
        chmod +x "$BIN_DIR/$SCRIPT_BASENAME"
        echo_success "Installed: $SCRIPT_BASENAME"
    fi
done

# Copy Python API server for GUI
if [ -f "$SCRIPT_DIR/cliproxyapi-api-server.py" ]; then
    cp "$SCRIPT_DIR/cliproxyapi-api-server.py" "$BIN_DIR/cliproxyapi-api-server"
    chmod +x "$BIN_DIR/cliproxyapi-api-server"
    echo_success "Installed: API server for GUI"
fi

# Copy GUI files
GUI_INSTALL_DIR="$HOME/.local/share/cliproxyapi/gui"
GUI_SOURCE_DIR="$(dirname "$SCRIPT_DIR")/gui"

if [ -d "$GUI_SOURCE_DIR" ]; then
    echo_step "Installing GUI Control Center..."
    mkdir -p "$GUI_INSTALL_DIR"
    cp -r "$GUI_SOURCE_DIR"/* "$GUI_INSTALL_DIR/"
    echo_success "GUI installed: $GUI_INSTALL_DIR"
fi

# OAuth login prompts
if [ "$SKIP_OAUTH" = false ]; then
    echo -e "\n${YELLOW}"
    cat << EOF
==============================================
  OAuth Login Setup (Optional)
==============================================
Run these commands to login to each provider:

  # Gemini CLI
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --login

  # Antigravity
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --antigravity-login

  # GitHub Copilot
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --github-copilot-login

  # Codex
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --codex-login

  # Claude
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --claude-login

  # Qwen
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --qwen-login

  # iFlow
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --iflow-login

  # Kiro (AWS)
  cliproxyapi-plus --config $CONFIG_DIR/config.yaml --kiro-aws-login

==============================================
EOF
    echo -e "${NC}"
fi

echo -e "\n${GREEN}"
cat << EOF
==============================================
  Installation Complete!
==============================================
EOF
echo -e "${NC}"

echo -e "${CYAN}"
cat << EOF
Installed Files:
  Binary:   $BIN_DIR/$BINARY_NAME
  Config:   $CONFIG_DIR/config.yaml
  Droid:    $FACTORY_DIR/config.json

Available Scripts (in $BIN_DIR):
  start-cliproxyapi     Start/stop/restart server
  cliproxyapi-oauth     Login to OAuth providers
  gui-cliproxyapi       Open Control Center GUI
  update-cliproxyapi    Update to latest version
  uninstall-cliproxyapi Remove everything

Quick Start:
  1. Reload shell:    source $SHELL_RC
  2. Start server:    start-cliproxyapi --background
  3. Login OAuth:     cliproxyapi-oauth --all
  4. Open GUI:        gui-cliproxyapi
  5. Use with Droid:  droid (select cliproxyapi-plus/* model)
EOF
echo -e "${NC}"

if [ "$PATH_ADDED" = true ]; then
    echo -e "${YELLOW}"
    cat << EOF

NOTE: Restart your terminal or run: source $SHELL_RC
      to apply PATH changes.
EOF
    echo -e "${NC}"
fi

echo -e "${GREEN}"
echo "=============================================="
echo -e "${NC}"
