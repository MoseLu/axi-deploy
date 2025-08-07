# 符合架构设计的301重定向修复指南

## 🚨 问题描述

部署后出现重定向循环问题：

```
Status: 301
Location: https://redamancy.com.cn/docs/
```

`/docs/` 路径重定向到自身，形成重定向循环。

## 🔍 根本原因分析

### 1. 重定向循环问题
- `/docs/` 重定向到 `/docs/` 
- `/` 重定向到 `/`
- 这表明nginx配置中存在冲突的location规则

### 2. 架构设计原则
- 必须保持include机制，避免耦合
- 主配置文件只负责基础配置
- 项目配置通过route-*.conf文件管理
- 避免在单个文件中耦合所有配置

## 🛠️ 符合架构的修复方案

### 方案1：智能冲突检测修复（推荐）

在服务器上运行以下脚本：

```bash
#!/bin/bash

echo "🔧 开始符合架构的301重定向修复..."

# 1. 备份当前配置
BACKUP_DIR="/tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)"
echo "📁 备份当前配置到: $BACKUP_DIR"
sudo cp -r /www/server/nginx/conf/conf.d/redamancy "$BACKUP_DIR"

# 2. 停止nginx
echo "🛑 停止nginx服务..."
sudo systemctl stop nginx

# 3. 清理所有route配置文件
echo "🧹 清理所有route配置文件..."
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf

# 4. 重新生成主配置文件（保持include机制）
echo "📝 重新生成主配置文件..."
sudo tee /www/server/nginx/conf/conf.d/redamancy/00-main.conf <<'EOF'
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    # 这里自动加载 route-*.conf（项目路由）——保持架构设计
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    
    # HTTP到HTTPS重定向
    return 301 https://$host$request_uri;
}
EOF

# 5. 重新生成axi-docs的route配置（避免冲突）
echo "📝 重新生成axi-docs配置..."
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf <<'EOF'
    # 处理 /docs/ 路径 - 服务 axi-docs 项目
    # 使用精确匹配，避免与其他location冲突
    location = /docs/ {
        alias /srv/static/axi-docs/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    location /docs/ {
        alias /srv/static/axi-docs/;
        
        # 确保不缓存HTML文件
        location ~* \.html$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
        
        # 静态资源缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # 处理 /docs 路径（不带斜杠）- 重定向到 /docs/
    location = /docs {
        return 301 /docs/;
    }
EOF

# 6. 重新生成axi-star-cloud的route配置（避免冲突）
echo "📝 重新生成axi-star-cloud配置..."
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf <<'EOF'
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

    # 上传文件
    location /uploads/ {
        alias /srv/apps/axi-star-cloud/uploads/;
        try_files $uri =404;
    }

    # 默认路由 - 使用精确匹配避免冲突
    location = / {
        root /srv/apps/axi-star-cloud/front;
        try_files /index.html =404;
    }

    # 其他路径 - 排除已处理的路由
    location ~ ^/(?!docs|static|api|health|uploads|$) {
        root /srv/apps/axi-star-cloud/front;
        try_files $uri $uri/ /index.html;
    }
EOF

# 7. 测试配置
echo "🔍 测试nginx配置..."
if sudo nginx -t; then
    echo "✅ nginx配置语法正确"
else
    echo "❌ nginx配置语法错误"
    echo "配置错误详情:"
    sudo nginx -t 2>&1
    exit 1
fi

# 8. 启动nginx
echo "🚀 启动nginx服务..."
sudo systemctl start nginx

# 9. 检查nginx状态
echo "📊 检查nginx状态..."
sudo systemctl status nginx --no-pager -l

# 10. 测试访问
echo "🌐 测试访问..."
echo "测试 /docs/ 路径:"
curl -I https://redamancy.com.cn/docs/ 2>/dev/null || echo "curl命令不可用，请手动测试"

echo "测试根路径:"
curl -I https://redamancy.com.cn/ 2>/dev/null || echo "curl命令不可用，请手动测试"

echo "✅ 修复完成！"
```

### 方案2：检查其他配置文件干扰

如果方案1不能解决问题，检查是否有其他配置文件干扰：

```bash
# 1. 检查所有包含redamancy的配置文件
echo "🔍 检查所有包含redamancy的配置文件..."
find /www/server/nginx/conf -name "*.conf" -exec grep -l "redamancy" {} \;

# 2. 检查宝塔面板的默认配置
echo "🔍 检查宝塔面板配置..."
if [ -f "/www/server/panel/vhost/nginx/redamancy.com.cn.conf" ]; then
    echo "发现宝塔面板配置文件:"
    cat "/www/server/panel/vhost/nginx/redamancy.com.cn.conf"
else
    echo "没有找到宝塔面板配置文件"
fi

# 3. 检查主nginx.conf文件
echo "🔍 检查主nginx.conf文件..."
grep -n "include.*redamancy" /www/server/nginx/conf/nginx.conf || echo "主配置文件中没有包含redamancy"

# 4. 检查所有include的文件
echo "🔍 检查所有include的文件..."
grep -r "include.*\.conf" /www/server/nginx/conf/ | grep -v "route-" || echo "没有找到其他include文件"
```

## 🔧 架构设计说明

### 修复的关键点

1. **保持include机制**: 继续使用route-*.conf文件，避免耦合
2. **精确location匹配**: 使用 `location = /docs/` 精确匹配，避免冲突
3. **优先级排序**: 确保 `/docs/` 路径优先级高于其他路径
4. **排除机制**: 使用 `location ~ ^/(?!docs|static|api|health|uploads|$)` 排除已处理路径

### 新的配置结构

```nginx
# 主配置文件 00-main.conf - 只负责基础配置
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    
    # 自动加载项目路由配置
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

# route-axi-docs.conf - 文档项目配置
location = /docs/ { ... }  # 精确匹配
location /docs/ { ... }    # 通用匹配
location = /docs { ... }   # 重定向

# route-axi-star-cloud.conf - 主项目配置
location /static/ { ... }
location /api/ { ... }
location = / { ... }       # 精确匹配根路径
location ~ ^/(?!docs|...) { ... }  # 排除已处理路径
```

## 🎯 验证修复

修复后，应该能够正常访问：

```bash
# 测试HTTPS访问
curl -I https://redamancy.com.cn/docs/

# 应该返回200状态码，而不是301
```

## 📝 注意事项

1. **保持架构**: 继续使用include机制，避免耦合
2. **精确匹配**: 使用 `location =` 精确匹配，避免冲突
3. **优先级**: 确保重要路径优先级高于通用路径
4. **排除机制**: 使用正则表达式排除已处理路径

这个方案既解决了301重定向问题，又保持了原有的架构设计原则。
