# 🚀 GitHub App 快速配置指南

## 📋 问题解决

**问题：** Personal Access Token 只显示一次，新建项目时无法获取密钥

**解决方案：** 使用 GitHub App，私钥永久保存，可重复使用

## ✅ GitHub App 优势

- 🔐 **永久有效** - 私钥不会消失，可重复使用
- 🏢 **企业级管理** - 一次配置，所有项目通用
- 🛡️ **安全可靠** - 比 Personal Access Token 更安全
- 📋 **权限精细** - 只授予必要权限

## 🔧 快速配置步骤

### 步骤 1：创建 GitHub App

1. **访问 GitHub 开发者设置**
   ```
   https://github.com/settings/apps
   ```

2. **点击 "New GitHub App"**

3. **填写基本信息**
   ```
   App name: axi-deploy-center
   Homepage URL: https://github.com/your-org/axi-deploy
   Description: AXI 多语言部署中心
   ```

4. **配置权限**
   ```
   Repository permissions:
   - Contents: Read
   - Metadata: Read
   - Actions: Read
   - Workflows: Read
   ```

5. **配置事件（可选）**
   ```
   Subscribe to events:
   - Workflow run
   ```

6. **创建 App**

### 步骤 2：获取 App 凭据

1. **记录 App ID**
   - 在 App 设置页面可以看到 App ID
   - 例如：`123456`

2. **生成私钥**
   - 点击 "Generate private key"
   - 下载 `.pem` 文件
   - 复制私钥内容（以 `-----BEGIN RSA PRIVATE KEY-----` 开头）

3. **获取 Installation ID**
   - 点击 "Install App"
   - 选择要安装的组织
   - 选择 "All repositories"
   - 安装后，访问：`https://api.github.com/app/installations`
   - 记录 Installation ID

### 步骤 3：配置部署仓库

在 `axi-deploy` 仓库中添加以下 Secrets：

| Secret 名称 | 描述 | 示例值 |
|-------------|------|--------|
| `APP_ID` | GitHub App ID | `123456` |
| `APP_PRIVATE_KEY` | GitHub App 私钥内容 | `-----BEGIN RSA PRIVATE KEY-----...` |
| `APP_INSTALLATION_ID` | Installation ID | `12345678` |

### 步骤 4：更新业务仓库

**业务仓库不再需要配置任何 Token！**

只需要更新工作流文件，使用新的部署工作流：

```yaml
# 业务仓库的 .github/workflows/deploy.yml
name: Build & Deploy

on:
  push:
    branches: [main, master]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      artifact-id: ${{ steps.upload.outputs.artifact-id }}
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
        
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
          name: dist-my-app
          path: dist/
          retention-days: 1

  trigger-deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'your-org',
              repo: 'axi-deploy',
              workflow_id: 'deploy-with-app.yml',  # 使用新的工作流
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

## 🎯 配置完成后的优势

### ✅ 解决的问题
- ❌ **不再需要为每个项目配置 Token**
- ❌ **不再担心 Token 丢失**
- ❌ **不再需要安全存储 Token**

### ✅ 获得的好处
- 🔐 **一次配置，永久使用**
- 🏢 **统一管理所有项目**
- 🛡️ **企业级安全**
- 📋 **精细权限控制**

## 🔍 验证配置

### 1. 测试 GitHub App 连接
```bash
# 在 axi-deploy 仓库中手动触发
# .github/workflows/deploy-with-app.yml
```

### 2. 测试业务仓库部署
```bash
# 在业务仓库中推送代码
# 或手动触发部署工作流
```

## 📚 故障排除

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

## 🎉 总结

使用 GitHub App 后，您将拥有：

- 🔐 **永久有效的凭据** - 私钥不会消失
- 🏢 **统一的管理方式** - 一个 App 服务所有项目
- 🛡️ **企业级安全** - 比 Personal Access Token 更安全
- 📋 **精细权限控制** - 只授予必要权限

**从此不再担心 Token 管理问题！**

---

🚀 **立即开始配置 GitHub App，享受无忧的部署体验！** 