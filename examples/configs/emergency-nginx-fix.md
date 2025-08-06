# Nginx 配置紧急修复指南

## 问题描述

当遇到 `"location" directive is not allowed here` 错误时，需要立即修复nginx配置。

## 立即修复命令

如果遇到配置错误，请立即在服务器上运行以下命令：

```bash
# 1. 备份当前配置
sudo cp /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf /www/server/nginx/conf/redamancy/route-axi-docs.conf.backup

# 2. 删除错误的配置文件
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf

# 3. 创建正确的配置文件
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf <<'EOF'
    location /docs/ {
        alias /www/wwwroot/redamancy.com.cn/docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
EOF

# 4. 测试配置
sudo nginx -t

# 5. 如果测试通过，重载配置
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "✅ Nginx配置已修复并重载"
else
    echo "❌ 配置仍有错误，请检查"
    exit 1
fi
```

## 修复当前配置文件

如果您的配置文件有冲突，请执行以下命令修复：

```bash
# 1. 备份当前配置
sudo cp /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf.backup
sudo cp /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf.backup

# 2. 修复 route-axi-docs.conf（只包含docs配置）
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf <<'EOF'
    location /docs/ {
        alias /www/wwwroot/redamancy.com.cn/docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
EOF

# 3. 修复 route-axi-star-cloud.conf（移除docs配置，避免冲突）
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf <<'EOF'
# axi-star-cloud 项目路由配置

# 主站点配置 - axi-star-cloud
location / {
    root /srv/apps/axi-star-cloud;
    index index.html index.htm;
    try_files $uri $uri/ /index.html;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

# API 代理到 Go 后端
location /api/ {
    proxy_pass http://127.0.0.1:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # 上传文件大小限制
    client_max_body_size 100M;
}

# 健康检查端点
location /health {
    proxy_pass http://127.0.0.1:8080/health;
    proxy_set_header Host $host;
}

# 上传文件服务
location /uploads/ {
    alias /srv/apps/axi-star-cloud/uploads/;
    try_files $uri =404;
}

# 静态资源服务
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
EOF

# 4. 测试配置
sudo nginx -t

# 5. 如果测试通过，重载配置
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "✅ Nginx配置已修复并重载"
else
    echo "❌ 配置仍有错误，请检查"
    exit 1
fi
```

## 紧急修复步骤

### 1. 备份当前配置

```bash
# 备份现有配置文件
sudo cp /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf.backup
```

### 2. 创建正确的配置文件

```bash
# 创建正确的配置文件
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf <<'EOF'
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    location /docs/ {
        alias /www/wwwroot/redamancy.com.cn/docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
        
        # 静态资源缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # HTML 文件不缓存
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
}
EOF
```

### 3. 测试配置

```bash
# 测试nginx配置语法
sudo nginx -t

# 如果测试通过，重载配置
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "✅ Nginx配置已修复并重载"
else
    echo "❌ 配置仍有错误，请检查"
    exit 1
fi
```

### 4. 验证修复

```bash
# 测试网站访问
curl -I https://redamancy.com.cn/docs/

# 检查nginx状态
sudo systemctl status nginx
```

## 预防措施

### 1. 检查部署配置

确保axi-docs项目的nginx配置使用正确的格式：

```yaml
nginx_config: 'location /docs/ { alias /www/wwwroot/redamancy.com.cn/docs/; index index.html; try_files $uri $uri/ /docs/index.html; location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { expires 1y; add_header Cache-Control "public, immutable"; } location ~* \.html$ { expires -1; add_header Cache-Control "no-cache, no-store, must-revalidate"; } }'
```

### 2. 监控配置

```bash
# 设置监控脚本
sudo tee /usr/local/bin/nginx-monitor.sh <<'EOF'
#!/bin/bash
if ! sudo nginx -t > /dev/null 2>&1; then
    echo "❌ Nginx配置错误，尝试修复..."
    sudo systemctl stop nginx
    # 这里可以添加自动修复逻辑
    sudo systemctl start nginx
fi
EOF

sudo chmod +x /usr/local/bin/nginx-monitor.sh

# 添加到crontab
echo "*/5 * * * * /usr/local/bin/nginx-monitor.sh" | sudo crontab -
```

## 常见问题

### 1. 路径不匹配

确保使用正确的部署路径：
- 正确: `/www/wwwroot/redamancy.com.cn/docs/`
- 错误: `/srv/static/axi-docs/`

### 2. 嵌套location块

确保嵌套的location块格式正确：
```nginx
location /docs/ {
    alias /www/wwwroot/redamancy.com.cn/docs/;
    
    # 正确的嵌套格式
    location ~* \.html$ {
        expires -1;
    }
}
```

### 3. 转义字符问题

避免使用双反斜杠：
- 错误: `\\.html$`
- 正确: `\.html$`

## 联系信息

如果问题持续存在，请：
1. 收集错误日志
2. 检查配置文件内容
3. 验证文件路径和权限 