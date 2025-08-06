#!/bin/bash

# 测试静态资源访问脚本
# 用于验证nginx配置是否正确处理静态资源

echo "🔍 开始测试静态资源访问..."

# 测试变量
DOMAIN="redamancy.com.cn"
BASE_URL="https://$DOMAIN"

echo "📋 测试配置:"
echo "- 域名: $DOMAIN"
echo "- 基础URL: $BASE_URL"

# 1. 测试CSS文件
echo "📋 测试CSS文件..."
CSS_FILES=(
    "/static/css/theme-toggle.css"
    "/static/css/responsive.css"
    "/static/css/font-optimization.css"
    "/static/css/theme-transition.css"
)

for css_file in "${CSS_FILES[@]}"; do
    echo "测试: $css_file"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$css_file")
    echo "状态码: $HTTP_STATUS"
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ 成功"
    else
        echo "❌ 失败"
    fi
done

# 2. 测试JS文件
echo "📋 测试JS文件..."
JS_FILES=(
    "/static/js/api/core.js"
    "/static/js/ui/core.js"
    "/static/js/auth/index.js"
)

for js_file in "${JS_FILES[@]}"; do
    echo "测试: $js_file"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$js_file")
    echo "状态码: $HTTP_STATUS"
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ 成功"
    else
        echo "❌ 失败"
    fi
done

# 3. 测试HTML模板文件
echo "📋 测试HTML模板文件..."
HTML_FILES=(
    "/static/html/main-content.html"
    "/static/html/header.html"
    "/static/html/login.html"
)

for html_file in "${HTML_FILES[@]}"; do
    echo "测试: $html_file"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$html_file")
    echo "状态码: $HTTP_STATUS"
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ 成功"
    else
        echo "❌ 失败"
    fi
done

# 4. 测试公共库文件
echo "📋 测试公共库文件..."
LIB_FILES=(
    "/static/public/libs/marked.min.js"
    "/static/public/libs/chart.umd.min.js"
    "/static/public/libs/font-awesome.min.css"
)

for lib_file in "${LIB_FILES[@]}"; do
    echo "测试: $lib_file"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$lib_file")
    echo "状态码: $HTTP_STATUS"
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ 成功"
    else
        echo "❌ 失败"
    fi
done

# 5. 检查重定向
echo "📋 检查重定向..."
REDIRECT_CHECK=$(curl -s -I "$BASE_URL/static/html/main-content.html" | grep -i "location\|301\|302" || echo "无重定向")
echo "重定向检查: $REDIRECT_CHECK"

echo "✅ 测试完成！"
