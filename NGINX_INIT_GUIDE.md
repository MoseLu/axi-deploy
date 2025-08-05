# Nginx 服务器初始化指南

## 概述

本指南介绍如何使用 axi-deploy 的 Nginx 初始化工作流来标准化服务器环境，确保所有项目部署的一致性和可靠性。

## 初始化流程

### 1. 前置要求

- ✅ 服务器已安装 Nginx
- ✅ 宝塔面板已配置 SSL 证书
- ✅ 域名已解析到服务器
- ✅ GitHub Actions 已配置服务器密钥

### 2. 标准化目录结构

初始化后，服务器将具有以下标准化目录结构：

```
/srv/apps/                    # Go项目部署目录
├── axi-star-cloud/          # Go后端项目
└── other-go-project/        # 其他Go项目

/srv/static/                  # 静态项目部署目录
├── axi-docs/                # VitePress文档项目
└── other-static-project/    # 其他静态项目

/www/server/nginx/conf/conf.d/redamancy/  # Nginx配置目录
├── 00-main.conf            # 主配置文件（固定）
├── route-axi-star-cloud.conf    # 项目路由配置
└── route-axi-docs.conf         # 项目路由配置

/www/server/nginx/ssl/redamancy/  # SSL证书目录
├── fullchain.pem           # 证书文件（软链）
└── privkey.pem             # 私钥文件（软链）
```

### 3. 执行初始化

#### 方法1：使用 GitHub Actions

1. 进入 `axi-deploy` 仓库
2. 点击 "Actions" 标签
3. 选择 "Nginx 服务器初始化" 工作流
4. 点击 "Run workflow"
5. 填写参数：
   - **服务器IP地址**: 你的服务器IP
   - **SSH用户名**: 通常是 `root`
   - **域名**: `redamancy.com.cn`
   - **业务运行用户**: `deploy`
   - 其他参数保持默认值

#### 方法2：手动执行

如果无法使用 GitHub Actions，可以手动在服务器上执行：

```bash
# 1. 前置检查
nginx -v
systemctl is-active --quiet nginx

# 2. 创建业务运行用户
sudo useradd -m -s /bin/bash deploy

# 3. 创建所需目录
sudo mkdir -p /srv/apps /srv/static /www/server/nginx/conf/conf.d/redamancy /www/server/nginx/ssl/redamancy
sudo chown deploy:deploy /srv/apps /srv/static

# 4. 软链宝塔证书
sudo ln -sf /www/server/panel/vhost/cert/redamancy.com.cn/fullchain.pem /www/server/nginx/ssl/redamancy/fullchain.pem
sudo ln -sf /www/server/panel/vhost/cert/redamancy.com.cn/privkey.pem /www/server/nginx/ssl/redamancy/privkey.pem

# 5. 写入固定主配置
sudo tee /www/server/nginx/conf/conf.d/redamancy/00-main.conf <<'EOF'
server {
    listen 443 ssl http2;
    server_name redamancy.com.cn;

    ssl_certificate     /www/server/nginx/ssl/redamancy/fullchain.pem;
    ssl_certificate_key /www/server/nginx/ssl/redamancy/privkey.pem;

    client_max_body_size 100m;

    # 这里自动加载 route-*.conf（项目路由）——主配置永远不用再改
    include /www/server/nginx/conf/conf.d/redamancy/route-*.conf;
}

server {
    listen 80;
    server_name redamancy.com.cn;
    return 301 https://$host$request_uri;
}
EOF

# 6. 检查并重载Nginx
sudo nginx -t
sudo systemctl reload nginx
```

### 4. 验证初始化结果

初始化完成后，验证以下项目：

```bash
# 检查目录结构
ls -la /srv/apps/
ls -la /srv/static/
ls -la /www/server/nginx/conf/conf.d/redamancy/

# 检查证书软链
ls -la /www/server/nginx/ssl/redamancy/

# 测试HTTPS访问
curl -I https://redamancy.com.cn
```

## 项目部署适配

### 1. Go项目部署

Go项目（如 axi-star-cloud）将部署到：
- **部署路径**: `/srv/apps/axi-star-cloud`
- **Nginx配置**: `/www/server/nginx/conf/conf.d/redamancy/route-axi-star-cloud.conf`

### 2. 静态项目部署

静态项目（如 axi-docs）将部署到：
- **部署路径**: `/srv/static/axi-docs`
- **Nginx配置**: `/www/server/nginx/conf/conf.d/redamancy/route-axi-docs.conf`

## 优势

### 1. 标准化
- 所有项目使用统一的目录结构
- 配置文件集中管理
- 部署流程一致

### 2. 安全性
- 业务进程以非root用户运行
- 证书自动软链，避免版本不一致
- 权限分离，降低安全风险

### 3. 可维护性
- 主配置文件固定，无需重复修改
- 项目配置独立，互不影响
- 自动加载机制，新增项目无需重启

### 4. 兼容性
- 兼容宝塔面板的SSL证书管理
- 支持自动续期
- 不影响现有服务

## 故障排除

### 常见问题

1. **Nginx配置语法错误**
   ```bash
   sudo nginx -t
   ```

2. **证书文件不存在**
   ```bash
   ls -la /www/server/panel/vhost/cert/redamancy.com.cn/
   ```

3. **权限问题**
   ```bash
   sudo chown -R deploy:deploy /srv/apps /srv/static
   ```

4. **防火墙问题**
   ```bash
   sudo firewall-cmd --list-services
   ```

### 调试命令

```bash
# 检查Nginx状态
sudo systemctl status nginx

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/error.log

# 查看Nginx访问日志
sudo tail -f /var/log/nginx/access.log

# 检查端口监听
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

## 后续步骤

初始化完成后，可以：

1. **部署 axi-star-cloud** - Go后端项目
2. **部署 axi-docs** - VitePress文档项目
3. **添加新项目** - 按照相同模式部署其他项目

所有项目都将自动使用标准化的目录结构和配置管理。 