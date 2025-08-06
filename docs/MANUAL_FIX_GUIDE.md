# 手动修复指南

## 问题分析

从测试结果可以看出，虽然重定向循环问题已经解决，但是静态文件访问仍然有问题：

1. **HTTP到HTTPS重定向正常** - 状态码301，重定向次数0
2. **但是静态文件访问异常** - 状态码301000，这表明配置没有正确更新

## 根本原因

主配置文件中的HTTP server块仍然使用的是旧的重定向规则：

```nginx
# 其他路径重定向到 HTTPS（排除已处理的路由）
location ~ ^/(?!docs|api|health|uploads|static|$) {
    return 301 https://$host$request_uri;
}
```

这说明我们的修复还没有被应用到服务器上。

## 立即修复方案

### 方案1：使用强制更新脚本（推荐）

在服务器上运行以下命令：

```bash
# 下载并运行强制更新脚本
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/force-update-config.sh
chmod +x force-update-config.sh
sudo ./force-update-config.sh
```

### 方案2：手动更新配置

如果无法下载脚本，可以手动执行：

```bash
# 1. 备份当前配置
sudo cp /www/server/nginx/conf/conf.d/redamancy/00-main.conf \
        /www/server/nginx/conf/conf.d/redamancy/00-main.conf.backup.$(date +%Y%m%d_%H%M%S)

# 2. 更新主配置文件
sudo tee /www/server/nginx/conf/conf.d/redamancy/00-main.conf <<'EOF'
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    # 这里自动加载 route-*.conf（项目路由）——主配置永远不用再改
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    
    # 自动加载所有项目路由配置（HTTP版本）
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
    
    # 对于未匹配的路由，重定向到HTTPS
    # 注意：这里不处理已经在route-*.conf中定义的路由
    location / {
        return 301 https://$host$request_uri;
    }
}
EOF

# 3. 验证配置语法
sudo nginx -t

# 4. 重新加载Nginx
sudo systemctl reload nginx
```

### 方案3：触发自动部署

通过GitHub Actions触发自动部署：

```bash
# 在axi-star-cloud仓库中触发部署
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/MoseLu/axi-star-cloud/dispatches \
  -d '{"event_type":"deploy","client_payload":{"force_rebuild":"true"}}'
```

## 验证修复效果

修复后，运行以下命令验证：

```bash
# 1. 检查配置是否已更新
cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf

# 2. 测试静态文件访问
curl -I https://redamancy.com.cn/static/html/main-content.html

# 3. 运行完整测试
cd /srv
./test-redirect-fix.sh
```

## 预期结果

修复成功后，您应该看到：

1. **主配置文件已更新** - 不再包含复杂的正则表达式重定向
2. **静态文件访问正常** - 状态码200或404（文件不存在但重定向正常）
3. **组件加载成功** - 前端JavaScript可以正常加载模板

## 故障排除

### 如果修复后仍有问题

1. **检查文件权限**：
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/html/
   ```

2. **检查Nginx错误日志**：
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

3. **检查服务状态**：
   ```bash
   sudo systemctl status nginx
   sudo systemctl status star-cloud
   ```

### 如果配置更新失败

1. **检查备份**：
   ```bash
   ls -la /www/server/nginx/conf/conf.d/redamancy/backups/main/
   ```

2. **手动恢复**：
   ```bash
   sudo cp /www/server/nginx/conf/conf.d/redamancy/backups/main/00-main.conf.backup.* \
           /www/server/nginx/conf/conf.d/redamancy/00-main.conf
   sudo systemctl reload nginx
   ```

## 预防措施

为了避免将来出现类似问题：

1. **定期检查配置**：
   ```bash
   # 每月检查一次配置
   grep -n "location ~" /www/server/nginx/conf/conf.d/redamancy/00-main.conf
   ```

2. **监控静态文件访问**：
   ```bash
   # 设置监控脚本
   curl -s -w "%{http_code}" -o /dev/null https://redamancy.com.cn/static/html/main-content.html
   ```

3. **自动化测试**：
   ```bash
   # 定期运行测试脚本
   bash /srv/test-redirect-fix.sh
   ```

## 总结

通过手动应用这个修复，您应该能够解决静态文件访问问题。修复的核心是简化HTTP重定向逻辑，确保Nginx能够正确处理所有路径，避免重定向循环。
