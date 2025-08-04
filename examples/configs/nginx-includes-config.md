# Nginx Include 配置示例 - 多项目部署

## 概述

为了支持多项目部署，建议使用Nginx的include功能来管理不同项目的配置。这样可以：

1. **模块化管理** - 每个项目的配置独立管理
2. **易于维护** - 修改单个项目配置不影响其他项目
3. **避免冲突** - 不同项目的配置相互隔离
4. **统一部署** - 通过axi-deploy统一管理所有项目

## 目录结构

```
/www/server/nginx/conf/vhost/
├── redamancy.com.cn.conf          # 主域名配置文件
└── includes/                      # 项目配置目录
    ├── axi-docs.conf             # axi-docs项目配置
    ├── axi-star-cloud.conf       # axi-star-cloud项目配置
    └── other-project.conf        # 其他项目配置
```

## 主域名配置

### redamancy.com.cn.conf

```nginx
# 主域名配置
server {
    listen 80;
    listen 443 ssl http2;
    server_name redamancy.com.cn;
    
    # SSL配置（如果有证书）
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

## 项目配置示例

### axi-docs.conf

```nginx
# axi-docs 项目配置 - 彻底解决重定向问题
location /docs/ {
    alias /www/wwwroot/axi-docs/;
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

### axi-star-cloud.conf

```nginx
# axi-star-cloud 项目配置（主项目，已在主配置中处理）
# 如果需要特殊路径，可以在这里添加

# 例如：管理后台路径
location /admin/ {
    alias /www/wwwroot/axi-star-cloud/admin/;
    try_files $uri $uri/ /admin/index.html;
}
```

## 部署脚本

### 创建include目录

```bash
# 在服务器上执行
mkdir -p /www/server/nginx/conf/vhost/includes
chmod 755 /www/server/nginx/conf/vhost/includes
```

### 自动生成项目配置

在axi-deploy的部署工作流中，可以自动生成项目配置：

```bash
# 为每个项目生成配置文件
cat > /www/server/nginx/conf/vhost/includes/${project_name}.conf << 'EOF'
# ${project_name} 项目配置
location /${project_path}/ {
    alias /www/wwwroot/${project_name}/;
    try_files $uri $uri/ /${project_path}/index.html;
    
    # 设置缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
```

## 使用说明

### 1. 部署新项目

当部署新项目时，axi-deploy会自动：

1. 创建项目配置文件到 `includes/` 目录
2. 更新主域名配置（如果需要）
3. 重新加载Nginx配置

### 2. 修改现有项目

修改项目配置时，只需要更新对应的include文件：

```bash
# 编辑特定项目配置
vim /www/server/nginx/conf/vhost/includes/axi-docs.conf

# 重新加载Nginx
nginx -s reload
```

### 3. 删除项目

删除项目时，移除对应的include文件：

```bash
# 删除项目配置
rm /www/server/nginx/conf/vhost/includes/project-name.conf

# 重新加载Nginx
nginx -s reload
```

## 注意事项

1. **路径冲突** - 确保不同项目的路径不冲突
2. **权限设置** - 确保Nginx有读取include文件的权限
3. **配置验证** - 每次修改后都要验证Nginx配置语法
4. **备份配置** - 修改前备份现有配置
5. **测试访问** - 修改后测试所有项目的访问

## 故障排除

### 常见问题

1. **403错误**
   - 检查文件权限
   - 检查路径配置
   - 检查Nginx配置语法

2. **404错误**
   - 检查文件路径
   - 检查alias/root配置
   - 检查try_files配置

3. **配置不生效**
   - 检查include路径
   - 重新加载Nginx
   - 检查配置语法

### 调试命令

```bash
# 检查Nginx配置语法
nginx -t

# 重新加载配置
nginx -s reload

# 查看Nginx错误日志
tail -f /var/log/nginx/error.log

# 查看Nginx访问日志
tail -f /var/log/nginx/access.log
``` 