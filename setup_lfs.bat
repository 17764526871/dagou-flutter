@echo off
chcp 65001 >nul
echo ==========================================
echo 配置 Git LFS 用于大文件存储
echo ==========================================
echo.

REM 检查 Git LFS 是否已安装
git lfs version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git LFS 未安装
    echo.
    echo 请先安装 Git LFS:
    echo   下载地址: https://git-lfs.github.com/
    echo   或使用 Git for Windows 自带的 LFS
    echo.
    pause
    exit /b 1
)

echo ✅ Git LFS 已安装
echo.

REM 初始化 Git LFS
echo 初始化 Git LFS...
git lfs install
echo.

REM 检查 .gitattributes 是否存在
if exist ".gitattributes" (
    echo ✅ .gitattributes 已存在
) else (
    echo 创建 .gitattributes...
    (
        echo *.litertlm filter=lfs diff=lfs merge=lfs -text
        echo *.task filter=lfs diff=lfs merge=lfs -text
    ) > .gitattributes
    echo ✅ .gitattributes 已创建
)
echo.

REM 检查模型文件
echo 检查模型文件...
if exist "assets\models\gemma-4-E2B-it.litertlm" (
    for %%A in ("assets\models\gemma-4-E2B-it.litertlm") do (
        set SIZE=%%~zA
    )
    echo ✅ 模型文件存在
) else (
    echo ⚠️  模型文件不存在
    echo    请先下载模型到 assets\models\
)
echo.

REM 提示下一步
echo ==========================================
echo 下一步操作:
echo ==========================================
echo.
echo 1. 添加 .gitattributes:
echo    git add .gitattributes
echo    git commit -m "chore: 添加 Git LFS 配置"
echo.
echo 2. 添加模型文件:
echo    git add assets\models\gemma-4-E2B-it.litertlm
echo    git commit -m "feat: 添加 Gemma 4 E2B 模型文件"
echo.
echo 3. 推送到 GitHub:
echo    git push
echo.
echo 注意: 首次推送大文件可能需要较长时间
echo ==========================================
echo.
pause
