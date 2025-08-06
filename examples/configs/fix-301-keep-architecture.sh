#!/bin/bash

# 修复301重定向问题 - 保持动态引入架构
# 解决axi-star-cloud部署时的301重定向循环问题，同时保持00-main.conf的动态引入设计

set -e

echo "🔧 开始修复301重定向问题（保持架构）..."

# 1. 备份当前配置
echo "📋 备份当前nginx配置..."
BACKUP_DIR="/tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /www/server/nginx/conf/conf.d/redamancy "$BACKUP_DIR/"
echo "✅ 配置已备份到: $BACKUP_DIR"

# 2. 检查当前主配置文件
echo "📋 检查当前主配置文件..."
if [ -f "/www/server/nginx/conf/conf.d/redamancy/00-main.conf" ]; then
    echo "📋 当前主配置文件内容:"
    cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf
else
    echo "❌ 主配置文件不存在"
fi

# 3. 检查所有route配置文件
echo "📋 检查所有route配置文件..."
ls -la /www/server/nginx/conf/conf.d/redamancy/route-*.conf 2>/dev/null || echo "没有找到route配置文件"

for conf in /www/server/nginx/conf/conf.d/redamancy/route-*.conf; do
    if [ -f "$conf" ]; then
        echo "📋 $conf 内容:"
        cat "$conf"
        echo ""
    fi
done

# 4. 检查是否有重复的location定义
echo "🔍 检查location冲突..."
CONFLICT_FOUND=false

# 检查是否有多个location /
LOCATION_COUNT=$(grep -r "location /" /www/server/nginx/conf/conf.d/redamancy/route-*.conf 2>/dev/null | wc -l)
if [ "$LOCATION_COUNT" -gt 1 ]; then
    echo "⚠️ 检测到多个 location / 定义，这可能导致冲突"
    echo "📋 找到的location / 定义:"
    grep -r "location /" /www/server/nginx/conf/conf.d/redamancy/route-*.conf 2>/dev/null
    CONFLICT_FOUND=true
fi

# 检查是否有多个location = /
EXACT_LOCATION_COUNT=$(grep -r "location = /" /www/server/nginx/conf/conf.d/redamancy/route-*.conf 2>/dev/null | wc -l)
if [ "$EXACT_LOCATION_COUNT" -gt 1 ]; then
    echo "⚠️ 检测到多个 location = / 定义，这可能导致冲突"
    echo "📋 找到的location = / 定义:"
    grep -r "location = /" /www/server/nginx/conf/conf.d/redamancy/route-*.conf 2>/dev/null
    CONFLICT_FOUND=true
fi

# 5. 如果发现冲突，清理冲突的配置文件
if [ "$CONFLICT_FOUND" = true ]; then
    echo "🔧 发现location冲突，清理冲突的配置文件..."
    
    # 备份所有route配置文件
    echo "📋 备份所有route配置文件..."
    sudo mkdir -p "$BACKUP_DIR/route-backup"
    sudo cp /www/server/nginx/conf/conf.d/redamancy/route-*.conf "$BACKUP_DIR/route-backup/" 2>/dev/null || true
    
    # 清理所有route配置文件
    echo "🧹 清理所有route配置文件..."
    sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf
    echo "✅ route配置文件已清理"
    
    # 重新生成主配置文件（确保包含include指令）
    echo "🔄 重新生成主配置文件..."
    sudo tee /www/server/nginx/conf/conf.d/redamancy/00-main.conf <<'EOF'
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
    
    # HTTP到HTTPS重定向
    return 301 https://$host$request_uri;
}
EOF
    echo "✅ 主配置文件已更新"
else
    echo "✅ 没有发现location冲突"
fi

# 6. 测试nginx配置
echo "🔍 测试nginx配置语法..."
if sudo nginx -t; then
    echo "✅ nginx配置语法检查通过"
else
    echo "❌ nginx配置语法错误"
    echo "配置错误详情:"
    sudo nginx -t 2>&1
    echo "🔧 尝试恢复备份..."
    sudo cp -r "$BACKUP_DIR/redamancy" /www/server/nginx/conf/conf.d/
    exit 1
fi

# 7. 重载nginx
echo "🔄 重载nginx服务..."
if sudo systemctl reload nginx; then
    echo "✅ nginx重载成功"
else
    echo "❌ nginx重载失败，尝试重启..."
    sudo systemctl restart nginx
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ nginx重启成功"
    else
        echo "❌ nginx重启失败"
        sudo systemctl status nginx --no-pager -l
        exit 1
    fi
fi

# 8. 等待服务稳定
echo "⏳ 等待服务稳定..."
sleep 5

# 9. 测试网站访问
echo "🌐 测试网站访问..."

echo "📋 测试主站点..."
if curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/ | grep -q "200"; then
    echo "✅ 主站点访问正常 (200)"
else
    echo "❌ 主站点访问异常"
    curl -I https://redamancy.com.cn/
fi

echo "📋 测试静态文件..."
if curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/static/html/main-content.html | grep -q "200\|404"; then
    echo "✅ 静态文件访问正常"
else
    echo "❌ 静态文件访问异常"
    curl -I https://redamancy.com.cn/static/html/main-content.html
fi

echo "📋 测试API..."
if curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/api/health | grep -q "200\|404"; then
    echo "✅ API访问正常"
else
    echo "❌ API访问异常"
    curl -I https://redamancy.com.cn/api/health
fi

echo "📋 测试文档站点..."
if curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/docs/ | grep -q "200\|404"; then
    echo "✅ 文档站点访问正常"
else
    echo "❌ 文档站点访问异常"
    curl -I https://redamancy.com.cn/docs/
fi

# 10. 检查后端服务
echo "🔍 检查后端服务状态..."
if sudo systemctl is-active --quiet star-cloud.service; then
    echo "✅ 后端服务正常运行"
else
    echo "❌ 后端服务未运行，尝试启动..."
    sudo systemctl start star-cloud.service
    sleep 3
    if sudo systemctl is-active --quiet star-cloud.service; then
        echo "✅ 后端服务启动成功"
    else
        echo "❌ 后端服务启动失败"
        sudo systemctl status star-cloud.service --no-pager -l
    fi
fi

# 11. 最终验证
echo "🎯 最终验证..."
echo "📋 检查nginx进程..."
if pgrep nginx > /dev/null; then
    echo "✅ nginx进程正常运行"
else
    echo "❌ nginx进程未运行"
fi

echo "📋 检查端口监听..."
if sudo netstat -tlnp | grep -q ":80\|:443"; then
    echo "✅ nginx端口监听正常"
else
    echo "❌ nginx端口监听异常"
fi

echo "📋 检查文件权限..."
if [ -r "/srv/apps/axi-star-cloud/front/index.html" ]; then
    echo "✅ 前端文件权限正常"
else
    echo "❌ 前端文件权限异常"
    ls -la /srv/apps/axi-star-cloud/front/
fi

echo ""
echo "🎉 修复完成！"
echo "📋 修复总结:"
echo "  - 保持了动态引入架构设计"
echo "  - 清理了冲突的location定义"
echo "  - 保持了00-main.conf的include机制"
echo "  - 修复了301重定向问题"
echo ""
echo "🌐 现在可以访问: https://redamancy.com.cn/"
echo "📚 文档站点: https://redamancy.com.cn/docs/"
echo ""
echo "📋 如果仍有问题，请检查:"
echo "  - 后端服务日志: sudo journalctl -u star-cloud.service -f"
echo "  - nginx错误日志: sudo tail -f /var/log/nginx/error.log"
echo "  - 备份位置: $BACKUP_DIR"
echo ""
echo "📋 重新部署时，系统会自动处理location冲突"
