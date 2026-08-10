@echo off

title Easy Pivot Workbench

echo.
echo ==========================================
echo      Easy Pivot Workbench
echo ==========================================
echo.
echo Starting local web server...
echo.

start "" http://localhost:8000

php -S localhost:8000
