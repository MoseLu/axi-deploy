# AXI Deploy - SSH连接公共仓库

这是一个专门用于SSH连接的公共GitHub仓库，其他仓库可以通过GitHub Actions工作流调用此仓库进行远程服务器部署。**本仓库统一管理所有SSH配置，包括服务器信息，其他项目无需配置任何SSH相关参数。**

## 功能特性

- 🔐 安全的SSH连接管理
- 🔄 可重用的GitHub Actions工作流
- 📦 支持多种部署场景
- 🛡️ 集中化的密钥管理
- 📋 详细的部署日志
- 🚀 **极简配置** - 其他项目无需配置任何SSH参数

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
      source_path: './dist'
      target_path: '/var/www/your-app'
      commands: |
        cd /var/www/your-app
        npm install --production
        pm2 restart your-app
```

### 2. 配置说明

**无需配置任何Secrets！** 所有SSH相关配置都由本仓库统一管理：

- `SERVER_HOST` - 服务器IP地址
- `SERVER_USER` - SSH用户名
- `SERVER_PORT` - SSH端口
- `SERVER_KEY` - SSH私钥

### 3. 服务器配置

确保您的服务器已配置好SSH密钥：

```bash
# 在服务器上添加本仓库的公钥到authorized_keys
# 请联系仓库管理员获取公钥信息
```

## 工作流参数

### 输入参数

| 参数名 | 必需 | 描述 | 默认值 |
|--------|------|------|--------|
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
    source_path: './build'
    target_path: '/opt/my-api'
    commands: |
      cd /opt/my-api
      npm install --production
      pm2 restart my-api
      sudo systemctl reload nginx
```

### 仅执行命令

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-command.yml@main
  with:
    commands: |
      cd /opt/my-api
      npm run migrate
      npm run seed
      pm2 restart my-api
```

## 安全注意事项

1. **完全集中化管理**: 所有SSH配置由本仓库统一管理
2. **权限控制**: 使用专门的部署用户，限制其权限
3. **网络安全**: 建议使用VPN或防火墙限制SSH访问
4. **日志监控**: 定期检查部署日志，监控异常活动
5. **密钥轮换**: 定期更新SSH密钥

## 故障排除

### 常见问题

1. **SSH连接失败**
   - 联系仓库管理员检查服务器配置
   - 确认服务器已添加本仓库的公钥
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
