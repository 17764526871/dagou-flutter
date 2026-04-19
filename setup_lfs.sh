#!/bin/bash
# Git LFS 设置脚本

echo "=========================================="
echo "配置 Git LFS 用于大文件存储"
echo "=========================================="
echo ""

# 检查 Git LFS 是否已安装
if ! command -v git-lfs &> /dev/null; then
    echo "❌ Git LFS 未安装"
    echo ""
    echo "请先安装 Git LFS:"
    echo "  Windows: https://git-lfs.github.com/"
    echo "  macOS: brew install git-lfs"
    echo "  Linux: sudo apt-get install git-lfs"
    echo ""
    exit 1
fi

echo "✅ Git LFS 已安装"
echo ""

# 初始化 Git LFS
echo "初始化 Git LFS..."
git lfs install
echo ""

# 检查 .gitattributes 是否存在
if [ -f ".gitattributes" ]; then
    echo "✅ .gitattributes 已存在"
else
    echo "创建 .gitattributes..."
    cat > .gitattributes << 'EOF'
*.litertlm filter=lfs diff=lfs merge=lfs -text
*.task filter=lfs diff=lfs merge=lfs -text
EOF
    echo "✅ .gitattributes 已创建"
fi
echo ""

# 检查模型文件
echo "检查模型文件..."
if [ -f "assets/models/gemma-4-E2B-it.litertlm" ]; then
    SIZE=$(du -h assets/models/gemma-4-E2B-it.litertlm | cut -f1)
    echo "✅ 模型文件存在: $SIZE"
else
    echo "⚠️  模型文件不存在"
    echo "   请先下载模型到 assets/models/"
fi
echo ""

# 提示下一步
echo "=========================================="
echo "下一步操作:"
echo "=========================================="
echo ""
echo "1. 添加 .gitattributes:"
echo "   git add .gitattributes"
echo "   git commit -m 'chore: 添加 Git LFS 配置'"
echo ""
echo "2. 添加模型文件:"
echo "   git add assets/models/gemma-4-E2B-it.litertlm"
echo "   git commit -m 'feat: 添加 Gemma 4 E2B 模型文件'"
echo ""
echo "3. 推送到 GitHub:"
echo "   git push"
echo ""
echo "注意: 首次推送大文件可能需要较长时间"
echo "=========================================="
