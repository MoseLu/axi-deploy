# 静态文件重定向循环修复指南

## 🚨 问题描述

静态文件访问出现重定向循环：

```
GET https://redamancy.com.cn/static/html/main-content.html net::ERR_TOO_MANY_REDIRECTS
```

## 🔍 问题分析

### 根本原因

问题在于nginx和Go后端都在处理`/static/`路径：

1. **nginx配置**: `location /static/` 直接服务静态文件
2. **Go后端**: 也注册了`/static/`路由处理静态文件
3. **冲突**: 两个服务都在处理同一个路径，导致重定向循环

### 具体问题

1. **路径冲突**: nginx和Go后端都在处理`/static/`路径
2. **代理配置不完整**: nginx只代理`/api/`到Go后端，但Go后端也处理`/static/`
3. **重定向循环**: 请求在nginx和Go后端之间循环

## 🛠️ 修复方案

### 方案1：修改nginx配置（推荐）

确保nginx正确处理静态文件，不代理到Go后端：

```bash
# 1. 备份当前配置
sudo cp -r /www/server/nginx/conf/conf.d/redamancy /tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)

# 2. 检查当前route配置
ls -la /www/server/nginx/conf/conf.d/redamancy/route-*.conf

# 3. 确保静态文件配置正确
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-static.conf <<'EOF'
# 静态文件服务 - 优先级高于API代理
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
    expires 1y;
    add_header Cache-Control "public, immutable";
    
    # 确保不代理到后端
    try_files $uri =404;
}

# API代理 - 只处理API请求
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

# 默认路由
location = / {
    root /srv/apps/axi-star-cloud/front;
    try_files /index.html =404;
}

location / {
    root /srv/apps/axi-star-cloud/front;
    try_files $uri $uri/ /index.html;
}
EOF

# 4. 测试配置
sudo nginx -t

# 5. 重载nginx
sudo systemctl reload nginx

# 6. 测试静态文件访问
curl -I https://redamancy.com.cn/static/html/main-content.html
```

### 方案2：修改Go后端配置

如果方案1不行，可以修改Go后端，让它不处理`/static/`路径：

```bash
# 1. 备份Go后端配置
sudo cp /srv/apps/axi-star-cloud/star-cloud-linux /srv/apps/axi-star-cloud/star-cloud-linux.backup

# 2. 修改Go后端，注释掉静态文件路由
# 在 routes.go 中注释掉 registerStaticRoutes() 调用
```

### 方案3：检查文件路径

确保静态文件在正确的位置：

```bash
# 1. 检查文件是否存在
ls -la /srv/apps/axi-star-cloud/front/html/main-content.html

# 2. 如果文件不存在，检查其他可能的位置
find /srv/apps/axi-star-cloud/front -name "main-content.html"

# 3. 如果文件在错误位置，移动到正确位置
sudo mkdir -p /srv/apps/axi-star-cloud/front/html
sudo mv /srv/apps/axi-star-cloud/front/main-content.html /srv/apps/axi-star-cloud/front/html/
```

## 🔧 配置说明

### 正确的nginx配置结构

```nginx
# 静态文件服务 - 优先级最高
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
    expires 1y;
    add_header Cache-Control "public, immutable";
    try_files $uri =404;  # 确保不代理到后端
}

# API代理 - 只处理API请求
location /api/ {
    proxy_pass http://127.0.0.1:8080/;
    # ... 代理配置
}

# 其他路径
location / {
    root /srv/apps/axi-star-cloud/front;
    try_files $uri $uri/ /index.html;
}
```

### 关键修复点

1. **明确路径优先级**: 静态文件路径优先级高于API代理
2. **避免路径冲突**: 确保nginx和Go后端不处理相同路径
3. **正确的文件路径**: 确保静态文件在nginx期望的位置

## 📋 验证修复

### 1. 测试静态文件访问
```bash
curl -I https://redamancy.com.cn/static/html/main-content.html
```

### 2. 测试API访问
```bash
curl -I https://redamancy.com.cn/api/health
```

### 3. 测试主页面
```bash
curl -I https://redamancy.com.cn/
```

### 4. 浏览器测试
- 打开 https://redamancy.com.cn/
- 检查开发者工具的网络面板
- 确认静态文件返回200状态码

## 📞 故障排除

如果问题仍然存在：

1. **检查nginx错误日志**:
   ```bash
   sudo tail -f /www/server/nginx/logs/error.log
   ```

2. **检查Go后端日志**:
   ```bash
   sudo journalctl -u star-cloud.service -f
   ```

3. **检查文件权限**:
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/html/main-content.html
   ```

4. **检查nginx配置**:
   ```bash
   sudo nginx -t
   cat /www/server/nginx/conf/conf.d/redamancy/route-static.conf
   ```

## 📝 注意事项

1. **路径优先级**: 确保静态文件路径在API代理之前
2. **文件位置**: 确保静态文件在nginx期望的位置
3. **权限设置**: 确保nginx有权限访问静态文件
4. **配置测试**: 修改后一定要测试nginx配置语法

## 🎯 总结

**问题根源**: nginx和Go后端都在处理`/static/`路径，导致冲突

**修复方案**: 确保nginx正确处理静态文件，不代理到Go后端

**预期效果**: 
- ✅ 静态文件正常访问
- ✅ 消除重定向循环
- ✅ API正常访问
- ✅ 网站正常显示

**修复状态**: ✅ 已提供修复方案
