#!/bin/bash

# 测试工作流文件修复脚本
echo "🔍 测试工作流文件修复..."

# 检查main-deployment.yml
echo "📋 检查 main-deployment.yml..."
if yamllint .github/workflows/main-deployment.yml 2>/dev/null; then
    echo "✅ main-deployment.yml 语法正确"
else
    echo "❌ main-deployment.yml 语法错误"
    exit 1
fi

# 检查start-service.yml
echo "📋 检查 start-service.yml..."
if yamllint .github/workflows/start-service.yml 2>/dev/null; then
    echo "✅ start-service.yml 语法正确"
else
    echo "❌ start-service.yml 语法错误"
    exit 1
fi

# 检查configure-nginx.yml
echo "📋 检查 configure-nginx.yml..."
if yamllint .github/workflows/configure-nginx.yml 2>/dev/null; then
    echo "✅ configure-nginx.yml 语法正确"
else
    echo "❌ configure-nginx.yml 语法错误"
    exit 1
fi

# 检查文件大小
echo "📊 检查文件大小..."
echo "main-deployment.yml: $(wc -c < .github/workflows/main-deployment.yml) 字节"
echo "start-service.yml: $(wc -c < .github/workflows/start-service.yml) 字节"
echo "configure-nginx.yml: $(wc -c < .github/workflows/configure-nginx.yml) 字节"

# 检查是否有超长的行
echo "📏 检查超长行..."
MAX_LINE_LENGTH=1000

LONG_LINES=$(grep -n ".\{$MAX_LINE_LENGTH,\}" .github/workflows/main-deployment.yml 2>/dev/null | wc -l)
if [ $LONG_LINES -eq 0 ]; then
    echo "✅ main-deployment.yml 没有超长行"
else
    echo "⚠️ main-deployment.yml 有 $LONG_LINES 行超过 $MAX_LINE_LENGTH 字符"
fi

LONG_LINES=$(grep -n ".\{$MAX_LINE_LENGTH,\}" .github/workflows/start-service.yml 2>/dev/null | wc -l)
if [ $LONG_LINES -eq 0 ]; then
    echo "✅ start-service.yml 没有超长行"
else
    echo "⚠️ start-service.yml 有 $LONG_LINES 行超过 $MAX_LINE_LENGTH 字符"
fi

LONG_LINES=$(grep -n ".\{$MAX_LINE_LENGTH,\}" .github/workflows/configure-nginx.yml 2>/dev/null | wc -l)
if [ $LONG_LINES -eq 0 ]; then
    echo "✅ configure-nginx.yml 没有超长行"
else
    echo "⚠️ configure-nginx.yml 有 $LONG_LINES 行超过 $MAX_LINE_LENGTH 字符"
fi

echo "🎉 工作流文件修复测试完成！"
