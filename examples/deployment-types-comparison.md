# 部署类型对比 - 动态项目 vs 静态项目

## 概述

axi-deploy支持两种主要的部署类型：动态项目（如Go后端）和静态项目（如VitePress文档）。它们在部署流程、配置和需求上有显著差异。

## 动态项目部署 (Go/Node.js/Python)

### 特点
- **需要重启服务** - 部署后需要重启systemd服务
- **端口监听** - 应用监听特定端口（如8080）
- **健康检查** - 需要验证服务是否正常启动
- **API代理** - Nginx需要代理API请求到后端服务

### 部署流程
1. **构建阶段**
   - 编译Go二进制文件
   - 打包所有必要文件（二进制、前端、配置、服务文件）
   - 上传构建产物

2. **部署阶段**
   - 下载构建产物
   - 解压到目标目录
   - 设置可执行权限
   - 创建必要目录
   - 配置systemd服务
   - 重启服务
   - 健康检查

### 示例配置

#### Go项目部署命令
```bash
cd /www/wwwroot/axi-star-cloud && \
tar xzf deployment.tar.gz && \
chmod +x star-cloud-linux && \
mkdir -p uploads/{image,document,audio,video,other,avatars} && \
mkdir -p logs && \
sudo cp star-cloud.service /etc/systemd/system/ && \
sudo chmod 644 /etc/systemd/system/star-cloud.service && \
sudo systemctl daemon-reload && \
sudo systemctl enable star-cloud.service && \
sudo systemctl restart star-cloud.service && \
sleep 5 && \
if curl -f -s http://127.0.0.1:8080/health > /dev/null 2>&1; then \
  echo '✅ 服务启动成功'; \
else \
  echo '❌ 服务启动失败'; \
  sudo systemctl status star-cloud.service --no-pager --lines 5; \
  exit 1; \
fi
```

#### Nginx配置
```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name redamancy.com.cn;
    
    # 静态文件服务
    location / {
        root /www/wwwroot/axi-star-cloud;
        try_files $uri $uri/ /index.html;
        
        # 设置缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API代理到Go后端
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 上传文件大小限制
        client_max_body_size 100M;
    }
    
    # 健康检查端点
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_set_header Host $host;
    }
    
    # 包含其他项目配置
    include /www/server/nginx/conf/vhost/includes/*.conf;
}
```

## 静态项目部署 (VitePress/Vue/React)

### 特点
- **无需重启** - 部署后无需重启任何服务
- **纯静态文件** - 只需要部署静态文件到web目录
- **无端口监听** - 不监听任何端口
- **直接访问** - 通过Nginx直接提供静态文件服务

### 部署流程
1. **构建阶段**
   - 构建静态网站
   - 上传构建产物

2. **部署阶段**
   - 下载构建产物
   - 直接复制到web目录
   - 无需重启服务

### 示例配置

#### 静态项目部署命令
```bash
# 静态项目通常只需要复制文件，无需重启服务
echo "静态网站部署完成，无需启动命令"
```

#### Nginx配置
```nginx
# axi-docs 项目配置
location /docs/ {
    alias /www/wwwroot/axi-docs/;
    try_files $uri $uri/ /docs/index.html;
    
    # 设置缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 设置正确的 MIME 类型
    location ~* \.(js)$ {
        add_header Content-Type application/javascript;
    }
    
    location ~* \.(css)$ {
        add_header Content-Type text/css;
    }
}
```

## 部署差异对比

| 特性 | 动态项目 (Go) | 静态项目 (VitePress) |
|------|---------------|---------------------|
| **服务重启** | ✅ 需要重启systemd服务 | ❌ 无需重启 |
| **端口监听** | ✅ 监听8080端口 | ❌ 无端口监听 |
| **健康检查** | ✅ 需要验证服务状态 | ❌ 无需健康检查 |
| **API代理** | ✅ Nginx代理API请求 | ❌ 无API请求 |
| **部署复杂度** | 🔴 高（需要服务管理） | 🟢 低（文件复制） |
| **故障排除** | 🔴 复杂（服务日志） | 🟢 简单（文件权限） |
| **扩展性** | 🔴 需要重启服务 | 🟢 即时生效 |

## 项目类型识别

### 动态项目特征
- 包含`main.go`或`package.json`（Node.js）
- 有systemd服务文件（`.service`）
- 需要监听端口
- 有API端点

### 静态项目特征
- 构建产物为静态文件（HTML/CSS/JS）
- 无服务文件
- 无端口监听
- 纯前端应用

## 部署建议

### 动态项目部署注意事项
1. **服务管理** - 确保systemd服务配置正确
2. **端口冲突** - 检查端口是否被占用
3. **健康检查** - 部署后验证服务状态
4. **日志监控** - 密切关注服务日志
5. **回滚机制** - 准备快速回滚方案

### 静态项目部署注意事项
1. **文件权限** - 确保Nginx有读取权限
2. **路径配置** - 检查alias/root配置
3. **缓存设置** - 配置适当的缓存策略
4. **MIME类型** - 确保正确的Content-Type

## 故障排除

### 动态项目常见问题
- 服务启动失败
- 端口被占用
- 权限不足
- 配置文件错误

### 静态项目常见问题
- 文件权限问题
- 路径配置错误
- 缓存问题
- MIME类型错误

## 最佳实践

1. **分离部署** - 动态项目和静态项目使用不同的部署流程
2. **统一管理** - 通过axi-deploy统一管理所有项目
3. **模块化配置** - 使用Nginx include功能管理多项目配置
4. **自动化验证** - 部署后自动验证服务状态
5. **详细日志** - 记录详细的部署和错误日志 