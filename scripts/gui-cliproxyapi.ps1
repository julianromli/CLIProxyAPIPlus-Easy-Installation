<#
.SYNOPSIS
    CLIProxyAPI-Plus GUI Control Center with Management Server
.DESCRIPTION
    Starts an HTTP management server that serves the GUI and provides API endpoints
    for controlling the CLIProxyAPI-Plus server (start/stop/restart/oauth).
.PARAMETER Port
    Port for the management server (default: 8318)
.PARAMETER NoBrowser
    Don't automatically open browser
.EXAMPLE
    gui-cliproxyapi.ps1
    gui-cliproxyapi.ps1 -Port 9000
    gui-cliproxyapi.ps1 -NoBrowser
#>

param(
    [int]$Port = 8318,
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"

# Paths
$SCRIPT_DIR = $PSScriptRoot
$GUI_PATH = Join-Path (Split-Path $SCRIPT_DIR -Parent) "gui\index.html"
$BIN_DIR = "$env:USERPROFILE\bin"
$CONFIG_DIR = "$env:USERPROFILE\.cli-proxy-api"
$BINARY = "$BIN_DIR\cliproxyapi-plus.exe"
$CONFIG = "$CONFIG_DIR\config.yaml"
$LOG_DIR = "$CONFIG_DIR\logs"
$API_PORT = 8317
$PROCESS_NAMES = @("cliproxyapi-plus", "cli-proxy-api")

# Fallback GUI path
if (-not (Test-Path $GUI_PATH)) {
    $GUI_PATH = "$env:USERPROFILE\CLIProxyAPIPlus-Easy-Installation\gui\index.html"
}

function Write-Log { param($msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" }

function Get-ServerProcess {
    foreach ($name in $PROCESS_NAMES) {
        $proc = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($proc) { return $proc }
    }
    return $null
}

function Get-ServerStatus {
    $proc = Get-ServerProcess
    $running = $null -ne $proc
    
    $status = @{
        running = $running
        pid = if ($running) { $proc.Id } else { $null }
        memory = if ($running) { [math]::Round($proc.WorkingSet64 / 1MB, 1) } else { $null }
        startTime = if ($running -and $proc.StartTime) { $proc.StartTime.ToString("o") } else { $null }
        port = $API_PORT
        endpoint = "http://localhost:$API_PORT/v1"
    }
    
    return $status
}

function Start-ApiServer {
    $proc = Get-ServerProcess
    if ($proc) {
        return @{ success = $false; error = "Server already running (PID: $($proc.Id))" }
    }
    
    if (-not (Test-Path $BINARY)) {
        return @{ success = $false; error = "Binary not found: $BINARY" }
    }
    
    if (-not (Test-Path $CONFIG)) {
        return @{ success = $false; error = "Config not found: $CONFIG" }
    }
    
    # Ensure log directory exists
    if (-not (Test-Path $LOG_DIR)) {
        New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
    }
    
    try {
        $logFile = Join-Path $LOG_DIR "server.log"
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $BINARY
        $startInfo.Arguments = "--config `"$CONFIG`""
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.CreateNoWindow = $true
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        
        $process = [System.Diagnostics.Process]::Start($startInfo)
        Start-Sleep -Milliseconds 500
        
        if (-not $process.HasExited) {
            return @{ success = $true; pid = $process.Id; message = "Server started" }
        } else {
            return @{ success = $false; error = "Server exited immediately" }
        }
    } catch {
        return @{ success = $false; error = $_.Exception.Message }
    }
}

function Stop-ApiServer {
    $proc = Get-ServerProcess
    if (-not $proc) {
        return @{ success = $false; error = "Server not running" }
    }
    
    try {
        $proc | Stop-Process -Force
        Start-Sleep -Milliseconds 300
        return @{ success = $true; message = "Server stopped" }
    } catch {
        return @{ success = $false; error = $_.Exception.Message }
    }
}

function Restart-ApiServer {
    $stopResult = Stop-ApiServer
    Start-Sleep -Milliseconds 500
    $startResult = Start-ApiServer
    return $startResult
}

function Start-OAuthLogin {
    param([string]$Provider)
    
    $flags = @{
        "gemini" = "--login"
        "copilot" = "--github-copilot-login"
        "antigravity" = "--antigravity-login"
        "codex" = "--codex-login"
        "claude" = "--claude-login"
        "qwen" = "--qwen-login"
        "iflow" = "--iflow-login"
        "kiro" = "--kiro-aws-login"
    }
    
    if (-not $flags.ContainsKey($Provider.ToLower())) {
        return @{ success = $false; error = "Unknown provider: $Provider" }
    }
    
    $flag = $flags[$Provider.ToLower()]
    
    try {
        # Start OAuth in a new window so user can interact
        Start-Process -FilePath $BINARY -ArgumentList "--config `"$CONFIG`" $flag" -Wait:$false
        return @{ success = $true; message = "OAuth login started for $Provider" }
    } catch {
        return @{ success = $false; error = $_.Exception.Message }
    }
}

function Get-AuthStatus {
    # Check for auth token files to determine which providers are logged in
    $authPatterns = @{
        gemini = "gemini-*.json"
        copilot = "github-copilot-*.json"
        antigravity = "antigravity-*.json"
        codex = "codex-*.json"
        claude = "claude-*.json"
        qwen = "qwen-*.json"
        iflow = "iflow-*.json"
        kiro = "kiro-*.json"
    }
    
    $status = @{}
    foreach ($provider in $authPatterns.Keys) {
        $pattern = Join-Path $CONFIG_DIR $authPatterns[$provider]
        $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        
        if ($null -ne $files -and $files.Count -gt 0) {
            # Try to read expiry from token file
            $latestFile = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $expiresIn = $null
            $expired = $false
            
            try {
                $tokenData = Get-Content $latestFile.FullName -Raw | ConvertFrom-Json
                
                # Check various expiry fields
                $expiryTime = $null
                if ($tokenData.expires_at) {
                    $expiryTime = [DateTime]::Parse($tokenData.expires_at)
                } elseif ($tokenData.expiry) {
                    $expiryTime = [DateTime]::Parse($tokenData.expiry)
                } elseif ($tokenData.expires_in -and $latestFile.LastWriteTime) {
                    $expiryTime = $latestFile.LastWriteTime.AddSeconds($tokenData.expires_in)
                }
                
                if ($expiryTime) {
                    $diff = ($expiryTime - (Get-Date)).TotalSeconds
                    if ($diff -le 0) {
                        $expired = $true
                        $expiresIn = 0
                    } else {
                        $expiresIn = [math]::Floor($diff)
                    }
                }
            } catch {
                # Ignore parse errors
            }
            
            $status[$provider] = @{
                loggedIn = $true
                expiresIn = $expiresIn
                expired = $expired
            }
        } else {
            $status[$provider] = @{
                loggedIn = $false
                expiresIn = $null
                expired = $false
            }
        }
    }
    
    return $status
}

function Get-ConfigContent {
    $configPath = "$env:USERPROFILE\.cli-proxy-api\config.yaml"
    if (-not (Test-Path $configPath)) {
        return @{ success = $false; error = "Config file not found at: $configPath"; content = "" }
    }
    
    try {
        $content = [System.IO.File]::ReadAllText($configPath)
        return @{ success = $true; content = $content }
    } catch {
        return @{ success = $false; error = $_.Exception.Message; content = "" }
    }
}

function Set-ConfigContent {
    param([string]$Content)
    
    try {
        # Create backup
        $backupPath = "$CONFIG.bak"
        if (Test-Path $CONFIG) {
            Copy-Item -Path $CONFIG -Destination $backupPath -Force
        }
        
        # Write new content
        $Content | Out-File -FilePath $CONFIG -Encoding UTF8 -Force
        return @{ success = $true; message = "Config saved" }
    } catch {
        return @{ success = $false; error = $_.Exception.Message }
    }
}

function Get-AvailableModels {
    $proc = Get-ServerProcess
    if (-not $proc) {
        return @{ success = $false; error = "Server not running"; models = @() }
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$API_PORT/v1/models" -Headers @{ "Authorization" = "Bearer sk-dummy" } -TimeoutSec 5
        $models = @()
        if ($response.data) {
            $models = $response.data | ForEach-Object { $_.id }
        }
        return @{ success = $true; models = $models }
    } catch {
        return @{ success = $false; error = $_.Exception.Message; models = @() }
    }
}

function Send-JsonResponse {
    param($Context, $Data, [int]$StatusCode = 200)
    
    $json = $Data | ConvertTo-Json -Depth 5
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
    
    $Context.Response.StatusCode = $StatusCode
    $Context.Response.ContentType = "application/json"
    $Context.Response.Headers.Add("Access-Control-Allow-Origin", "*")
    $Context.Response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $Context.Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
    $Context.Response.ContentLength64 = $buffer.Length
    $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Context.Response.OutputStream.Close()
}

function Send-HtmlResponse {
    param($Context, $HtmlPath)
    
    if (-not (Test-Path $HtmlPath)) {
        $Context.Response.StatusCode = 404
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("GUI not found")
        $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        $Context.Response.OutputStream.Close()
        return
    }
    
    $html = Get-Content -Path $HtmlPath -Raw -Encoding UTF8
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    
    $Context.Response.StatusCode = 200
    $Context.Response.ContentType = "text/html; charset=utf-8"
    $Context.Response.ContentLength64 = $buffer.Length
    $Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Context.Response.OutputStream.Close()
}

# Main
Write-Host @"

============================================
  CLIProxyAPI+ Control Center
============================================
"@ -ForegroundColor Magenta

# Check if GUI exists
if (-not (Test-Path $GUI_PATH)) {
    Write-Host "[-] GUI not found at: $GUI_PATH" -ForegroundColor Red
    exit 1
}

# Check if port is available
$portInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "[-] Port $Port already in use" -ForegroundColor Red
    exit 1
}

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Log "Management server started on http://localhost:$Port"
    Write-Host ""
    Write-Host "  GUI:      http://localhost:$Port" -ForegroundColor Cyan
    Write-Host "  API:      http://localhost:$Port/api/*" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    # Open browser
    if (-not $NoBrowser) {
        Start-Process "http://localhost:$Port"
    }
    
    # Request loop
    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $path = $request.Url.LocalPath
            $method = $request.HttpMethod
            
            Write-Log "$method $path"
            
            # Handle CORS preflight
            if ($method -eq "OPTIONS") {
                $context.Response.Headers.Add("Access-Control-Allow-Origin", "*")
                $context.Response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
                $context.Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
                $context.Response.StatusCode = 204
                $context.Response.OutputStream.Close()
                continue
            }
            
            # Route requests
            switch -Regex ($path) {
                "^/$" {
                    Send-HtmlResponse -Context $context -HtmlPath $GUI_PATH
                }
                "^/api/status$" {
                    $status = Get-ServerStatus
                    Send-JsonResponse -Context $context -Data $status
                }
                "^/api/auth-status$" {
                    $authStatus = Get-AuthStatus
                    Send-JsonResponse -Context $context -Data $authStatus
                }
                "^/api/models$" {
                    $models = Get-AvailableModels
                    Send-JsonResponse -Context $context -Data $models
                }
                "^/api/config$" {
                    if ($method -eq "GET") {
                        $config = Get-ConfigContent
                        Send-JsonResponse -Context $context -Data $config
                    } elseif ($method -eq "POST") {
                        # Read request body
                        $reader = New-Object System.IO.StreamReader($request.InputStream)
                        $body = $reader.ReadToEnd()
                        $reader.Close()
                        
                        try {
                            $data = $body | ConvertFrom-Json
                            $result = Set-ConfigContent -Content $data.content
                            Send-JsonResponse -Context $context -Data $result
                        } catch {
                            Send-JsonResponse -Context $context -Data @{ success = $false; error = "Invalid JSON" } -StatusCode 400
                        }
                    } else {
                        Send-JsonResponse -Context $context -Data @{ error = "Method not allowed" } -StatusCode 405
                    }
                }
                "^/api/start$" {
                    if ($method -eq "POST") {
                        $result = Start-ApiServer
                        Send-JsonResponse -Context $context -Data $result
                    } else {
                        Send-JsonResponse -Context $context -Data @{ error = "Method not allowed" } -StatusCode 405
                    }
                }
                "^/api/stop$" {
                    if ($method -eq "POST") {
                        $result = Stop-ApiServer
                        Send-JsonResponse -Context $context -Data $result
                    } else {
                        Send-JsonResponse -Context $context -Data @{ error = "Method not allowed" } -StatusCode 405
                    }
                }
                "^/api/restart$" {
                    if ($method -eq "POST") {
                        $result = Restart-ApiServer
                        Send-JsonResponse -Context $context -Data $result
                    } else {
                        Send-JsonResponse -Context $context -Data @{ error = "Method not allowed" } -StatusCode 405
                    }
                }
                "^/api/oauth/(.+)$" {
                    if ($method -eq "POST") {
                        $provider = $matches[1]
                        $result = Start-OAuthLogin -Provider $provider
                        Send-JsonResponse -Context $context -Data $result
                    } else {
                        Send-JsonResponse -Context $context -Data @{ error = "Method not allowed" } -StatusCode 405
                    }
                }
                default {
                    Send-JsonResponse -Context $context -Data @{ error = "Not found" } -StatusCode 404
                }
            }
        } catch {
            Write-Host "[-] Request error: $_" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "[-] Server error: $_" -ForegroundColor Red
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
    Write-Log "Server stopped"
}
