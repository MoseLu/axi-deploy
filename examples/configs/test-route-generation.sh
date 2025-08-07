#!/bin/bash

# 测试route配置文件生成逻辑
echo "🧪 测试route配置文件生成逻辑"

# 模拟axi-docs项目的nginx配置
AXI_DOCS_CONFIG='# 处理 /docs/ 路径 - 服务 axi-docs 项目
location /docs/ {
    alias /srv/static/axi-docs/;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
    
    # 确保不缓存HTML文件
    add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;
}

# 处理 /docs 路径（不带斜杠）- 重定向到 /docs/
location = /docs {
    return 301 /docs/;
}'

# 模拟axi-star-cloud项目的nginx配置
AXI_STAR_CLOUD_CONFIG='location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location /api/ {
    proxy_pass http://127.0.0.1:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 100M;
}

location /health {
    proxy_pass http://127.0.0.1:8080/health;
    proxy_set_header Host $host;
}

location / {
    root /srv/apps/axi-star-cloud/front;
    try_files $uri $uri/ /index.html;
}'

echo "📋 测试axi-docs配置..."
echo "$AXI_DOCS_CONFIG" | grep -q "location /[^a-zA-Z]" && echo "❌ 检测到location /配置" || echo "✅ 没有location /配置"

echo "📋 测试axi-star-cloud配置..."
echo "$AXI_STAR_CLOUD_CONFIG" | grep -q "location /[^a-zA-Z]" && echo "✅ 检测到location /配置" || echo "❌ 没有location /配置"

echo "📋 测试location = /docs配置..."
echo "$AXI_DOCS_CONFIG" | grep -q "location = /docs" && echo "✅ 检测到location = /docs配置" || echo "❌ 没有location = /docs配置"

echo "📋 测试location = /配置..."
echo "$AXI_DOCS_CONFIG" | grep -q "location = /" && echo "❌ 检测到location = /配置" || echo "✅ 没有location = /配置"

echo "✅ 测试完成"
