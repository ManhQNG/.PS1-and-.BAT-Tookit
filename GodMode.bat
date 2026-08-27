@echo off
setlocal EnableExtensions
title Master Control Panel (GodMode) Deployment Utility - htmqng.blogspot.com

:MENU
cls
echo =======================================================
echo          Master Control Panel (GodMode) Utility
echo =======================================================
echo 1. Standard Mode (Local User Profile Desktop)
echo 2. Enterprise Mode (Resolves Redirected/OneDrive Paths)
echo 3. Remove Shortcut
echo 4. Exit
echo =======================================================
set /p choice="Select an operation (1-4): "

if "%choice%"=="1" goto STANDARD
if "%choice%"=="2" goto ENTERPRISE
if "%choice%"=="3" goto REMOVE
if "%choice%"=="4" exit

:STANDARD
set "TARGET_PATH=%USERPROFILE%\Desktop"
goto CREATE_SHORTCUT

:ENTERPRISE
:: Query the registry for the true Desktop path, accounting for KFM/GPO Redirection
for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do (
    set "REG_DESKTOP=%%B"
)
:: Expand environment variables returned from the registry (e.g., %USERPROFILE%)
call set "TARGET_PATH=%REG_DESKTOP%"
goto CREATE_SHORTCUT

:CREATE_SHORTCUT
set "GODMODE_DIR=%TARGET_PATH%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
if exist "%GODMODE_DIR%" (
    echo.
    echo [INFO] GodMode is already present at: %TARGET_PATH%
) else (
    mkdir "%GODMODE_DIR%" >nul 2>&1
    echo.
    echo [SUCCESS] GodMode provisioned successfully at: %TARGET_PATH%
)
pause
goto MENU

:REMOVE
:: Attempt removal from both standard and enterprise paths to ensure complete cleanup
set "CLEANUP_COUNT=0"

:: Check Standard Path
if exist "%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" (
    rmdir /Q /S "%USERPROFILE%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" >nul 2>&1
    set /a CLEANUP_COUNT+=1
)

:: Check Enterprise Path
for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do (
    set "REG_DESKTOP=%%B"
)
call set "ENT_PATH=%REG_DESKTOP%"
if exist "%ENT_PATH%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" (
    rmdir /Q /S "%ENT_PATH%\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" >nul 2>&1
    set /a CLEANUP_COUNT+=1
)

echo.
if %CLEANUP_COUNT% GTR 0 (
    echo [SUCCESS] Removed GodMode from system desktop locations.
) else (
    echo [INFO] No GodMode shortcut found to remove.
)
pause
goto MENU