# 🚀 快速开始指南

## 推荐方案：workflow_dispatch

这是目前唯一能绕过 GitHub Actions 限制的方案，**强烈推荐使用**。

### 步骤 1：配置公共仓库（axi-deploy）

1. **配置 GitHub Secrets**
   - 进入 axi-deploy 仓库的 Settings → Secrets and variables → Actions
   - 添加以下 secrets：
     - `SERVER_HOST`: 服务器IP地址
     - `SERVER_PORT`: SSH端口（通常是22）
     - `SERVER_USER`: SSH用户名
     - `SERVER_KEY`: SSH私钥内容

2. **验证配置**
   - 在 axi-deploy 仓库中手动运行 `deploy-dispatch.yml` 工作流
   - 输入测试参数验证SSH连接

### 步骤 2：在业务仓库中配置

在您的项目仓库中创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
        
      - name: 设置 Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',  # 替换为您的用户名
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
            console.log('部署已触发:', response);
```

### 步骤 3：测试部署

1. **推送代码到主分支**
   ```bash
   git push origin main
   ```

2. **查看部署状态**
   - 在您的业务仓库中查看构建状态
   - 在 axi-deploy 仓库中查看部署状态

## 方案对比

| 特性 | workflow_dispatch | Reusable Workflow |
|------|-------------------|-------------------|
| 访问 Secrets | ✅ 可以 | ❌ 不能 |
| 复用部署逻辑 | ✅ 可以 | ✅ 可以 |
| 配置复杂度 | 简单 | 简单 |
| 推荐程度 | ✅ 强烈推荐 | ❌ 不推荐 |

## 常见问题

### Q: 为什么推荐 workflow_dispatch？
A: 因为它是目前唯一能绕过 GitHub Actions 限制的方案，可以访问公共仓库自己的 Secrets。

### Q: 业务仓库需要配置 SSH 密钥吗？
A: 不需要！所有 SSH 配置都在公共仓库中统一管理。

### Q: 如何修改部署参数？
A: 在触发部署时通过 `inputs` 参数传递，如 `source_path`、`target_path`、`commands` 等。

### Q: 支持哪些类型的项目？
A: 支持所有类型的项目，包括前端、后端、静态网站等。

## 故障排除

### SSH 连接失败
1. 检查 axi-deploy 仓库的 Secrets 配置
2. 确认服务器 SSH 服务正常运行
3. 验证网络连接和防火墙设置

### 权限问题
1. 确保业务仓库有权限调用 axi-deploy 仓库
2. 检查 GitHub Token 权限设置

### 部署失败
1. 检查目标路径权限
2. 确认磁盘空间充足
3. 查看详细的部署日志 