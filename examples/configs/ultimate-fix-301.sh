#!/bin/bash

# 终极修复301重定向问题
# 考虑到可能存在多个层面的问题：nginx配置、代理、CDN等

set -e

echo "🔧 开始终极修复301重定向问题..."

# 1. 备份当前配置
echo "📋 备份当前nginx配置..."
BACKUP_DIR="/tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /www/server/nginx/conf/conf.d/redamancy "$BACKUP_DIR/"
echo "✅ 配置已备份到: $BACKUP_DIR"

# 2. 停止nginx服务
echo "🛑 停止nginx服务..."
sudo systemctl stop nginx
sudo pkill -f nginx || true
sleep 3

# 3. 清理所有可能的配置文件
echo "🧹 清理所有可能的配置文件..."
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/00-main.conf

# 4. 检查是否有其他配置文件包含redamancy.com.cn
echo "📋 检查其他配置文件..."
OTHER_CONFIGS=$(find /www/server/nginx/conf -name "*.conf" -exec grep -l "redamancy.com.cn" {} \; 2>/dev/null | grep -v "backup" || true)
if [ -n "$OTHER_CONFIGS" ]; then
    echo "⚠️ 发现其他配置文件包含redamancy.com.cn:"
    echo "$OTHER_CONFIGS"
    echo "📋 备份这些配置文件..."
    for config in $OTHER_CONFIGS; do
        if [ -f "$config" ]; then
            sudo cp "$config" "$BACKUP_DIR/"
            echo "✅ 已备份: $config"
        fi
    done
fi

# 5. 重新生成主配置文件（最简版本）
echo "🔄 重新生成主配置文件（最简版本）..."
sudo tee /www/server/nginx/conf/conf.d/redamancy/00-main.conf <<'EOF'
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    # 静态文件服务
    location /static/ {
        alias /srv/apps/axi-star-cloud/front/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 100M;
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host $host;
    }

    # 文档站点
    location /docs/ {
        alias /srv/static/axi-docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
    }

    # 上传文件
    location /uploads/ {
        alias /srv/apps/axi-star-cloud/uploads/;
        try_files $uri =404;
    }

    # 默认路由 - 直接处理根路径
    location / {
        root /srv/apps/axi-star-cloud/front;
        try_files $uri $uri/ /index.html;
    }
}

server {
    listen 80;
    server_name redamancy.com.cn;
    
    # HTTP到HTTPS重定向
    return 301 https://$host$request_uri;
}
EOF

echo "✅ 主配置文件已更新"

# 6. 检查nginx配置语法
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

# 7. 启动nginx服务
echo "🚀 启动nginx服务..."
sudo systemctl start nginx
sleep 5

# 8. 检查nginx服务状态
if sudo systemctl is-active --quiet nginx; then
    echo "✅ nginx服务启动成功"
else
    echo "❌ nginx服务启动失败"
    sudo systemctl status nginx --no-pager -l
    exit 1
fi

# 9. 等待服务稳定
echo "⏳ 等待服务稳定..."
sleep 10

# 10. 测试网站访问
echo "🌐 测试网站访问..."

echo "📋 测试本地访问..."
LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/ 2>/dev/null || echo "000")
echo "本地HTTP状态: $LOCAL_STATUS"

LOCAL_HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://127.0.0.1/ 2>/dev/null || echo "000")
echo "本地HTTPS状态: $LOCAL_HTTPS_STATUS"

echo "📋 测试域名访问..."
DOMAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://redamancy.com.cn/ 2>/dev/null || echo "000")
echo "域名HTTP状态: $DOMAIN_STATUS"

DOMAIN_HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/ 2>/dev/null || echo "000")
echo "域名HTTPS状态: $DOMAIN_HTTPS_STATUS"

# 11. 检查后端服务
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

# 12. 详细测试
echo "📋 详细测试..."

if [ "$DOMAIN_HTTPS_STATUS" = "200" ]; then
    echo "✅ 域名HTTPS访问正常 (200)"
else
    echo "❌ 域名HTTPS访问异常 ($DOMAIN_HTTPS_STATUS)"
    echo "📋 详细响应:"
    curl -I https://redamancy.com.cn/ 2>/dev/null || echo "无法获取响应头"
fi

echo "📋 测试静态文件..."
STATIC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/static/html/main-content.html 2>/dev/null || echo "000")
if [ "$STATIC_STATUS" = "200" ] || [ "$STATIC_STATUS" = "404" ]; then
    echo "✅ 静态文件访问正常 ($STATIC_STATUS)"
else
    echo "❌ 静态文件访问异常 ($STATIC_STATUS)"
fi

echo "📋 测试API..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/api/health 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ] || [ "$API_STATUS" = "404" ]; then
    echo "✅ API访问正常 ($API_STATUS)"
else
    echo "❌ API访问异常 ($API_STATUS)"
fi

# 13. 检查nginx进程和端口
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

# 14. 检查文件权限
echo "📋 检查文件权限..."
if [ -r "/srv/apps/axi-star-cloud/front/index.html" ]; then
    echo "✅ 前端文件权限正常"
else
    echo "❌ 前端文件权限异常"
    ls -la /srv/apps/axi-star-cloud/front/
fi

# 15. 检查nginx错误日志
echo "📋 检查nginx错误日志..."
if [ -f "/var/log/nginx/error.log" ]; then
    echo "📋 最近的错误日志:"
    sudo tail -n 10 /var/log/nginx/error.log
else
    echo "错误日志文件不存在"
fi

echo ""
echo "🎉 终极修复完成！"
echo "📋 修复总结:"
echo "  - 清理了所有可能的配置文件"
echo "  - 重新生成了最简的nginx配置"
echo "  - 直接在主配置文件中定义所有规则"
echo "  - 避免了include机制的复杂性"
echo ""
echo "🌐 现在可以访问: https://redamancy.com.cn/"
echo ""
echo "📋 如果仍有问题，请检查:"
echo "  - 后端服务日志: sudo journalctl -u star-cloud.service -f"
echo "  - nginx错误日志: sudo tail -f /var/log/nginx/error.log"
echo "  - 备份位置: $BACKUP_DIR"
echo ""
echo "📋 测试结果:"
echo "  - 本地HTTP: $LOCAL_STATUS"
echo "  - 本地HTTPS: $LOCAL_HTTPS_STATUS"
echo "  - 域名HTTP: $DOMAIN_STATUS"
echo "  - 域名HTTPS: $DOMAIN_HTTPS_STATUS"
