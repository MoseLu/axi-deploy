#!/bin/bash

# HTML模板调试脚本
# 用于检查HTML模板文件是否正确部署

echo "🔍 开始调试HTML模板文件..."

# 检查变量
DEPLOY_PATH="/srv/apps/axi-star-cloud"
HTML_PATH="$DEPLOY_PATH/front/html"

echo "📋 调试配置:"
echo "- 部署路径: $DEPLOY_PATH"
echo "- HTML路径: $HTML_PATH"

# 1. 检查部署目录结构
echo "📋 检查部署目录结构..."
if [ -d "$DEPLOY_PATH" ]; then
    echo "✅ 部署目录存在: $DEPLOY_PATH"
    ls -la "$DEPLOY_PATH/"
else
    echo "❌ 部署目录不存在: $DEPLOY_PATH"
    exit 1
fi

# 2. 检查front目录
echo "📋 检查front目录..."
if [ -d "$DEPLOY_PATH/front" ]; then
    echo "✅ front目录存在"
    ls -la "$DEPLOY_PATH/front/"
else
    echo "❌ front目录不存在"
    exit 1
fi

# 3. 检查html目录
echo "📋 检查html目录..."
if [ -d "$HTML_PATH" ]; then
    echo "✅ html目录存在"
    ls -la "$HTML_PATH/"
else
    echo "❌ html目录不存在"
    exit 1
fi

# 4. 检查具体的HTML文件
echo "📋 检查HTML文件..."
HTML_FILES=(
    "main-content.html"
    "header.html"
    "login.html"
    "welcome-section.html"
    "file-list.html"
    "folder-section.html"
    "upload-area.html"
    "storage-overview.html"
    "file-type-filters.html"
    "modals.html"
)

for html_file in "${HTML_FILES[@]}"; do
    if [ -f "$HTML_PATH/$html_file" ]; then
        echo "✅ $html_file 存在"
        ls -la "$HTML_PATH/$html_file"
    else
        echo "❌ $html_file 不存在"
    fi
done

# 5. 检查nginx配置
echo "📋 检查nginx配置..."
NGINX_CONF="/www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf"
if [ -f "$NGINX_CONF" ]; then
    echo "✅ nginx配置文件存在"
    echo "📋 nginx配置内容:"
    cat "$NGINX_CONF"
else
    echo "❌ nginx配置文件不存在"
fi

# 6. 测试nginx配置语法
echo "📋 测试nginx配置语法..."
if nginx -t; then
    echo "✅ nginx配置语法正确"
else
    echo "❌ nginx配置语法错误"
    nginx -t 2>&1
fi

# 7. 测试本地访问
echo "📋 测试本地访问..."
LOCAL_TEST=$(curl -s -I -H "Host: redamancy.com.cn" "http://127.0.0.1/static/html/main-content.html" 2>/dev/null || echo "本地访问失败")
echo "本地测试结果: $LOCAL_TEST"

# 8. 检查文件权限
echo "📋 检查文件权限..."
if [ -d "$HTML_PATH" ]; then
    echo "HTML目录权限:"
    ls -la "$HTML_PATH/"
    
    echo "nginx进程用户:"
    ps aux | grep nginx | grep -v grep || echo "没有找到nginx进程"
fi

echo "✅ 调试完成！"
