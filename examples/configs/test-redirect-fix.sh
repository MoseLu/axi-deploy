#!/bin/bash

# 测试重定向循环修复脚本
# 用于诊断和验证Nginx配置中的重定向问题

set -e

echo "🔍 开始诊断重定向循环问题..."

# 1. 检查Nginx配置语法
echo "📋 检查Nginx配置语法..."
if sudo nginx -t; then
    echo "✅ Nginx配置语法正确"
else
    echo "❌ Nginx配置语法错误"
    exit 1
fi

# 2. 检查主配置文件
echo "📋 检查主配置文件..."
MAIN_CONF="/www/server/nginx/conf/conf.d/redamancy/00-main.conf"
if [ -f "$MAIN_CONF" ]; then
    echo "✅ 主配置文件存在: $MAIN_CONF"
    echo "📄 主配置文件内容:"
    cat "$MAIN_CONF"
else
    echo "❌ 主配置文件不存在: $MAIN_CONF"
fi

# 3. 检查路由配置文件
echo "📋 检查路由配置文件..."
ROUTE_CONFS=$(find /www/server/nginx/conf/conf.d/redamancy/ -name "route-*.conf" 2>/dev/null)
if [ -n "$ROUTE_CONFS" ]; then
    echo "✅ 找到路由配置文件:"
    for conf in $ROUTE_CONFS; do
        echo "📄 $conf:"
        cat "$conf"
        echo "---"
    done
else
    echo "⚠️ 没有找到路由配置文件"
fi

# 4. 测试静态文件访问
echo "📋 测试静态文件访问..."
STATIC_TEST_URL="http://redamancy.com.cn/static/html/main-content.html"
echo "🔗 测试URL: $STATIC_TEST_URL"

# 使用curl测试，设置最大重定向次数
RESPONSE=$(curl -s -w "%{http_code}|%{redirect_url}|%{num_redirects}" -o /dev/null \
    --max-redirs 5 \
    "$STATIC_TEST_URL" 2>/dev/null || echo "curl failed")

HTTP_CODE=$(echo "$RESPONSE" | cut -d'|' -f1)
REDIRECT_URL=$(echo "$RESPONSE" | cut -d'|' -f2)
REDIRECT_COUNT=$(echo "$RESPONSE" | cut -d'|' -f3)

echo "📊 响应状态码: $HTTP_CODE"
echo "📊 重定向URL: $REDIRECT_URL"
echo "📊 重定向次数: $REDIRECT_COUNT"

if [ "$REDIRECT_COUNT" -gt 3 ]; then
    echo "❌ 检测到重定向循环！"
    echo "🔍 详细诊断信息:"
    
    # 检查文件是否存在
    echo "📁 检查静态文件是否存在..."
    if [ -f "/srv/apps/axi-star-cloud/front/html/main-content.html" ]; then
        echo "✅ 文件存在: /srv/apps/axi-star-cloud/front/html/main-content.html"
        ls -la "/srv/apps/axi-star-cloud/front/html/main-content.html"
    else
        echo "❌ 文件不存在: /srv/apps/axi-star-cloud/front/html/main-content.html"
    fi
    
    # 检查目录结构
    echo "📁 检查目录结构..."
    find /srv/apps/axi-star-cloud/front/ -name "*.html" | head -10
    
    # 检查Nginx错误日志
    echo "📋 检查Nginx错误日志..."
    sudo tail -n 20 /var/log/nginx/error.log 2>/dev/null || echo "无法读取错误日志"
    
else
    echo "✅ 重定向正常"
fi

# 5. 测试其他路径
echo "📋 测试其他路径..."
TEST_PATHS=(
    "http://redamancy.com.cn/"
    "http://redamancy.com.cn/static/"
    "http://redamancy.com.cn/api/"
    "https://redamancy.com.cn/"
)

for url in "${TEST_PATHS[@]}"; do
    echo "🔗 测试: $url"
    RESPONSE=$(curl -s -w "%{http_code}|%{redirect_url}|%{num_redirects}" -o /dev/null \
        --max-redirs 3 \
        "$url" 2>/dev/null || echo "curl failed")
    
    HTTP_CODE=$(echo "$RESPONSE" | cut -d'|' -f1)
    REDIRECT_COUNT=$(echo "$RESPONSE" | cut -d'|' -f3)
    
    echo "  状态码: $HTTP_CODE, 重定向次数: $REDIRECT_COUNT"
    
    if [ "$REDIRECT_COUNT" -gt 2 ]; then
        echo "  ⚠️ 可能存在问题"
    fi
done

echo "✅ 诊断完成"
