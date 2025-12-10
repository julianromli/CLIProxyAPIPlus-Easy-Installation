# CLIProxyAPIPlus Easy Installation

> One-click setup scripts for [CLIProxyAPIPlus](https://github.com/router-for-me/CLIProxyAPIPlus) - Use multiple AI providers through a single OpenAI-compatible API.

[English](README.md) | [Bahasa Indonesia](README_ID.md)

---

## What is CLIProxyAPIPlus?

**CLIProxyAPIPlus** is a local proxy server that lets you access multiple AI providers (Gemini, Claude, GPT, Qwen, etc.) through a **single OpenAI-compatible API endpoint**.

Think of it as a "router" for AI models - you login once to each provider via OAuth, and the proxy handles everything else. Your CLI tools (Droid, Claude Code, Cursor, etc.) just talk to `localhost:8317` like it's OpenAI.

### Why Use This?

- **One endpoint, many models** - Switch between Claude, GPT, Gemini without changing configs
- **No API keys needed** - Uses OAuth tokens from free tiers (Gemini CLI, GitHub Copilot, etc.)
- **Works with any OpenAI-compatible client** - Droid, Claude Code, Cursor, Continue, OpenCode, etc.
- **Auto quota management** - Automatically switches providers when one hits rate limits

---

## Supported Providers

| Provider | Login Command | Models Available |
|----------|---------------|------------------|
| **Gemini CLI** | `--login` | gemini-2.5-pro, gemini-3-pro-preview |
| **Antigravity** | `--antigravity-login` | claude-opus-4.5-thinking, claude-sonnet-4.5, gpt-oss-120b |
| **GitHub Copilot** | `--github-copilot-login` | claude-opus-4.5, gpt-5-mini, grok-code-fast-1 |
| **Codex** | `--codex-login` | gpt-5.1-codex-max |
| **Claude** | `--claude-login` | claude-sonnet-4, claude-opus-4 |
| **Qwen** | `--qwen-login` | qwen3-coder-plus |
| **iFlow** | `--iflow-login` | glm-4.6, minimax-m2 |
| **Kiro (AWS)** | `--kiro-aws-login` | kiro-claude-opus-4.5, kiro-claude-sonnet-4.5 |

---

## How It Works

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│   Your CLI      │     │   CLIProxyAPIPlus    │     │   AI Providers  │
│  (Droid, etc.)  │────▶│   localhost:8317     │────▶│  Gemini, Claude │
│                 │     │                      │     │  GPT, Qwen, etc │
└─────────────────┘     └──────────────────────┘     └─────────────────┘
        │                        │
        │  OpenAI API format     │  OAuth tokens
        │  POST /v1/chat/...     │  (stored locally)
        ▼                        ▼
   model: "gemini-2.5-pro"  ──▶  Routes to Gemini
   model: "claude-opus-4.5" ──▶  Routes to Copilot
   model: "gpt-5.1-codex"   ──▶  Routes to Codex
```

1. **You login** to each provider once (OAuth flow opens in browser)
2. **Tokens are stored** locally in `~/.cli-proxy-api/*.json`
3. **Proxy server runs** on `localhost:8317`
4. **Your CLI sends requests** to the proxy using OpenAI API format
5. **Proxy routes** requests to the correct provider based on model name

---

## Quick Start (Windows)

### Prerequisites

- **Git** - [Download](https://git-scm.com/downloads)
- **Go 1.21+** (optional, for building from source) - [Download](https://go.dev/dl/)

### Option 1: One-Line Install (Recommended)

```powershell
# Download and run the installer (via JSDelivr CDN - faster)
irm https://cdn.jsdelivr.net/gh/julianromli/CLIProxyAPIPlus-Easy-Installation@main/scripts/install-cliproxyapi.ps1 | iex

# Alternative (via GitHub raw)
irm https://raw.githubusercontent.com/julianromli/CLIProxyAPIPlus-Easy-Installation/main/scripts/install-cliproxyapi.ps1 | iex
```

### Option 2: Manual Install

```powershell
# Clone this repo
git clone https://github.com/julianromli/CLIProxyAPIPlus-Easy-Installation.git
cd CLIProxyAPIPlus-Easy-Installation

# Run the installer
.\scripts\install-cliproxyapi.ps1
```

### After Installation

```powershell
# Login to providers (interactive menu)
cliproxyapi-oauth.ps1

# Or login to specific providers
cliproxyapi-oauth.ps1 -Gemini -Copilot -Antigravity

# Start the proxy server
cliproxyapi-plus --config ~/.cli-proxy-api/config.yaml
```

---

## Usage with Different CLI Tools

### Factory Droid

The install script **automatically configures** Droid by updating `~/.factory/config.json`.

Just start the proxy and select a model in Droid:

```powershell
# Start proxy (keep running in background)
cliproxyapi-plus --config ~/.cli-proxy-api/config.yaml

# Use Droid normally - custom models will appear in model selector
droid
```

### Claude Code

Set environment variables before running:

```powershell
# PowerShell
$env:ANTHROPIC_BASE_URL = "http://localhost:8317/v1"
$env:ANTHROPIC_API_KEY = "sk-dummy"
claude

# Or in one line
$env:ANTHROPIC_BASE_URL="http://localhost:8317/v1"; $env:ANTHROPIC_API_KEY="sk-dummy"; claude
```

For persistent config, add to your PowerShell profile (`$PROFILE`):

```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:8317/v1"
$env:ANTHROPIC_API_KEY = "sk-dummy"
```

### OpenCode

Create or edit `~/.opencode/config.json`:

```json
{
  "provider": "openai",
  "model": "gemini-2.5-pro",
  "providers": {
    "openai": {
      "apiKey": "sk-dummy",
      "baseUrl": "http://localhost:8317/v1"
    }
  }
}
```

### Cursor

Go to **Settings → Models → OpenAI API**:

- **API Key**: `sk-dummy`
- **Base URL**: `http://localhost:8317/v1`
- **Model**: Choose from available models (e.g., `gemini-2.5-pro`)

### Continue (VS Code Extension)

Edit `~/.continue/config.json`:

```json
{
  "models": [
    {
      "title": "CLIProxy - Gemini",
      "provider": "openai",
      "model": "gemini-2.5-pro",
      "apiKey": "sk-dummy",
      "apiBase": "http://localhost:8317/v1"
    },
    {
      "title": "CLIProxy - Claude",
      "provider": "openai", 
      "model": "claude-opus-4.5",
      "apiKey": "sk-dummy",
      "apiBase": "http://localhost:8317/v1"
    }
  ]
}
```

### Generic OpenAI Client (Python)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8317/v1",
    api_key="sk-dummy"  # Any string works
)

response = client.chat.completions.create(
    model="gemini-2.5-pro",  # Or any supported model
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

### Generic OpenAI Client (curl)

```bash
curl http://localhost:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{
    "model": "gemini-2.5-pro",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## Available Models

### Antigravity Provider
| Model ID | Description |
|----------|-------------|
| `gemini-claude-opus-4-5-thinking` | Claude Opus 4.5 with extended thinking |
| `gemini-claude-sonnet-4-5-thinking` | Claude Sonnet 4.5 with extended thinking |
| `gemini-claude-sonnet-4-5` | Claude Sonnet 4.5 |
| `gemini-3-pro-preview` | Gemini 3 Pro Preview |
| `gpt-oss-120b-medium` | GPT OSS 120B |

### GitHub Copilot Provider
| Model ID | Description |
|----------|-------------|
| `claude-opus-4.5` | Claude Opus 4.5 |
| `gpt-5-mini` | GPT-5 Mini |
| `grok-code-fast-1` | Grok Code Fast |

### Gemini CLI Provider
| Model ID | Description |
|----------|-------------|
| `gemini-2.5-pro` | Gemini 2.5 Pro |
| `gemini-3-pro-preview` | Gemini 3 Pro Preview |

### Codex Provider
| Model ID | Description |
|----------|-------------|
| `gpt-5.1-codex-max` | GPT-5.1 Codex Max |

### Qwen Provider
| Model ID | Description |
|----------|-------------|
| `qwen3-coder-plus` | Qwen3 Coder Plus |

### iFlow Provider
| Model ID | Description |
|----------|-------------|
| `glm-4.6` | GLM 4.6 |
| `minimax-m2` | Minimax M2 |

### Kiro (AWS) Provider
| Model ID | Description |
|----------|-------------|
| `kiro-claude-opus-4.5` | Claude Opus 4.5 via Kiro |
| `kiro-claude-sonnet-4.5` | Claude Sonnet 4.5 via Kiro |
| `kiro-claude-sonnet-4` | Claude Sonnet 4 via Kiro |
| `kiro-claude-haiku-4.5` | Claude Haiku 4.5 via Kiro |

---

## Scripts Reference

### `start-cliproxyapi.ps1`

Server manager - start, stop, and monitor.

```powershell
# Start server (foreground)
.\start-cliproxyapi.ps1

# Start in background
.\start-cliproxyapi.ps1 -Background

# Check status
.\start-cliproxyapi.ps1 -Status

# Stop server
.\start-cliproxyapi.ps1 -Stop

# Restart
.\start-cliproxyapi.ps1 -Restart

# View logs
.\start-cliproxyapi.ps1 -Logs
```

### `install-cliproxyapi.ps1`

Full installation script.

```powershell
# Default: Build from source
.\install-cliproxyapi.ps1

# Use pre-built binary (no Go required)
.\install-cliproxyapi.ps1 -UsePrebuilt

# Force reinstall (overwrites existing)
.\install-cliproxyapi.ps1 -Force

# Skip OAuth instructions
.\install-cliproxyapi.ps1 -SkipOAuth
```

### `update-cliproxyapi.ps1`

Update to latest version.

```powershell
# Update from source (if cloned)
.\update-cliproxyapi.ps1

# Update using pre-built binary
.\update-cliproxyapi.ps1 -UsePrebuilt

# Force update even if up-to-date
.\update-cliproxyapi.ps1 -Force
```

### `cliproxyapi-oauth.ps1`

Interactive OAuth login helper.

```powershell
# Interactive menu
.\cliproxyapi-oauth.ps1

# Login to all providers
.\cliproxyapi-oauth.ps1 -All

# Login to specific providers
.\cliproxyapi-oauth.ps1 -Gemini -Copilot -Kiro
```

### `uninstall-cliproxyapi.ps1`

Clean uninstallation.

```powershell
# Uninstall (keeps auth files)
.\uninstall-cliproxyapi.ps1

# Remove everything including auth
.\uninstall-cliproxyapi.ps1 -All

# Force without confirmation
.\uninstall-cliproxyapi.ps1 -All -Force
```

---

## File Locations

| File | Location | Description |
|------|----------|-------------|
| Binary | `~/bin/cliproxyapi-plus.exe` | The proxy server executable |
| Config | `~/.cli-proxy-api/config.yaml` | Proxy configuration |
| Auth tokens | `~/.cli-proxy-api/*.json` | OAuth tokens for each provider |
| Droid config | `~/.factory/config.json` | Custom models for Factory Droid |
| Source | `~/CLIProxyAPIPlus/` | Cloned source (if built from source) |

---

## Troubleshooting

### "Connection refused" when using CLI

Make sure the proxy server is running:

```powershell
cliproxyapi-plus --config ~/.cli-proxy-api/config.yaml
```

### "Unauthorized" or "Invalid API key"

The proxy accepts any API key. Make sure you're using `sk-dummy` or any non-empty string.

### OAuth login fails

1. Make sure you have a browser installed
2. Try with `--incognito` flag for fresh session
3. Check if the provider's website is accessible

### Model not found

1. Make sure you've logged into the provider that offers that model
2. Check the model name spelling (case-sensitive)
3. Run `cliproxyapi-oauth.ps1` to see which providers you're logged into

### Quota exceeded

The proxy auto-switches to another provider/model when quota is hit. If all providers are exhausted, wait for quota reset (usually 1-24 hours depending on provider).

---

## Credits

- [CLIProxyAPIPlus](https://github.com/router-for-me/CLIProxyAPIPlus) - The original proxy server
- [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) - The mainline project
- Community contributors for GitHub Copilot and Kiro OAuth implementations

---

## License

MIT License - See [LICENSE](LICENSE) file.

---

## Contributing

PRs welcome! Feel free to:
- Add support for more CLI tools
- Improve documentation
- Report bugs
- Suggest new features

---

**Happy coding!** 🚀
