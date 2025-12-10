# AGENTS.md - Scripts Directory

> Detailed guidance for PowerShell scripts in this repository.

## Package Identity

- **Purpose**: Automation scripts for CLIProxyAPIPlus installation/management
- **Language**: PowerShell 5.1+ (Windows-native)
- **No dependencies**: Scripts are self-contained

## Script Inventory

| Script | Purpose | Key Params |
|--------|---------|------------|
| `install-cliproxyapi.ps1` | Full installation | `-UsePrebuilt`, `-Force`, `-SkipOAuth` |
| `update-cliproxyapi.ps1` | Update to latest | `-UsePrebuilt`, `-Force` |
| `cliproxyapi-oauth.ps1` | OAuth login helper | `-All`, `-Gemini`, `-Copilot`, etc. |
| `uninstall-cliproxyapi.ps1` | Clean removal | `-All`, `-KeepAuth`, `-Force` |

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

## JIT Index Hints

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

## Common Gotchas

1. **PowerShell string escaping**: Use single quotes for literals, double for variables
2. **Path separators**: Use `\` on Windows, but `/` works in most contexts
3. **Invoke-WebRequest**: May fail without `-UseBasicParsing` on older systems
4. **JSON depth**: `ConvertTo-Json` defaults to depth 2, use `-Depth 10` for nested

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
