#!/bin/bash

# 修复nginx配置脚本
# 用于手动更新route-axi-docs.conf配置文件

echo "🔧 修复nginx配置..."

PROJECT="axi-docs"
NGINX_CONF_DIR="/www/server/nginx/conf/conf.d/redamancy"
ROUTE_CONF="$NGINX_CONF_DIR/route-$PROJECT.conf"

echo "📋 配置信息:"
echo "- 项目: $PROJECT"
echo "- 配置文件: $ROUTE_CONF"

# 备份旧配置
if [ -f "$ROUTE_CONF" ]; then
    echo "📋 备份旧配置..."
    BACKUP_FILE="$ROUTE_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$ROUTE_CONF" "$BACKUP_FILE"
    echo "✅ 旧配置已备份到: $BACKUP_FILE"
fi

# 生成正确的配置
echo "📝 生成新配置..."
NGINX_CONFIG="
location /docs/ {
    alias /srv/static/$PROJECT/;
    index index.html;
    try_files \$uri \$uri/ /docs/index.html;
    
    # 确保不缓存HTML文件
    add_header Cache-Control \"no-cache, no-store, must-revalidate\" always;
    add_header Pragma \"no-cache\" always;
    add_header Expires \"0\" always;
}

# 处理 /docs 路径（不带斜杠）- 重定向到 /docs/
location = /docs {
    return 301 /docs/;
}"

# 写入新配置
echo "$NGINX_CONFIG" | sudo tee "$ROUTE_CONF"

# 验证配置
echo "📄 新配置内容:"
cat "$ROUTE_CONF"

# 检查nginx配置语法
echo "🔍 检查nginx配置语法..."
if sudo nginx -t; then
    echo "✅ nginx配置语法正确"
    sudo systemctl reload nginx
    echo "✅ nginx配置已重新加载"
else
    echo "❌ nginx配置语法错误"
    exit 1
fi

echo "✅ 配置修复完成"
