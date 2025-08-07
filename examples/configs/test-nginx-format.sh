#!/bin/bash

# 测试nginx配置格式
echo "🧪 测试nginx配置格式"

# 模拟生成的axi-docs配置
AXI_DOCS_CONFIG=$(echo -e "    location /docs/ {\n        alias /srv/static/axi-docs/;\n        index index.html;\n        try_files \$uri \$uri/ /docs/index.html;\n        \n        # 确保不缓存HTML文件\n        add_header Cache-Control \"no-cache, no-store, must-revalidate\" always;\n        add_header Pragma \"no-cache\" always;\n        add_header Expires \"0\" always;\n    }\n    \n    # 处理 /docs 路径（不带斜杠）- 重定向到 /docs/\n    location = /docs {\n        return 301 /docs/;\n    }")

echo "📋 生成的axi-docs配置:"
echo "$AXI_DOCS_CONFIG"

echo ""
echo "📋 配置行数: $(echo "$AXI_DOCS_CONFIG" | wc -l)"
echo "📋 是否包含换行: $(echo "$AXI_DOCS_CONFIG" | grep -c $'\n')"
echo "📋 是否包含缩进: $(echo "$AXI_DOCS_CONFIG" | grep -c '^    ')"

# 模拟生成的axi-star-cloud配置
AXI_STAR_CLOUD_CONFIG=$(echo -e "    # 静态文件服务\n    location /static/ {\n        alias /srv/apps/axi-star-cloud/front/;\n        expires 1y;\n        add_header Cache-Control \"public, immutable\";\n    }\n    \n    # API代理\n    location /api/ {\n        proxy_pass http://127.0.0.1:8080/;\n        proxy_set_header Host \$host;\n        proxy_set_header X-Real-IP \$remote_addr;\n        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto \$scheme;\n        client_max_body_size 100M;\n    }")

echo ""
echo "📋 生成的axi-star-cloud配置:"
echo "$AXI_STAR_CLOUD_CONFIG"

echo ""
echo "📋 配置行数: $(echo "$AXI_STAR_CLOUD_CONFIG" | wc -l)"
echo "📋 是否包含换行: $(echo "$AXI_STAR_CLOUD_CONFIG" | grep -c $'\n')"
echo "📋 是否包含缩进: $(echo "$AXI_STAR_CLOUD_CONFIG" | grep -c '^    ')"

echo ""
echo "✅ 测试完成"
