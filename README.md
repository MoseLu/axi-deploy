# Axi Deploy - 统一部署中心

## 概述

Axi Deploy 是一个统一的部署中心，用于管理多个项目的自动化部署。支持静态网站和后端服务的部署，并提供完整的 Nginx 配置管理。

## 最新更新

### 🚀 工作流链重构 (v3.0)

**主要改进：**
- ✅ 拆分为模块化的工作流链，提高可维护性
- ✅ 完整的10步部署流程，包含所有必要步骤
- ✅ 智能条件执行，支持可选步骤跳过
- ✅ 全面的错误处理和重试机制
- ✅ 支持Go、Python等后端服务启动

**新的工作流结构：**
```
外部请求 → repository_dispatch_handler.yml
                ↓
         main-deployment.yml
                ↓
      deployment-orchestrator.yml
                ↓
    ┌─────────────────────────────────┐
    │ 1. download-artifact.yml       │ ← 检出代码、下载构建产物、显示信息
    │ 2. upload-files.yml            │ ← 上传到服务器、验证上传
    │ 3. deploy-project.yml          │ ← 部署到服务器
    │ 4. configure-nginx.yml (可选)  │ ← 配置Nginx
    │ 5. start-service.yml (可选)    │ ← 执行启动命令
    │ 6. test-website.yml (可选)     │ ← 测试网站可访问性
    │ 7. deployment-summary          │ ← 部署完成通知
    └─────────────────────────────────┘
```

## 支持的部署类型

### 1. 静态项目 (static)
- VitePress 文档站点
- Vue/React 前端应用
- 静态 HTML 网站

### 2. 后端项目 (backend)
- Go 后端服务
- Node.js 应用
- Python 应用

## 工作流文件说明

### 主入口工作流

#### `main-deployment.yml`
- **作用**: 整个部署流程的主入口点
- **触发方式**: `workflow_dispatch` (手动触发)
- **功能**: 接收部署参数并调用部署编排器

#### `repository_dispatch_handler.yml`
- **作用**: 处理来自其他仓库的部署请求
- **触发方式**: `repository_dispatch` (外部仓库触发)
- **功能**: 接收外部部署请求并触发主部署工作流

### 部署编排器

#### `deployment-orchestrator.yml`
- **作用**: 协调整个部署流程
- **触发方式**: `workflow_call` (被其他工作流调用)
- **功能**: 按顺序调用各个部署步骤

### 核心部署步骤

#### `download-artifact.yml`
- **作用**: 下载构建产物
- **功能**: 
  - 检出代码
  - 从源仓库下载构建产物
  - 验证产物完整性
  - 显示构建产物信息
  - 输出产物路径和大小

#### `upload-files.yml`
- **作用**: 上传文件到服务器
- **功能**: 
  - 上传构建产物到服务器临时目录
  - 验证上传结果
  - 重试机制
  - 输出临时目录路径

#### `deploy-project.yml`
- **作用**: 部署项目到服务器
- **功能**:
  - 备份现有部署
  - 从临时目录部署到目标目录
  - 设置文件权限
  - 验证部署结果
  - 清理临时目录
  - 输出部署路径

#### `configure-nginx.yml`
- **作用**: 配置Nginx
- **功能**:
  - 生成Nginx配置
  - 验证配置语法
  - 应用配置到服务器

#### `start-service.yml`
- **作用**: 执行启动命令（后端项目）
- **功能**:
  - 执行自定义启动命令
  - 检查服务状态
  - 等待服务启动
  - 支持Go、Python等后端服务

#### `test-website.yml`
- **作用**: 测试网站可访问性
- **功能**:
  - HTTP/HTTPS访问测试
  - Nginx配置验证
  - 部署文件检查
  - 错误诊断

## 详细步骤说明

### 步骤1: 检出代码和下载构建产物
- ✅ 检出代码 (`actions/checkout@v4`)
- ✅ 下载构建产物 (`dawidd6/action-download-artifact@v2`)
- ✅ 验证构建产物完整性
- ✅ 显示构建产物信息

### 步骤2: 上传到服务器
- ✅ 创建服务器临时目录
- ✅ 上传文件到服务器 (带重试机制)
- ✅ 验证上传结果

### 步骤3: 部署到服务器
- ✅ 备份现有部署
- ✅ 从临时目录部署到目标目录
- ✅ 设置文件权限
- ✅ 验证部署结果
- ✅ 清理临时目录

### 步骤4: 配置Nginx (可选)
- ✅ 生成Nginx配置
- ✅ 验证配置语法
- ✅ 应用配置到服务器

### 步骤5: 执行启动命令 (可选，后端项目)
- ✅ 执行自定义启动命令
- ✅ 检查服务状态
- ✅ 等待服务启动
- ✅ 支持Go、Python等后端服务

### 步骤6: 测试网站可访问性 (可选)
- ✅ HTTP/HTTPS访问测试
- ✅ Nginx配置验证
- ✅ 部署文件检查
- ✅ 错误诊断

### 步骤7: 部署完成通知
- ✅ 显示部署摘要
- ✅ 报告各步骤执行状态
- ✅ 显示访问信息

## 快速开始

### 1. 配置项目部署

#### 静态项目配置示例

```yaml
# .github/workflows/deploy.yml
name: Build & Deploy

on:
  push:
    branches: [main, master]
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
          node-version: '20'
          cache: 'npm'

      - name: 安装依赖并构建
        run: |
          npm ci
          npm run build

      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.event.repository.name }}
          path: dist/
          retention-days: 1

  deploy:
    needs: build
    uses: MoseLu/axi-deploy/.github/workflows/main-deployment.yml@master
    with:
      project: ${{ github.event.repository.name }}
      source_repo: ${{ github.repository }}
      run_id: ${{ github.run_id }}
      deploy_type: static
      nginx_config: |
        location /your-path/ {
            alias /srv/static/${{ github.event.repository.name }}/;
            try_files $uri $uri/ /your-path/index.html;
            
            # 静态资源缓存
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }
      test_url: https://your-domain.com/your-path/
    secrets:
      SERVER_HOST: ${{ secrets.SERVER_HOST }}
      SERVER_PORT: ${{ secrets.SERVER_PORT }}
      SERVER_USER: ${{ secrets.SERVER_USER }}
      SERVER_KEY: ${{ secrets.SERVER_KEY }}
```

#### 后端项目配置示例

```yaml
# .github/workflows/deploy.yml
name: Build & Deploy

on:
  push:
    branches: [main, master]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
        
      - name: 设置 Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.23.4'
          cache: true
          
      - name: 构建项目
        run: |
          cd backend
          go mod tidy
          CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app main.go
          
      - name: 打包部署文件
        run: |
          tar czf deployment.tar.gz \
            backend/app \
            front/ \
            index.html \
            backend/config/ \
            app.service
          
      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.event.repository.name }}
          path: deployment.tar.gz
          retention-days: 1

  deploy:
    needs: build
    uses: MoseLu/axi-deploy/.github/workflows/main-deployment.yml@master
    with:
      project: ${{ github.event.repository.name }}
      source_repo: ${{ github.repository }}
      run_id: ${{ github.run_id }}
      deploy_type: backend
      nginx_config: |
        location /api/ {
            proxy_pass http://127.0.0.1:8080/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            client_max_body_size 100M;
        }
        
        location /health {
            proxy_pass http://127.0.0.1:8080/health;
            proxy_set_header Host $host;
        }
        
        location / {
            root /srv/apps/${{ github.event.repository.name }}/front;
            try_files $uri $uri/ /index.html;
            
            # 静态资源缓存
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }
      test_url: https://your-domain.com/
      start_cmd: sudo systemctl daemon-reload; sudo systemctl enable star-cloud.service; sudo systemctl restart star-cloud.service
    secrets:
      SERVER_HOST: ${{ secrets.SERVER_HOST }}
      SERVER_PORT: ${{ secrets.SERVER_PORT }}
      SERVER_USER: ${{ secrets.SERVER_USER }}
      SERVER_KEY: ${{ secrets.SERVER_KEY }}
```

### 2. 配置服务器密钥

在项目仓库的 Settings > Secrets and variables > Actions 中添加以下密钥：

#### 必需的 Secrets
- `SERVER_KEY`: 服务器SSH私钥

#### 必需的 Variables
- `SERVER_HOST`: 服务器地址
- `SERVER_USER`: 服务器用户名
- `SERVER_PORT`: 服务器SSH端口

### 3. 手动触发部署

在 GitHub Actions 页面手动触发 `main-deployment.yml`，填写必要参数：

- `project`: 项目名称
- `source_repo`: 源仓库 (格式: owner/repo)
- `run_id`: 构建运行ID
- `deploy_type`: 部署类型 (static/backend)
- `nginx_config`: Nginx配置（可选）
- `test_url`: 测试URL（可选）
- `start_cmd`: 启动命令（后端项目，可选）
- 其他可选参数...

### 4. 外部仓库触发部署

从其他仓库发送 `repository_dispatch` 事件到本仓库：

```javascript
// 示例：从其他仓库触发部署
await github.rest.repos.createDispatchEvent({
  owner: 'MoseLu',
  repo: 'axi-deploy',
  event_type: 'deploy',
  client_payload: {
    // 必需参数
    project: 'my-project',
    source_repo: 'owner/repo',
    run_id: '1234567890',
    server_host: 'your-server.com',
    server_user: 'deploy',
    server_key: 'your-ssh-private-key',
    server_port: '22',
    deploy_center_pat: 'your-github-token',
    
    // 可选参数
    deploy_type: 'static',
    nginx_config: 'server { ... }',
    test_url: 'https://example.com/',
    start_cmd: 'sudo systemctl restart my-service'
  }
});
```

**支持的参数说明：**

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `project` | string | ✅ | 项目名称 |
| `source_repo` | string | ✅ | 源仓库 (格式: owner/repo) |
| `run_id` | string | ✅ | 构建运行ID |
| `server_host` | string | ✅ | 服务器地址 |
| `server_user` | string | ✅ | 服务器用户名 |
| `server_key` | string | ✅ | 服务器SSH私钥 |
| `server_port` | string | ✅ | 服务器SSH端口 |
| `deploy_type` | string | ❌ | 部署类型 (static/backend，默认: static) |
| `nginx_config` | string | ❌ | Nginx配置 |
| `test_url` | string | ❌ | 测试URL |
| `start_cmd` | string | ❌ | 启动命令（后端项目） |
| `deploy_center_pat` | string | ❌ | GitHub Token (用于下载构建产物) |

## 部署流程

### 静态项目部署流程

1. **检出代码和下载构建产物** → 从源仓库下载
2. **上传到服务器** → `/tmp/<project>/`
3. **验证上传** → 检查文件完整性
4. **部署到服务器** → `/srv/static/<project>/`
5. **配置 Nginx 路由** (可选)
6. **测试网站可访问性** (可选)
7. **部署完成通知**

### 后端项目部署流程

1. **检出代码和下载构建产物** → 从源仓库下载
2. **上传到服务器** → `/tmp/<project>/`
3. **验证上传** → 检查文件完整性
4. **部署到服务器** → `/srv/apps/<project>/`
5. **配置 Nginx 路由** (可选)
6. **执行启动命令** (可选) → 启动Go/Python服务
7. **测试网站可访问性** (可选)
8. **部署完成通知**

## 验证部署

### 使用验证脚本

```bash
# 在服务器上运行验证脚本
sudo bash /path/to/verify_deployment.sh
```

验证脚本会检查：
- ✅ 目录结构是否正确
- ✅ 文件交叉污染
- ✅ 服务状态
- ✅ 端口占用
- ✅ 健康检查
- ✅ Nginx 配置
- ✅ SSL 证书
- ✅ 网站访问

### 手动验证

```bash
# 检查目录结构
ls -la /srv/apps/axi-star-cloud/
ls -la /srv/static/axi-docs/

# 检查服务状态
sudo systemctl status star-cloud.service
sudo systemctl status nginx

# 检查端口
sudo netstat -tlnp | grep -E ":(80|443|8080)"

# 测试健康检查
curl -f http://127.0.0.1:8080/health

# 测试网站访问
curl -I https://your-domain.com/
```

## 目录结构

```
/srv/
├── apps/                    # 后端项目目录
│   └── axi-star-cloud/     # 后端项目
│       ├── star-cloud-linux
│       ├── star-cloud.service
│       ├── backend/
│       ├── front/
│       ├── uploads/
│       └── logs/
└── static/                  # 静态项目目录
    └── axi-docs/           # 静态项目
        ├── index.html
        ├── assets/
        └── ...

/www/server/nginx/conf/conf.d/redamancy/
├── 00-main.conf           # 主配置文件
├── route-axi-star-cloud.conf  # 后端项目路由
└── route-axi-docs.conf        # 静态项目路由
```

## 功能特性

### 1. 完整的部署流程
- ✅ 检出代码
- ✅ 下载构建产物
- ✅ 显示构建产物信息
- ✅ 上传到服务器
- ✅ 验证上传
- ✅ 部署到服务器
- ✅ 配置Nginx
- ✅ 执行启动命令（后端项目）
- ✅ 测试网站可访问性
- ✅ 部署完成通知

### 2. 智能条件执行
- 根据部署类型自动选择执行步骤
- 可选参数支持跳过相应步骤
- 错误处理和状态报告

### 3. 全面的测试验证
- HTTP/HTTPS访问测试
- Nginx配置语法检查
- 部署文件完整性验证
- 服务状态检查

### 4. 后端服务支持
- Go服务启动和重启
- Python服务启动
- 系统服务管理
- 服务状态检查

## 优势

1. **模块化**: 每个工作流专注于特定功能
2. **可重用**: 各个步骤可以独立调用
3. **可维护**: 问题定位更容易
4. **灵活性**: 可以根据需要跳过某些步骤
5. **可扩展**: 易于添加新的部署步骤
6. **完整性**: 包含原通用工作流的所有功能
7. **可靠性**: 包含重试机制和错误处理

## 故障排除

### 常见问题

1. **工作流调用失败**
   - 检查可重用工作流的路径是否正确
   - 确认输入参数是否匹配

2. **权限问题**
   - 确认GitHub Token权限
   - 检查服务器SSH密钥配置

3. **构建产物下载失败**
   - 确认源仓库和构建ID正确
   - 检查构建产物名称是否匹配

4. **文件上传失败**
   - 检查服务器连接
   - 确认临时目录权限
   - 查看重试日志

5. **网站测试失败**
   - 检查域名解析
   - 验证Nginx配置
   - 确认SSL证书状态
   - 检查防火墙设置

6. **服务启动失败**
   - 检查启动命令语法
   - 确认服务依赖
   - 查看系统日志

### 调试方法

1. 查看各个工作流的执行日志
2. 检查 `deployment-summary` 步骤的输出
3. 验证服务器连接和权限
4. 使用 `test-website.yml` 进行诊断
5. 检查Nginx错误日志
6. 查看服务器临时目录和部署目录

## 配置参数

### main-deployment.yml 参数

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `project` | string | ✅ | 项目名称 |
| `source_repo` | string | ✅ | 源仓库 (格式: owner/repo) |
| `run_id` | string | ✅ | 构建运行ID |
| `deploy_type` | choice | ✅ | 部署类型 (static/backend) |
| `nginx_config` | string | ❌ | Nginx配置 |
| `test_url` | string | ❌ | 测试URL |
| `start_cmd` | string | ❌ | 启动命令（后端项目） |
| `domain` | string | ❌ | 域名 |
| `apps_root` | string | ❌ | 应用目录路径 |
| `static_root` | string | ❌ | 静态文件目录路径 |
| `backup_root` | string | ❌ | 备份根目录 |
| `run_user` | string | ❌ | 运行用户 |
| `nginx_conf_dir` | string | ❌ | Nginx配置目录 |
| `backend_port` | string | ❌ | 后端服务端口 |
| `service_name` | string | ❌ | 服务名称 |

## 示例项目

### 静态项目
- [axi-docs](https://github.com/MoseLu/axi-docs) - VitePress 文档站点

### 后端项目
- [axi-star-cloud](https://github.com/MoseLu/axi-star-cloud) - Go 后端服务

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个部署中心。

## 许可证

MIT License

## 重要说明

### 可复用工作流的 Secrets 限制

**⚠️ 重要限制**：可复用工作流（reusable workflows）无法直接访问调用者仓库的 secrets。这是 GitHub Actions 的安全限制。

**解决方案**：
1. **通过输入参数传递**：所有必需的 secrets 必须通过 `inputs` 参数传递
2. **业务仓库配置**：业务仓库需要在触发部署时提供所有必需的参数
3. **参数验证**：工作流会验证所有必需参数是否已提供

### 必需的参数

当从业务仓库触发部署时，必须提供以下参数：

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `project` | string | ✅ | 项目名称 |
| `source_repo` | string | ✅ | 源仓库 (格式: owner/repo) |
| `run_id` | string | ✅ | 构建运行ID |
| `server_host` | string | ✅ | 服务器地址 |
| `server_user` | string | ✅ | 服务器用户名 |
| `server_key` | string | ✅ | 服务器SSH私钥 |
| `server_port` | string | ✅ | 服务器SSH端口 |
| `deploy_center_pat` | string | ✅ | GitHub Token (用于下载构建产物) |
| `deploy_type` | string | ❌ | 部署类型 (static/backend，默认: static) |
| `nginx_config` | string | ❌ | Nginx配置 |
| `test_url` | string | ❌ | 测试URL |
| `start_cmd` | string | ❌ | 启动命令（后端项目） |