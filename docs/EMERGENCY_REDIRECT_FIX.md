# 紧急修复：重定向循环问题

## 🚨 问题描述

修复后仍然出现重定向循环问题：
```
该网页无法正常运作
redamancy.com.cn 将您重定向的次数过多。
```

## 🔍 问题分析

### 可能的原因

1. **其他配置文件干扰**: 可能存在其他Nginx配置文件包含redamancy配置
2. **缓存问题**: 浏览器或CDN缓存了错误的重定向
3. **配置冲突**: 多个配置文件之间存在冲突
4. **SSL证书问题**: SSL证书配置可能导致重定向循环

### 诊断步骤

1. **检查所有配置文件**:
   ```bash
   find /www/server/nginx/conf -name "*.conf" -exec grep -l "redamancy" {} \;
   ```

2. **检查浏览器缓存**:
   - 清除浏览器缓存
   - 使用无痕模式访问
   - 检查开发者工具的网络面板

3. **检查CDN缓存**:
   - 如果使用了CDN，清除CDN缓存
   - 检查CDN配置

## 🛠️ 紧急修复方案

### 方案1：紧急修复脚本（推荐）

在服务器上运行紧急修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/emergency-redirect-fix.sh
chmod +x emergency-redirect-fix.sh
sudo ./emergency-redirect-fix.sh
```

### 方案2：深度修复脚本

如果紧急修复不成功，运行深度修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/deep-fix.sh
chmod +x deep-fix.sh
sudo ./deep-fix.sh
```

### 方案3：手动修复

如果无法下载脚本，手动执行：

```bash
# 1. 停止Nginx
sudo systemctl stop nginx
sudo pkill -f nginx || true
sleep 3

# 2. 备份配置
sudo cp -r /www/server/nginx/conf/conf.d/redamancy /tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)

# 3. 清理所有配置文件
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/00-main.conf

# 4. 检查其他配置文件
find /www/server/nginx/conf -name "*.conf" -exec grep -l "redamancy" {} \;

# 5. 创建最简单的配置文件
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
    }

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host $host;
    }

    # 文档站点
    location /docs/ {
        alias /srv/static/axi-docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
    }

    # 上传文件
    location /uploads/ {
        alias /srv/apps/axi-star-cloud/uploads/;
    }

    # 默认路由
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

# 6. 测试配置
sudo nginx -t

# 7. 启动Nginx
sudo systemctl start nginx

# 8. 测试访问
curl -I https://redamancy.com.cn/
curl -I https://redamancy.com.cn/static/html/main-content.html
```

## 🔧 配置说明

### 最简单的配置

新的配置移除了所有复杂的重定向规则，只保留：

1. **HTTPS server块**: 处理所有HTTPS请求
2. **HTTP server块**: 简单重定向到HTTPS
3. **明确的location映射**: 每个路径都有明确的处理规则

### 关键改进

1. **移除了所有include指令**: 避免配置文件冲突
2. **移除了复杂的重定向规则**: 只保留简单的HTTP到HTTPS重定向
3. **移除了缓存配置**: 先确保基本功能正常
4. **使用最简单的配置**: 最小化配置，减少出错可能

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
- 清除浏览器缓存
- 使用无痕模式访问 https://redamancy.com.cn/
- 检查开发者工具的网络面板
- 确认没有重定向循环

## 🚀 重新部署

修复完成后，可以重新部署项目：

1. **推送代码到GitHub** - 触发自动部署
2. **系统会自动处理配置冲突** - 新的部署逻辑会避免重复location
3. **验证部署结果** - 检查网站是否正常访问

## 📞 故障排除

如果问题仍然存在：

1. **运行诊断脚本**：
   ```bash
   wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/simple-test.sh
   chmod +x simple-test.sh
   sudo ./simple-test.sh
   ```

2. **检查其他配置文件**：
   ```bash
   find /www/server/nginx/conf -name "*.conf" -exec grep -l "redamancy" {} \;
   ```

3. **检查SSL证书**：
   ```bash
   sudo nginx -t
   ls -la /www/server/nginx/ssl/redamancy/
   ```

4. **检查部署目录**：
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/
   ls -la /srv/static/axi-docs/
   ```

5. **检查Nginx日志**：
   ```bash
   sudo tail -f /var/log/nginx/error.log
   sudo tail -f /var/log/nginx/access.log
   ```

## 🔄 长期维护

### 部署策略更新

在`axi-deploy/.github/workflows/universal_deploy.yml`中，已经添加了冲突检测逻辑，确保：

1. **避免重复location配置**: 检测到冲突时跳过配置
2. **正确的路径映射**: 确保静态文件路径正确
3. **配置验证**: 部署前验证Nginx配置语法

### 最佳实践

1. **使用最简单的配置**: 避免复杂的重定向规则
2. **明确的路径映射**: 每个路径都有明确的处理规则
3. **避免配置文件冲突**: 不要使用include指令
4. **定期测试**: 定期运行测试脚本验证配置
