# 🚀 部署场景指南

本文档展示了不同语言和项目类型的部署配置示例。

## 📋 支持的语言

| 语言 | 构建工具 | 部署方式 | 示例项目 |
|------|----------|----------|----------|
| Node.js | npm/yarn | PM2/Systemd | Web应用、API服务 |
| Go | go build | Systemd/Docker | 微服务、CLI工具 |
| Python | pip | Systemd/Gunicorn | Web应用、脚本 |
| Rust | cargo | Systemd | 高性能服务 |
| Java | Maven/Gradle | Systemd/Docker | 企业应用 |

## 🎯 部署场景

### 1. Node.js Web 应用

**适用场景：** React/Vue 前端应用、Express API 服务

**构建配置：**
```yaml
- name: 设置 Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'
    
- name: 安装依赖
  run: npm ci
  
- name: 构建项目
  run: npm run build
  
- name: 上传构建产物
  uses: actions/upload-artifact@v4
  id: upload
  with:
    name: dist-my-node-app
    path: dist/
    retention-days: 1
```

**部署配置：**
```yaml
inputs: {
  project: 'my-node-app',
  lang: 'node',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-node-app',
  start_cmd: 'cd /www/wwwroot/my-node-app && npm ci --production && pm2 reload ecosystem.config.js',
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

**服务器配置：**
```bash
# 安装 PM2
npm install -g pm2

# 创建 ecosystem.config.js
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'my-node-app',
    script: 'app.js',
    instances: 2,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
}
EOF
```

### 2. Go 微服务

**适用场景：** API 服务、微服务、CLI 工具

**构建配置：**
```yaml
- name: 设置 Go
  uses: actions/setup-go@v5
  with:
    go-version: '1.22'
    cache: true
    
- name: 构建项目
  run: |
    go mod download
    go build -o app ./cmd/main.go
    
- name: 上传构建产物
  uses: actions/upload-artifact@v4
  id: upload
  with:
    name: dist-my-go-app
    path: app
    retention-days: 1
```

**部署配置：**
```yaml
inputs: {
  project: 'my-go-app',
  lang: 'go',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-go-app',
  start_cmd: 'cd /www/wwwroot/my-go-app && chmod +x app && systemctl restart my-go-app',
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

**服务器配置：**
```bash
# 创建 systemd 服务
sudo tee /etc/systemd/system/my-go-app.service << EOF
[Unit]
Description=My Go App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/www/wwwroot/my-go-app
ExecStart=/www/wwwroot/my-go-app/app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl enable my-go-app
sudo systemctl start my-go-app
```

### 3. Python Web 应用

**适用场景：** Django/Flask 应用、数据处理脚本

**构建配置：**
```yaml
- name: 设置 Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'
    cache: 'pip'
    
- name: 安装依赖
  run: |
    pip install -r requirements.txt
    
- name: 上传构建产物
  uses: actions/upload-artifact@v4
  id: upload
  with:
    name: dist-my-python-app
    path: |
      *.py
      requirements.txt
      config/
      static/
      templates/
    retention-days: 1
```

**部署配置：**
```yaml
inputs: {
  project: 'my-python-app',
  lang: 'python',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-python-app',
  start_cmd: 'cd /www/wwwroot/my-python-app && pip install -r requirements.txt && systemctl restart my-python-app',
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

**服务器配置：**
```bash
# 创建 systemd 服务
sudo tee /etc/systemd/system/my-python-app.service << EOF
[Unit]
Description=My Python App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/www/wwwroot/my-python-app
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl enable my-python-app
sudo systemctl start my-python-app
```

### 4. Rust 高性能服务

**适用场景：** 高性能 API、系统工具

**构建配置：**
```yaml
- name: 设置 Rust
  uses: actions-rs/toolchain@v1
  with:
    toolchain: stable
    override: true
    
- name: 构建项目
  run: |
    cargo build --release
    
- name: 上传构建产物
  uses: actions/upload-artifact@v4
  id: upload
  with:
    name: dist-my-rust-app
    path: target/release/my-rust-app
    retention-days: 1
```

**部署配置：**
```yaml
inputs: {
  project: 'my-rust-app',
  lang: 'rust',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-rust-app',
  start_cmd: 'cd /www/wwwroot/my-rust-app && chmod +x my-rust-app && systemctl restart my-rust-app',
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

**服务器配置：**
```bash
# 创建 systemd 服务
sudo tee /etc/systemd/system/my-rust-app.service << EOF
[Unit]
Description=My Rust App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/www/wwwroot/my-rust-app
ExecStart=/www/wwwroot/my-rust-app/my-rust-app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl enable my-rust-app
sudo systemctl start my-rust-app
```

## 🔧 高级配置

### 1. 多环境部署

**开发环境：**
```yaml
inputs: {
  project: 'my-app-dev',
  lang: 'node',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-app-dev',
  start_cmd: 'cd /www/wwwroot/my-app-dev && npm ci --production && pm2 reload ecosystem.dev.js',
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

**生产环境：**
```yaml
inputs: {
  project: 'my-app-prod',
  lang: 'node',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-app-prod',
  start_cmd: 'cd /www/wwwroot/my-app-prod && npm ci --production && pm2 reload ecosystem.prod.js',
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

### 2. Docker 部署

**Docker 配置：**
```yaml
inputs: {
  project: 'my-docker-app',
  lang: 'docker',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-docker-app',
  start_cmd: 'cd /www/wwwroot/my-docker-app && docker-compose down && docker-compose up -d',
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

### 3. 数据库迁移

**包含数据库迁移的部署：**
```yaml
inputs: {
  project: 'my-app-with-db',
  lang: 'node',
  artifact_id: '${{ needs.build.outputs.artifact-id }}',
  deploy_path: '/www/wwwroot/my-app',
  start_cmd: |
    cd /www/wwwroot/my-app
    npm ci --production
    npm run migrate
    npm run seed
    pm2 reload ecosystem.config.js
  caller_repo: '${{ github.repository }}',
  caller_branch: '${{ github.ref_name }}',
  caller_commit: '${{ github.sha }}'
}
```

## 🛡️ 安全最佳实践

### 1. 环境变量管理

**使用 .env 文件：**
```bash
# 在服务器上创建环境变量文件
cat > /www/wwwroot/my-app/.env << EOF
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@localhost/db
API_KEY=your-api-key
EOF
```

### 2. 权限控制

**限制服务用户权限：**
```bash
# 创建专用用户
sudo useradd -r -s /bin/false my-app-user

# 设置目录权限
sudo chown -R my-app-user:my-app-user /www/wwwroot/my-app
sudo chmod 755 /www/wwwroot/my-app
```

### 3. 日志管理

**配置日志轮转：**
```bash
# 创建 logrotate 配置
sudo tee /etc/logrotate.d/my-app << EOF
/www/wwwroot/my-app/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 my-app-user my-app-user
}
EOF
```

## 📊 监控和健康检查

### 1. 健康检查端点

**在应用中添加健康检查：**
```javascript
// Node.js 示例
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

### 2. 监控脚本

**创建监控脚本：**
```bash
#!/bin/bash
# /usr/local/bin/monitor-my-app.sh

APP_URL="http://localhost:3000/health"
LOG_FILE="/var/log/my-app-monitor.log"

if curl -f -s "$APP_URL" > /dev/null; then
    echo "$(date): App is healthy" >> "$LOG_FILE"
else
    echo "$(date): App is down, restarting..." >> "$LOG_FILE"
    systemctl restart my-app
fi
```

### 3. 定时监控

**添加到 crontab：**
```bash
# 每分钟检查一次
* * * * * /usr/local/bin/monitor-my-app.sh
```

## 🔍 故障排除

### 常见问题解决

1. **服务启动失败**
   ```bash
   # 查看服务状态
   systemctl status my-app
   
   # 查看日志
   journalctl -u my-app -f
   ```

2. **权限问题**
   ```bash
   # 检查文件权限
   ls -la /www/wwwroot/my-app/
   
   # 修复权限
   chown -R www-data:www-data /www/wwwroot/my-app/
   ```

3. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep :3000
   
   # 杀死占用进程
   sudo kill -9 <PID>
   ```

## 📚 更多资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [PM2 文档](https://pm2.keymetrics.io/docs/)
- [Systemd 文档](https://systemd.io/)
- [Docker Compose 文档](https://docs.docker.com/compose/)

---

🎯 **提示：** 根据您的具体需求选择合适的部署场景，并参考相应的配置示例进行定制。 