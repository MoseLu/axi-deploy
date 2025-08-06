# 静态文件404问题修复指南

## 🚨 问题描述

Nginx配置修复成功后，主页面可以正常访问，但静态文件返回404错误：

```
🔗 测试静态文件...
  静态文件状态码: 404, 重定向次数: 0
```

## 🔍 问题分析

### 可能的原因

1. **文件路径不正确**: 静态文件不在预期的目录中
2. **部署路径错误**: 前端文件部署到了错误的路径
3. **Nginx配置路径不匹配**: Nginx配置中的路径与实际文件路径不匹配
4. **文件权限问题**: 文件存在但权限不正确
5. **Nginx配置缺失**: 没有配置静态文件服务的location块

### 诊断步骤

1. **检查部署目录**:
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/
   ```

2. **检查静态文件**:
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/static/html/
   ```

3. **检查Nginx配置**:
   ```bash
   cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf
   ```

4. **检查路由配置**:
   ```bash
   ls -la /www/server/nginx/conf/conf.d/redamancy/route-*.conf
   ```

## 🛠️ 解决方案

### 方案1：Nginx配置检查脚本（推荐）

在服务器上运行Nginx配置检查脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/check-nginx-config.sh
chmod +x check-nginx-config.sh
sudo ./check-nginx-config.sh
```

### 方案2：添加静态文件配置脚本

如果发现缺少静态文件配置，运行添加配置脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/add-static-config.sh
chmod +x add-static-config.sh
sudo ./add-static-config.sh
```

### 方案3：静态文件路径检查脚本

如果静态文件路径有问题，运行静态文件路径检查脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/fix-static-files.sh
chmod +x fix-static-files.sh
sudo ./fix-static-files.sh
```

### 方案4：文件结构修复脚本

如果文件结构有问题，运行文件结构修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/fix-file-structure.sh
chmod +x fix-file-structure.sh
sudo ./fix-file-structure.sh
```

### 方案5：手动修复

如果无法下载脚本，手动执行：

```bash
# 1. 检查当前部署状态
ls -la /srv/apps/axi-star-cloud/front/

# 2. 检查Nginx配置
cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf

# 3. 检查路由配置
ls -la /www/server/nginx/conf/conf.d/redamancy/route-*.conf

# 4. 如果缺少静态文件配置，创建配置
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-static.conf <<'EOF'
# 静态文件服务
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# 主页面服务
location / {
    try_files $uri $uri/ /index.html;
    root /srv/apps/axi-star-cloud/front;
    index index.html;
}

# API代理
location /api/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
EOF

# 5. 检查Nginx语法
sudo nginx -t

# 6. 重载Nginx
sudo systemctl reload nginx

# 7. 测试静态文件访问
curl -I https://redamancy.com.cn/static/html/main-content.html
```

## 🔧 配置说明

### 正确的文件结构

前端文件应该部署在以下结构中：

```
/srv/apps/axi-star-cloud/front/
├── index.html
├── static/
│   ├── html/
│   │   ├── main-content.html
│   │   ├── header.html
│   │   └── login.html
│   ├── css/
│   ├── js/
│   └── public/
└── ...
```

### Nginx配置路径映射

Nginx配置中的静态文件路径映射：

```nginx
# 静态文件服务
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
}
```

这意味着：
- 访问 `/static/html/main-content.html` 
- 实际文件路径 `/srv/apps/axi-star-cloud/front/html/main-content.html`

### 完整的Nginx配置示例

```nginx
# 静态文件服务
location /static/ {
    alias /srv/apps/axi-star-cloud/front/;
    expires 1y;
    add_header Cache-Control "public, immutable";
    
    # 允许跨域访问
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
    
    # 处理OPTIONS请求
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
        add_header Access-Control-Max-Age 1728000;
        add_header Content-Type "text/plain; charset=utf-8";
        add_header Content-Length 0;
        return 204;
    }
}

# 主页面服务
location / {
    try_files $uri $uri/ /index.html;
    root /srv/apps/axi-star-cloud/front;
    index index.html;
}

# API代理
location /api/ {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## 📋 验证修复

### 1. 检查文件存在
```bash
ls -la /srv/apps/axi-star-cloud/front/static/html/main-content.html
```

### 2. 测试静态文件访问
```bash
curl -I https://redamancy.com.cn/static/html/main-content.html
```

### 3. 检查浏览器访问
- 打开 https://redamancy.com.cn/
- 检查开发者工具的网络面板
- 确认静态文件返回200状态码

## 🚀 重新部署

如果静态文件路径有问题，可以重新部署前端：

1. **推送代码到GitHub** - 触发自动部署
2. **运行重新部署脚本** - 确保文件部署到正确位置
3. **验证部署结果** - 检查静态文件是否可以正常访问

## 📞 故障排除

如果问题仍然存在：

1. **运行诊断脚本**：
   ```bash
   wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/check-nginx-config.sh
   chmod +x check-nginx-config.sh
   sudo ./check-nginx-config.sh
   ```

2. **检查文件权限**：
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/static/html/
   sudo chown -R deploy:deploy /srv/apps/axi-star-cloud/front
   ```

3. **检查Nginx配置**：
   ```bash
   sudo nginx -t
   cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf
   ```

4. **检查Nginx日志**：
   ```bash
   sudo tail -f /var/log/nginx/error.log
   sudo tail -f /var/log/nginx/access.log
   ```

5. **手动测试文件访问**：
   ```bash
   curl -v https://redamancy.com.cn/static/html/main-content.html
   ```

## 🔄 长期维护

### 部署策略更新

在`axi-deploy/.github/workflows/universal_deploy.yml`中，确保：

1. **正确的部署路径**: 前端文件部署到 `/srv/apps/axi-star-cloud/front/`
2. **正确的文件权限**: 设置正确的文件所有者
3. **正确的Nginx配置**: 确保路径映射正确
4. **完整的Nginx配置**: 包含静态文件、主页面和API代理配置

### 最佳实践

1. **统一的部署路径**: 所有前端文件都部署到同一个路径
2. **正确的文件权限**: 确保Nginx可以访问文件
3. **正确的Nginx配置**: 确保路径映射与实际文件路径匹配
4. **完整的location配置**: 包含静态文件、主页面和API代理
5. **定期测试**: 定期运行测试脚本验证静态文件访问
