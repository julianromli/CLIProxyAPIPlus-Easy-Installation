#!/usr/bin/env bash
#
# CLIProxyAPI-Plus Update Script
#
# Update to the latest version from GitHub

set -e

REPO_URL="https://github.com/router-for-me/CLIProxyAPIPlus.git"
RELEASE_API="https://api.github.com/repos/router-for-me/CLIProxyAPIPlus/releases/latest"
CLONE_DIR="$HOME/CLIProxyAPIPlus"
BIN_DIR="$HOME/.local/bin"
BINARY_NAME="cliproxyapi-plus"

USE_PREBUILT=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --use-prebuilt) USE_PREBUILT=true; shift ;;
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
NC='\033[0m'

echo_step() { echo -e "\n${CYAN}[*] $1${NC}"; }
echo_success() { echo -e "${GREEN}[+] $1${NC}"; }
echo_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
echo_error() { echo -e "${RED}[-] $1${NC}"; }

echo -e "${MAGENTA}"
cat << "EOF"
==============================================
  CLIProxyAPI-Plus Update Script
==============================================
EOF
echo -e "${NC}"

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Check if currently installed
if [ ! -f "$BIN_DIR/$BINARY_NAME" ]; then
    echo_error "CLIProxyAPI-Plus is not installed"
    echo_info "Run install-cliproxyapi first"
    exit 1
fi

# Get current version
CURRENT_VERSION="unknown"
if [ -f "$BIN_DIR/$BINARY_NAME" ]; then
    CURRENT_VERSION=$("$BIN_DIR/$BINARY_NAME" --version 2>&1 | head -1 || echo "unknown")
fi
echo_info "Current version: $CURRENT_VERSION"

# Check if server is running
PID_FILE="$HOME/.cli-proxy-api/server.pid"
SERVER_WAS_RUNNING=false
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        SERVER_WAS_RUNNING=true
        echo_warning "Server is running. Stopping it first..."
        if command -v start-cliproxyapi &> /dev/null; then
            start-cliproxyapi --stop
        else
            kill "$PID" 2>/dev/null || true
            rm -f "$PID_FILE"
        fi
        sleep 1
    fi
fi

# Update method
if [ "$USE_PREBUILT" = true ] || [ ! -d "$CLONE_DIR" ]; then
    echo_step "Downloading latest pre-built binary..."

    # Check for curl or wget
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl"
    elif command -v wget &> /dev/null; then
        DOWNLOADER="wget"
    else
        echo_error "Neither curl nor wget is installed"
        exit 1
    fi

    # Get latest release info
    if [ "$DOWNLOADER" = "curl" ]; then
        RELEASE_JSON=$(curl -sL "$RELEASE_API")
    else
        RELEASE_JSON=$(wget -qO- "$RELEASE_API")
    fi

    # Extract version
    LATEST_VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": *"\(.*\)"/\1/')
    echo_info "Latest version: $LATEST_VERSION"

    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ "$FORCE" = false ]; then
        echo_success "Already up to date!"
        exit 0
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

    # Find the binary (might have different name)
    BINARY_PATH=$(find "$TMP_DIR" -type f \( -name "cliproxyapi-plus" -o -name "cli-proxy-api-plus" -o -name "server" \) | head -1)

    if [ -z "$BINARY_PATH" ]; then
        echo_error "Could not find binary in extracted archive"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Backup old binary
    if [ -f "$BIN_DIR/$BINARY_NAME" ]; then
        cp "$BIN_DIR/$BINARY_NAME" "$BIN_DIR/$BINARY_NAME.backup"
    fi

    cp "$BINARY_PATH" "$BIN_DIR/$BINARY_NAME"
    chmod +x "$BIN_DIR/$BINARY_NAME"
    rm -rf "$TMP_DIR"

    echo_success "Binary updated to $LATEST_VERSION"
else
    echo_step "Updating from source..."

    # Check Go
    if ! command -v go &> /dev/null; then
        echo_error "Go is not installed. Use --use-prebuilt flag instead."
        exit 1
    fi

    if [ ! -d "$CLONE_DIR" ]; then
        echo_error "Source directory not found: $CLONE_DIR"
        echo_info "Use --use-prebuilt flag to download binary"
        exit 1
    fi

    cd "$CLONE_DIR"

    # Get current commit
    OLD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    # Pull latest changes
    echo "    Pulling latest changes..."
    git fetch origin
    git reset --hard origin/main

    # Get new commit
    NEW_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    if [ "$OLD_COMMIT" = "$NEW_COMMIT" ] && [ "$FORCE" = false ]; then
        echo_success "Already up to date! (commit: $NEW_COMMIT)"
        cd - > /dev/null
        exit 0
    fi

    echo_info "Updating from $OLD_COMMIT to $NEW_COMMIT"

    # Build
    echo "    Building binary..."

    # Backup old binary
    if [ -f "$BIN_DIR/$BINARY_NAME" ]; then
        cp "$BIN_DIR/$BINARY_NAME" "$BIN_DIR/$BINARY_NAME.backup"
    fi

    go build -o "$BIN_DIR/$BINARY_NAME" ./cmd/server
    chmod +x "$BIN_DIR/$BINARY_NAME"

    cd - > /dev/null
    echo_success "Binary updated to commit $NEW_COMMIT"
fi

# Verify new version
NEW_VERSION=$("$BIN_DIR/$BINARY_NAME" --version 2>&1 | head -1 || echo "installed")
echo_success "New version: $NEW_VERSION"

# Restart server if it was running
if [ "$SERVER_WAS_RUNNING" = true ]; then
    echo_step "Restarting server..."
    if command -v start-cliproxyapi &> /dev/null; then
        start-cliproxyapi --background
        echo_success "Server restarted"
    else
        echo_warning "Server was not restarted automatically"
        echo_info "Run 'start-cliproxyapi --background' to start it"
    fi
fi

echo ""
echo_success "Update complete!"

if [ -f "$BIN_DIR/$BINARY_NAME.backup" ]; then
    echo_info "Backup saved to: $BIN_DIR/$BINARY_NAME.backup"
    echo_info "Run 'rm $BIN_DIR/$BINARY_NAME.backup' to remove it"
fi
