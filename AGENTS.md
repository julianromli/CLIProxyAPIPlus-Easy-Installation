# AGENTS.md - CLIProxyAPIPlus Easy Installation

> Guidance for AI coding agents working on this repository.

## Project Snapshot

- **Type**: Utility scripts collection (PowerShell)
- **Purpose**: One-click installation scripts for CLIProxyAPIPlus proxy server
- **Platform**: Windows (PowerShell 5.1+)
- **Sub-docs**: See [scripts/AGENTS.md](scripts/AGENTS.md) for script-specific patterns

## Quick Commands

```powershell
# Test install script (dry run not available - test on VM/sandbox)
.\scripts\install-cliproxyapi.ps1 -UsePrebuilt

# Test OAuth script (interactive)
.\scripts\cliproxyapi-oauth.ps1

# Test update script
.\scripts\update-cliproxyapi.ps1 -UsePrebuilt

# Test uninstall (use -Force to skip confirmation)
.\scripts\uninstall-cliproxyapi.ps1 -Force
```

## Repository Structure

```
├── scripts/           → PowerShell scripts [see scripts/AGENTS.md]
├── configs/           → Example config files (YAML, JSON)
├── README.md          → English docs
├── README_ID.md       → Indonesian docs
└── LICENSE            → MIT
```

## Universal Conventions

### Code Style
- **PowerShell**: Use approved verbs (`Get-`, `Set-`, `New-`, `Remove-`)
- **Indentation**: 4 spaces (no tabs)
- **Comments**: Use `#` for inline, `<# #>` for block/help
- **Encoding**: UTF-8 with BOM for PowerShell scripts

### Commit Format
```
type: short description

- detail 1
- detail 2
```
Types: `feat`, `fix`, `docs`, `refactor`, `chore`

### Branch Strategy
- `main` - stable releases only
- `dev` - development branch
- Feature branches: `feat/description`

## Security & Secrets

- **NEVER** commit real API keys or OAuth tokens
- Use `sk-dummy` as placeholder in examples
- Config paths use `~` or `$env:USERPROFILE` (resolved at runtime)
- No hardcoded usernames or paths

## JIT Index

### Find Script Functions
```powershell
# Find all functions in scripts
Select-String -Path "scripts\*.ps1" -Pattern "^function\s+\w+"

# Find param blocks
Select-String -Path "scripts\*.ps1" -Pattern "param\s*\("
```

### Find Config Patterns
```powershell
# Find model definitions
Select-String -Path "configs\*.json" -Pattern "model_display_name"

# Find YAML keys
Select-String -Path "configs\*.yaml" -Pattern "^\w+:"
```

## Definition of Done

Before PR:
- [ ] Script runs without errors on clean Windows install
- [ ] Help text updated (`Get-Help .\script.ps1`)
- [ ] README updated if new features added
- [ ] Both English and Indonesian READMEs in sync
