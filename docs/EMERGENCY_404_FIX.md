# 紧急修复301重定向问题指南

## 🚨 问题描述

部署后网站返回301状态码而不是200，导致工作流失败：

```
out: HTTP测试结果: 301
out: HTTPS测试结果: 301
out: ❌ 网站测试失败 - HTTPS返回状态码: 301
out: 🚨 工作流错误：网站未返回200状态码，直接退出工作流
```

## 🔍 问题分析

从日志分析，问题在于：

1. **Nginx配置正确生成**：route-axi-docs.conf文件已正确创建
2. **文件部署成功**：index.html文件已存在
3. **配置语法正确**：Nginx配置语法检查通过
4. **问题**：HTTPS访问返回301重定向，而不是200状态码

## 🛠️ 立即修复方案

### 方案1：服务器端紧急修复（推荐）

在服务器上运行以下命令：

```bash
# 1. 备份当前配置
sudo cp -r /www/server/nginx/conf/conf.d/redamancy /tmp/nginx-backup-$(date +%Y%m%d_%H%M%S)

# 2. 检查当前所有配置文件
echo "🔍 检查所有nginx配置文件..."
find /www/server/nginx/conf -name "*.conf" -exec echo "文件: {}" \; -exec grep -l "redamancy" {} \;

# 3. 清理所有可能冲突的配置文件
echo "🧹 清理冲突的配置文件..."
sudo rm -f /www/server/nginx/conf/conf.d/redamancy/route-*.conf

# 4. 重新生成主配置文件
echo "📝 重新生成主配置文件..."
sudo tee /www/server/nginx/conf/conf.d/redamancy/00-main.conf <<'EOF'
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    http2 on;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    # 这里自动加载 route-*.conf（项目路由）
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    
    # HTTP到HTTPS重定向
    return 301 https://$host$request_uri;
}
EOF

# 5. 重新生成axi-docs的route配置
echo "📝 重新生成axi-docs配置..."
sudo tee /www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf <<'EOF'
    # 处理 /docs/ 路径 - 服务 axi-docs 项目
    location /docs/ {
        alias /srv/static/axi-docs/;
        
        # 直接返回 index.html
        location = /docs/ {
            alias /srv/static/axi-docs/index.html;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
        
        # 确保不缓存HTML文件
        location ~* \.html$ {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
        
        # 静态资源缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # 处理 /docs 路径（不带斜杠）- 重定向到 /docs/
    location = /docs {
        return 301 /docs/;
    }
EOF

# 6. 测试配置
echo "🔍 测试nginx配置..."
sudo nginx -t

# 7. 重载nginx
echo "🔄 重载nginx..."
sudo systemctl reload nginx

# 8. 测试访问
echo "🌐 测试访问..."
curl -I https://redamancy.com.cn/docs/
```

### 方案2：检查其他配置文件干扰

如果方案1不能解决问题，检查是否有其他配置文件干扰：

```bash
# 1. 检查所有包含redamancy的配置文件
echo "🔍 检查所有包含redamancy的配置文件..."
find /www/server/nginx/conf -name "*.conf" -exec grep -l "redamancy" {} \;

# 2. 检查宝塔面板的默认配置
echo "🔍 检查宝塔面板配置..."
if [ -f "/www/server/panel/vhost/nginx/redamancy.com.cn.conf" ]; then
    echo "发现宝塔面板配置文件:"
    cat "/www/server/panel/vhost/nginx/redamancy.com.cn.conf"
else
    echo "没有找到宝塔面板配置文件"
fi

# 3. 检查主nginx.conf文件
echo "🔍 检查主nginx.conf文件..."
grep -n "include.*redamancy" /www/server/nginx/conf/nginx.conf || echo "主配置文件中没有包含redamancy"

# 4. 检查所有include的文件
echo "🔍 检查所有include的文件..."
grep -r "include.*\.conf" /www/server/nginx/conf/ | grep -v "route-" || echo "没有找到其他include文件"
```

### 方案3：强制清理并重建

如果上述方案都不能解决问题，执行强制清理：

```bash
# 1. 停止nginx
sudo systemctl stop nginx

# 2. 备份所有配置
sudo cp -r /www/server/nginx/conf /tmp/nginx-conf-backup-$(date +%Y%m%d_%H%M%S)

# 3. 清理所有redamancy相关配置
sudo rm -rf /www/server/nginx/conf/conf.d/redamancy

# 4. 重新创建目录结构
sudo mkdir -p /www/server/nginx/conf/conf.d/redamancy/backups/main
sudo mkdir -p /www/server/nginx/conf/conf.d/redamancy/backups/axi-docs

# 5. 重新生成配置（使用方案1的配置）

# 6. 启动nginx
sudo systemctl start nginx

# 7. 测试访问
curl -I https://redamancy.com.cn/docs/
```

## 🔧 配置说明

### 修复的关键点

1. **清理冲突配置**：删除所有可能冲突的route-*.conf文件
2. **重新生成主配置**：确保主配置文件正确包含route文件
3. **精确的location规则**：使用精确的location匹配规则
4. **正确的文件路径**：确保alias路径指向正确的文件

### 新的配置结构

```nginx
# 主配置文件 00-main.conf
server {
    listen 443 ssl;
    server_name redamancy.com.cn;
    
    # 自动加载项目路由配置
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    return 301 https://$host$request_uri;
}

# route-axi-docs.conf - 文档项目配置
location /docs/ {
    alias /srv/static/axi-docs/;
    # ... 其他配置
}
```

## 🎯 验证修复

修复后，应该能够正常访问：

```bash
# 测试HTTPS访问
curl -I https://redamancy.com.cn/docs/

# 应该返回200状态码，而不是301
```

如果仍然返回301，请检查：

1. **DNS解析**：确保域名正确解析到服务器
2. **SSL证书**：确保SSL证书有效
3. **防火墙**：确保80和443端口开放
4. **其他配置文件**：检查是否有其他nginx配置文件干扰
