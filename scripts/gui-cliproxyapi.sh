#!/usr/bin/env bash
#
# CLIProxyAPI-Plus GUI Control Center
#
# Web-based control panel for managing the proxy server

set -e

GUI_PORT="${1:-8318}"
NO_BROWSER=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port|-p)
            GUI_PORT="$2"
            shift 2
            ;;
        --no-browser)
            NO_BROWSER=true
            shift
            ;;
        --help|-h)
            cat << EOF
CLIProxyAPI-Plus GUI Control Center

Usage:
  gui-cliproxyapi [OPTIONS]

Options:
  --port, -p PORT     GUI server port (default: 8318)
  --no-browser        Don't auto-open browser
  --help, -h          Show this help

Examples:
  gui-cliproxyapi              # Start GUI on port 8318
  gui-cliproxyapi --port 9000  # Use custom port
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

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

# Find GUI HTML file
GUI_HTML=""
if [ -f "$SCRIPT_DIR/../gui/index.html" ]; then
    GUI_HTML="$SCRIPT_DIR/../gui/index.html"
elif [ -f "$HOME/.local/share/cliproxyapi/gui/index.html" ]; then
    GUI_HTML="$HOME/.local/share/cliproxyapi/gui/index.html"
elif [ -f "/usr/share/cliproxyapi/gui/index.html" ]; then
    GUI_HTML="/usr/share/cliproxyapi/gui/index.html"
fi

if [ -z "$GUI_HTML" ]; then
    echo_error "GUI files not found"
    echo_info "Creating temporary GUI..."

    # Create minimal GUI
    TMP_GUI=$(mktemp -d)/index.html
    cat > "$TMP_GUI" << 'EOFHTML'
<!DOCTYPE html>
<html>
<head>
    <title>CLIProxyAPI-Plus Control Center</title>
    <meta charset="utf-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #1e1e1e;
            color: #d4d4d4;
        }
        h1 { color: #4ec9b0; }
        .button {
            background: #0e639c;
            color: white;
            border: none;
            padding: 10px 20px;
            margin: 5px;
            cursor: pointer;
            border-radius: 4px;
        }
        .button:hover { background: #1177bb; }
        .status {
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
            background: #2d2d30;
        }
        .success { color: #4ec9b0; }
        .error { color: #f48771; }
        .info { color: #9cdcfe; }
    </style>
</head>
<body>
    <h1>🚀 CLIProxyAPI-Plus Control Center</h1>
    <div class="status">
        <h2>Quick Commands</h2>
        <p class="info">Use these commands in your terminal:</p>
        <pre>
# Start server
start-cliproxyapi --background

# Check status
start-cliproxyapi --status

# Stop server
start-cliproxyapi --stop

# Login to providers
cliproxyapi-oauth --all

# Update
update-cliproxyapi --use-prebuilt
        </pre>
    </div>
    <div class="status">
        <h2>Server Endpoint</h2>
        <p class="success">http://localhost:8317/v1</p>
        <p class="info">Use this as your OpenAI API base URL</p>
    </div>
</body>
</html>
EOFHTML
    GUI_HTML="$TMP_GUI"
fi

# Check if port is available
if command -v lsof &> /dev/null; then
    if lsof -Pi ":$GUI_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo_warning "Port $GUI_PORT is already in use"
        GUI_PORT=$((GUI_PORT + 1))
        echo_info "Using port $GUI_PORT instead"
    fi
fi

# Start simple HTTP server
echo_success "Starting GUI Control Center on port $GUI_PORT"
GUI_URL="http://localhost:$GUI_PORT"

# Open browser
if [ "$NO_BROWSER" = false ]; then
    sleep 1
    if command -v xdg-open &> /dev/null; then
        xdg-open "$GUI_URL" 2>/dev/null || true
    elif command -v open &> /dev/null; then
        open "$GUI_URL" 2>/dev/null || true
    elif command -v python3 &> /dev/null; then
        python3 -m webbrowser "$GUI_URL" 2>/dev/null || true
    fi &
fi

echo -e "${CYAN}"
cat << EOF
==============================================
  GUI Control Center
==============================================
  URL: $GUI_URL
  Press Ctrl+C to stop
==============================================
EOF
echo -e "${NC}"

# Start server based on what's available
if command -v python3 &> /dev/null; then
    cd "$(dirname "$GUI_HTML")"
    python3 -m http.server "$GUI_PORT" 2>/dev/null
elif command -v python &> /dev/null; then
    cd "$(dirname "$GUI_HTML")"
    python -m SimpleHTTPServer "$GUI_PORT" 2>/dev/null
else
    echo_error "No HTTP server available (python/python3 required)"
    echo_info "Please install Python to use the GUI"
    exit 1
fi
