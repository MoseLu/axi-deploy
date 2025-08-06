#!/bin/bash

# 强制更新Nginx配置脚本
# 用于解决配置未更新的问题

set -e

echo "🔧 强制更新Nginx配置..."

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

# 2. 强制更新主配置文件
echo "🔄 强制更新主配置文件..."
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
    
    # 对于未匹配的路由，重定向到HTTPS
    # 注意：这里不处理已经在route-*.conf中定义的路由
    location / {
        return 301 https://$host$request_uri;
    }
}
EOF

echo "✅ 主配置文件已强制更新"

# 3. 验证配置语法
echo "📋 验证Nginx配置语法..."
if sudo nginx -t; then
    echo "✅ Nginx配置语法正确"
else
    echo "❌ Nginx配置语法错误"
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

# 5. 验证配置已更新
echo "🔍 验证配置已更新..."
echo "📄 当前主配置文件内容:"
cat "$MAIN_CONF"

# 6. 测试静态文件访问
echo "📋 测试静态文件访问..."
TEST_URL="https://redamancy.com.cn/static/html/main-content.html"
echo "🔗 测试URL: $TEST_URL"

RESPONSE=$(curl -s -w "%{http_code}|%{num_redirects}" -o /dev/null \
    --max-redirs 3 \
    "$TEST_URL" 2>/dev/null || echo "curl failed")

HTTP_CODE=$(echo "$RESPONSE" | cut -d'|' -f1)
REDIRECT_COUNT=$(echo "$RESPONSE" | cut -d'|' -f2)

echo "📊 响应状态码: $HTTP_CODE"
echo "📊 重定向次数: $REDIRECT_COUNT"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 静态文件访问正常"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "⚠️ 文件不存在，但重定向正常"
else
    echo "❌ 静态文件访问异常，状态码: $HTTP_CODE"
fi

echo "✅ 配置强制更新完成"
