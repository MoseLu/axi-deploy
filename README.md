# AXI Deploy - SSH连接公共仓库

这是一个专门用于SSH连接的公共GitHub仓库，其他仓库可以通过GitHub Actions工作流调用此仓库进行远程服务器部署。

## 功能特性

- 🔐 安全的SSH连接管理
- 🔄 可重用的GitHub Actions工作流
- 📦 支持多种部署场景
- 🛡️ 集中化的密钥管理
- 📋 详细的部署日志

## 使用方法

### 1. 在其他仓库中调用

在您的项目仓库中创建 `.github/workflows/deploy.yml` 文件：

```yaml
name: Deploy via SSH

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  deploy:
    uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@main
    with:
      host: ${{ secrets.SSH_HOST }}
      username: ${{ secrets.SSH_USERNAME }}
      port: ${{ secrets.SSH_PORT }}
      source_path: './dist'
      target_path: '/var/www/your-app'
      commands: |
        cd /var/www/your-app
        npm install --production
        pm2 restart your-app
    secrets:
      ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
      ssh_known_hosts: ${{ secrets.SSH_KNOWN_HOSTS }}
```

### 2. 配置Secrets

在您的项目仓库中配置以下Secrets：

| Secret名称 | 描述 | 示例值 |
|-----------|------|--------|
| `SSH_HOST` | 目标服务器IP地址 | `192.168.1.100` |
| `SSH_USERNAME` | SSH用户名 | `deploy` |
| `SSH_PORT` | SSH端口号 | `22` |
| `SSH_PRIVATE_KEY` | SSH私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `SSH_KNOWN_HOSTS` | 服务器公钥指纹 | `github.com ssh-rsa AAAAB3NzaC1yc2E...` |

### 3. 生成SSH密钥

```bash
# 生成SSH密钥对
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/deploy_key

# 将公钥添加到服务器
ssh-copy-id -i ~/.ssh/deploy_key.pub username@your-server

# 获取服务器公钥指纹
ssh-keyscan -H your-server-ip
```

## 工作流参数

### 输入参数

| 参数名 | 必需 | 描述 | 默认值 |
|--------|------|------|--------|
| `host` | ✅ | 目标服务器IP地址 | - |
| `username` | ✅ | SSH用户名 | - |
| `port` | ❌ | SSH端口号 | `22` |
| `source_path` | ❌ | 本地文件路径 | `./dist` |
| `target_path` | ❌ | 远程目标路径 | `/var/www/app` |
| `commands` | ❌ | 部署后执行的命令 | - |
| `exclude_files` | ❌ | 排除的文件/目录 | - |
| `timeout` | ❌ | SSH连接超时时间(秒) | `300` |

### 输出参数

| 参数名 | 描述 |
|--------|------|
| `deploy_status` | 部署状态 (`success` 或 `failed`) |
| `deploy_time` | 部署完成时间 |

## 示例场景

### 前端项目部署

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@main
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USERNAME }}
    source_path: './dist'
    target_path: '/var/www/my-app'
    commands: |
      cd /var/www/my-app
      chmod -R 755 .
      sudo systemctl reload nginx
```

### 后端项目部署

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@main
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USERNAME }}
    source_path: './build'
    target_path: '/opt/my-api'
    commands: |
      cd /opt/my-api
      npm install --production
      pm2 restart my-api
      sudo systemctl reload nginx
```

### 数据库迁移

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@main
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USERNAME }}
    commands: |
      cd /opt/my-api
      npm run migrate
      npm run seed
```

## 安全注意事项

1. **密钥管理**: 确保SSH私钥安全存储，定期轮换
2. **权限控制**: 使用专门的部署用户，限制其权限
3. **网络安全**: 建议使用VPN或防火墙限制SSH访问
4. **日志监控**: 定期检查部署日志，监控异常活动

## 故障排除

### 常见问题

1. **SSH连接失败**
   - 检查服务器IP和端口是否正确
   - 确认SSH密钥配置正确
   - 验证服务器防火墙设置

2. **文件传输失败**
   - 检查目标路径权限
   - 确认磁盘空间充足
   - 验证网络连接稳定性

3. **命令执行失败**
   - 检查用户权限
   - 确认命令路径正确
   - 查看服务器日志

### 调试模式

在调用工作流时添加调试信息：

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@main
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USERNAME }}
    commands: |
      set -x  # 启用调试模式
      cd /var/www/app
      ls -la
      pwd
```

## 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 许可证

MIT License
