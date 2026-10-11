@echo off
cd /d "%~dp0"
where npm >nul 2>nul || (
  echo Node.js 18 or newer is required: https://nodejs.org/
  pause
  exit /b 1
)
rem The uninstaller needs smol-toml too, e.g. if install.bat never ran here.
if not exist node_modules\ call npm install --omit=dev --ignore-scripts --no-audit --no-fund
node scripts\install.mjs uninstall %*
pause
