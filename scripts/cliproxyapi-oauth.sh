#!/usr/bin/env bash
#
# CLIProxyAPI-Plus OAuth Login Helper
#
# Interactive OAuth login for all supported providers

set -e

BINARY_PATH="$HOME/.local/bin/cliproxyapi-plus"
CONFIG_PATH="$HOME/.cli-proxy-api/config.yaml"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo_info() { echo -e "${CYAN}[*] $1${NC}"; }
echo_success() { echo -e "${GREEN}[+] $1${NC}"; }
echo_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
echo_error() { echo -e "${RED}[-] $1${NC}"; }

# Check prerequisites
if [ ! -f "$BINARY_PATH" ]; then
    echo_error "Binary not found: $BINARY_PATH"
    echo_error "Run install-cliproxyapi first"
    exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
    echo_error "Config not found: $CONFIG_PATH"
    echo_error "Run install-cliproxyapi first"
    exit 1
fi

# Login functions
login_gemini() {
    echo_info "Logging into Gemini CLI..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --login
    echo_success "Gemini login complete"
}

login_antigravity() {
    echo_info "Logging into Antigravity..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --antigravity-login
    echo_success "Antigravity login complete"
}

login_copilot() {
    echo_info "Logging into GitHub Copilot..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --github-copilot-login
    echo_success "GitHub Copilot login complete"
}

login_codex() {
    echo_info "Logging into Codex..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --codex-login
    echo_success "Codex login complete"
}

login_claude() {
    echo_info "Logging into Claude..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --claude-login
    echo_success "Claude login complete"
}

login_qwen() {
    echo_info "Logging into Qwen..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --qwen-login
    echo_success "Qwen login complete"
}

login_iflow() {
    echo_info "Logging into iFlow..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --iflow-login
    echo_success "iFlow login complete"
}

login_kiro() {
    echo_info "Logging into Kiro (AWS)..."
    "$BINARY_PATH" --config "$CONFIG_PATH" --kiro-aws-login
    echo_success "Kiro login complete"
}

# Login to all providers
login_all() {
    echo -e "${MAGENTA}"
    cat << "EOF"
==============================================
  Login to All Providers
==============================================
EOF
    echo -e "${NC}"

    echo_warning "This will open multiple browser windows for OAuth login."
    echo_warning "Press Enter to continue or Ctrl+C to cancel..."
    read

    PROVIDERS=("Gemini" "Antigravity" "GitHub Copilot" "Codex" "Claude" "Qwen" "iFlow" "Kiro")
    FUNCS=(login_gemini login_antigravity login_copilot login_codex login_claude login_qwen login_iflow login_kiro)

    for i in "${!PROVIDERS[@]}"; do
        echo ""
        echo_info "[$((i+1))/${#PROVIDERS[@]}] ${PROVIDERS[$i]}"
        ${FUNCS[$i]} || echo_warning "Failed to login to ${PROVIDERS[$i]}"
        sleep 1
    done

    echo ""
    echo_success "All OAuth logins complete!"
}

# Interactive menu
show_menu() {
    echo -e "${MAGENTA}"
    cat << "EOF"
==============================================
  CLIProxyAPI-Plus OAuth Login
==============================================
EOF
    echo -e "${NC}"

    echo "Select provider to login:"
    echo "  1) Gemini CLI"
    echo "  2) Antigravity"
    echo "  3) GitHub Copilot"
    echo "  4) Codex"
    echo "  5) Claude"
    echo "  6) Qwen"
    echo "  7) iFlow"
    echo "  8) Kiro (AWS)"
    echo "  9) All providers"
    echo "  0) Exit"
    echo ""
    read -p "Enter choice [0-9]: " choice

    case $choice in
        1) login_gemini ;;
        2) login_antigravity ;;
        3) login_copilot ;;
        4) login_codex ;;
        5) login_claude ;;
        6) login_qwen ;;
        7) login_iflow ;;
        8) login_kiro ;;
        9) login_all ;;
        0) exit 0 ;;
        *) echo_error "Invalid choice"; exit 1 ;;
    esac
}

# Show help
show_help() {
    cat << EOF
CLIProxyAPI-Plus OAuth Login Helper

Usage:
  cliproxyapi-oauth [OPTIONS]

Options:
  --all               Login to all providers
  --gemini            Login to Gemini CLI
  --antigravity       Login to Antigravity
  --copilot           Login to GitHub Copilot
  --codex             Login to Codex
  --claude            Login to Claude
  --qwen              Login to Qwen
  --iflow             Login to iFlow
  --kiro              Login to Kiro (AWS)
  --help, -h          Show this help

Examples:
  cliproxyapi-oauth                    # Interactive menu
  cliproxyapi-oauth --all              # Login to all
  cliproxyapi-oauth --gemini --copilot # Login to specific providers
EOF
}

# Parse arguments
if [ $# -eq 0 ]; then
    show_menu
    exit 0
fi

LOGIN_ANY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            login_all
            LOGIN_ANY=true
            shift
            ;;
        --gemini)
            login_gemini
            LOGIN_ANY=true
            shift
            ;;
        --antigravity)
            login_antigravity
            LOGIN_ANY=true
            shift
            ;;
        --copilot)
            login_copilot
            LOGIN_ANY=true
            shift
            ;;
        --codex)
            login_codex
            LOGIN_ANY=true
            shift
            ;;
        --claude)
            login_claude
            LOGIN_ANY=true
            shift
            ;;
        --qwen)
            login_qwen
            LOGIN_ANY=true
            shift
            ;;
        --iflow)
            login_iflow
            LOGIN_ANY=true
            shift
            ;;
        --kiro)
            login_kiro
            LOGIN_ANY=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo_error "Unknown option: $1"
            echo "Run 'cliproxyapi-oauth --help' for usage"
            exit 1
            ;;
    esac
done

if [ "$LOGIN_ANY" = true ]; then
    echo ""
    echo_success "OAuth login process complete!"
    echo_info "You can now use the models with Factory Droid or other clients."
fi
