# 301重定向问题修复指南

## 🚨 问题描述

axi-star-cloud部署时出现301重定向问题：

```
out: HTTP测试结果: 301
out: HTTPS测试结果: 301
out: 重定向目标: https://redamancy.com.cn/
out: ❌ HTTPS网站无法访问 (HTTP 301) - 部署失败
```

## 🔍 问题分析

### 根本原因

1. **nginx配置冲突**: 多个项目都配置了`location /`，导致重复定义
2. **重定向规则问题**: HTTP到HTTPS的重定向规则与静态文件访问冲突
3. **include文件覆盖**: route-*.conf中的配置可能被覆盖或冲突

### 具体问题

从错误日志可以看出：
- HTTP和HTTPS都返回301重定向
- 重定向目标都是 `https://redamancy.com.cn/`
- 这表明所有请求都被重定向，而不是正常处理

## 🛠️ 修复方案

### 方案1：使用修复脚本（推荐）

在服务器上运行修复脚本：

```bash
cd /srv
wget https://raw.githubusercontent.com/MoseLu/axi-deploy/master/examples/configs/fix-301-keep-architecture.sh
chmod +x fix-301-keep-architecture.sh
sudo ./fix-301-keep-architecture.sh
```

### 方案2：手动修复

如果无法下载脚本，手动执行：

```bash
# 1. 备份当前配置
sudo cp -r /www/server/nginx/conf/conf.d/redamancy /tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)

# 2. 检查location冲突
echo "🔍 检查location冲突..."
LOCATION_COUNT=$(grep -r "location /" /www/server/nginx/conf/conf.d/redamancy/route-*.conf 2>/dev/null | wc -l)
if [ "$LOCATION_COUNT" -gt 1 ]; then
    echo "⚠️ 检测到多个 location / 定义，清理冲突..."
    sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf
fi

# 3. 重新生成主配置文件（保持include机制）
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

# 4. 测试配置
sudo nginx -t

# 5. 重载nginx
sudo systemctl reload nginx

# 6. 测试访问
curl -I https://redamancy.com.cn/
```

## 🔧 配置说明

### 修复的关键点

1. **保持动态引入架构**: 继续使用include机制，不写死主配置文件
2. **智能冲突检测**: 在部署时检测location冲突，避免重复定义
3. **改进的location规则**: 使用更精确的location匹配规则
4. **保持架构设计**: 确保00-main.conf永远不用再改

### 新的配置结构

```nginx
# 主配置文件 00-main.conf - 永远不用再改
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    
    # 这里自动加载 route-*.conf（项目路由）
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    return 301 https://$host$request_uri;
}

# route-axi-star-cloud.conf - 项目特定配置
location /static/ { ... }
location /api/ { ... }
location /health { ... }
location /uploads/ { ... }
location = / { ... }
location ~ ^/(?!docs|static|api|health|uploads) { ... }

# route-axi-docs.conf - 文档项目配置
location /docs/ { ... }
```

### 改进的location规则

为了避免冲突，axi-star-cloud项目现在使用更精确的location规则：

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

# 测试文档站点
curl -I https://redamancy.com.cn/docs/
```

### 3. 检查后端服务
```bash
sudo systemctl status star-cloud.service
```

## 🚀 重新部署

修复完成后，可以重新部署项目：

1. **推送代码到GitHub** - 触发自动部署
2. **系统会自动处理配置冲突** - 新的部署逻辑会避免重复location
3. **验证部署结果** - 检查网站是否正常访问

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
   ls -la /srv/static/axi-docs/
   ```

4. **检查nginx进程**:
   ```bash
   sudo systemctl status nginx
   ```

## 📝 注意事项

1. **保持架构设计**: 修复时不要破坏动态引入的架构
2. **备份配置**: 修复前一定要备份当前配置
3. **测试配置**: 修改后一定要测试nginx配置语法
4. **监控日志**: 修复后监控错误日志确保无异常

## 🎯 预期结果

修复成功后应该看到：

1. **nginx配置语法正确** - `nginx: configuration file /www/server/nginx/conf/nginx.conf test is successful`
2. **主页面访问正常** - 状态码200
3. **静态文件访问正常** - 状态码200或404
4. **无重定向循环** - 重定向次数≤1
5. **后端服务正常运行** - 状态码active
6. **保持动态引入架构** - 00-main.conf继续使用include机制
