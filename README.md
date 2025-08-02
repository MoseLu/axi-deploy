# AXI Deploy - 通用部署中心

这是一个专门用于多语言项目部署的公共GitHub仓库，其他仓库可以通过GitHub Actions工作流调用此仓库进行远程服务器部署。**本仓库统一管理所有SSH配置和部署逻辑，支持Go、Node.js、Python、Rust、Java等多种语言，其他项目无需配置任何SSH相关参数。**

## 🚀 核心优势

- 🔐 **集中化密钥管理** - 所有SSH配置统一在此仓库
- 🌍 **多语言支持** - 支持Go、Node.js、Python、Rust、Java等
- 🔄 **统一部署流程** - 通过workflow_dispatch实现标准化部署
- 🛡️ **安全可靠** - 业务仓库无需配置敏感信息
- 📦 **极简配置** - 新增项目只需复制示例模板

## 配置要求

### GitHub Secrets 配置

本仓库需要在 GitHub Secrets 中配置以下变量：

| Secret 名称 | 必需 | 描述 | 示例值 |
|-------------|------|------|--------|
| `SERVER_HOST` | ✅ | 服务器主机名或IP地址 | `192.168.1.100` 或 `example.com` |
| `SERVER_PORT` | ✅ | SSH 端口号 | `22` 或 `2222` |
| `SERVER_USER` | ✅ | SSH 用户名 | `root` 或 `deploy` |
| `SERVER_KEY` | ✅ | SSH 私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### 配置步骤

1. **进入仓库设置**: 在 axi-deploy 仓库页面，点击 Settings
2. **找到 Secrets**: 在左侧菜单中点击 "Secrets and variables" → "Actions"
3. **添加 Secrets**: 点击 "New repository secret"，依次添加上述四个 secrets
4. **验证配置**: 确保所有 secrets 都已正确配置

## 使用方法

### 业务仓库配置

在您的项目仓库中创建 `.github/workflows/deploy.yml` 文件，参考 `examples/` 目录下的示例：

#### Node.js 项目示例

## 配置要求

### GitHub Secrets 配置

本仓库需要在 GitHub Secrets 中配置以下变量：

| Secret 名称 | 必需 | 描述 | 示例值 |
|-------------|------|------|--------|
| `SERVER_HOST` | ✅ | 服务器主机名或IP地址 | `192.168.1.100` 或 `example.com` |
| `SERVER_PORT` | ✅ | SSH 端口号 | `22` 或 `2222` |
| `SERVER_USER` | ✅ | SSH 用户名 | `root` 或 `deploy` |
| `SERVER_KEY` | ✅ | SSH 私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### 配置步骤

1. **进入仓库设置**: 在 axi-deploy 仓库页面，点击 Settings
2. **找到 Secrets**: 在左侧菜单中点击 "Secrets and variables" → "Actions"
3. **添加 Secrets**: 点击 "New repository secret"，依次添加上述四个 secrets
4. **验证配置**: 确保所有 secrets 都已正确配置

## 使用方法

<<<<<<< Updated upstream
### 🎯 多语言项目部署示例

#### 1. Node.js 项目

在您的Node.js项目仓库中创建 `.github/workflows/deploy.yml` 文件：
=======
### 业务仓库配置

在您的项目仓库中创建 `.github/workflows/deploy.yml` 文件，参考 `examples/` 目录下的示例：

#### Node.js 项目示例
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
          name: dist-${{ github.event.repository.name }}
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
<<<<<<< Updated upstream
                project: '${{ github.event.repository.name }}',
                lang: 'node',
                artifact_id: '${{ needs.build.outputs.artifact-id }}',
                deploy_path: '/www/wwwroot/${{ github.event.repository.name }}',
                start_cmd: 'cd /www/wwwroot/${{ github.event.repository.name }} && npm ci --production && pm2 reload ecosystem.config.js',
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                server_host: '${{ secrets.SERVER_HOST }}',
                server_port: '${{ secrets.SERVER_PORT }}',
                server_user: '${{ secrets.SERVER_USER }}',
                server_key: '${{ secrets.SERVER_SSH_KEY }}'
              }
            });
            console.log('✅ 部署已触发:', response);
```

<<<<<<< Updated upstream
#### 2. Go 项目

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

#### 3. Python 项目

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

### 🔧 业务仓库配置

#### 1. Token 管理方案

**强烈推荐：GitHub App（永久有效）**

GitHub App 解决了 Personal Access Token 只显示一次的问题：

1. **创建 GitHub App**
   - 访问 https://github.com/settings/apps
   - 点击 "New GitHub App"
   - 配置必要权限（Contents、Actions、Workflows 的 Read 权限）
   - 安装到目标组织

2. **获取 App 凭据**
   - 记录 App ID
   - 生成私钥（永久保存）
   - 获取 Installation ID

3. **配置部署仓库**
   - 在 `axi-deploy` 仓库中添加 GitHub App 相关 Secrets
   - 使用新的部署工作流 `deploy-with-app.yml`

4. **业务仓库配置**
   - **业务仓库不再需要配置任何 Token！**
   - 只需要调用新的部署工作流

**详细配置指南：**
- **快速配置**：详见 `GITHUB_APP_QUICK_SETUP.md`
- **详细文档**：详见 `GITHUB_APP_SETUP.md`
- **Token 管理**：详见 `TOKEN_MANAGEMENT.md`

#### 2. 修改配置
=======
### 业务仓库需要配置的 Secret

| Secret 名称 | 描述 |
|-------------|------|
| `DEPLOY_CENTER_PAT` | GitHub Personal Access Token，用于调用部署中心 |
| `SERVER_HOST` | 服务器主机名或IP地址 |
| `SERVER_PORT` | SSH端口号 |
| `SERVER_USER` | SSH用户名 |
| `SERVER_SSH_KEY` | SSH私钥内容 |

### 修改配置参数
>>>>>>> Stashed changes

在示例代码中，需要修改以下参数：

- `owner`: 改为您的GitHub用户名或组织名
- `repo`: 改为您的部署仓库名（如 `axi-deploy`）
<<<<<<< Updated upstream
- `project`: 改为您的项目名
- `deploy_path`: 改为您的服务器部署路径
- `start_cmd`: 改为您的启动命令

## 部署流程

1. **业务仓库构建**: 构建项目并上传产物
2. **触发部署**: 调用公共仓库的 workflow_dispatch
3. **公共仓库执行**: 下载产物并部署到服务器
4. **启动应用**: 执行指定的启动命令
=======
- `deploy_path`: 改为您的服务器部署路径（可选，默认使用 `/www/wwwroot/仓库名`）
- `start_cmd`: 改为您的启动命令（可选，默认使用仓库名作为服务名）

**注意**: 
- `project` 参数会自动使用仓库名称，无需手动修改
- 所有项目默认部署到 `/www/wwwroot/` 目录下，每个项目使用仓库名作为子目录
>>>>>>> Stashed changes

## 支持的语言

| 语言 | 构建命令 | 启动命令示例 |
|------|----------|-------------|
| Node.js | `npm run build` | `npm ci --production && pm2 reload app` |
| Go | `go build -o app` | `chmod +x app && systemctl restart app` |
| Python | 无需构建 | `pip install -r requirements.txt && systemctl restart app` |
| Rust | `cargo build --release` | `chmod +x app && systemctl restart app` |
| Java | `mvn clean package` | `java -jar app.jar` |
<<<<<<< Updated upstream
=======
| **静态网站** | `pnpm docs:build` 或 `npm run build` | 无需启动命令 |
>>>>>>> Stashed changes

## 示例文件

查看 `examples/` 目录下的完整示例：

- `node-project-deploy.yml` - Node.js项目部署示例
- `go-project-deploy.yml` - Go项目部署示例  
- `python-project-deploy.yml` - Python项目部署示例
- `rust-project-deploy.yml` - Rust项目部署示例
<<<<<<< Updated upstream
=======
- `vitepress-project-deploy.yml` - VitePress静态网站部署示例
- `vue-project-deploy.yml` - Vue.js静态网站部署示例
- `react-project-deploy.yml` - React静态网站部署示例

## 部署流程

1. **业务仓库构建**: 构建项目并上传产物
2. **触发部署**: 调用公共仓库的 workflow_dispatch
3. **公共仓库执行**: 下载产物并部署到服务器
4. **启动应用**: 执行指定的启动命令

## 服务器目录结构

所有项目统一部署到 `/www/wwwroot/` 目录下：

```
/www/wwwroot/
├── project-a/          # 项目A的部署目录
│   ├── app            # Go应用可执行文件
│   └── ...
├── project-b/          # 项目B的部署目录
│   ├── dist/          # Node.js构建产物
│   └── ...
├── project-c/          # 项目C的部署目录
│   ├── .vitepress/    # VitePress静态文件
│   └── ...
└── ...
```

每个项目使用其GitHub仓库名称作为子目录，确保项目间相互隔离。
>>>>>>> Stashed changes

## 故障排除

### 常见问题

1. **SSH连接失败**
   - 检查 `SERVER_HOST`、`SERVER_PORT`、`SERVER_USER` 配置
   - 验证 `SERVER_KEY` 私钥格式是否正确

2. **权限不足**
   - 确保服务器用户有目标目录的写入权限
   - 检查启动命令的执行权限

3. **构建产物下载失败**
   - 确认 `artifact_id` 参数正确
   - 检查构建产物名称是否匹配

### 调试方法

1. 查看公共仓库的 Actions 日志
2. 检查业务仓库的构建日志
3. 验证服务器上的文件传输情况

<<<<<<< Updated upstream
## 📚 相关文档

- [GitHub App 快速配置](GITHUB_APP_QUICK_SETUP.md) - **推荐：解决 Token 管理问题**
- [GitHub App 详细设置](GITHUB_APP_SETUP.md) - 企业级部署方案
- [Token 管理解决方案](TOKEN_MANAGEMENT.md) - 传统 Token 管理方案
- [快速开始指南](QUICKSTART.md) - 快速配置部署系统
- [部署场景指南](examples/deployment-scenarios.md) - 不同语言项目部署示例
=======
## 项目结构

```
axi-deploy/
├── .github/
│   └── workflows/
│       ├── deploy.yml          # 核心部署工作流
│       └── test-connection.yml # SSH连接测试
├── examples/                   # 多语言项目部署示例
│   ├── node-project-deploy.yml
│   ├── go-project-deploy.yml
│   ├── python-project-deploy.yml
│   ├── rust-project-deploy.yml
│   ├── vitepress-project-deploy.yml
│   ├── vue-project-deploy.yml
│   └── react-project-deploy.yml
├── README.md                   # 项目说明文档
├── CHANGELOG.md               # 更新日志
├── LICENSE                    # 开源许可证
└── .gitignore                # Git忽略文件
```
>>>>>>> Stashed changes

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个部署系统！

## 许可证

MIT License