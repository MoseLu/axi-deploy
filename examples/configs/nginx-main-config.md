# Nginx 主配置文件示例

## 概述

本文档提供 Nginx 主配置文件的示例，用于多项目部署的统一管理。

## 配置结构

### 目录结构

```
/www/server/nginx/conf/conf.d/your-domain/
├── 00-main.conf           # 主配置文件
├── route-project1.conf     # 项目1路由配置
├── route-project2.conf     # 项目2路由配置
└── route-project3.conf     # 项目3路由配置
```

### 主配置文件

```nginx
# /www/server/nginx/conf/conf.d/your-domain/00-main.conf

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL 证书配置
    ssl_certificate     /www/server/nginx/ssl/your-domain/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/your-domain/privkey.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 客户端配置
    client_max_body_size 100m;
    client_body_timeout 60s;
    client_header_timeout 60s;

    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 包含项目路由配置
    include /www/server/nginx/conf/conf.d/your-domain/route-*.conf;
}

# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}
```

## 项目路由配置

### 后端项目配置

```nginx
# /www/server/nginx/conf/conf.d/your-domain/route-backend.conf

# API 代理
location /api/ {
    proxy_pass http://127.0.0.1:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    
    # 超时设置
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    
    # 缓冲区设置
    proxy_buffering on;
    proxy_buffer_size 4k;
    proxy_buffers 8 4k;
    
    # 文件上传
    client_max_body_size 100M;
}

# 健康检查
location /health {
    proxy_pass http://127.0.0.1:8080/health;
    proxy_set_header Host $host;
    access_log off;
}

# 前端文件
location / {
    root /srv/apps/backend-project/front;
    try_files $uri $uri/ /index.html;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }
    
    # HTML 文件不缓存
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

### 静态项目配置

```nginx
# /www/server/nginx/conf/conf.d/your-domain/route-static.conf

# 文档站点
location /docs/ {
    alias /srv/static/docs-project/;
    try_files $uri $uri/ /docs/index.html;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }
    
    # HTML 文件不缓存
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}

# 应用站点
location /app/ {
    alias /srv/static/app-project/;
    try_files $uri $uri/ /app/index.html;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }
    
    # HTML 文件不缓存
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

## 高级配置

### 负载均衡配置

```nginx
# 上游服务器配置
upstream backend_servers {
    server 127.0.0.1:8080 weight=1 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8081 weight=1 max_fails=3 fail_timeout=30s backup;
}

# 使用负载均衡
location /api/ {
    proxy_pass http://backend_servers/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### 缓存配置

```nginx
# 代理缓存
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=10g inactive=60m use_temp_path=off;

location /api/ {
    proxy_cache api_cache;
    proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
    proxy_cache_valid 200 302 10m;
    proxy_cache_valid 404 1m;
    
    proxy_pass http://127.0.0.1:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### 限流配置

```nginx
# 限流配置
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location /api/ {
    limit_req zone=api burst=20 nodelay;
    
    proxy_pass http://127.0.0.1:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## 安全配置

### 基本安全头

```nginx
# 安全头配置
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Referrer-Policy "strict-origin-when-cross-origin";
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;";
```

### 访问控制

```nginx
# 限制访问特定路径
location /admin/ {
    allow 192.168.1.0/24;
    allow 10.0.0.0/8;
    deny all;
    
    proxy_pass http://127.0.0.1:8080/admin/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## 监控和日志

### 访问日志配置

```nginx
# 自定义日志格式
log_format detailed '$remote_addr - $remote_user [$time_local] '
                   '"$request" $status $body_bytes_sent '
                   '"$http_referer" "$http_user_agent" '
                   'rt=$request_time uct="$upstream_connect_time" '
                   'uht="$upstream_header_time" urt="$upstream_response_time"';

# 使用自定义日志格式
access_log /var/log/nginx/your-domain.access.log detailed;
error_log /var/log/nginx/your-domain.error.log;
```

### 健康检查

```nginx
# 健康检查端点
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

## 部署脚本

### 配置部署脚本

```bash
#!/bin/bash

# 配置变量
DOMAIN="your-domain.com"
NGINX_CONF_DIR="/www/server/nginx/conf/conf.d/$DOMAIN"
CERT_DIR="/www/server/nginx/ssl/$DOMAIN"

# 创建配置目录
sudo mkdir -p $NGINX_CONF_DIR

# 部署主配置
sudo tee $NGINX_CONF_DIR/00-main.conf <<'EOF'
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate     /www/server/nginx/ssl/your-domain/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/your-domain/privkey.pem;

    client_max_body_size 100m;

    # 包含项目路由配置
    include /www/server/nginx/conf/conf.d/your-domain/route-*.conf;
}

server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}
EOF

# 检查配置语法
if sudo nginx -t; then
    echo "✅ Nginx 配置语法检查通过"
    sudo systemctl reload nginx
    echo "✅ Nginx 配置重载完成"
else
    echo "❌ Nginx 配置语法错误"
    exit 1
fi
```

## 故障排除

### 常见问题

1. **SSL 证书问题**
   ```bash
   # 检查证书文件
   ls -la /www/server/nginx/ssl/your-domain/
   
   # 检查证书有效期
   openssl x509 -enddate -noout -in /www/server/nginx/ssl/your-domain/fullchain.pem
   ```

2. **配置语法错误**
   ```bash
   # 检查配置语法
   sudo nginx -t
   
   # 查看详细错误
   sudo nginx -T
   ```

3. **权限问题**
   ```bash
   # 检查文件权限
   ls -la /www/server/nginx/conf/conf.d/your-domain/
   
   # 修复权限
   sudo chown -R nginx:nginx /www/server/nginx/conf/conf.d/your-domain/
   sudo chmod 644 /www/server/nginx/conf/conf.d/your-domain/*.conf
   ```

### 调试命令

```bash
# 查看 Nginx 状态
sudo systemctl status nginx

# 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 查看访问日志
sudo tail -f /var/log/nginx/your-domain.access.log

# 测试配置
sudo nginx -t

# 重载配置
sudo systemctl reload nginx
```

## 总结

通过合理的 Nginx 配置，可以实现：

1. **多项目管理** - 使用 include 功能管理多个项目
2. **安全防护** - 配置安全头和访问控制
3. **性能优化** - 启用缓存和压缩
4. **监控维护** - 配置日志和健康检查
5. **故障恢复** - 提供详细的故障排除指南

根据实际需求调整配置参数，确保系统稳定运行。 