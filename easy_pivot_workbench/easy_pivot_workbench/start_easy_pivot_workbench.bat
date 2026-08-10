@echo off

title Easy Pivot Workbench

set "PORT=18743"

echo.
echo ==========================================
echo      Easy Pivot Workbench
echo ==========================================
echo.

echo Checking port %PORT%...
echo.

powershell -NoProfile -Command "$c = Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue; if ($c) { exit 1 } else { exit 0 }"

if errorlevel 1 (
    echo.
    echo ==========================================
    echo      EASY PIVOT IS ALREADY RUNNING
    echo ==========================================
    echo.
    echo Easy Pivot Workbench cannot start because
    echo port %PORT% is already in use.
    echo.
    echo If you previously started Easy Pivot Workbench,
    echo the PHP server may still be running.
    echo.
    echo Look for the Easy Pivot Workbench command
    echo prompt window and close it before starting
    echo Easy Pivot again.
    echo.
    echo If Easy Pivot is not already running, another
    echo application may be using port %PORT%.
    echo In that case, you can change the PORT value
    echo in this launcher at line number 5.
    echo.
    pause
    exit /b 1
)

echo Port %PORT% is available.
echo.
echo Starting local web server...
echo.

start "" http://localhost:%PORT%

php -S localhost:%PORT%
