# Nginx 重定向循环问题修复

## 🚨 问题描述

访问 https://redamancy.com.cn/ 时出现 `ERR_TOO_MANY_REDIRECTS` 错误，具体表现为：

1. **静态文件加载失败**: `GET https://redamancy.com.cn/static/html/main-content.html net::ERR_TOO_MANY_REDIRECTS`
2. **组件加载失败**: 多个容器找不到，因为主内容模板加载失败
3. **页面无法正常显示**: 前端JavaScript无法加载必要的模板文件

## 🔍 问题分析

### 根本原因
当前的Nginx配置存在以下问题：

1. **重复的location配置**: 多个项目都配置了`location /`，导致冲突
2. **重定向规则冲突**: HTTP到HTTPS的重定向规则与静态文件访问冲突
3. **include文件覆盖**: route-*.conf中的配置可能被覆盖或冲突

### 具体表现
- 静态文件访问返回301重定向而不是200状态码
- 前端无法加载必要的HTML模板文件
- 页面组件无法正常初始化

## 🛠️ 解决方案

### 方案1：完整修复脚本（推荐）

在服务器上运行完整修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/complete-fix.sh
chmod +x complete-fix.sh
sudo ./complete-fix.sh
```

### 方案2：手动修复

如果无法下载脚本，手动执行：

```bash
# 1. 备份当前配置
sudo cp -r /www/server/nginx/conf/conf.d/redamancy /tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)

# 2. 清理所有route-*.conf文件
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf

# 3. 重新生成主配置文件（完整版本）
sudo tee /www/server/nginx/conf/conf.d/redamancy/00-main.conf <<'EOF'
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    # 静态文件服务（axi-star-cloud）
    location /static/ {
        alias /srv/apps/axi-star-cloud/front/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理到Go后端
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 100M;
    }

    # 健康检查端点
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host $host;
    }

    # 文档站点
    location /docs/ {
        alias /srv/static/axi-docs/;
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

    # 上传文件服务
    location /uploads/ {
        alias /srv/apps/axi-star-cloud/uploads/;
        try_files $uri =404;
    }

    # 默认路由（axi-star-cloud前端）
    location / {
        root /srv/apps/axi-star-cloud/front;
        try_files $uri $uri/ /index.html;
        
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

server {
    listen 80;
    server_name redamancy.com.cn;
    
    # 重定向到HTTPS
    return 301 https://$host$request_uri;
}
EOF

# 4. 测试配置
sudo nginx -t

# 5. 重载Nginx
sudo systemctl reload nginx
```

## 🔧 配置说明

### 新的配置结构

1. **静态文件服务**: `/static/` 路径直接映射到前端目录
2. **API代理**: `/api/` 路径代理到Go后端
3. **文档站点**: `/docs/` 路径服务VitePress文档
4. **上传文件**: `/uploads/` 路径服务上传的文件
5. **默认路由**: `/` 路径服务前端应用

### 关键改进

1. **移除了复杂的重定向规则**: 不再使用复杂的正则表达式重定向
2. **明确的路径映射**: 每个路径都有明确的处理规则
3. **正确的缓存策略**: 静态资源缓存，HTML文件不缓存
4. **简化的HTTP重定向**: 只做简单的HTTP到HTTPS重定向

## 📋 验证修复

### 1. 测试Nginx配置
```bash
sudo nginx -t
```

### 2. 测试网站访问
```bash
# 测试主站点
curl -I https://redamancy.com.cn/

# 测试静态文件
curl -I https://redamancy.com.cn/static/html/main-content.html

# 测试文档站点
curl -I https://redamancy.com.cn/docs/

# 测试API
curl -I https://redamancy.com.cn/api/health
```

### 3. 检查浏览器访问
- 打开 https://redamancy.com.cn/
- 检查开发者工具的网络面板
- 确认静态文件返回200状态码而不是301重定向

## 🚀 重新部署

修复完成后，可以重新部署项目：

1. **推送代码到GitHub** - 触发自动部署
2. **系统会自动处理配置冲突** - 新的部署逻辑会避免重复location
3. **验证部署结果** - 检查网站是否正常访问

## 📞 故障排除

如果问题仍然存在：

1. **运行诊断脚本**：
   ```bash
   wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/test-static-access.sh
   chmod +x test-static-access.sh
   sudo ./test-static-access.sh
   ```

2. **检查Nginx错误日志**：
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

3. **检查部署目录**：
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/
   ls -la /srv/static/axi-docs/
   ```

4. **手动测试静态文件**：
   ```bash
   curl -v https://redamancy.com.cn/static/html/main-content.html
   ```

## 🔄 长期维护

### 部署策略更新

在`axi-deploy/.github/workflows/universal_deploy.yml`中，已经添加了冲突检测逻辑，确保：

1. **避免重复location配置**: 检测到冲突时跳过配置
2. **正确的路径映射**: 确保静态文件路径正确
3. **配置验证**: 部署前验证Nginx配置语法

### 最佳实践

1. **主项目配置**: axi-star-cloud配置`location /`作为默认路由
2. **子项目配置**: axi-docs只配置`location /docs/`避免冲突
3. **静态文件**: 使用明确的路径映射，避免重定向
4. **缓存策略**: 静态资源缓存，动态内容不缓存
