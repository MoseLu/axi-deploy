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
    uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@master
    with:
      # 部署配置
      source_path: './dist'
      target_path: '/www/wwwroot/your-app'
      commands: |
        cd /www/wwwroot/your-app
        npm install --production
        pm2 restart your-app
```

### 2. 配置说明

**无需配置任何服务器信息！** 所有SSH配置都由本仓库统一管理：

- 服务器IP地址、用户名、端口、私钥等配置都在本仓库的Secrets中
- 调用方只需要配置部署相关的参数

### 3. 使用说明

#### 3.1 直接使用

无需任何配置，直接在其他项目中调用即可：

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@master
  with:
    source_path: './dist'
    target_path: '/www/wwwroot/my-app'
    commands: |
      cd /www/wwwroot/my-app
      npm install --production
      pm2 restart my-app
```

#### 3.2 测试连接

在您的项目中测试SSH连接：

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/test-connection.yml@master
```

#### 3.3 故障诊断

如果SSH连接失败，请联系仓库管理员检查服务器配置。

#### 3.4 常见问题

如果SSH连接失败，请检查：

```bash
# 常见问题解决：
# 1. 启动SSH服务: systemctl start sshd
# 2. 配置防火墙: firewall-cmd --permanent --add-service=ssh && firewall-cmd --reload
# 3. 检查云服务器安全组设置
```

## 工作流参数

### 输入参数

| 参数名 | 必需 | 描述 | 默认值 |
|--------|------|------|--------|
| `source_path` | ❌ | 本地文件路径 | `./dist` |
| `target_path` | ❌ | 远程目标路径 | `/www/wwwroot` |
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
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@master
  with:
    source_path: './dist'
    target_path: '/www/wwwroot/my-app'
    commands: |
      cd /www/wwwroot/my-app
      chmod -R 755 .
      sudo systemctl reload nginx
```

### 后端项目部署

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@master
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
- uses: MoseLu/axi-deploy/.github/workflows/ssh-command.yml@master
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
6. **访问控制**: 只有授权项目可以调用此仓库的工作流

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

4. **权限问题**
   - 确认您的项目有权限调用此仓库的工作流
   - 联系仓库管理员获取访问权限

### 调试模式

在调用工作流时添加调试信息：

```yaml
- uses: MoseLu/axi-deploy/.github/workflows/ssh-deploy.yml@master
  with:
    commands: |
      set -x  # 启用调试模式
      cd /www/wwwroot/app
      ls -la
      pwd
```

## 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 许可证

MIT License