# AGENTS.md - Scripts Directory

> Detailed guidance for installation and management scripts in this repository.

## Package Identity

- **Purpose**: Automation scripts for CLIProxyAPIPlus installation/management
- **Platform Support**: Windows (PowerShell 5.1+), Linux/macOS (Bash)
- **No dependencies**: Scripts are self-contained

## Script Inventory

### PowerShell Scripts (Windows)

| Script | Purpose | Key Params |
|--------|---------|------------|
| `install-cliproxyapi.ps1` | Full installation | `-UsePrebuilt`, `-Force`, `-SkipOAuth` |
| `start-cliproxyapi.ps1` | Server manager | `-Background`, `-Stop`, `-Restart`, `-Status`, `-Logs` |
| `update-cliproxyapi.ps1` | Update to latest | `-UsePrebuilt`, `-Force` |
| `cliproxyapi-oauth.ps1` | OAuth login helper | `-All`, `-Gemini`, `-Copilot`, etc. |
| `gui-cliproxyapi.ps1` | Web GUI launcher | `-Port`, `-NoBrowser` |
| `uninstall-cliproxyapi.ps1` | Clean removal | `-All`, `-Force` |

### Bash Scripts (Linux/macOS)

| Script | Purpose | Key Params |
|--------|---------|------------|
| `install-cliproxyapi.sh` | Full installation | `--use-prebuilt`, `--force`, `--skip-oauth` |
| `start-cliproxyapi.sh` | Server manager | `--background`, `--stop`, `--restart`, `--status`, `--logs` |
| `update-cliproxyapi.sh` | Update to latest | `--use-prebuilt`, `--force` |
| `cliproxyapi-oauth.sh` | OAuth login helper | `--all`, `--gemini`, `--copilot`, etc. |
| `gui-cliproxyapi.sh` | Web GUI launcher | `--port`, `--no-browser` |
| `uninstall-cliproxyapi.sh` | Clean removal | `--all`, `--force` |

## Patterns & Conventions

### Script Header Template

Every script MUST have this structure:

```powershell
<#
.SYNOPSIS
    One-line description
.DESCRIPTION
    Detailed description of what the script does.
.EXAMPLE
    script.ps1 -Param1 value
.NOTES
    Author: ...
    Repo: https://github.com/...
#>

param(
    [switch]$SomeFlag,
    [string]$SomeParam = "default"
)

$ErrorActionPreference = "Stop"
```

✅ DO: Copy from `install-cliproxyapi.ps1` header

### Output Functions

Use consistent colored output:

```powershell
function Write-Step { param($msg) Write-Host "`n[*] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "[-] $msg" -ForegroundColor Red }
```

✅ DO: See `install-cliproxyapi.ps1` lines 30-33

### Path Variables

Always use expandable paths:

```powershell
# ✅ DO: Use environment variables
$CONFIG_DIR = "$env:USERPROFILE\.cli-proxy-api"
$BIN_DIR = "$env:USERPROFILE\bin"

# ❌ DON'T: Hardcode paths
$CONFIG_DIR = "C:\Users\faiz\.cli-proxy-api"
```

### Error Handling

```powershell
# ✅ DO: Use try-catch with specific error messages
try {
    Some-Operation
} catch {
    Write-Error "Failed to do X: $_"
    exit 1
}

# ❌ DON'T: Ignore errors silently
Some-Operation 2>$null
```

### External Commands

```powershell
# ✅ DO: Check exit codes
& git clone $REPO_URL $CLONE_DIR
if ($LASTEXITCODE -ne 0) {
    Write-Error "Git clone failed"
    exit 1
}

# ❌ DON'T: Assume success
& git clone $REPO_URL $CLONE_DIR
```

## Touch Points / Key Files

| File | Purpose | Lines to Study |
|------|---------|----------------|
| `install-cliproxyapi.ps1` | Reference implementation | Full script - best example |
| `cliproxyapi-oauth.ps1` | Interactive menu pattern | Lines 45-80 (menu loop) |
| `uninstall-cliproxyapi.ps1` | Safe deletion pattern | Lines 20-40 (item registry) |

## Adding a New Script

1. Copy header from `install-cliproxyapi.ps1`
2. Define params with proper types and defaults
3. Add the 4 Write-* helper functions
4. Use consistent path variables
5. Add to README.md "Scripts Reference" section
6. Add to README_ID.md (Indonesian version)

### Checklist for New Script

```powershell
# Verify these patterns:
Select-String -Path "scripts\NEW_SCRIPT.ps1" -Pattern "\.SYNOPSIS"     # Has help
Select-String -Path "scripts\NEW_SCRIPT.ps1" -Pattern "param\s*\("     # Has params
Select-String -Path "scripts\NEW_SCRIPT.ps1" -Pattern "ErrorActionPreference"  # Error handling
Select-String -Path "scripts\NEW_SCRIPT.ps1" -Pattern "env:USERPROFILE"  # Uses env vars
```

## Bash Script Patterns (Linux/macOS)

### Script Header Template

```bash
#!/usr/bin/env bash
#
# Script Description
#
# Detailed explanation of what this script does
#
# Author: ...
# Repo: https://github.com/...

set -e  # Exit on error

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --flag) FLAG=true; shift ;;
        --param) PARAM="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done
```

✅ DO: Copy from `install-cliproxyapi.sh` header

### Output Functions

Use consistent colored output:

```bash
# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo_step() { echo -e "\n${CYAN}[*] $1${NC}"; }
echo_success() { echo -e "${GREEN}[+] $1${NC}"; }
echo_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
echo_error() { echo -e "${RED}[-] $1${NC}"; }
```

### Path Variables

Use HOME and XDG conventions:

```bash
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.cli-proxy-api"
FACTORY_DIR="$HOME/.factory"
```

### Error Handling

```bash
set -e  # Exit on any error

# Check command availability
if ! command -v git &> /dev/null; then
    echo_error "Git is not installed"
    exit 1
fi

# Check file existence
if [ ! -f "$FILE" ]; then
    echo_error "File not found: $FILE"
    exit 1
fi
```

### Cross-Platform Compatibility

```bash
# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo_error "Unsupported: $ARCH"; exit 1 ;;
esac

# Detect shell config file
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.profile"
fi
```

### Checklist for New Bash Script

```bash
# Verify before commit:
grep -q "#!/usr/bin/env bash" script.sh  # Has shebang
grep -q "set -e" script.sh               # Has error handling
grep -q "echo_" script.sh                # Uses output functions
chmod +x script.sh                       # Is executable
shellcheck script.sh || true             # Run linter (if available)
```

## JIT Index Hints

### PowerShell

```powershell
# Find all param definitions
Select-String -Path "*.ps1" -Pattern "\[switch\]|\[string\]"

# Find all Write-Host calls (for UI consistency)
Select-String -Path "*.ps1" -Pattern "Write-Host.*-ForegroundColor"

# Find all external command calls
Select-String -Path "*.ps1" -Pattern "& \w+"

# Find all exit points
Select-String -Path "*.ps1" -Pattern "exit \d"
```

### Bash

```bash
# Find all function definitions
grep -n "^[a-z_]*() {" scripts/*.sh

# Find all echo_* calls (for UI consistency)
grep -n "echo_\(step\|success\|warning\|error\)" scripts/*.sh

# Find all exit points
grep -n "exit [0-9]" scripts/*.sh

# Find command checks
grep -n "command -v" scripts/*.sh
```

## Common Gotchas

### PowerShell

1. **String escaping**: Use single quotes for literals, double for variables
2. **Path separators**: Use `\` on Windows, but `/` works in most contexts
3. **Invoke-WebRequest**: May fail without `-UseBasicParsing` on older systems
4. **JSON depth**: `ConvertTo-Json` defaults to depth 2, use `-Depth 10` for nested

### Bash

1. **Quoting variables**: Always quote: `"$VAR"` not `$VAR` (handles spaces)
2. **Command substitution**: Use `$(command)` not backticks
3. **Test expressions**: Use `[[ ]]` not `[ ]` (more robust)
4. **Temporary files**: Use `mktemp` for secure temp file creation
5. **Cross-platform paths**: Use `$HOME` not `~` in scripts
6. **Exit on error**: Always use `set -e` at script start

## Pre-PR Checks

```powershell
# Syntax check all scripts
Get-ChildItem *.ps1 | ForEach-Object {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$null)
    Write-Host "✓ $($_.Name)" -ForegroundColor Green
}

# Verify help exists
Get-ChildItem *.ps1 | ForEach-Object { Get-Help $_.FullName | Out-Null }
```
