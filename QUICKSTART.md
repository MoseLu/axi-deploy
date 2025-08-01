# 🚀 快速开始 - 多语言部署系统

本指南将帮助您快速设置和使用 AXI Deploy 多语言部署系统。

## 📋 前置要求

1. **GitHub 账户**
2. **服务器访问权限**（SSH 密钥）
3. **业务项目仓库**

## 🔧 第一步：配置公共仓库

### 1.1 配置 GitHub Secrets

在 `axi-deploy` 仓库中配置以下 Secrets：

| Secret 名称 | 描述 | 示例值 |
|-------------|------|--------|
| `SERVER_HOST` | 服务器IP或域名 | `192.168.1.100` |
| `SERVER_PORT` | SSH端口 | `22` |
| `SERVER_USER` | SSH用户名 | `root` |
| `SERVER_KEY` | SSH私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

**配置步骤：**
1. 进入 `axi-deploy` 仓库
2. 点击 Settings → Secrets and variables → Actions
3. 点击 "New repository secret"
4. 依次添加上述四个 secrets

### 1.2 验证配置

运行测试连接工作流验证配置是否正确：

```yaml
# 在 axi-deploy 仓库中手动触发
# .github/workflows/test-connection.yml
```

## 🔧 第二步：配置业务仓库

### 2.1 获取 Personal Access Token

1. 访问 GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 点击 "Generate new token (classic)"
3. 勾选 `repo` 权限
4. 复制生成的 token

### 2.2 配置业务仓库 Secrets

在您的业务仓库中添加：

| Secret 名称 | 描述 |
|-------------|------|
| `DEPLOY_CENTER_PAT` | 刚才生成的 Personal Access Token |

## 🎯 第三步：选择语言模板

根据您的项目语言，选择对应的部署模板：

### Node.js 项目

复制 `examples/node-project-deploy.yml` 到您的项目：

```yaml
name: Build & Deploy Node.js Project

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
          name: dist-my-node-app
          path: dist/
          retention-days: 1

  trigger-deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.DEPLOY_CENTER_PAT }}
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'your-org',
              repo: 'axi-deploy',
              workflow_id: 'deploy.yml',
              ref: 'main',
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
            });
            console.log('✅ 部署已触发:', response);
```

### Go 项目

复制 `examples/go-project-deploy.yml` 到您的项目：

```yaml
name: Build & Deploy Go Project

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

  trigger-deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.DEPLOY_CENTER_PAT }}
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'your-org',
              repo: 'axi-deploy',
              workflow_id: 'deploy.yml',
              ref: 'main',
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
            });
            console.log('✅ 部署已触发:', response);
```

### Python 项目

复制 `examples/python-project-deploy.yml` 到您的项目：

```yaml
name: Build & Deploy Python Project

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

  trigger-deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.DEPLOY_CENTER_PAT }}
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'your-org',
              repo: 'axi-deploy',
              workflow_id: 'deploy.yml',
              ref: 'main',
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
            });
            console.log('✅ 部署已触发:', response);
```

## 🔧 第四步：修改配置

在您选择的模板中，需要修改以下参数：

### 必需修改的参数

| 参数 | 描述 | 示例 |
|------|------|------|
| `owner` | GitHub用户名或组织名 | `your-username` 或 `your-org` |
| `repo` | 部署仓库名 | `axi-deploy` |
| `project` | 项目标识 | `my-app` |
| `deploy_path` | 服务器部署路径 | `/www/wwwroot/my-app` |
| `start_cmd` | 启动命令 | `cd /www/wwwroot/my-app && npm ci --production && pm2 reload app` |

### 可选修改的参数

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `node-version` | Node.js版本 | `20` |
| `go-version` | Go版本 | `1.22` |
| `python-version` | Python版本 | `3.11` |
| `artifact-name` | 构建产物名称 | `dist-my-app` |

## 🚀 第五步：测试部署

1. **提交代码**：将工作流文件提交到您的仓库
2. **触发构建**：推送到 `main` 或 `master` 分支
3. **查看日志**：
   - 在业务仓库查看构建日志
   - 在 `axi-deploy` 仓库查看部署日志
4. **验证部署**：检查服务器上的应用是否正常运行

## 🔍 故障排除

### 常见问题

1. **SSH连接失败**
   ```
   检查 axi-deploy 仓库的 Secrets 配置
   ```

2. **构建失败**
   ```
   检查业务仓库的构建配置和依赖
   ```

3. **部署失败**
   ```
   检查服务器路径权限和启动命令
   ```

### 调试步骤

1. 查看业务仓库的 Actions 日志
2. 查看 `axi-deploy` 仓库的 Actions 日志
3. 检查服务器上的文件传输情况
4. 验证启动命令的执行权限

## 📚 更多资源

- [完整文档](README.md)
- [示例文件](examples/)
- [部署脚本](scripts/)

## 🆘 获取帮助

如果遇到问题，请：

1. 查看 [故障排除](README.md#故障排除) 部分
2. 提交 [Issue](https://github.com/your-org/axi-deploy/issues)
3. 查看 [Actions 日志](https://github.com/your-org/axi-deploy/actions)

---

🎉 **恭喜！** 您已经成功设置了多语言部署系统。现在可以享受集中化、安全、高效的部署体验了！ 