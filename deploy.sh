#!/bin/bash

# 部署脚本
set -e

echo "🚀 开始部署..."

# 检查是否在虚拟环境中
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "📦 激活虚拟环境..."
    source venv/bin/activate
fi

# 构建静态文件
echo "🔨 构建静态文件..."
mkdocs build

# 检查构建结果
if [ ! -d "site" ]; then
    echo "❌ 构建失败：site 目录不存在"
    exit 1
fi

echo "✅ 构建成功！"

# 显示构建信息
echo "📊 构建信息："
echo "   - 构建目录: $(pwd)/site"
echo "   - 文件数量: $(find site -type f | wc -l)"
echo "   - 总大小: $(du -sh site | cut -f1)"

# 可选：推送到 GitHub Pages
if [ "$1" = "--deploy" ]; then
    echo "🌐 部署到 GitHub Pages..."
    
    # 检查是否有 git 仓库
    if [ ! -d ".git" ]; then
        echo "❌ 不是 git 仓库，跳过部署"
        exit 1
    fi
    
    # 创建 gh-pages 分支（如果不存在）
    git checkout -b gh-pages 2>/dev/null || git checkout gh-pages
    
    # 清空分支内容
    git rm -rf . || true
    
    # 复制构建文件
    cp -r site/* .
    
    # 提交更改
    git add .
    git commit -m "Deploy to GitHub Pages - $(date)"
    
    # 推送到远程仓库
    git push origin gh-pages --force
    
    # 切换回主分支
    git checkout main 2>/dev/null || git checkout master
    
    echo "✅ 部署完成！"
    echo "🌐 访问地址: https://fanqingsong.github.io"
fi

echo "🎉 部署脚本执行完成！"
echo ""
echo "📝 使用方法："
echo "  ./deploy.sh          # 仅构建"
echo "  ./deploy.sh --deploy # 构建并部署到 GitHub Pages" 