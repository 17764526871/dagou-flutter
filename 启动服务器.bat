@echo off
chcp 65001 >nul
echo ============================================================
echo 🚀 启动 Dagou AI 模型服务器
echo ============================================================
echo.
echo 正在启动服务器...
echo.

cd /d "%~dp0"
node model_server.js

pause
