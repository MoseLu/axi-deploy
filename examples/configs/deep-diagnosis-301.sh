#!/bin/bash

# 深度诊断301重定向问题
# 全面检查nginx配置、代理设置、CDN等可能的问题

set -e

echo "🔍 开始深度诊断301重定向问题..."

# 1. 备份当前配置
echo "📋 备份当前nginx配置..."
BACKUP_DIR="/tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /www/server/nginx/conf/conf.d/redamancy "$BACKUP_DIR/"
echo "✅ 配置已备份到: $BACKUP_DIR"

# 2. 检查所有nginx配置文件
echo "📋 检查所有nginx配置文件..."
echo "📋 主nginx.conf:"
cat /www/server/nginx/conf/nginx.conf

echo "📋 00-main.conf:"
cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf

echo "📋 route-axi-star-cloud.conf:"
if [ -f "/www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf" ]; then
    cat /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf
else
    echo "文件不存在"
fi

# 3. 检查是否有其他配置文件包含redamancy.com.cn
echo "📋 检查所有包含redamancy.com.cn的配置文件..."
find /www/server/nginx/conf -name "*.conf" -exec grep -l "redamancy.com.cn" {} \;

# 4. 检查是否有重定向规则
echo "📋 检查所有重定向规则..."
grep -r "301\|302\|redirect" /www/server/nginx/conf/ || echo "没有找到重定向规则"

# 5. 检查是否有location /规则
echo "📋 检查所有location /规则..."
grep -r "location /" /www/server/nginx/conf/ || echo "没有找到location /规则"

# 6. 检查是否有其他server块处理redamancy.com.cn
echo "📋 检查所有server块..."
grep -r "server_name redamancy.com.cn" /www/server/nginx/conf/ || echo "没有找到server_name"

# 7. 检查是否有include文件包含其他配置
echo "📋 检查include文件..."
grep -r "include.*redamancy" /www/server/nginx/conf/ || echo "没有找到include redamancy"

# 8. 检查是否有其他配置文件被include
echo "📋 检查nginx.conf中的include..."
grep -A5 -B5 "include" /www/server/nginx/conf/nginx.conf

# 9. 检查是否有宝塔面板配置
echo "📋 检查宝塔面板配置..."
find /www/server/panel -name "*.conf" -exec grep -l "redamancy" {} \; 2>/dev/null || echo "没有找到宝塔面板配置"

# 10. 检查是否有其他nginx配置目录
echo "📋 检查其他nginx配置目录..."
find /etc/nginx -name "*.conf" -exec grep -l "redamancy" {} \; 2>/dev/null || echo "没有找到/etc/nginx配置"

# 11. 检查是否有代理或CDN配置
echo "📋 检查代理配置..."
if command -v nginx >/dev/null 2>&1; then
    echo "nginx版本:"
    nginx -v
fi

# 12. 检查网络连接
echo "📋 检查网络连接..."
echo "本地访问测试:"
curl -I http://127.0.0.1/ 2>/dev/null || echo "本地访问失败"

echo "HTTPS本地访问测试:"
curl -I https://127.0.0.1/ 2>/dev/null || echo "HTTPS本地访问失败"

# 13. 检查DNS解析
echo "📋 检查DNS解析..."
nslookup redamancy.com.cn 2>/dev/null || echo "DNS解析失败"

# 14. 检查防火墙
echo "📋 检查防火墙..."
sudo iptables -L | grep -E "(80|443)" || echo "没有找到相关防火墙规则"

# 15. 检查SSL证书
echo "📋 检查SSL证书..."
if [ -f "/www/server/nginx/ssl/redamancy/fullchain.pem" ]; then
    echo "SSL证书存在"
    ls -la /www/server/nginx/ssl/redamancy/
else
    echo "SSL证书不存在"
fi

# 16. 检查nginx进程
echo "📋 检查nginx进程..."
ps aux | grep nginx

# 17. 检查nginx错误日志
echo "📋 检查nginx错误日志..."
if [ -f "/var/log/nginx/error.log" ]; then
    echo "最近的错误日志:"
    sudo tail -n 20 /var/log/nginx/error.log
else
    echo "错误日志文件不存在"
fi

# 18. 检查nginx访问日志
echo "📋 检查nginx访问日志..."
if [ -f "/var/log/nginx/access.log" ]; then
    echo "最近的访问日志:"
    sudo tail -n 10 /var/log/nginx/access.log
else
    echo "访问日志文件不存在"
fi

# 19. 测试不同的访问方式
echo "📋 测试不同的访问方式..."

echo "测试HTTP访问:"
curl -v http://redamancy.com.cn/ 2>&1 | head -20

echo "测试HTTPS访问:"
curl -v https://redamancy.com.cn/ 2>&1 | head -20

echo "测试IP直接访问:"
SERVER_IP=$(curl -s ifconfig.me)
echo "服务器IP: $SERVER_IP"
curl -v http://$SERVER_IP/ 2>&1 | head -20

# 20. 检查是否有其他服务占用80/443端口
echo "📋 检查端口占用..."
sudo netstat -tlnp | grep -E ":80|:443"

# 21. 检查systemd服务
echo "📋 检查systemd服务..."
sudo systemctl status nginx --no-pager -l

# 22. 检查nginx配置测试
echo "📋 测试nginx配置..."
sudo nginx -t

# 23. 检查nginx模块
echo "📋 检查nginx模块..."
nginx -V 2>&1 | grep -o "with-http_ssl_module\|with-http_realip_module\|with-http_proxy_module" || echo "没有找到相关模块信息"

echo ""
echo "🎯 深度诊断完成！"
echo "📋 诊断总结:"
echo "  - 检查了所有nginx配置文件"
echo "  - 检查了重定向规则"
echo "  - 检查了网络连接"
echo "  - 检查了SSL证书"
echo "  - 检查了nginx进程和日志"
echo ""
echo "📋 如果发现问题，请根据诊断结果进行修复"
echo "📋 备份位置: $BACKUP_DIR"
