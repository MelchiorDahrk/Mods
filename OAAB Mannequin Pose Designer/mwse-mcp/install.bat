@echo off
cd /d "%~dp0"
where npm >nul 2>nul || (
  echo Node.js 18 or newer is required: https://nodejs.org/
  pause
  exit /b 1
)
rem Only when missing: in a dev checkout, --omit=dev would prune the build tools.
if not exist node_modules\ call npm install --omit=dev --ignore-scripts --no-audit --no-fund
if errorlevel 1 (
  echo Failed to install dependencies.
  pause
  exit /b 1
)
node scripts\install.mjs install %*
pause
