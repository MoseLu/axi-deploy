# 🚀 AXI Deploy - workflow_dispatch 解决方案

## 问题背景

GitHub Actions 的 Reusable Workflow 存在限制：**无法访问调用方的 Secrets**，这导致无法在可重用工作流中使用 SSH 密钥等敏感信息。

## 解决方案

我们实现了基于 `workflow_dispatch` 的集中化部署方案，这是目前唯一能绕过 GitHub Actions 限制的办法。

## 方案对比

| 方案 | 是否能访问密钥 | 是否能复用部署逻辑 | 推荐程度 |
|------|----------------|-------------------|----------|
| Reusable Workflow | ❌ 不能 | ✅ 可以 | ❌ 不推荐 |
| **公共仓库的 workflow_dispatch** | ✅ **可以（访问自己的 Secrets）** | ✅ **可以（集中部署脚本）** | ✅ **强烈推荐** |

## 实现架构

### 1. 公共仓库（axi-deploy）

**职责：**
- 存储 SSH 密钥和服务器配置
- 定义部署脚本和工作流
- 执行真正的 SSH 部署操作

**核心文件：**
- `.github/workflows/deploy-dispatch.yml` - 主要的部署工作流
- `.github/workflows/test-dispatch.yml` - 测试连接的工作流
- `scripts/deploy.sh` - 通用部署脚本

**配置要求：**
```bash
# GitHub Secrets
SERVER_HOST=192.168.1.100
SERVER_PORT=22
SERVER_USER=deploy
SERVER_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
```

### 2. 业务仓库（任意项目）

**职责：**
- 构建项目（npm run build）
- 触发公共仓库的 workflow_dispatch
- 传递部署参数

**配置示例：**
```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
        
      - name: 构建项目
        run: npm run build
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/www/wwwroot/my-app',
                commands: |
                  cd /www/wwwroot/my-app
                  npm install --production
                  pm2 restart my-app
              }
            });
```

## 核心特性

### ✅ 优势

1. **完全绕过限制**: workflow_dispatch 可以访问自己的 Secrets
2. **集中化管理**: 所有 SSH 配置统一管理
3. **安全性**: 业务仓库无需配置任何敏感信息
4. **灵活性**: 支持多种部署场景和参数
5. **可扩展性**: 易于添加新的部署功能

### 🔧 功能特性

- **文件传输**: 使用 rsync 高效传输文件
- **命令执行**: 支持自定义部署命令
- **备份机制**: 自动备份当前版本
- **权限管理**: 安全的 SSH 密钥管理
- **日志记录**: 详细的部署日志
- **错误处理**: 完善的错误处理机制

## 使用流程

### 步骤 1: 配置公共仓库

1. 在 axi-deploy 仓库中配置 GitHub Secrets
2. 测试 SSH 连接（使用 test-dispatch.yml）
3. 验证部署脚本功能

### 步骤 2: 在业务仓库中配置

1. 创建 `.github/workflows/deploy.yml`
2. 配置构建步骤
3. 添加触发部署的步骤

### 步骤 3: 测试部署

1. 推送代码到主分支
2. 查看构建和部署状态
3. 验证部署结果

## 部署场景支持

### 前端项目
- Vue.js、React、Angular 等
- 静态网站（Hugo、Jekyll 等）
- 单页应用（SPA）

### 后端项目
- Node.js API
- Python Flask/Django
- Java Spring Boot
- Go 应用

### 多环境部署
- 开发环境
- 测试环境
- 生产环境

### 特殊场景
- 数据库迁移
- 条件部署
- 蓝绿部署

## 安全考虑

1. **密钥安全**: SSH 私钥存储在公共仓库的 Secrets 中
2. **权限控制**: 使用专门的部署用户，限制权限
3. **网络安全**: 建议使用 VPN 或防火墙限制 SSH 访问
4. **访问控制**: 只有授权项目可以调用此仓库的工作流
5. **日志监控**: 定期检查部署日志，监控异常活动

## 故障排除

### 常见问题

1. **SSH 连接失败**
   - 检查 Secrets 配置
   - 确认服务器 SSH 服务状态
   - 验证网络连接

2. **权限问题**
   - 确保业务仓库有调用权限
   - 检查 GitHub Token 权限

3. **部署失败**
   - 检查目标路径权限
   - 确认磁盘空间
   - 查看详细日志

### 调试方法

1. **使用测试工作流**: 运行 test-dispatch.yml 验证配置
2. **查看详细日志**: 在部署工作流中启用调试模式
3. **手动测试**: 在服务器上手动执行部署命令

## 最佳实践

1. **环境隔离**: 为不同环境使用不同的目标路径
2. **备份策略**: 部署前自动备份当前版本
3. **回滚机制**: 准备快速回滚方案
4. **监控告警**: 部署后监控应用状态
5. **文档维护**: 保持部署文档的更新

## 总结

这个 `workflow_dispatch` 方案成功解决了 GitHub Actions 的限制问题，提供了一个安全、可靠、易用的集中化部署解决方案。通过将 SSH 配置集中在公共仓库中，业务仓库可以专注于构建和触发部署，实现了职责分离和安全性提升。

**推荐使用此方案进行所有项目的自动化部署！** 