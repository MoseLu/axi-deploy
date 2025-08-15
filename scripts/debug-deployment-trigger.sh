#!/bin/bash

# 调试部署触发问题脚本
# 用于诊断为什么 axi-deploy 识别错了项目

set -e

echo "🔍 开始调试部署触发问题..."

# 检查最近的 GitHub Actions 运行
echo "📊 检查最近的 GitHub Actions 运行..."

# 检查 axi-docs 的最近运行
echo ""
echo "🔍 检查 axi-docs 的最近运行..."
if [ -d "axi-docs/.git" ]; then
    cd axi-docs
    echo "📁 axi-docs 最近提交:"
    git log --oneline -5
    echo ""
    echo "📊 axi-docs 工作流状态:"
    gh run list --limit 5 --repo MoseLu/axi-docs 2>/dev/null || echo "无法获取 axi-docs 运行状态"
    cd ..
else
    echo "❌ axi-docs 目录不存在或不是 git 仓库"
fi

# 检查 axi-project-dashboard 的最近运行
echo ""
echo "🔍 检查 axi-project-dashboard 的最近运行..."
if [ -d "axi-project-dashboard/.git" ]; then
    cd axi-project-dashboard
    echo "📁 axi-project-dashboard 最近提交:"
    git log --oneline -5
    echo ""
    echo "📊 axi-project-dashboard 工作流状态:"
    gh run list --limit 5 --repo MoseLu/axi-project-dashboard 2>/dev/null || echo "无法获取 axi-project-dashboard 运行状态"
    cd ..
else
    echo "❌ axi-project-dashboard 目录不存在或不是 git 仓库"
fi

# 检查 axi-deploy 的最近运行
echo ""
echo "🔍 检查 axi-deploy 的最近运行..."
if [ -d "axi-deploy/.git" ]; then
    cd axi-deploy
    echo "📁 axi-deploy 最近提交:"
    git log --oneline -5
    echo ""
    echo "📊 axi-deploy 工作流状态:"
    gh run list --limit 10 --repo MoseLu/axi-deploy 2>/dev/null || echo "无法获取 axi-deploy 运行状态"
    cd ..
else
    echo "❌ axi-deploy 目录不存在或不是 git 仓库"
fi

echo ""
echo "🔍 检查工作流配置..."

# 检查 axi-docs 的触发配置
echo ""
echo "📋 axi-docs 触发配置:"
if [ -f "axi-docs/.github/workflows/axi-docs_deploy.yml" ]; then
    echo "✅ axi-docs_deploy.yml 存在"
    echo "🔍 检查触发参数:"
    grep -A 5 -B 5 "context.repo.repo" axi-docs/.github/workflows/axi-docs_deploy.yml || echo "未找到 context.repo.repo"
    grep -A 5 -B 5 "project.*context.repo.repo" axi-docs/.github/workflows/axi-docs_deploy.yml || echo "未找到 project 配置"
else
    echo "❌ axi-docs_deploy.yml 不存在"
fi

# 检查 axi-project-dashboard 的触发配置
echo ""
echo "📋 axi-project-dashboard 触发配置:"
if [ -f "axi-project-dashboard/.github/workflows/axi-project-dashboard_deploy.yml" ]; then
    echo "✅ axi-project-dashboard_deploy.yml 存在"
    echo "🔍 检查触发参数:"
    grep -A 5 -B 5 "context.repo.repo" axi-project-dashboard/.github/workflows/axi-project-dashboard_deploy.yml || echo "未找到 context.repo.repo"
    grep -A 5 -B 5 "project.*context.repo.repo" axi-project-dashboard/.github/workflows/axi-project-dashboard_deploy.yml || echo "未找到 project 配置"
else
    echo "❌ axi-project-dashboard_deploy.yml 不存在"
fi

echo ""
echo "💡 可能的问题原因:"
echo "1. 多个工作流同时运行，触发时间接近"
echo "2. GitHub Actions 的并发限制导致触发混乱"
echo "3. 工作流参数传递错误"
echo "4. 缓存或状态问题"
echo ""
echo "🔧 建议解决方案:"
echo "1. 检查 GitHub Actions 的运行日志，确认触发源"
echo "2. 确保只有一个工作流在运行"
echo "3. 在触发前添加延迟，避免并发问题"
echo "4. 检查工作流参数是否正确传递"
