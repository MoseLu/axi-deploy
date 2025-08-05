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

在您的项目仓库中创建 `.github/workflows/{仓库名}_deploy.yml` 文件，参考 `examples/` 目录下的示例：

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
              workflow_id: 'central_external_deploy.yml',
              ref: 'main',
              inputs: {
                project: '${{ github.event.repository.name }}',
                source_repo: '${{ github.repository }}',
                run_id: '${{ needs.build.outputs.artifact-id }}',
                deploy_type: 'static',
                nginx_config: 'location /docs/ { alias /srv/static/${{ github.event.repository.name }}/; try_files $uri $uri/ /docs/index.html; }',
                test_url: 'https://redamancy.com.cn/docs/'
              }
            });
            console.log('部署已触发:', response);
```

#### Go 项目示例

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
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
          cache: true
          
      - name: 构建项目
        run: go build -o app main.go
        
      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        id: upload
        with:
          name: app-${{ github.event.repository.name }}
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
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'central_external_deploy.yml',
              ref: 'main',
              inputs: {
                project: '${{ github.event.repository.name }}',
                source_repo: '${{ github.repository }}',
                run_id: '${{ needs.build.outputs.artifact-id }}',
                deploy_type: 'backend',
                start_cmd: './app',
                nginx_config: 'location /api/ { proxy_pass http://127.0.0.1:8080/; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }',
                test_url: 'https://redamancy.com.cn/api/health'
              }
            });
            console.log('部署已触发:', response);
```

## 部署流程

### 1. 构建阶段
- 在业务仓库中构建项目
- 上传构建产物到 GitHub Actions
- 获取构建运行ID

### 2. 触发部署
- 调用中央部署仓库的工作流
- 传递项目信息和构建运行ID
- 自动执行部署流程

### 3. 部署执行
- 下载构建产物
- 上传到服务器指定目录
- 配置Nginx路由（如果提供）
- 执行启动命令（后端项目）
- 测试网站可访问性

## 优势

1. **集中管理** - 所有SSH配置和部署逻辑统一管理
2. **安全可靠** - 业务仓库无需配置敏感信息
3. **易于维护** - 新增项目只需复制示例模板
4. **避免冲突** - 不同项目的配置相互隔离
5. **统一部署** - 通过axi-deploy统一管理所有项目

### Nginx Include配置示例

主域名配置会自动包含所有项目配置：

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name redamancy.com.cn;
    
    # 主项目配置
    location / {
        root /www/wwwroot/axi-star-cloud;
        try_files $uri $uri/ /index.html;
    }
    
    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 包含其他项目配置
    include /www/server/nginx/conf/vhost/includes/*.conf;
}
```

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
│       ├── central_deploy_handler.yml      # 中央部署处理器
│       ├── central_external_deploy.yml     # 外部项目部署工作流
│       └── repository_dispatch_handler.yml # 仓库调度处理器
├── docs/                          # 📚 文档中心
│   ├── workflow-standards/        # 工作流标准
│   ├── guides/                    # 使用指南
│   ├── improvements/              # 改进记录
│   └── README.md                  # 文档索引
├── examples/                      # 多语言项目部署示例
│   ├── backend/                   # 后端项目示例
│   ├── frontend/                  # 前端项目示例
│   └── docs/                      # 文档项目示例
├── README.md                      # 项目说明文档
├── LICENSE                        # 开源许可证
└── .gitignore                     # Git忽略文件
```

## 📚 文档中心

更多详细文档请查看 [docs/](docs/) 目录：

- [📋 工作流标准](docs/workflow-standards/) - 工作流命名规范和标准
- [🔧 使用指南](docs/guides/) - 部署和使用相关指南
- [🚀 改进记录](docs/improvements/) - 项目改进和优化记录
- [📖 详细部署指南](docs/DEPLOYMENT_GUIDE.md) - 完整的部署说明和故障排查

## 工作流重组历史

### 重组目标
将原有的多工作流同时触发模式改为自动化分步骤触发模式，每次部署都会自动触发初始化工作流，提高部署的可控性和安全性。

### 变更内容

#### 删除的工作流
- `axi-star-cloud_deploy.yml` - 特定项目工作流
- `axi-docs_deploy.yml` - 特定项目工作流

#### 新增的工作流
- `server_init.yml` - 服务器初始化工作流（支持自动触发）
- `universal_deploy.yml` - 通用部署工作流（自动包含初始化）

#### 保留的工作流
- `central_deploy_handler.yml` - 中央部署处理器
- `central_external_deploy.yml` - 外部部署处理器
- `repository_dispatch_handler.yml` - 仓库分发处理器（已更新）

### 新的自动化部署流程

#### 步骤1: 自动服务器初始化
- 每次部署前自动执行
- 检查并修复服务器环境
- 验证Nginx配置和证书状态
- 确保目录结构和权限正确

#### 步骤2: 项目部署
- 下载构建产物
- 上传到服务器
- 根据项目类型执行部署
- 配置Nginx路由（如果提供）
- 执行启动命令（后端项目）
- 测试网站可访问性

### 初始化工作流的触发方式

#### 1. 自动触发
- 每次部署前自动调用
- 确保环境状态一致
- 无需手动干预

#### 2. 手动触发
- **灾后自愈**: 检测并修复缺失的目录、配置文件
- **配置变更管理**: 支持声明式配置更新
- **强制重建**: 设置 `force_rebuild: true` 重新生成配置

#### 3. 定时触发
- 每周一凌晨2点自动健康巡检
- 检查证书软链、Nginx配置、防火墙状态
- 发现问题时CI会标红提醒

### 优势

1. **自动化** - 每次部署自动初始化，无需手动干预
2. **可控性** - 分步骤执行，可以独立控制每个环节
3. **安全性** - 初始化步骤自动执行，减少误操作风险
4. **通用性** - 支持任意项目的部署，统一的部署流程
5. **可维护性** - 工作流结构更清晰，代码复用性更高
6. **灾后自愈能力** - 自动检测并修复缺失的目录和配置文件

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个部署系统！

## 许可证

MIT License

<!-- 测试部署 - $(date) -->

## 自动化部署

本项目已配置自动化部署工作流，推送代码到main分支时会自动部署到 `https://redamancy.com.cn/docs/`。

<!-- 触发部署测试 -->