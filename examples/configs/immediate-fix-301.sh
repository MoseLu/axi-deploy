#!/bin/bash

# 立即修复301重定向问题
# 直接修复服务器上的nginx配置

set -e

echo "🔧 立即修复301重定向问题..."

# 1. 备份当前配置
echo "📋 备份当前nginx配置..."
BACKUP_DIR="/tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /www/server/nginx/conf/conf.d/redamancy "$BACKUP_DIR/"
echo "✅ 配置已备份到: $BACKUP_DIR"

# 2. 检查当前配置
echo "📋 检查当前配置..."
echo "📋 主配置文件:"
cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf

echo "📋 route-axi-star-cloud.conf:"
if [ -f "/www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf" ]; then
    cat /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf
else
    echo "文件不存在"
fi

# 3. 清理所有route配置文件
echo "🧹 清理所有route配置文件..."
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf
echo "✅ route配置文件已清理"

# 4. 重新生成主配置文件
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

# 5. 重新生成axi-star-cloud的route配置
echo "🔄 重新生成axi-star-cloud的route配置..."
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf <<'EOF'
    # 静态文件服务
    location /static/ {
        alias /srv/apps/axi-star-cloud/front/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
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

    # 上传文件
    location /uploads/ {
        alias /srv/apps/axi-star-cloud/uploads/;
        try_files $uri =404;
    }

    # 精确匹配根路径
    location = / {
        root /srv/apps/axi-star-cloud/front;
        try_files /index.html =404;
    }

    # 排除其他项目路径的通用规则
    location ~ ^/(?!docs|static|api|health|uploads) {
        root /srv/apps/axi-star-cloud/front;
        try_files $uri $uri/ /index.html;
    }
EOF

echo "✅ axi-star-cloud route配置已更新"

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
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/)
echo "HTTPS测试结果: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ 主站点访问正常 (200)"
else
    echo "❌ 主站点访问异常"
    curl -I https://redamancy.com.cn/
fi

echo "📋 测试静态文件..."
STATIC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/static/html/main-content.html)
echo "静态文件测试结果: $STATIC_STATUS"

if [ "$STATIC_STATUS" = "200" ] || [ "$STATIC_STATUS" = "404" ]; then
    echo "✅ 静态文件访问正常"
else
    echo "❌ 静态文件访问异常"
    curl -I https://redamancy.com.cn/static/html/main-content.html
fi

echo "📋 测试API..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://redamancy.com.cn/api/health)
echo "API测试结果: $API_STATUS"

if [ "$API_STATUS" = "200" ] || [ "$API_STATUS" = "404" ]; then
    echo "✅ API访问正常"
else
    echo "❌ API访问异常"
    curl -I https://redamancy.com.cn/api/health
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
echo "🎉 立即修复完成！"
echo "📋 修复总结:"
echo "  - 清理了所有冲突的route配置文件"
echo "  - 重新生成了正确的nginx配置"
echo "  - 使用了改进的location规则"
echo "  - 保持了动态引入架构"
echo ""
echo "🌐 现在可以访问: https://redamancy.com.cn/"
echo ""
echo "📋 如果仍有问题，请检查:"
echo "  - 后端服务日志: sudo journalctl -u star-cloud.service -f"
echo "  - nginx错误日志: sudo tail -f /var/log/nginx/error.log"
echo "  - 备份位置: $BACKUP_DIR"
