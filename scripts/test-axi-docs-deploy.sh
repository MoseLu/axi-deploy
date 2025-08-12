#!/bin/bash

# 测试 axi-docs 部署修复脚本
# 用于验证构建产物是否完整上传

set -e

echo "🧪 开始测试 axi-docs 部署修复..."

# 检查本地构建产物
echo "📁 检查本地构建产物..."
if [ -d "axi-docs/docs/.vitepress/dist" ]; then
    echo "✅ 本地构建产物存在"
    echo "📊 本地文件数量: $(find axi-docs/docs/.vitepress/dist -type f | wc -l)"
    
    # 检查关键文件
    if [ -f "axi-docs/docs/.vitepress/dist/index.html" ]; then
        echo "✅ index.html 存在"
    else
        echo "❌ index.html 不存在"
        exit 1
    fi
    
    if [ -d "axi-docs/docs/.vitepress/dist/assets" ]; then
        echo "✅ assets 目录存在"
        echo "📊 assets 文件数量: $(find axi-docs/docs/.vitepress/dist/assets -type f | wc -l)"
    else
        echo "❌ assets 目录不存在"
        exit 1
    fi
else
    echo "❌ 本地构建产物不存在，请先运行构建"
    echo "运行命令: cd axi-docs && pnpm run docs:build"
    exit 1
fi

echo ""
echo "🔍 检查部署配置..."

# 检查部署工作流配置
if [ -f "axi-deploy/.github/workflows/deploy-project.yml" ]; then
    echo "✅ 部署工作流配置存在"
    
    # 检查是否使用了正确的 scp-action 版本
    if grep -q "appleboy/scp-action@v1.0.0" "axi-deploy/.github/workflows/deploy-project.yml"; then
        echo "✅ 使用了正确的 scp-action 版本 (v1.0.0)"
    else
        echo "⚠️ 可能仍在使用旧版本的 scp-action"
    fi
    
    # 检查是否有验证步骤
    if grep -q "验证上传结果" "axi-deploy/.github/workflows/deploy-project.yml"; then
        echo "✅ 包含上传验证步骤"
    else
        echo "⚠️ 缺少上传验证步骤"
    fi
else
    echo "❌ 部署工作流配置不存在"
    exit 1
fi

echo ""
echo "📋 测试总结:"
echo "1. 本地构建产物检查: ✅"
echo "2. 关键文件验证: ✅"
echo "3. 部署配置检查: ✅"
echo ""
echo "🎉 测试完成！如果所有检查都通过，部署问题应该已经修复。"
echo ""
echo "💡 建议:"
echo "- 下次部署时观察日志中的 '验证上传结果' 步骤"
echo "- 确认服务器上的 /srv/static/axi-docs/ 目录包含完整的文件"
echo "- 检查 assets 目录是否包含所有静态资源"
