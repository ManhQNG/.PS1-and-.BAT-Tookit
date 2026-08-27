<#
.SYNOPSIS
Removes or restores Windows shortcut overlay arrows and resolves the black square rendering bug.
#>
$Host.UI.RawUI.WindowTitle = "Remove or Restore Shortcut Arrows - htmqng.blogspot.com"
# Require Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges are required. Please right-click and run as Administrator."
    Pause
    exit
}

$RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons"
$IconFile = "$env:windir\System32\transparent_overlay.ico"

function Restart-ExplorerAndClearCache {
    Write-Host "`nStopping Windows Explorer..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2 # Allow time for file locks to release

    Write-Host "Clearing Icon Cache to force a clean UI refresh..." -ForegroundColor Cyan
    $CachePaths = @(
        "$env:localappdata\IconCache.db",
        "$env:localappdata\Microsoft\Windows\Explorer\iconcache_*.db"
    )
    foreach ($Path in $CachePaths) {
        if (Test-Path $Path) { Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue }
    }

    Write-Host "Restarting Windows Explorer..." -ForegroundColor Cyan
    Start-Process explorer.exe
    Write-Host "Operation Complete!`n" -ForegroundColor Green
    Pause
    Show-Menu
}

function Show-Menu {
    Clear-Host
    Write-Host "------------------------------------" -ForegroundColor Magenta
    Write-Host " Remove or Restore Shortcut Arrows  " -ForegroundColor White
    Write-Host "------------------------------------" -ForegroundColor Magenta
    Write-Host "1. Remove shortcut arrow"
    Write-Host "2. Restore the original default arrow"
    Write-Host ""
    Write-Host "3. Exit`n"
    Write-Host "------------------------------------"

    $Choice = Read-Host "Enter your choice (1-3)"

    switch ($Choice) {
        '1' {
            Write-Host "`nGenerating transparent ICO payload..." -ForegroundColor Cyan
            # Base64 for a standard 1x1 transparent .ico file
            $Base64 = "AAABAAEAAQEAAAEAIAAwAAAAFgAAACgAAAABAAAAAgAAAAEAIAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAA=="
            [IO.File]::WriteAllBytes($IconFile, [Convert]::FromBase64String($Base64))

            if (-not (Test-Path $RegKey)) { New-Item -Path $RegKey -Force | Out-Null }
            Set-ItemProperty -Path $RegKey -Name "29" -Value "$IconFile,0" -Force
            Restart-ExplorerAndClearCache
        }
        '2' {
            Write-Host "`nRestoring the original default arrow..." -ForegroundColor Cyan
            if (Test-Path $RegKey) { Remove-ItemProperty -Path $RegKey -Name "29" -ErrorAction SilentlyContinue }
            if (Test-Path $IconFile) { Remove-Item -Path $IconFile -Force -ErrorAction SilentlyContinue }
            Restart-ExplorerAndClearCache
        }
        '3' { exit }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Show-Menu
        }
    }
}

Show-Menu