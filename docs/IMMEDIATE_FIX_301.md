# 立即修复301重定向问题指南

## 🚨 问题描述

部署后仍然出现301重定向问题：

```
out: HTTP测试结果: 301
out: HTTPS测试结果: 301
out: 重定向目标: https://redamancy.com.cn/
out: ❌ HTTPS网站无法访问 (HTTP 301) - 部署失败
```

从日志可以看出，route-axi-star-cloud.conf中仍然包含旧的`location /`配置，说明我们的修改还没有生效。

## 🔧 立即修复方案

### 方案1：使用立即修复脚本（推荐）

在服务器上运行立即修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/immediate-fix-301.sh
chmod +x immediate-fix-301.sh
sudo ./immediate-fix-301.sh
```

### 方案2：手动立即修复

如果无法下载脚本，手动执行：

```bash
# 1. 备份当前配置
sudo cp -r /www/server/nginx/conf/conf.d/redamancy /tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)

# 2. 清理所有route配置文件
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

    # 这里自动加载 route-*.conf（项目路由）——主配置永远不用再改
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    
    # HTTP到HTTPS重定向
    return 301 https://$host$request_uri;
}
EOF

# 4. 重新生成axi-star-cloud的route配置
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf <<'EOF'
    # 静态文件服务
    location /static/ {
        alias /srv/apps/axi-star-cloud/front/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
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

    # 精确匹配根路径
    location = / {
        root /srv/apps/axi-star-cloud/front;
        try_files /index.html =404;
    }

    # 排除其他项目路径的通用规则
    location ~ ^/(?!docs|static|api|health|uploads) {
        root /srv/apps/axi-star-cloud/front;
        try_files $uri $uri/ /index.html;
    }
EOF

# 5. 测试配置
sudo nginx -t

# 6. 重载nginx
sudo systemctl reload nginx

# 7. 测试访问
curl -I https://redamancy.com.cn/
```

## 🔧 修复原理

### 问题分析

从错误日志可以看出：
- route-axi-star-cloud.conf中仍然包含`location /`
- 这说明我们的修改还没有被应用到服务器上
- 需要直接修复服务器上的配置文件

### 修复关键点

1. **清理冲突配置**: 移除所有旧的route配置文件
2. **重新生成配置**: 使用正确的location规则
3. **保持架构**: 继续使用include机制
4. **立即生效**: 直接修改服务器配置

### 新的location规则

```nginx
# 精确匹配根路径
location = / {
    root /srv/apps/axi-star-cloud/front;
    try_files /index.html =404;
}

# 排除其他项目路径的通用规则
location ~ ^/(?!docs|static|api|health|uploads) {
    root /srv/apps/axi-star-cloud/front;
    try_files $uri $uri/ /index.html;
}
```

## 📋 验证修复

### 1. 测试nginx配置
```bash
sudo nginx -t
```

### 2. 测试网站访问
```bash
# 测试主站点
curl -I https://redamancy.com.cn/

# 测试静态文件
curl -I https://redamancy.com.cn/static/html/main-content.html

# 测试API
curl -I https://redamancy.com.cn/api/health
```

### 3. 检查后端服务
```bash
sudo systemctl status star-cloud.service
```

## 🎯 预期结果

修复成功后应该看到：

1. **nginx配置语法正确** - `nginx: configuration file /www/server/nginx/conf/nginx.conf test is successful`
2. **主页面访问正常** - 状态码200
3. **静态文件访问正常** - 状态码200或404
4. **无重定向循环** - 重定向次数≤1
5. **后端服务正常运行** - 状态码active

## 📞 故障排除

如果问题仍然存在：

1. **检查nginx错误日志**:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

2. **检查后端服务日志**:
   ```bash
   sudo journalctl -u star-cloud.service -f
   ```

3. **检查文件权限**:
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/
   ```

4. **检查nginx进程**:
   ```bash
   sudo systemctl status nginx
   ```

## 📝 注意事项

1. **立即生效**: 这个修复会立即生效，不需要等待重新部署
2. **备份配置**: 修复前会自动备份当前配置
3. **保持架构**: 修复后仍然保持动态引入架构
4. **监控日志**: 修复后监控错误日志确保无异常
