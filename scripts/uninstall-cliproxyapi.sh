#!/usr/bin/env bash
#
# CLIProxyAPI-Plus Uninstall Script
#
# Remove all installed files and optionally auth tokens

set -e

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.cli-proxy-api"
FACTORY_DIR="$HOME/.factory"
CLONE_DIR="$HOME/CLIProxyAPIPlus"
BINARY_NAME="cliproxyapi-plus"

REMOVE_ALL=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) REMOVE_ALL=true; shift ;;
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
  CLIProxyAPI-Plus Uninstall Script
==============================================
EOF
echo -e "${NC}"

# Confirmation prompt
if [ "$FORCE" = false ]; then
    echo_warning "This will remove CLIProxyAPI-Plus from your system."
    if [ "$REMOVE_ALL" = true ]; then
        echo_warning "Including auth tokens and configuration files!"
    else
        echo_info "Auth tokens will be preserved (use --all to remove them)"
    fi
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Uninstall cancelled"
        exit 0
    fi
fi

# Stop server if running
PID_FILE="$CONFIG_DIR/server.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo_step "Stopping server..."
        kill "$PID" 2>/dev/null || true
        sleep 1
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -9 "$PID" 2>/dev/null || true
        fi
        echo_success "Server stopped"
    fi
fi

# Remove binary
echo_step "Removing binary..."
if [ -f "$BIN_DIR/$BINARY_NAME" ]; then
    rm -f "$BIN_DIR/$BINARY_NAME"
    echo_success "Removed: $BIN_DIR/$BINARY_NAME"
else
    echo_warning "Binary not found (already removed?)"
fi

# Remove helper scripts
echo_step "Removing helper scripts..."
for script in start-cliproxyapi cliproxyapi-oauth gui-cliproxyapi update-cliproxyapi uninstall-cliproxyapi; do
    if [ -f "$BIN_DIR/$script" ]; then
        rm -f "$BIN_DIR/$script"
        echo_success "Removed: $script"
    fi
done

# Remove source directory
if [ -d "$CLONE_DIR" ]; then
    echo_step "Removing source directory..."
    rm -rf "$CLONE_DIR"
    echo_success "Removed: $CLONE_DIR"
fi

# Remove config and auth
if [ "$REMOVE_ALL" = true ]; then
    echo_step "Removing configuration and auth tokens..."
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        echo_success "Removed: $CONFIG_DIR"
    fi

    # Remove Droid custom models
    if [ -f "$FACTORY_DIR/config.json" ]; then
        echo_step "Removing Droid custom models..."
        rm -f "$FACTORY_DIR/config.json"
        echo_success "Removed: $FACTORY_DIR/config.json"
    fi
else
    echo_step "Preserving configuration and auth tokens..."
    echo_info "Config: $CONFIG_DIR"
    echo_info "Use --all flag to remove them"
fi

# Clean up PATH entry
echo_step "Checking PATH configuration..."
SHELL_RC=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.profile"
fi

if [ -f "$SHELL_RC" ]; then
    if grep -q "CLIProxyAPI-Plus installer" "$SHELL_RC" 2>/dev/null; then
        echo_warning "Found PATH entry in $SHELL_RC"
        echo_info "You may want to manually remove the following lines:"
        echo ""
        grep -A1 "CLIProxyAPI-Plus installer" "$SHELL_RC" || true
        echo ""
    fi
fi

echo ""
echo -e "${GREEN}"
cat << "EOF"
==============================================
  Uninstall Complete!
==============================================
EOF
echo -e "${NC}"

if [ "$REMOVE_ALL" = true ]; then
    echo_success "All CLIProxyAPI-Plus files have been removed"
else
    echo_success "CLIProxyAPI-Plus binary removed"
    echo_info "Configuration and auth tokens preserved at: $CONFIG_DIR"
    echo_info "Run with --all flag to remove everything"
fi

echo ""
echo_info "Thank you for using CLIProxyAPI-Plus!"
