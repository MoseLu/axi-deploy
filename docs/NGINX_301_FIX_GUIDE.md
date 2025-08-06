# Nginx 301重定向问题修复指南

## 问题描述

访问 `https://redamancy.com.cn/` 时返回 HTTP 301 重定向，而不是直接返回 200 状态码。

## 问题原因分析

### 1. 主配置文件重定向规则问题

在 `00-main.conf` 中，HTTP server块有这样的重定向规则：

```nginx
location ~ ^/(?!docs|api|health|uploads) {
    return 301 https://$host$request_uri;
}
```

这个规则会将所有不匹配 `docs|api|health|uploads` 的路径重定向到HTTPS，但是axi-star-cloud项目需要处理根路径 `/`，而这个路径被重定向规则捕获了。

### 2. 项目路由配置问题

axi-star-cloud的nginx配置中，根路径的配置不够精确：

```nginx
location / { 
    root /srv/apps/axi-star-cloud/front; 
    try_files $uri $uri/ /index.html; 
    ...
}
```

这个配置没有正确处理根路径，导致与重定向规则冲突。

## 修复方案

### 1. 修复主配置文件重定向规则

**文件**: `axi-deploy/.github/workflows/universal_deploy.yml`

**修改前**:
```nginx
location ~ ^/(?!docs|api|health|uploads) {
    return 301 https://$host$request_uri;
}
```

**修改后**:
```nginx
location ~ ^/(?!docs|api|health|uploads|$) {
    return 301 https://$host$request_uri;
}
```

**说明**: 添加 `|$` 到排除列表中，确保根路径 `/` 不被重定向规则捕获。

### 2. 修复axi-star-cloud项目配置

**文件**: `axi-star-cloud/.github/workflows/axi-star-cloud_deploy.yml`

**修改前**:
```nginx
location / { 
    root /srv/apps/axi-star-cloud/front; 
    try_files $uri $uri/ /index.html; 
    ...
}
```

**修改后**:
```nginx
location = / { 
    root /srv/apps/axi-star-cloud/front; 
    try_files /index.html =404; 
} 
location / { 
    root /srv/apps/axi-star-cloud/front; 
    try_files $uri $uri/ /index.html; 
    ...
}
```

**说明**: 
- 添加精确匹配的 `location = /` 来处理根路径
- 使用 `try_files /index.html =404` 确保根路径直接返回index.html
- 保留原有的 `location /` 来处理其他路径

## 验证步骤

### 1. 检查配置文件

```bash
# 检查主配置文件
cat /www/server/nginx/conf/conf.d/redamancy/00-main.conf

# 检查项目路由配置
cat /www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf
```

### 2. 测试nginx配置语法

```bash
nginx -t
```

### 3. 重载nginx配置

```bash
systemctl reload nginx
```

### 4. 测试网站访问

```bash
# 测试HTTP访问
curl -I http://redamancy.com.cn/

# 测试HTTPS访问
curl -I https://redamancy.com.cn/

# 测试docs路径
curl -I https://redamancy.com.cn/docs/
```

### 5. 检查重定向

```bash
# 检查是否有重定向
curl -s -I https://redamancy.com.cn/ | grep -i "location\|301\|302"
```

## 预期结果

修复后应该看到：

1. **HTTPS根路径**: 返回 200 状态码，直接显示网站内容
2. **HTTP访问**: 返回 301 重定向到HTTPS
3. **docs路径**: 返回 200 状态码，显示文档内容
4. **API路径**: 正常代理到后端服务

## 故障排除

### 如果问题仍然存在

1. **检查nginx错误日志**:
   ```bash
   tail -f /var/log/nginx/error.log
   ```

2. **检查nginx访问日志**:
   ```bash
   tail -f /var/log/nginx/access.log
   ```

3. **检查服务状态**:
   ```bash
   systemctl status nginx
   curl -f http://127.0.0.1:8080/health
   ```

4. **检查文件权限**:
   ```bash
   ls -la /srv/apps/axi-star-cloud/front/
   ls -la /srv/static/axi-docs/
   ```

### 常见问题

1. **配置未生效**: 确保nginx配置已重载
2. **文件路径错误**: 检查部署路径是否正确
3. **权限问题**: 确保nginx用户有读取权限
4. **其他配置冲突**: 检查是否有其他配置文件干扰

## 测试脚本

使用提供的测试脚本进行自动化验证：

```bash
bash /path/to/test-nginx-fix.sh
```

## 部署流程

1. 推送修复后的代码到GitHub
2. 触发axi-star-cloud项目的部署
3. 等待部署完成
4. 运行测试脚本验证修复效果
5. 如果成功，触发axi-docs项目的部署

## 联系信息

如果修复后问题仍然存在，请：

1. 收集所有测试脚本的输出
2. 检查nginx错误日志的详细信息
3. 确认所有配置文件的内容
4. 考虑是否有其他服务（如CDN、负载均衡器）在起作用
