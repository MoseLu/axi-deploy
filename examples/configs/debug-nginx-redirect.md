# Nginx 重定向问题调试指南

## 问题描述

访问 `https://redamancy.com.cn/docs/` 时仍然返回 HTTP 301 重定向，而不是直接返回 200 状态码。

## 常见错误

### 1. "location" directive is not allowed here

**错误信息**: `nginx: [emerg] "location" directive is not allowed here`

**原因**: location 指令出现在错误的位置，通常是因为：
- 配置文件结构不正确
- location 块没有正确包装在 server 块中
- 嵌套的 location 块格式错误

**解决方案**:

```bash
# 1. 检查生成的配置文件
sudo cat /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf

# 2. 检查配置文件语法
sudo nginx -t

# 3. 查看错误日志
sudo tail -f /var/log/nginx/error.log
```

**正确的配置格式**:

```nginx
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    location /docs/ {
        alias /www/wwwroot/redamancy.com.cn/docs/;
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
}
```

## 调试步骤

### 1. 检查所有Nginx配置文件

```bash
# 查找所有包含 "docs" 的配置文件
find /www/server/nginx/conf -name "*.conf" -exec grep -l "docs" {} \;

# 查找所有包含重定向的配置
grep -r "301\|302\|redirect" /www/server/nginx/conf/
```

### 2. 检查主配置文件

```bash
# 查看主域名配置文件
cat /www/server/nginx/conf/vhost/redamancy.com.cn.conf

# 检查是否有include文件
grep -r "include" /www/server/nginx/conf/vhost/
```

### 3. 检查Nginx错误日志

```bash
# 查看错误日志
tail -f /var/log/nginx/error.log

# 查看访问日志
tail -f /var/log/nginx/access.log
```

### 4. 测试Nginx配置

```bash
# 测试配置语法
nginx -t

# 重新加载配置
nginx -s reload
```

### 5. 检查文件权限和路径

```bash
# 检查部署路径是否存在
ls -la /www/wwwroot/redamancy.com.cn/docs/

# 检查文件权限
ls -la /www/wwwroot/redamancy.com.cn/docs/index.html

# 检查Nginx用户权限
ps aux | grep nginx
```

## 可能的原因

### 1. 其他配置文件冲突

可能有其他Nginx配置文件也在处理 `/docs/` 路径：

```bash
# 查找所有处理 /docs/ 的配置
grep -r "location.*docs" /www/server/nginx/conf/
```

### 2. 主配置文件中的重定向规则

主配置文件中可能有全局重定向规则：

```bash
# 检查主配置文件中的重定向
grep -A5 -B5 "301\|302" /www/server/nginx/conf/vhost/redamancy.com.cn.conf
```

### 3. CDN或代理重定向

如果使用了CDN或代理，可能在CDN层面有重定向规则。

### 4. 浏览器缓存

浏览器可能缓存了旧的重定向响应。

## 解决方案

### 方案1：完全替换配置

备份现有配置，然后使用新的配置：

```bash
# 备份现有配置
cp /www/server/nginx/conf/vhost/redamancy.com.cn.conf /www/server/nginx/conf/vhost/redamancy.com.cn.conf.backup

# 使用新的配置
```

### 方案2：检查并删除冲突配置

```bash
# 查找并删除所有与 /docs/ 相关的配置
grep -r "location.*docs" /www/server/nginx/conf/ -l | xargs -I {} echo "检查文件: {}"
```

### 方案3：使用不同的路径

如果 `/docs/` 路径有冲突，可以尝试使用其他路径：

```nginx
# 使用 /documentation/ 路径
location /documentation/ {
    alias /www/wwwroot/redamancy.com.cn/docs/;
    index index.html;
    try_files $uri $uri/ /documentation/index.html;
}
```

## 测试命令

### 使用curl测试

```bash
# 测试重定向
curl -I https://redamancy.com.cn/docs/

# 测试不跟随重定向
curl -I -L https://redamancy.com.cn/docs/

# 测试详细输出
curl -v https://redamancy.com.cn/docs/
```

### 使用wget测试

```bash
# 测试重定向
wget --spider -S https://redamancy.com.cn/docs/

# 测试不跟随重定向
wget --spider --max-redirect=0 -S https://redamancy.com.cn/docs/
```

## 紧急修复

如果问题持续存在，可以尝试以下紧急修复：

### 1. 临时禁用重定向

```nginx
# 在配置中添加
location /docs/ {
    alias /www/wwwroot/redamancy.com.cn/docs/;
    index index.html;
    try_files $uri $uri/ /docs/index.html;
    
    # 强制返回200
    add_header X-Status "200 OK";
    return 200;
}
```

### 2. 使用不同的端口

```nginx
# 在单独的端口上提供服务
server {
    listen 8080;
    server_name redamancy.com.cn;
    
    location /docs/ {
        alias /www/wwwroot/redamancy.com.cn/docs/;
        index index.html;
        try_files $uri $uri/ /docs/index.html;
    }
}
```

## 联系信息

如果以上步骤都无法解决问题，请：

1. 收集所有调试命令的输出
2. 检查服务器上的实际Nginx配置
3. 查看Nginx错误日志的详细信息
4. 考虑是否有其他服务（如CDN、负载均衡器）在起作用 