# 分离式Nginx配置方案

## 问题分析

当前问题：两个项目都在修改同一个Nginx配置文件，导致配置冲突和重定向问题。

### 当前配置冲突

1. **axi-star-cloud** (Go项目)
   - 部署路径: `/www/wwwroot/axi-star-cloud`
   - 配置文件: `/www/server/nginx/conf/vhost/redamancy.com.cn.conf`
   - 提供完整的server块配置

2. **axi-docs** (VitePress项目)
   - 部署路径: `/www/wwwroot/redamancy.com.cn/docs`
   - 配置文件: 同样使用 `redamancy.com.cn.conf`
   - 只提供location块配置

## 解决方案：分离式配置

### 方案1：使用Include方式（推荐）

#### 主配置文件：redamancy.com.cn.conf

```nginx
# 主域名配置 - 由宝塔面板管理
server {
    listen 80;
    listen 443 ssl http2;
    server_name redamancy.com.cn;
    
    # SSL配置（由宝塔面板管理）
    # ssl_certificate /path/to/cert.pem;
    # ssl_certificate_key /path/to/key.pem;
    
    # 默认静态文件服务（axi-star-cloud）
    location / {
        root /www/wwwroot/axi-star-cloud;
        try_files $uri $uri/ /index.html;
        
        # 设置缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API代理到Go后端
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
    
    # 包含其他项目配置
    include /www/server/nginx/conf/vhost/includes/*.conf;
}
```

#### axi-docs项目配置：includes/axi-docs.conf

```nginx
# axi-docs 项目配置 - 无重定向版本
location /docs/ {
    alias /www/wwwroot/redamancy.com.cn/docs/;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
    
    # 禁用任何重定向
    add_header X-Robots-Tag "noindex, nofollow";
    
    # 设置正确的Content-Type
    location ~* \.html$ {
        add_header Content-Type "text/html; charset=utf-8";
    }
}
```

### 方案2：使用不同配置文件

#### axi-star-cloud配置：redamancy.com.cn.conf

```nginx
# 主域名配置 - 只包含axi-star-cloud
server {
    listen 80;
    listen 443 ssl http2;
    server_name redamancy.com.cn;
    
    # SSL配置（由宝塔面板管理）
    
    # 静态文件服务（axi-star-cloud）
    location / {
        root /www/wwwroot/axi-star-cloud;
        try_files $uri $uri/ /index.html;
        
        # 设置缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API代理到Go后端
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
    
    # axi-docs项目配置
    location /docs/ {
        alias /www/wwwroot/redamancy.com.cn/docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
        
        # 禁用任何重定向
        add_header X-Robots-Tag "noindex, nofollow";
        
        # 设置正确的Content-Type
        location ~* \.html$ {
            add_header Content-Type "text/html; charset=utf-8";
        }
    }
}
```

## 部署策略

### 对于axi-star-cloud项目

1. **使用方案2** - 直接修改主配置文件
2. **配置路径**: `/www/server/nginx/conf/vhost/redamancy.com.cn.conf`
3. **包含axi-docs配置** - 在主配置中直接添加docs location

### 对于axi-docs项目

1. **不修改主配置文件**
2. **只部署静态文件** - 不涉及Nginx配置修改
3. **依赖axi-star-cloud的配置** - 确保主配置中包含docs location

## 实施步骤

### 1. 修改axi-star-cloud部署配置

在 `axi-star-cloud/.github/workflows/deploy.yml` 中：

```yaml
"nginx_config": "server { listen 80; listen 443 ssl http2; server_name redamancy.com.cn; location / { root /www/wwwroot/axi-star-cloud; try_files $uri $uri/ /index.html; location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ { expires 1y; add_header Cache-Control \"public, immutable\"; } } location /api/ { proxy_pass http://127.0.0.1:8080/; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $scheme; client_max_body_size 100M; } location /health { proxy_pass http://127.0.0.1:8080/health; proxy_set_header Host $host; } location /docs/ { alias /www/wwwroot/redamancy.com.cn/docs/; index index.html; try_files $uri $uri/ /docs/index.html; add_header X-Robots-Tag \"noindex, nofollow\"; location ~* \\.html$ { add_header Content-Type \"text/html; charset=utf-8\"; } } }"
```

### 2. 修改axi-docs部署配置

在 `axi-docs/.github/workflows/build.yml` 中：

```yaml
# 移除nginx_config参数，不修改Nginx配置
"client-payload": |
  {
    "project": "${{ github.event.repository.name }}",
    "deploy_path": "${{ env.DEPLOY_PATH }}",
    "run_id": "${{ github.run_id }}",
    "source_repo": "${{ github.repository }}",
    "nginx_config": "",
    "nginx_path": "",
    "test_url": "https://redamancy.com.cn/docs/"
  }
```

## 验证步骤

1. **部署axi-star-cloud** - 确保主配置包含docs location
2. **部署axi-docs** - 只部署静态文件，不修改Nginx配置
3. **测试访问** - 验证两个项目都能正常访问
4. **检查重定向** - 确保没有301重定向

## 优势

1. **避免配置冲突** - 只有一个项目修改主配置文件
2. **简化部署** - axi-docs只需要部署静态文件
3. **易于维护** - 配置集中在一个地方
4. **兼容宝塔** - 不影响宝塔面板的SSL配置 