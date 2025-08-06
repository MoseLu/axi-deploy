#!/bin/bash

# 紧急修复脚本 - 解决重复location错误
# 立即修复Nginx配置语法错误

set -e

echo "🚨 紧急修复：解决重复location错误..."

# 1. 备份当前配置
MAIN_CONF="/www/server/nginx/conf/conf.d/redamancy/00-main.conf"
BACKUP_DIR="/www/server/nginx/conf/conf.d/redamancy/backups/main"
sudo mkdir -p "$BACKUP_DIR"

if [ -f "$MAIN_CONF" ]; then
    echo "📋 备份当前主配置文件..."
    BACKUP_FILE="$BACKUP_DIR/00-main.conf.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$MAIN_CONF" "$BACKUP_FILE"
    echo "✅ 配置已备份到: $BACKUP_FILE"
fi

# 2. 应用修复后的配置
echo "🔄 应用修复后的配置..."
sudo tee "$MAIN_CONF" <<'EOF'
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    # 这里自动加载 route-*.conf（项目路由）——主配置永远不用再改
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    
    # 自动加载所有项目路由配置（HTTP版本）
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}
EOF

echo "✅ 配置已更新"

# 3. 验证配置语法
echo "📋 验证Nginx配置语法..."
if sudo nginx -t; then
    echo "✅ Nginx配置语法正确"
else
    echo "❌ Nginx配置语法错误"
    echo "显示当前配置内容:"
    cat "$MAIN_CONF"
    exit 1
fi

# 4. 重新加载Nginx
echo "🔄 重新加载Nginx..."
if sudo systemctl reload nginx; then
    echo "✅ Nginx重新加载成功"
else
    echo "❌ Nginx重新加载失败，尝试重启..."
    sudo systemctl restart nginx
    echo "✅ Nginx重启成功"
fi

# 5. 验证修复效果
echo "🔍 验证修复效果..."
echo "📄 当前主配置文件内容:"
cat "$MAIN_CONF"

# 6. 测试网站功能
echo "📋 测试网站功能..."

# 测试主页面
echo "🔗 测试主页面..."
MAIN_RESPONSE=$(curl -s -w "%{http_code}|%{num_redirects}" -o /dev/null \
    --max-redirs 3 \
    "https://redamancy.com.cn/" 2>/dev/null || echo "curl failed")

MAIN_CODE=$(echo "$MAIN_RESPONSE" | cut -d'|' -f1)
MAIN_REDIRECTS=$(echo "$MAIN_RESPONSE" | cut -d'|' -f2)

echo "  主页面状态码: $MAIN_CODE, 重定向次数: $MAIN_REDIRECTS"

# 测试静态文件
echo "🔗 测试静态文件..."
STATIC_RESPONSE=$(curl -s -w "%{http_code}|%{num_redirects}" -o /dev/null \
    --max-redirs 3 \
    "https://redamancy.com.cn/static/html/main-content.html" 2>/dev/null || echo "curl failed")

STATIC_CODE=$(echo "$STATIC_RESPONSE" | cut -d'|' -f1)
STATIC_REDIRECTS=$(echo "$STATIC_RESPONSE" | cut -d'|' -f2)

echo "  静态文件状态码: $STATIC_CODE, 重定向次数: $STATIC_REDIRECTS"

# 7. 分析结果
echo "📊 修复结果分析..."

if [ "$MAIN_CODE" = "200" ]; then
    echo "✅ 主页面访问正常"
else
    echo "❌ 主页面访问异常，状态码: $MAIN_CODE"
fi

if [ "$STATIC_CODE" = "200" ] || [ "$STATIC_CODE" = "404" ]; then
    echo "✅ 静态文件访问正常（404表示文件不存在但重定向正常）"
else
    echo "❌ 静态文件访问异常，状态码: $STATIC_CODE"
fi

if [ "$MAIN_REDIRECTS" -gt 2 ] || [ "$STATIC_REDIRECTS" -gt 2 ]; then
    echo "⚠️  检测到可能的重定向循环"
else
    echo "✅ 重定向正常"
fi

echo "✅ 紧急修复完成"
