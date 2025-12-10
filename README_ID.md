# CLIProxyAPIPlus Easy Installation

> Script instalasi sekali klik untuk [CLIProxyAPIPlus](https://github.com/router-for-me/CLIProxyAPIPlus) - Gunakan berbagai provider AI melalui satu API yang kompatibel dengan OpenAI.

[English](README.md) | [Bahasa Indonesia](README_ID.md)

---

## Apa itu CLIProxyAPIPlus?

**CLIProxyAPIPlus** adalah proxy server lokal yang memungkinkan kamu mengakses berbagai provider AI (Gemini, Claude, GPT, Qwen, dll.) melalui **satu endpoint API yang kompatibel dengan OpenAI**.

Anggap saja ini seperti "router" untuk model AI - kamu login sekali ke setiap provider via OAuth, dan proxy yang handle sisanya. Tool CLI kamu (Droid, Claude Code, Cursor, dll.) tinggal ngobrol ke `localhost:8317` seolah-olah itu OpenAI.

### Kenapa Pake Ini?

- **Satu endpoint, banyak model** - Ganti-ganti Claude, GPT, Gemini tanpa ubah config
- **Gak perlu API key berbayar** - Pake token OAuth dari tier gratis (Gemini CLI, GitHub Copilot, dll.)
- **Kompatibel dengan semua client OpenAI** - Droid, Claude Code, Cursor, Continue, OpenCode, dll.
- **Auto kelola quota** - Otomatis pindah provider kalau satu kena rate limit

---

## Provider yang Didukung

| Provider | Perintah Login | Model Tersedia |
|----------|----------------|----------------|
| **Gemini CLI** | `--login` | gemini-2.5-pro, gemini-3-pro-preview |
| **Antigravity** | `--antigravity-login` | claude-opus-4.5-thinking, claude-sonnet-4.5, gpt-oss-120b |
| **GitHub Copilot** | `--github-copilot-login` | claude-opus-4.5, gpt-5-mini, grok-code-fast-1 |
| **Codex** | `--codex-login` | gpt-5.1-codex-max |
| **Claude** | `--claude-login` | claude-sonnet-4, claude-opus-4 |
| **Qwen** | `--qwen-login` | qwen3-coder-plus |
| **iFlow** | `--iflow-login` | glm-4.6, minimax-m2 |
| **Kiro (AWS)** | `--kiro-aws-login` | kiro-claude-opus-4.5, kiro-claude-sonnet-4.5 |

---

## Cara Kerjanya

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│   CLI Kamu      │     │   CLIProxyAPIPlus    │     │   Provider AI   │
│  (Droid, dll.)  │────▶│   localhost:8317     │────▶│  Gemini, Claude │
│                 │     │                      │     │  GPT, Qwen, dll │
└─────────────────┘     └──────────────────────┘     └─────────────────┘
        │                        │
        │  Format OpenAI API     │  Token OAuth
        │  POST /v1/chat/...     │  (disimpan lokal)
        ▼                        ▼
   model: "gemini-2.5-pro"  ──▶  Diarahkan ke Gemini
   model: "claude-opus-4.5" ──▶  Diarahkan ke Copilot
   model: "gpt-5.1-codex"   ──▶  Diarahkan ke Codex
```

1. **Kamu login** ke setiap provider sekali (OAuth flow buka di browser)
2. **Token disimpan** secara lokal di `~/.cli-proxy-api/*.json`
3. **Proxy server jalan** di `localhost:8317`
4. **CLI kamu kirim request** ke proxy pake format OpenAI API
5. **Proxy routing** request ke provider yang benar berdasarkan nama model

---

## Quick Start (Windows)

### Prasyarat

- **Git** - [Download](https://git-scm.com/downloads)
- **Go 1.21+** (opsional, untuk build dari source) - [Download](https://go.dev/dl/)

### Opsi 1: Install Satu Baris (Recommended)

```powershell
# Download dan jalankan installer (via JSDelivr CDN - lebih cepat)
irm https://cdn.jsdelivr.net/gh/julianromli/CLIProxyAPIPlus-Easy-Installation@main/scripts/install-cliproxyapi.ps1 | iex

# Alternatif (via GitHub raw)
irm https://raw.githubusercontent.com/julianromli/CLIProxyAPIPlus-Easy-Installation/main/scripts/install-cliproxyapi.ps1 | iex
```

### Opsi 2: Install Manual

```powershell
# Clone repo ini
git clone https://github.com/julianromli/CLIProxyAPIPlus-Easy-Installation.git
cd CLIProxyAPIPlus-Easy-Installation

# Jalankan installer
.\scripts\install-cliproxyapi.ps1
```

### Setelah Instalasi

Script diinstall ke `~/bin/` dan otomatis ditambahkan ke PATH.

```powershell
# Restart terminal (atau refresh PATH)
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'User')

# Start server di background
start-cliproxyapi -Background

# Login ke provider
cliproxyapi-oauth -All

# Buka GUI Control Center (kontrol penuh via browser)
gui-cliproxyapi
```

**Script yang Tersedia:**

- `start-cliproxyapi` - Start/stop/restart server
- `cliproxyapi-oauth` - Login ke OAuth provider
- `gui-cliproxyapi` - Buka GUI Control Center
- `update-cliproxyapi` - Update ke versi terbaru
- `uninstall-cliproxyapi` - Hapus semuanya

---

## Quick Start (Linux/macOS)

### Prasyarat

- **Git** - Biasanya sudah terinstall, atau install dengan `sudo apt install git` (Ubuntu) / `brew install git` (macOS)
- **Go 1.21+** (opsional, untuk build dari source) - [Download](https://go.dev/dl/)
- **curl** atau **wget** - Biasanya sudah terinstall

### Instalasi

```bash
# Clone repo ini
git clone https://github.com/julianromli/CLIProxyAPIPlus-Easy-Installation.git
cd CLIProxyAPIPlus-Easy-Installation

# Buat script executable dan jalankan installer
chmod +x scripts/install-cliproxyapi.sh
./scripts/install-cliproxyapi.sh

# Atau pake binary pre-built (gak perlu Go)
./scripts/install-cliproxyapi.sh --use-prebuilt
```

### Setelah Instalasi

Script diinstall ke `~/.local/bin/` dan otomatis ditambahkan ke PATH.

```bash
# Reload shell config (atau buka terminal baru)
source ~/.bashrc  # atau ~/.zshrc kalau pake zsh

# Start server di background
start-cliproxyapi --background

# Login ke provider
cliproxyapi-oauth --all

# Buka GUI Control Center (kontrol penuh via browser)
gui-cliproxyapi
```

**Script yang Tersedia:**

- `start-cliproxyapi` - Start/stop/restart server
- `cliproxyapi-oauth` - Login ke OAuth provider
- `gui-cliproxyapi` - Buka GUI Control Center
- `update-cliproxyapi` - Update ke versi terbaru
- `uninstall-cliproxyapi` - Hapus semuanya

### Testing Instalasi

Setelah instalasi, cek apakah semuanya berjalan:

```bash
# 1. Cek status server
start-cliproxyapi --status

# 2. Test endpoint API
curl -H "Authorization: Bearer sk-dummy" http://localhost:8317/v1/models

# 3. Test chat completion
curl http://localhost:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{
    "model": "gemini-2.5-pro",
    "messages": [{"role": "user", "content": "Halo!"}]
  }'

# 4. Lihat log server
start-cliproxyapi --logs
```

Hasil yang diharapkan:

- `/v1/models` mengembalikan daftar model
- Chat completion mengembalikan respon AI
- Log menunjukkan API call berhasil

---

## Penggunaan dengan Berbagai CLI Tool

### Factory Droid

Script install **otomatis mengkonfigurasi** Droid dengan update `~/.factory/config.json`.

Tinggal jalankan proxy dan pilih model di Droid:

```powershell
# Start proxy di background
start-cliproxyapi -Background

# Pake Droid seperti biasa - custom models akan muncul di model selector
droid
```

Atau pake GUI:

```powershell
# Buka Control Center, klik "Start", terus pake Droid
gui-cliproxyapi
```

### Claude Code

Set environment variable sebelum running:

**Windows (PowerShell):**

```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:8317/v1"
$env:ANTHROPIC_API_KEY = "sk-dummy"
claude

# Atau dalam satu baris
$env:ANTHROPIC_BASE_URL="http://localhost:8317/v1"; $env:ANTHROPIC_API_KEY="sk-dummy"; claude
```

Untuk config permanen, tambahkan ke PowerShell profile (`$PROFILE`):

```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:8317/v1"
$env:ANTHROPIC_API_KEY = "sk-dummy"
```

**Linux/macOS (Bash/Zsh):**

```bash
export ANTHROPIC_BASE_URL="http://localhost:8317/v1"
export ANTHROPIC_API_KEY="sk-dummy"
claude

# Atau dalam satu baris
ANTHROPIC_BASE_URL="http://localhost:8317/v1" ANTHROPIC_API_KEY="sk-dummy" claude
```

Untuk config permanen, tambahkan ke `~/.bashrc` atau `~/.zshrc`:

```bash
export ANTHROPIC_BASE_URL="http://localhost:8317/v1"
export ANTHROPIC_API_KEY="sk-dummy"
```

### OpenCode

Buat atau edit `~/.opencode/config.json`:

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

Pergi ke **Settings → Models → OpenAI API**:

- **API Key**: `sk-dummy`
- **Base URL**: `http://localhost:8317/v1`
- **Model**: Pilih dari model yang tersedia (misal `gemini-2.5-pro`)

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

### Client OpenAI Generic (Python)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8317/v1",
    api_key="sk-dummy"  # String apapun bisa
)

response = client.chat.completions.create(
    model="gemini-2.5-pro",  # Atau model lain yang didukung
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

### Client OpenAI Generic (curl)

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

## Model yang Tersedia

### Provider Antigravity

| Model ID | Deskripsi |
|----------|-----------|
| `gemini-claude-opus-4-5-thinking` | Claude Opus 4.5 dengan extended thinking |
| `gemini-claude-sonnet-4-5-thinking` | Claude Sonnet 4.5 dengan extended thinking |
| `gemini-claude-sonnet-4-5` | Claude Sonnet 4.5 |
| `gemini-3-pro-preview` | Gemini 3 Pro Preview |
| `gpt-oss-120b-medium` | GPT OSS 120B |

### Provider GitHub Copilot

| Model ID | Deskripsi |
|----------|-----------|
| `claude-opus-4.5` | Claude Opus 4.5 |
| `gpt-5-mini` | GPT-5 Mini |
| `grok-code-fast-1` | Grok Code Fast |

### Provider Gemini CLI

| Model ID | Deskripsi |
|----------|-----------|
| `gemini-2.5-pro` | Gemini 2.5 Pro |
| `gemini-3-pro-preview` | Gemini 3 Pro Preview |

### Provider Codex

| Model ID | Deskripsi |
|----------|-----------|
| `gpt-5.1-codex-max` | GPT-5.1 Codex Max |

### Provider Qwen

| Model ID | Deskripsi |
|----------|-----------|
| `qwen3-coder-plus` | Qwen3 Coder Plus |

### Provider iFlow

| Model ID | Deskripsi |
|----------|-----------|
| `glm-4.6` | GLM 4.6 |
| `minimax-m2` | Minimax M2 |

### Provider Kiro (AWS)

| Model ID | Deskripsi |
|----------|-----------|
| `kiro-claude-opus-4.5` | Claude Opus 4.5 via Kiro |
| `kiro-claude-sonnet-4.5` | Claude Sonnet 4.5 via Kiro |
| `kiro-claude-sonnet-4` | Claude Sonnet 4 via Kiro |
| `kiro-claude-haiku-4.5` | Claude Haiku 4.5 via Kiro |

---

## Referensi Script

### `start-cliproxyapi.ps1`

Server manager - start, stop, dan monitor.

```powershell
# Start server (foreground)
.\start-cliproxyapi.ps1

# Start di background
.\start-cliproxyapi.ps1 -Background

# Cek status
.\start-cliproxyapi.ps1 -Status

# Stop server
.\start-cliproxyapi.ps1 -Stop

# Restart
.\start-cliproxyapi.ps1 -Restart

# Lihat logs
.\start-cliproxyapi.ps1 -Logs
```

### `install-cliproxyapi.ps1`

Script instalasi lengkap.

```powershell
# Default: Build dari source
.\install-cliproxyapi.ps1

# Pake binary pre-built (gak perlu Go)
.\install-cliproxyapi.ps1 -UsePrebuilt

# Force reinstall (overwrite yang ada)
.\install-cliproxyapi.ps1 -Force

# Skip instruksi OAuth
.\install-cliproxyapi.ps1 -SkipOAuth
```

### `update-cliproxyapi.ps1`

Update ke versi terbaru.

```powershell
# Update dari source (kalau clone)
.\update-cliproxyapi.ps1

# Update pake binary pre-built
.\update-cliproxyapi.ps1 -UsePrebuilt

# Force update walau sudah up-to-date
.\update-cliproxyapi.ps1 -Force
```

### `cliproxyapi-oauth.ps1`

Helper OAuth login interaktif.

```powershell
# Menu interaktif
.\cliproxyapi-oauth.ps1

# Login ke semua provider
.\cliproxyapi-oauth.ps1 -All

# Login ke provider tertentu
.\cliproxyapi-oauth.ps1 -Gemini -Copilot -Kiro
```

### `uninstall-cliproxyapi.ps1`

Uninstall bersih.

```powershell
# Uninstall (simpan file auth)
.\uninstall-cliproxyapi.ps1

# Hapus semuanya termasuk auth
.\uninstall-cliproxyapi.ps1 -All

# Force tanpa konfirmasi
.\uninstall-cliproxyapi.ps1 -All -Force
```

### `gui-cliproxyapi.ps1`

GUI Control Center dengan fitur manajemen server lengkap.

```powershell
# Buka GUI (start management server di port 8318)
gui-cliproxyapi.ps1

# Pake port custom
gui-cliproxyapi.ps1 -Port 9000

# Jangan auto-buka browser
gui-cliproxyapi.ps1 -NoBrowser
```

**Fitur:**

- Monitoring status server real-time
- Tombol Start/Stop/Restart (beneran jalan!)
- Tombol OAuth login untuk semua provider
- **Request Statistics** - Total request, success rate, avg latency, errors
- **Auto-Updater** - Klik version badge untuk cek update
- Indikator status auth provider (hijau = terhubung)
- Daftar model tersedia (saat server running)
- Editor konfigurasi (edit config.yaml langsung)
- Tombol copy endpoint untuk setup cepat
- Opsi auto-start (ingat preferensi kamu)
- Activity log viewer
- Keyboard shortcut: `R` untuk refresh, `Esc` untuk tutup modal

GUI menjalankan management server lokal di `localhost:8318` yang handle semua perintah kontrol.

---

## Lokasi File

| File | Lokasi | Deskripsi |
|------|--------|-----------|
| Binary | `~/bin/cliproxyapi-plus.exe` | Executable proxy server |
| Config | `~/.cli-proxy-api/config.yaml` | Konfigurasi proxy |
| Token auth | `~/.cli-proxy-api/*.json` | Token OAuth untuk setiap provider |
| Config Droid | `~/.factory/config.json` | Custom models untuk Factory Droid |
| Source | `~/CLIProxyAPIPlus/` | Source yang di-clone (kalau build dari source) |

---

## Troubleshooting

### "Connection refused" pas pake CLI

Pastikan proxy server jalan:

```powershell
cliproxyapi-plus --config ~/.cli-proxy-api/config.yaml
```

### "Unauthorized" atau "Invalid API key"

Proxy menerima API key apapun. Pastikan kamu pake `sk-dummy` atau string non-kosong apapun.

### OAuth login gagal

1. Pastikan ada browser terinstall
2. Coba pake flag `--incognito` untuk fresh session
3. Cek apakah website provider bisa diakses

### Model not found

1. Pastikan kamu sudah login ke provider yang punya model itu
2. Cek ejaan nama model (case-sensitive)
3. Jalankan `cliproxyapi-oauth.ps1` untuk lihat provider mana saja yang sudah login

### Quota exceeded

Proxy otomatis pindah ke provider/model lain kalau quota habis. Kalau semua provider habis, tunggu quota reset (biasanya 1-24 jam tergantung provider).

---

## Credits

- [CLIProxyAPIPlus](https://github.com/router-for-me/CLIProxyAPIPlus) - Proxy server original
- [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) - Project mainline
- Kontributor komunitas untuk implementasi OAuth GitHub Copilot dan Kiro

---

## Lisensi

MIT License - Lihat file [LICENSE](LICENSE).

---

## Kontribusi

PR welcome! Silakan:

- Tambah dukungan untuk CLI tool lain
- Perbaiki dokumentasi
- Laporkan bug
- Saran fitur baru

---

**Happy coding!** 🚀
