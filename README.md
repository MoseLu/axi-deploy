# AXI Deploy - 通用部署中心

这是一个专门用于多语言项目部署的公共GitHub仓库，其他仓库可以通过GitHub Actions工作流调用此仓库进行远程服务器部署。**本仓库统一管理所有SSH配置和部署逻辑，支持Go、Node.js、Python、Vue、React、VitePress等多种语言，其他项目无需配置任何SSH相关参数。**

## 🚀 核心优势

- 🔐 **集中化密钥管理** - 所有SSH配置统一在此仓库
- 🌍 **多语言支持** - 支持Go、Node.js、Python、Vue、React、VitePress等
- 🔄 **统一部署流程** - 通过workflow_dispatch实现标准化部署
- 🛡️ **安全可靠** - 业务仓库无需配置敏感信息
- 📦 **极简配置** - 新增项目只需复制示例模板

## 配置要求

### 中央部署仓库 (axi-deploy) Secrets 配置

本仓库需要在 GitHub Secrets 中配置以下变量：

| Secret 名称 | 必需 | 描述 | 示例值 |
|-------------|------|------|--------|
| `SERVER_HOST` | ✅ | 服务器主机名或IP地址 | `192.168.1.100` 或 `example.com` |
| `SERVER_PORT` | ✅ | SSH 端口号 | `22` 或 `2222` |
| `SERVER_USER` | ✅ | SSH 用户名 | `root` 或 `deploy` |
| `SERVER_KEY` | ✅ | SSH 私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### 业务仓库 Secrets 配置

业务仓库需要配置以下 Secret：

| Secret 名称 | 描述 | 权限要求 |
|-------------|------|----------|
| `DEPLOY_CENTER_PAT` | GitHub Personal Access Token，用于调用部署中心 | `repo`, `workflow` |
| `SERVER_HOST` | 服务器主机名或IP地址 | - |
| `SERVER_PORT` | SSH端口号 | - |
| `SERVER_USER` | SSH用户名 | - |
| `SERVER_KEY` | SSH私钥内容 | - |

**重要**: `DEPLOY_CENTER_PAT` 需要以下权限：
- `repo` - 访问私有仓库
- `workflow` - 触发工作流

## 使用方法

### 业务仓库配置

在您的项目仓库中创建 `.github/workflows/deploy.yml` 文件，参考 `examples/` 目录下的示例：

#### VitePress 项目示例

```yaml
name: Build & Deploy VitePress Project

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
        run: npm run docs:build
        
      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        id: upload
        with:
          name: dist-${{ github.event.repository.name }}
          path: docs/.vitepress/dist/
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
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'external-deploy.yml',
              ref: 'master',
              inputs: {
                project: '${{ github.event.repository.name }}',
                lang: 'static',
                artifact_id: '${{ needs.build.outputs.artifact-id }}',
                deploy_path: '/www/wwwroot/${{ github.event.repository.name }}',
                start_cmd: 'echo "静态网站部署完成，无需启动命令"',
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                server_host: '${{ secrets.SERVER_HOST }}',
                server_port: '${{ secrets.SERVER_PORT }}',
                server_user: '${{ secrets.SERVER_USER }}',
                server_key: '${{ secrets.SERVER_KEY }}'
              }
            });
            console.log('✅ 部署已触发:', response);
```

### 修改配置参数

在示例代码中，需要修改以下参数：

- `owner`: 改为您的GitHub用户名或组织名
- `repo`: 改为您的部署仓库名（如 `axi-deploy`）
- `workflow_id`: 改为 `external-deploy.yml`
- `deploy_path`: 改为您的服务器部署路径（可选，默认使用 `/www/wwwroot/仓库名`）
- `start_cmd`: 改为您的启动命令（可选，默认使用仓库名作为服务名）

**注意**: 
- `project` 参数会自动使用仓库名称，无需手动修改
- 所有项目默认部署到 `/www/wwwroot/` 目录下，每个项目使用仓库名作为子目录

## 支持的语言

| 语言 | 构建命令 | 启动命令示例 | 示例文件 |
|------|----------|-------------|----------|
| Node.js | `npm run build` | `npm ci --production && pm2 reload app` | `node-project-deploy.yml` |
| Go | `go build -o app` | `chmod +x app && systemctl restart app` | `go-project-deploy.yml` |
| Python | 无需构建 | `pip install -r requirements.txt && systemctl restart app` | `python-project-deploy.yml` |
| **Vue.js** | `npm run build` | 无需启动命令 | `vue-project-deploy.yml` |
| **React** | `npm run build` | 无需启动命令 | `react-project-deploy.yml` |
| **VitePress** | `npm run docs:build` | 无需启动命令 | `vitepress-project-deploy.yml` |

## 示例文件

查看 `examples/` 目录下的完整示例：

- `node-project-deploy.yml` - Node.js项目部署示例
- `go-project-deploy.yml` - Go项目部署示例  
- `python-project-deploy.yml` - Python项目部署示例
- `vue-project-deploy.yml` - Vue.js静态网站部署示例
- `react-project-deploy.yml` - React静态网站部署示例
- `vitepress-project-deploy.yml` - VitePress静态网站部署示例

## 部署流程

1. **业务仓库构建**: 构建项目并上传产物
2. **触发部署**: 使用 `DEPLOY_CENTER_PAT` 调用中央部署仓库的 `external-deploy.yml`
3. **中央部署仓库执行**: 从调用者仓库下载产物并部署到服务器
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

4. **工作流触发失败**
   - 确保 `DEPLOY_CENTER_PAT` 有正确的权限（`repo`, `workflow`）
   - 检查工作流ID是否正确（应该是 `external-deploy.yml`）

### 调试方法

1. 查看中央部署仓库的 Actions 日志
2. 检查业务仓库的构建日志
3. 验证服务器上的文件传输情况

## 项目结构

```
axi-deploy/
├── .github/
│   └── workflows/
│       ├── deploy.yml              # 内部部署工作流
│       └── external-deploy.yml     # 外部调用部署工作流
├── examples/                       # 多语言项目部署示例
│   ├── node-project-deploy.yml
│   ├── go-project-deploy.yml
│   ├── python-project-deploy.yml
│   ├── vue-project-deploy.yml
│   ├── react-project-deploy.yml
│   └── vitepress-project-deploy.yml
├── README.md                       # 项目说明文档
├── CHANGELOG.md                   # 更新日志
├── LICENSE                        # 开源许可证
└── .gitignore                     # Git忽略文件
```

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个部署系统！

## 许可证

MIT License

<!-- 测试部署 - $(date) -->