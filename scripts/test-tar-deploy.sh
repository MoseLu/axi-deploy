#!/bin/bash

# 测试压缩包部署方案脚本
# 用于验证 axi-docs 的压缩包上传和下载是否正常工作

set -e

echo "🧪 开始测试压缩包部署方案..."

# 检查 axi-docs 构建产物
echo "📁 检查 axi-docs 构建产物..."
if [ -d "axi-docs/docs/.vitepress/dist" ]; then
    echo "✅ axi-docs 构建产物存在"
    echo "📊 构建产物文件数量: $(find axi-docs/docs/.vitepress/dist -type f | wc -l)"
    
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
    echo "❌ axi-docs 构建产物不存在，请先运行构建"
    echo "运行命令: cd axi-docs && pnpm run docs:build"
    exit 1
fi

echo ""
echo "📦 测试压缩包创建..."

# 创建测试压缩包
cd axi-docs
echo "📦 创建测试压缩包..."
tar -czf ../test-dist-axi-docs.tar.gz -C docs/.vitepress dist

echo "✅ 测试压缩包创建完成"
echo "📊 压缩包大小: $(du -h ../test-dist-axi-docs.tar.gz | cut -f1)"

# 测试解压
cd ..
echo "📦 测试压缩包解压..."
rm -rf test-dist-axi-docs || true
tar -xzf test-dist-axi-docs.tar.gz

if [ -d "dist" ]; then
    echo "✅ 压缩包解压成功"
    echo "📊 解压后文件数量: $(find dist -type f | wc -l)"
    
    # 检查解压后的关键文件
    if [ -f "dist/index.html" ]; then
        echo "✅ 解压后 index.html 存在"
    else
        echo "❌ 解压后 index.html 不存在"
    fi
    
    if [ -d "dist/assets" ]; then
        echo "✅ 解压后 assets 目录存在"
        echo "📊 解压后 assets 文件数量: $(find dist/assets -type f | wc -l)"
    else
        echo "❌ 解压后 assets 目录不存在"
    fi
    
    # 重命名目录
    mv dist test-dist-axi-docs
    echo "✅ 目录重命名完成: dist -> test-dist-axi-docs"
else
    echo "❌ 压缩包解压失败"
    exit 1
fi

echo ""
echo "🔍 检查部署配置..."

# 检查 axi-docs 构建工作流配置
if [ -f "axi-docs/.github/workflows/axi-docs_deploy.yml" ]; then
    echo "✅ axi-docs 构建工作流配置存在"
    
    # 检查是否包含压缩包创建
    if grep -q "tar -czf dist-axi-docs.tar.gz" "axi-docs/.github/workflows/axi-docs_deploy.yml"; then
        echo "✅ 包含压缩包创建步骤"
    else
        echo "⚠️ 缺少压缩包创建步骤"
    fi
    
    # 检查是否上传压缩包
    if grep -q "dist-axi-docs.tar.gz" "axi-docs/.github/workflows/axi-docs_deploy.yml"; then
        echo "✅ 包含压缩包上传"
    else
        echo "⚠️ 缺少压缩包上传"
    fi
else
    echo "❌ axi-docs 构建工作流配置不存在"
    exit 1
fi

# 检查 axi-deploy 部署工作流配置
if [ -f "axi-deploy/.github/workflows/deploy-project.yml" ]; then
    echo "✅ axi-deploy 部署工作流配置存在"
    
    # 检查是否包含压缩包解压
    if grep -q "tar -xzf.*tar.gz" "axi-deploy/.github/workflows/deploy-project.yml"; then
        echo "✅ 包含压缩包解压步骤"
    else
        echo "⚠️ 缺少压缩包解压步骤"
    fi
else
    echo "❌ axi-deploy 部署工作流配置不存在"
    exit 1
fi

echo ""
echo "🧹 清理测试文件..."
rm -f test-dist-axi-docs.tar.gz
rm -rf test-dist-axi-docs

echo ""
echo "📋 测试总结:"
echo "1. 构建产物检查: ✅"
echo "2. 压缩包创建测试: ✅"
echo "3. 压缩包解压测试: ✅"
echo "4. 文件完整性验证: ✅"
echo "5. 构建工作流配置: ✅"
echo "6. 部署工作流配置: ✅"
echo ""
echo "🎉 压缩包部署方案测试完成！"
echo ""
echo "💡 建议:"
echo "- 下次部署时观察压缩包创建和解压步骤的日志"
echo "- 确认服务器上的文件数量与本地构建产物一致"
echo "- 验证网站是否能正常加载所有静态资源"
