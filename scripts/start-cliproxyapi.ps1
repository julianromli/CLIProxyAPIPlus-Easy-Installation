<#
.SYNOPSIS
    CLIProxyAPI-Plus Server Manager
.DESCRIPTION
    Start, stop, and manage the CLIProxyAPI-Plus proxy server.
.EXAMPLE
    start-cliproxyapi.ps1              # Start in foreground
    start-cliproxyapi.ps1 -Background  # Start in background
    start-cliproxyapi.ps1 -Status      # Check if running
    start-cliproxyapi.ps1 -Stop        # Stop server
    start-cliproxyapi.ps1 -Logs        # View logs
.NOTES
    Author: Auto-generated
    Repo: https://github.com/julianromli/CLIProxyAPIPlus-Easy-Installation
#>

param(
    [switch]$Background,
    [switch]$Status,
    [switch]$Stop,
    [switch]$Logs,
    [switch]$Restart
)

$BINARY = "$env:USERPROFILE\bin\cliproxyapi-plus.exe"
$CONFIG = "$env:USERPROFILE\.cli-proxy-api\config.yaml"
$LOG_DIR = "$env:USERPROFILE\.cli-proxy-api\logs"
$PORT = 8317
$PROCESS_NAMES = @("cliproxyapi-plus", "cli-proxy-api")

function Write-Step { param($msg) Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "[-] $msg" -ForegroundColor Red }

function Get-ServerProcess {
    foreach ($name in $PROCESS_NAMES) {
        $proc = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($proc) { return $proc }
    }
    return $null
}

function Test-PortInUse {
    $connection = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue
    return $null -ne $connection
}

function Show-Status {
    Write-Host "`n=== CLIProxyAPI-Plus Status ===" -ForegroundColor Magenta
    
    $process = Get-ServerProcess
    if ($process) {
        Write-Success "Server is RUNNING"
        Write-Host "  PID: $($process.Id)"
        Write-Host "  Memory: $([math]::Round($process.WorkingSet64 / 1MB, 1)) MB"
        Write-Host "  CPU Time: $($process.CPU) seconds"
        Write-Host "  Started: $($process.StartTime)"
    } else {
        Write-Warning "Server is NOT running"
    }
    
    if (Test-PortInUse) {
        Write-Host "`nPort $PORT is in use" -ForegroundColor Green
    } else {
        Write-Host "`nPort $PORT is free" -ForegroundColor Yellow
    }
    
    # Test endpoint
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$PORT/v1/models" -TimeoutSec 2 -ErrorAction Stop
        Write-Success "API endpoint responding (HTTP $($response.StatusCode))"
    } catch {
        Write-Warning "API endpoint not responding"
    }
    
    Write-Host ""
}

function Stop-Server {
    $process = Get-ServerProcess
    if ($process) {
        Write-Step "Stopping server (PID: $($process.Id))..."
        Stop-Process -Id $process.Id -Force
        Start-Sleep -Milliseconds 500
        
        if (-not (Get-ServerProcess)) {
            Write-Success "Server stopped"
        } else {
            Write-Error "Failed to stop server"
        }
    } else {
        Write-Warning "Server is not running"
    }
}

function Show-Logs {
    $logFiles = Get-ChildItem -Path $LOG_DIR -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    
    if ($logFiles) {
        $latestLog = $logFiles[0]
        Write-Step "Showing logs from: $($latestLog.Name)"
        Write-Host "Press Ctrl+C to exit`n" -ForegroundColor DarkGray
        Get-Content -Path $latestLog.FullName -Tail 50 -Wait
    } else {
        Write-Warning "No log files found in $LOG_DIR"
        Write-Host "Server may be running without file logging."
        Write-Host "Start with: cliproxyapi-plus --config $CONFIG"
    }
}

function Start-Server {
    param([switch]$InBackground)
    
    # Check if already running
    if (Get-ServerProcess) {
        Write-Warning "Server is already running!"
        Show-Status
        return
    }
    
    # Verify binary exists
    if (-not (Test-Path $BINARY)) {
        Write-Error "Binary not found: $BINARY"
        Write-Host "Run install-cliproxyapi.ps1 first."
        exit 1
    }
    
    # Verify config exists
    if (-not (Test-Path $CONFIG)) {
        Write-Error "Config not found: $CONFIG"
        Write-Host "Run install-cliproxyapi.ps1 first."
        exit 1
    }
    
    if ($InBackground) {
        Write-Step "Starting server in background..."
        $process = Start-Process -FilePath $BINARY -ArgumentList "--config", $CONFIG -PassThru -WindowStyle Hidden
        Start-Sleep -Seconds 2
        
        if (Get-ServerProcess) {
            Write-Success "Server started in background (PID: $($process.Id))"
            Write-Host "`nEndpoint: http://localhost:$PORT/v1"
            Write-Host "To stop:   start-cliproxyapi.ps1 -Stop"
            Write-Host "To status: start-cliproxyapi.ps1 -Status"
        } else {
            Write-Error "Server failed to start"
            exit 1
        }
    } else {
        Write-Host "=== CLIProxyAPI-Plus Server ===" -ForegroundColor Magenta
        Write-Host "Config:   $CONFIG"
        Write-Host "Endpoint: http://localhost:$PORT/v1"
        Write-Host "Press Ctrl+C to stop`n" -ForegroundColor DarkGray
        
        & $BINARY --config $CONFIG
    }
}

# Main logic
if ($Status) {
    Show-Status
} elseif ($Stop) {
    Stop-Server
} elseif ($Logs) {
    Show-Logs
} elseif ($Restart) {
    Stop-Server
    Start-Sleep -Seconds 1
    Start-Server -InBackground:$Background
} else {
    Start-Server -InBackground:$Background
}
