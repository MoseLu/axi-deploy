# 快速开始指南

## 🚀 5分钟快速部署

### 1. 生成SSH密钥

```bash
# 克隆仓库
git clone https://github.com/MoseLu/axi-deploy.git
cd axi-deploy

# 生成SSH密钥
chmod +x scripts/generate-ssh-key.sh
./scripts/generate-ssh-key.sh -e your-email@example.com
```

### 2. 配置服务器

```bash
# 在目标服务器上运行
chmod +x scripts/setup-server.sh
sudo ./scripts/setup-server.sh -u deploy -d /var/www/myapp
```

### 3. 配置GitHub Secrets

在您的项目仓库中配置以下Secrets：

| Secret名称 | 值 |
|-----------|-----|
| `SSH_HOST` | 您的服务器IP地址 |
| `SSH_USERNAME` | `deploy` |
| `SSH_PORT` | `22` |
| `SSH_PRIVATE_KEY` | 私钥内容 (从步骤1获取) |
| `SSH_KNOWN_HOSTS` | 服务器公钥指纹 |

获取服务器公钥指纹：
```bash
ssh-keyscan -H YOUR_SERVER_IP
```

### 4. 创建部署工作流

在您的项目仓库中创建 `.github/workflows/deploy.yml`：

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
      source_path: './dist'
      target_path: '/var/www/myapp'
      commands: |
        cd /var/www/myapp
        npm install --production
        pm2 restart myapp
    secrets:
      ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
      ssh_known_hosts: ${{ secrets.SSH_KNOWN_HOSTS }}
```

### 5. 测试部署

推送代码到main分支，GitHub Actions将自动触发部署。

## 📋 常用命令

### 测试SSH连接
```bash
ssh deploy@YOUR_SERVER_IP
```

### 查看部署日志
```bash
# 在服务器上
pm2 logs myapp
tail -f /var/log/nginx/access.log
```

### 重启应用
```bash
# 在服务器上
pm2 restart myapp
sudo systemctl reload nginx
```

## 🔧 故障排除

### SSH连接失败
1. 检查服务器IP和端口
2. 确认SSH密钥配置正确
3. 验证服务器防火墙设置

### 文件传输失败
1. 检查目标路径权限
2. 确认磁盘空间充足
3. 验证网络连接稳定性

### 命令执行失败
1. 检查用户权限
2. 确认命令路径正确
3. 查看服务器日志

## 📞 获取帮助

- 📖 查看完整文档：[README.md](README.md)
- 🐛 报告问题：[GitHub Issues](https://github.com/MoseLu/axi-deploy/issues)
- 💬 讨论：[GitHub Discussions](https://github.com/MoseLu/axi-deploy/discussions) 