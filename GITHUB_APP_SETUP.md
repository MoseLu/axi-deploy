# 🔐 GitHub App 设置指南

## 📋 问题背景

Personal Access Token 只会在生成时显示一次，如果丢失就需要重新生成。对于多个项目使用部署系统，这会造成管理困难。

## ✅ 解决方案：GitHub App

使用 GitHub App 可以解决 Token 管理问题，并提供更好的权限控制。

### 🎯 GitHub App 的优势

1. **永久有效** - 不会过期，无需重新生成
2. **权限精细** - 可以精确控制访问权限
3. **多仓库支持** - 一个 App 可以服务多个仓库
4. **安全可靠** - 比 Personal Access Token 更安全
5. **易于管理** - 可以在一个地方管理所有权限

## 🔧 创建 GitHub App

### 步骤 1：创建 GitHub App

1. 访问 [GitHub Developer Settings](https://github.com/settings/apps)
2. 点击 "New GitHub App"
3. 填写基本信息：
   - **App name**: `axi-deploy-center`
   - **Homepage URL**: `https://github.com/MoseLu/axi-deploy`
   - **Webhook**: 可选，用于实时通知
   - **Description**: `AXI 多语言部署中心`

### 步骤 2：配置权限

在 "Permissions" 部分配置以下权限：

| 权限 | 访问级别 | 说明 |
|------|----------|------|
| `Repository permissions` | | |
| `Contents` | Read | 读取仓库内容 |
| `Metadata` | Read | 读取仓库元数据 |
| `Actions` | Read | 读取 Actions 信息 |
| `Workflows` | Read | 读取工作流信息 |

### 步骤 3：配置事件

在 "Subscribe to events" 部分：

- ✅ `Workflow run` - 监听工作流运行事件

### 步骤 4：安装 App

1. 创建 App 后，点击 "Install App"
2. 选择要安装的组织或用户
3. 选择要授权的仓库（建议选择 "All repositories"）

## 🔧 获取 App 凭据

### 1. 获取 App ID

在 App 设置页面可以看到 App ID，记录下来。

### 2. 生成私钥

1. 在 App 设置页面，点击 "Generate private key"
2. 下载生成的 `.pem` 文件
3. 将私钥内容保存为 Secret

### 3. 获取 Installation ID

1. 访问 `https://api.github.com/app/installations`
2. 使用 App 凭据获取 Installation ID

## 📝 更新部署系统

### 1. 更新 axi-deploy 仓库

在 `axi-deploy` 仓库中添加新的 Secrets：

| Secret 名称 | 描述 |
|-------------|------|
| `GITHUB_APP_ID` | GitHub App ID |
| `GITHUB_APP_PRIVATE_KEY` | GitHub App 私钥内容 |
| `GITHUB_APP_INSTALLATION_ID` | Installation ID |

### 2. 创建 JWT Token 生成脚本

```javascript
// scripts/generate-jwt.js
const jwt = require('jsonwebtoken');

const appId = process.env.GITHUB_APP_ID;
const privateKey = process.env.GITHUB_APP_PRIVATE_KEY;

const payload = {
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + (10 * 60), // 10 minutes
  iss: appId
};

const token = jwt.sign(payload, privateKey, { algorithm: 'RS256' });
console.log(token);
```

### 3. 更新部署工作流

```yaml
# .github/workflows/deploy.yml
name: Deploy Any Project

on:
  workflow_dispatch:
    inputs:
      project: { required: true, type: string }
      lang: { required: true, type: string }
      artifact_id: { required: true, type: string }
      deploy_path: { required: true, type: string }
      start_cmd: { required: true, type: string }
      caller_repo: { required: true, type: string }
      caller_branch: { required: true, type: string }
      caller_commit: { required: true, type: string }

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: 生成 GitHub App Token
        id: generate-token
        run: |
          # 这里调用 JWT 生成脚本
          TOKEN=$(node scripts/generate-jwt.js)
          echo "token=$TOKEN" >> $GITHUB_OUTPUT
      
      - name: 下载构建产物
        uses: actions/download-artifact@v4
        with:
          name: dist-${{ github.event.inputs.project }}
          github-token: ${{ steps.generate-token.outputs.token }}
          run-id: ${{ github.event.inputs.artifact_id }}
      
      # ... 其他部署步骤
```

## 🔄 更新业务仓库配置

### 1. 移除 Personal Access Token

业务仓库不再需要配置 `DEPLOY_CENTER_PAT`，改为使用 GitHub App。

### 2. 更新工作流调用

```yaml
# 业务仓库的工作流
- name: 触发部署
  uses: actions/github-script@v7
  with:
    script: |
      // 使用 GitHub App 调用部署
      const { data: response } = await github.rest.actions.createWorkflowDispatch({
        owner: 'MoseLu',
        repo: 'axi-deploy',
        workflow_id: 'deploy.yml',
        ref: 'main',
        inputs: {
          project: 'my-app',
          lang: 'node',
          artifact_id: '${{ needs.build.outputs.artifact-id }}',
          deploy_path: '/www/wwwroot/my-app',
          start_cmd: 'cd /www/wwwroot/my-app && npm ci --production && pm2 reload app',
          caller_repo: '${{ github.repository }}',
          caller_branch: '${{ github.ref_name }}',
          caller_commit: '${{ github.sha }}'
        }
      });
      console.log('✅ 部署已触发:', response);
```

## 🛡️ 安全优势

### 1. 权限隔离
- GitHub App 只能访问被授权的仓库
- 可以精确控制权限范围
- 比 Personal Access Token 更安全

### 2. 审计便利
- 所有操作都有详细的审计日志
- 可以追踪每次部署的来源
- 支持权限变更通知

### 3. 易于管理
- 一个 App 可以服务多个仓库
- 统一的权限管理
- 无需为每个项目配置 Token

## 📋 迁移步骤

### 1. 创建 GitHub App
1. 按照上述步骤创建 GitHub App
2. 配置必要的权限
3. 安装到目标组织/用户

### 2. 更新 axi-deploy 仓库
1. 添加 GitHub App 相关的 Secrets
2. 更新部署工作流使用 App Token
3. 测试部署功能

### 3. 更新业务仓库
1. 移除 `DEPLOY_CENTER_PAT` Secret
2. 更新工作流调用方式
3. 测试部署流程

## 🔍 故障排除

### 常见问题

1. **权限不足**
   - 检查 GitHub App 的权限配置
   - 确认 App 已安装到目标仓库

2. **Token 生成失败**
   - 检查 App ID 和私钥配置
   - 确认私钥格式正确

3. **调用失败**
   - 检查 Installation ID 配置
   - 确认 App 已正确安装

## 📚 相关资源

- [GitHub App 文档](https://docs.github.com/en/developers/apps)
- [JWT Token 生成](https://docs.github.com/en/developers/apps/authenticating-with-github-apps#generating-a-jwt)
- [Installation Token](https://docs.github.com/en/developers/apps/authenticating-with-github-apps#authenticating-as-an-installation)

---

🎉 **使用 GitHub App 后，您将拥有一个更安全、更易管理的多语言部署系统！** 