#!/usr/bin/env bash
#
# CLIProxyAPI-Plus Server Manager
#
# Start, stop, restart, and monitor the proxy server

set -e

BINARY_PATH="$HOME/.local/bin/cliproxyapi-plus"
CONFIG_PATH="$HOME/.cli-proxy-api/config.yaml"
PID_FILE="$HOME/.cli-proxy-api/server.pid"
LOG_FILE="$HOME/.cli-proxy-api/server.log"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${CYAN}[*] $1${NC}"; }
echo_success() { echo -e "${GREEN}[+] $1${NC}"; }
echo_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
echo_error() { echo -e "${RED}[-] $1${NC}"; }

# Check if server is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Start server
start_server() {
    if is_running; then
        echo_warning "Server is already running (PID: $(cat "$PID_FILE"))"
        return 0
    fi

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

    if [ "$1" = "--background" ]; then
        echo_info "Starting server in background..."
        nohup "$BINARY_PATH" --config "$CONFIG_PATH" > "$LOG_FILE" 2>&1 &
        PID=$!
        echo $PID > "$PID_FILE"
        sleep 1

        if is_running; then
            echo_success "Server started (PID: $PID)"
            echo_info "Log: $LOG_FILE"
            echo_info "Endpoint: http://localhost:8317/v1"
        else
            echo_error "Server failed to start. Check logs: $LOG_FILE"
            exit 1
        fi
    else
        echo_info "Starting server in foreground..."
        echo_info "Press Ctrl+C to stop"
        "$BINARY_PATH" --config "$CONFIG_PATH"
    fi
}

# Stop server
stop_server() {
    if ! is_running; then
        echo_warning "Server is not running"
        return 0
    fi

    PID=$(cat "$PID_FILE")
    echo_info "Stopping server (PID: $PID)..."
    kill "$PID" 2>/dev/null || true
    sleep 1

    if is_running; then
        echo_warning "Server didn't stop gracefully, forcing..."
        kill -9 "$PID" 2>/dev/null || true
        sleep 1
    fi

    rm -f "$PID_FILE"

    if is_running; then
        echo_error "Failed to stop server"
        exit 1
    else
        echo_success "Server stopped"
    fi
}

# Restart server
restart_server() {
    echo_info "Restarting server..."
    stop_server
    sleep 1
    start_server --background
}

# Show status
show_status() {
    if is_running; then
        PID=$(cat "$PID_FILE")
        echo_success "Server is running (PID: $PID)"
        echo_info "Endpoint: http://localhost:8317/v1"

        if [ -f "$LOG_FILE" ]; then
            echo_info "Log file: $LOG_FILE"
        fi

        # Try to get process info
        if command -v ps &> /dev/null; then
            PS_INFO=$(ps -p "$PID" -o comm= 2>/dev/null || echo "N/A")
            echo_info "Process: $PS_INFO"
        fi
    else
        echo_warning "Server is not running"
    fi
}

# Show logs
show_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo_error "Log file not found: $LOG_FILE"
        exit 1
    fi

    if [ "$1" = "--follow" ] || [ "$1" = "-f" ]; then
        tail -f "$LOG_FILE"
    else
        tail -n 50 "$LOG_FILE"
    fi
}

# Show help
show_help() {
    cat << EOF
CLIProxyAPI-Plus Server Manager

Usage:
  start-cliproxyapi [OPTIONS]

Options:
  --background, -b    Start server in background
  --stop, -s          Stop server
  --restart, -r       Restart server
  --status            Show server status
  --logs [--follow]   Show server logs (use --follow to tail)
  --help, -h          Show this help

Examples:
  start-cliproxyapi --background    # Start in background
  start-cliproxyapi                 # Start in foreground
  start-cliproxyapi --stop          # Stop server
  start-cliproxyapi --restart       # Restart server
  start-cliproxyapi --status        # Check status
  start-cliproxyapi --logs          # Show last 50 log lines
  start-cliproxyapi --logs --follow # Tail logs
EOF
}

# Parse arguments
case "${1:-}" in
    --background|-b)
        start_server --background
        ;;
    --stop|-s)
        stop_server
        ;;
    --restart|-r)
        restart_server
        ;;
    --status)
        show_status
        ;;
    --logs)
        show_logs "$2"
        ;;
    --help|-h)
        show_help
        ;;
    "")
        start_server
        ;;
    *)
        echo_error "Unknown option: $1"
        echo "Run 'start-cliproxyapi --help' for usage"
        exit 1
        ;;
esac
