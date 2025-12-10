#!/usr/bin/env python3
"""
Simple HTTP API server for CLIProxyAPI-Plus management
Provides REST API endpoints for the GUI Control Center
"""

import http.server
import socketserver
import json
import subprocess
import os
from urllib.parse import urlparse, parse_qs
from pathlib import Path

PORT = 8318
HOME = Path.home()
BIN_DIR = HOME / ".local" / "bin"
CONFIG_DIR = HOME / ".cli-proxy-api"

class APIHandler(http.server.SimpleHTTPRequestHandler):
    """Handler for API requests"""

    def do_GET(self):
        """Handle GET requests"""
        parsed = urlparse(self.path)

        if parsed.path == '/api/status':
            self.handle_status()
        elif parsed.path == '/api/config':
            self.handle_get_config()
        elif parsed.path == '/api/auth-status':
            self.handle_auth_status()
        elif parsed.path == '/api/models':
            self.handle_models()
        elif parsed.path == '/api/stats':
            self.handle_stats()
        elif parsed.path == '/api/update/check':
            self.handle_update_check()
        else:
            # Serve static files (GUI)
            super().do_GET()

    def do_POST(self):
        """Handle POST requests"""
        parsed = urlparse(self.path)

        if parsed.path == '/api/start':
            self.handle_start()
        elif parsed.path == '/api/stop':
            self.handle_stop()
        elif parsed.path == '/api/restart':
            self.handle_restart()
        elif parsed.path.startswith('/api/oauth/'):
            provider = parsed.path.split('/')[-1]
            self.handle_oauth(provider)
        elif parsed.path == '/api/update/apply':
            self.handle_update_apply()
        else:
            self.send_error(404)

    def handle_status(self):
        """Get server status"""
        try:
            result = subprocess.run(
                [str(BIN_DIR / "start-cliproxyapi"), "--status"],
                capture_output=True,
                text=True,
                timeout=5
            )

            # Parse output
            is_running = "Server is running" in result.stdout
            pid = None
            if is_running:
                for line in result.stdout.split('\n'):
                    if 'PID:' in line:
                        pid = line.split('PID:')[-1].strip().rstrip(')')

            response = {
                "running": is_running,
                "pid": pid,
                "endpoint": "http://localhost:8317/v1" if is_running else None
            }

            self.send_json(response)
        except Exception as e:
            self.send_json({"running": False, "error": str(e)})

    def handle_start(self):
        """Start the server"""
        try:
            result = subprocess.run(
                [str(BIN_DIR / "start-cliproxyapi"), "--background"],
                capture_output=True,
                text=True,
                timeout=10
            )

            success = result.returncode == 0
            self.send_json({
                "success": success,
                "message": result.stdout + result.stderr
            })
        except Exception as e:
            self.send_json({"success": False, "message": str(e)})

    def handle_stop(self):
        """Stop the server"""
        try:
            result = subprocess.run(
                [str(BIN_DIR / "start-cliproxyapi"), "--stop"],
                capture_output=True,
                text=True,
                timeout=10
            )

            success = result.returncode == 0
            self.send_json({
                "success": success,
                "message": result.stdout + result.stderr
            })
        except Exception as e:
            self.send_json({"success": False, "message": str(e)})

    def handle_restart(self):
        """Restart the server"""
        try:
            result = subprocess.run(
                [str(BIN_DIR / "start-cliproxyapi"), "--restart"],
                capture_output=True,
                text=True,
                timeout=15
            )

            success = result.returncode == 0
            self.send_json({
                "success": success,
                "message": result.stdout + result.stderr
            })
        except Exception as e:
            self.send_json({"success": False, "message": str(e)})

    def handle_oauth(self, provider):
        """Trigger OAuth login"""
        provider_map = {
            "gemini": "--gemini",
            "antigravity": "--antigravity",
            "copilot": "--copilot",
            "codex": "--codex",
            "claude": "--claude",
            "qwen": "--qwen",
            "iflow": "--iflow",
            "kiro": "--kiro"
        }

        flag = provider_map.get(provider.lower())
        if not flag:
            self.send_json({"success": False, "message": "Unknown provider"})
            return

        try:
            # Run in background, don't wait
            subprocess.Popen(
                [str(BIN_DIR / "cliproxyapi-oauth"), flag],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

            self.send_json({
                "success": True,
                "message": f"OAuth login started for {provider}"
            })
        except Exception as e:
            self.send_json({"success": False, "message": str(e)})

    def handle_get_config(self):
        """Get current config"""
        config_file = CONFIG_DIR / "config.yaml"
        try:
            if config_file.exists():
                with open(config_file, 'r') as f:
                    self.send_json({"config": f.read()})
            else:
                self.send_json({"config": ""})
        except Exception as e:
            self.send_json({"config": "", "error": str(e)})

    def handle_auth_status(self):
        """Get auth status for providers"""
        try:
            auth_files = list(CONFIG_DIR.glob("*.json"))
            providers = {
                "gemini": False,
                "antigravity": False,
                "copilot": False,
                "codex": False,
                "claude": False,
                "qwen": False,
                "iflow": False,
                "kiro": False
            }

            for f in auth_files:
                name = f.stem.lower()
                if "gemini" in name or "@gmail.com" in name:
                    providers["gemini"] = True
                if "antigravity" in name:
                    providers["antigravity"] = True
                if "copilot" in name or "github" in name:
                    providers["copilot"] = True
                if "codex" in name:
                    providers["codex"] = True
                if "claude" in name:
                    providers["claude"] = True
                if "qwen" in name:
                    providers["qwen"] = True
                if "iflow" in name:
                    providers["iflow"] = True
                if "kiro" in name:
                    providers["kiro"] = True

            self.send_json(providers)
        except Exception as e:
            self.send_json({p: False for p in ["gemini", "antigravity", "copilot", "codex", "claude", "qwen", "iflow", "kiro"]})

    def handle_models(self):
        """Get available models"""
        try:
            result = subprocess.run(
                ["curl", "-s", "-H", "Authorization: Bearer sk-dummy",
                 "http://localhost:8317/v1/models"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                data = json.loads(result.stdout)
                models = [m["id"] for m in data.get("data", [])]
                self.send_json({"models": models})
            else:
                self.send_json({"models": []})
        except Exception as e:
            self.send_json({"models": [], "error": str(e)})

    def handle_stats(self):
        """Get request statistics (stub for now)"""
        self.send_json({
            "totalRequests": 0,
            "successRate": 0,
            "avgLatency": 0,
            "errors": 0
        })

    def handle_update_check(self):
        """Check for updates (stub)"""
        self.send_json({
            "available": False,
            "current": "6.5.64",
            "latest": "6.5.64"
        })

    def handle_update_apply(self):
        """Apply update"""
        try:
            # Run update in background
            subprocess.Popen(
                [str(BIN_DIR / "update-cliproxyapi"), "--use-prebuilt"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

            self.send_json({
                "success": True,
                "message": "Update started in background"
            })
        except Exception as e:
            self.send_json({"success": False, "message": str(e)})

    def send_json(self, data):
        """Send JSON response"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, format, *args):
        """Override to reduce noise"""
        pass

def main():
    """Start the API server"""
    # Change to GUI directory
    gui_dir = HOME / ".local" / "share" / "cliproxyapi" / "gui"
    if gui_dir.exists():
        os.chdir(gui_dir)

    with socketserver.TCPServer(("", PORT), APIHandler) as httpd:
        print(f"API Server running on http://localhost:{PORT}")
        print(f"GUI available at http://localhost:{PORT}")
        print("Press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down...")

if __name__ == "__main__":
    main()
