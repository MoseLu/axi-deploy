#!/bin/bash

# Nginx配置修复测试脚本
# 用于验证301重定向问题的修复

echo "🔍 开始测试Nginx配置修复..."

# 测试变量
DOMAIN="redamancy.com.cn"
NGINX_CONF_DIR="/www/server/nginx/conf/conf.d/redamancy"

echo "📋 测试配置:"
echo "- 域名: $DOMAIN"
echo "- 配置目录: $NGINX_CONF_DIR"

# 1. 检查主配置文件
echo "📋 检查主配置文件..."
if [ -f "$NGINX_CONF_DIR/00-main.conf" ]; then
    echo "✅ 主配置文件存在"
    echo "📋 主配置文件内容:"
    cat "$NGINX_CONF_DIR/00-main.conf"
else
    echo "❌ 主配置文件不存在"
    exit 1
fi

# 2. 检查项目路由配置
echo "📋 检查项目路由配置..."
for conf in "$NGINX_CONF_DIR"/route-*.conf; do
    if [ -f "$conf" ]; then
        echo "📁 发现配置文件: $conf"
        echo "📋 配置文件内容:"
        cat "$conf"
    fi
done

# 3. 检查nginx配置语法
echo "📋 检查nginx配置语法..."
if nginx -t; then
    echo "✅ Nginx配置语法检查通过"
else
    echo "❌ Nginx配置语法错误"
    nginx -t 2>&1
    exit 1
fi

# 4. 重载nginx配置
echo "🔄 重载nginx配置..."
if systemctl reload nginx; then
    echo "✅ Nginx配置重载完成"
else
    echo "❌ Nginx重载失败"
    systemctl status nginx --no-pager -l
    exit 1
fi

# 5. 测试HTTP访问
echo "📋 测试HTTP访问..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN/)
echo "HTTP测试结果: $HTTP_STATUS"

# 6. 测试HTTPS访问
echo "📋 测试HTTPS访问..."
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/)
echo "HTTPS测试结果: $HTTPS_STATUS"

# 7. 测试docs路径
echo "📋 测试docs路径..."
DOCS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/docs/)
echo "Docs测试结果: $DOCS_STATUS"

# 8. 检查重定向
echo "📋 检查重定向..."
REDIRECT_CHECK=$(curl -s -I https://$DOMAIN/ | grep -i "location\|301\|302" || echo "无重定向")
echo "重定向检查: $REDIRECT_CHECK"

# 9. 检查服务状态
echo "📋 检查服务状态..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx服务正常运行"
else
    echo "❌ Nginx服务未运行"
fi

if curl -f -s http://127.0.0.1:8080/health > /dev/null 2>&1; then
    echo "✅ 后端服务正常运行"
else
    echo "❌ 后端服务未启动或无法访问"
fi

# 10. 最终验证
echo "📋 最终验证..."
if [ "$HTTPS_STATUS" = "200" ]; then
    echo "✅ HTTPS网站可访问 (HTTP $HTTPS_STATUS)"
    echo "🎉 配置修复成功！"
else
    echo "❌ HTTPS网站无法访问 (HTTP $HTTPS_STATUS)"
    echo "可能的原因:"
    echo "1. 配置未生效"
    echo "2. 文件路径错误"
    echo "3. 权限问题"
    echo "4. 其他配置冲突"
    exit 1
fi

echo "✅ 测试完成！"
