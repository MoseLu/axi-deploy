# Docs路径重定向问题修复指南

## 🚨 问题描述

访问 `https://redamancy.com.cn/docs/` 时返回 HTTP 301 重定向到 `https://redamancy.com.cn/`，而不是直接返回文档页面。

## 🔍 问题分析

### 根本原因
当前的nginx配置中存在重定向规则，导致 `/docs/` 路径被错误地重定向到根路径。

### 测试结果分析
从测试输出可以看出：
- HTTP测试结果: 301
- HTTPS测试结果: 301  
- 重定向目标: https://redamancy.com.cn/
- 这表明所有对 `/docs/` 的访问都被重定向到根路径

## 🛠️ 修复方案

### 方案1：完整修复脚本（推荐）

在服务器上运行以下命令：

```bash
# 1. 备份当前配置
sudo cp -r /www/server/nginx/conf/conf.d/redamancy /tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)

# 2. 清理所有route-*.conf文件
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf

# 3. 重新生成主配置文件
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

    # 文档站点 - 修复重定向问题
    location /docs/ {
        alias /srv/static/axi-docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
        
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

    # 上传文件
    location /uploads/ {
        alias /srv/apps/axi-star-cloud/uploads/;
        try_files $uri =404;
    }

    # 默认路由 - 精确匹配根路径
    location = / {
        root /srv/apps/axi-star-cloud/front;
        try_files /index.html =404;
    }

    # 其他路径
    location / {
        root /srv/apps/axi-star-cloud/front;
        try_files $uri $uri/ /index.html;
    }
}

server {
    listen 80;
    server_name redamancy.com.cn;
    return 301 https://$host$request_uri;
}
EOF

# 4. 测试配置
sudo nginx -t

# 5. 重载Nginx
sudo systemctl reload nginx

# 6. 测试访问
echo "测试主站点..."
curl -I https://redamancy.com.cn/

echo "测试文档站点..."
curl -I https://redamancy.com.cn/docs/

echo "测试静态文件..."
curl -I https://redamancy.com.cn/static/html/main-content.html
```

### 方案2：手动修复

如果无法运行完整脚本，可以手动执行：

```bash
# 1. 备份配置
sudo cp /www/server/nginx/conf/conf.d/redamancy/00-main.conf \
        /www/server/nginx/conf/conf.d/redamancy/00-main.conf.backup.$(date +%Y%m%d_%H%M%S)

# 2. 编辑主配置文件
sudo nano /www/server/nginx/conf/conf.d/redamancy/00-main.conf
```

在编辑器中，确保 `/docs/` location块如下：

```nginx
# 文档站点
location /docs/ {
    alias /srv/static/axi-docs/;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
}
```

## 🔧 配置说明

### 关键修复点

1. **移除复杂的重定向规则**: 不再使用正则表达式重定向
2. **明确的路径映射**: `/docs/` 直接映射到文档目录
3. **正确的try_files**: 确保找不到文件时返回index.html
4. **分离根路径处理**: 使用 `location = /` 精确匹配根路径

### 新的配置结构

- **`/docs/`**: 文档站点，直接服务VitePress构建的文件
- **`/static/`**: 静态文件，服务前端资源
- **`/api/`**: API代理，转发到Go后端
- **`/uploads/`**: 上传文件
- **`/`**: 默认路由，服务前端应用

## 📋 验证修复

### 1. 测试Nginx配置
```bash
sudo nginx -t
```

### 2. 测试网站访问
```bash
# 测试主站点
curl -I https://redamancy.com.cn/

# 测试文档站点
curl -I https://redamancy.com.cn/docs/

# 测试静态文件
curl -I https://redamancy.com.cn/static/html/main-content.html

# 测试API
curl -I https://redamancy.com.cn/api/health
```

### 3. 浏览器测试
- 打开 https://redamancy.com.cn/docs/
- 应该直接显示文档页面，而不是重定向

## 🚀 重新部署

修复完成后，可以重新部署axi-docs项目：

```bash
# 在axi-docs目录中
cd /srv/apps/axi-docs
git pull origin main
pnpm install
pnpm docs:build

# 复制构建结果到静态目录
sudo cp -r docs/.vitepress/dist/* /srv/static/axi-docs/
```

## 📞 故障排除

如果问题仍然存在：

1. **检查nginx错误日志**:
   ```bash
   sudo tail -f /www/server/nginx/logs/error.log
   ```

2. **检查nginx访问日志**:
   ```bash
   sudo tail -f /www/server/nginx/logs/access.log
   ```

3. **检查文件权限**:
   ```bash
   ls -la /srv/static/axi-docs/
   ```

4. **检查nginx进程**:
   ```bash
   sudo systemctl status nginx
   ```

## 📝 注意事项

1. **备份配置**: 修复前一定要备份当前配置
2. **测试配置**: 修改后一定要测试nginx配置语法
3. **逐步验证**: 修复后逐步测试各个路径
4. **监控日志**: 关注nginx错误日志，及时发现问题
