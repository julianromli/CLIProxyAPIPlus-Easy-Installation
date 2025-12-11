#!/bin/bash
#
# CLIProxyAPI-Plus Server Manager for Linux
# Usage:
#   ./start-cliproxyapi.sh              # Start foreground
#   ./start-cliproxyapi.sh --background # Start background
#   ./start-cliproxyapi.sh --status     # Check status
#   ./start-cliproxyapi.sh --stop       # Stop server
#   ./start-cliproxyapi.sh --restart    # Restart
#   ./start-cliproxyapi.sh --logs       # View logs
#

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

BINARY="$HOME/bin/cliproxyapi-plus"
CONFIG="$HOME/.cli-proxy-api/config.yaml"
LOG_DIR="$HOME/.cli-proxy-api/logs"
PID_FILE="$HOME/.cli-proxy-api/server.pid"
PORT=8317

BACKGROUND=false; STATUS=false; STOP=false; LOGS=false; RESTART=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --background|-b) BACKGROUND=true; shift ;;
        --status|-s) STATUS=true; shift ;;
        --stop) STOP=true; shift ;;
        --restart|-r) RESTART=true; shift ;;
        --logs|-l) LOGS=true; shift ;;
        *) shift ;;
    esac
done

get_server_pid() {
    [ -f "$PID_FILE" ] && PID=$(cat "$PID_FILE") && ps -p "$PID" &>/dev/null && echo "$PID" && return
    pgrep -f "cliproxyapi-plus" 2>/dev/null | head -n1
}

show_status() {
    echo -e "\n${MAGENTA}=== CLIProxyAPI-Plus Status ===${NC}"
    PID=$(get_server_pid)
    if [ -n "$PID" ]; then
        echo -e "${GREEN}[+] Server RUNNING (PID: $PID)${NC}"
        [ -f "/proc/$PID/status" ] && MEM=$(grep VmRSS /proc/$PID/status | awk '{print $2}') && echo "    Memory: $((MEM/1024)) MB"
    else
        echo -e "${YELLOW}[!] Server NOT running${NC}"
    fi
    ss -tuln 2>/dev/null | grep -q ":$PORT " && echo -e "${GREEN}Port $PORT in use${NC}" || echo -e "${YELLOW}Port $PORT free${NC}"
    curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:$PORT/v1/models" | grep -q "200\|401" && echo -e "${GREEN}[+] API responding${NC}"
    echo ""
}

stop_server() {
    PID=$(get_server_pid)
    if [ -n "$PID" ]; then
        echo -e "${CYAN}[*] Stopping server (PID: $PID)...${NC}"
        kill "$PID" 2>/dev/null; sleep 0.5
        ps -p "$PID" &>/dev/null && kill -9 "$PID" 2>/dev/null
        rm -f "$PID_FILE"
        echo -e "${GREEN}[+] Server stopped${NC}"
    else
        echo -e "${YELLOW}[!] Server not running${NC}"
    fi
}

show_logs() {
    mkdir -p "$LOG_DIR"
    LATEST=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -n1)
    [ -n "$LATEST" ] && tail -f "$LATEST" || echo -e "${YELLOW}[!] No logs found${NC}"
}

start_server() {
    PID=$(get_server_pid)
    [ -n "$PID" ] && echo -e "${YELLOW}[!] Already running (PID: $PID)${NC}" && show_status && return
    [ ! -f "$BINARY" ] && echo -e "${RED}[-] Binary not found. Run install-cliproxyapi.sh${NC}" && exit 1
    [ ! -f "$CONFIG" ] && echo -e "${RED}[-] Config not found. Run install-cliproxyapi.sh${NC}" && exit 1
    
    mkdir -p "$LOG_DIR"
    
    if [ "$BACKGROUND" = true ]; then
        echo -e "${CYAN}[*] Starting in background...${NC}"
        LOG_FILE="$LOG_DIR/server-$(date +%Y%m%d).log"
        nohup "$BINARY" --config "$CONFIG" >> "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        sleep 2
        ps -p $(cat "$PID_FILE") &>/dev/null && echo -e "${GREEN}[+] Started (PID: $(cat $PID_FILE))${NC}\nEndpoint: http://localhost:$PORT/v1" || echo -e "${RED}[-] Failed to start${NC}"
    else
        echo -e "${MAGENTA}=== CLIProxyAPI-Plus ===${NC}\nConfig: $CONFIG\nEndpoint: http://localhost:$PORT/v1\n${YELLOW}Ctrl+C to stop${NC}\n"
        exec "$BINARY" --config "$CONFIG"
    fi
}

[ "$STATUS" = true ] && show_status && exit 0
[ "$STOP" = true ] && stop_server && exit 0
[ "$LOGS" = true ] && show_logs && exit 0
[ "$RESTART" = true ] && stop_server && sleep 1
start_server
