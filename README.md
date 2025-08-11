# Axi Deploy - 统一部署中心

## 概述

Axi Deploy 是一个统一的部署中心，用于管理多个项目的自动化部署。支持静态网站和后端服务的部署，并提供完整的 Nginx 配置管理。

## 最新更新

### 🚀 工作流优化重构 (v4.1)

**主要改进：**
- ✅ 优化为16个模块化工作流，减少冗余提高效率
- ✅ 删除5个重复工作流，提高维护性
- ✅ 增强 validate-artifact.yml 的诊断功能
- ✅ 完整的部署流程，包含核心功能和可选增强功能
- ✅ 智能条件执行，支持可选步骤跳过
- ✅ 全面的错误处理和重试机制
- ✅ **新增**: deploy-project.yml 完整重试机制，解决 timeout i/o 问题
- ✅ 支持Go、Python等后端服务启动
- ✅ 完整的运维监控和故障恢复功能

**优化后的工作流结构：**

```
外部请求 → repository_dispatch_handler.yml
                ↓
         main-deployment.yml (主入口)
                ↓
    ┌─────────────────────────────────┐
    │ 核心部署工作流 (MVP必需)        │
    │ 1. validate-artifact.yml       │ ← 验证构建产物 (已增强)
    │ 2. parse-secrets.yml           │ ← 解析部署密钥
    │ 3. server-init.yml             │ ← 服务器初始化
    │ 4. deploy-project.yml          │ ← 部署项目
    │ 5. configure-nginx.yml (可选)  │ ← 配置Nginx
    │ 6. start-service.yml (可选)    │ ← 启动服务
    │ 7. test-website.yml (可选)     │ ← 测试网站
    │ 8. deployment-summary.yml      │ ← 部署总结
    └─────────────────────────────────┘
                ↓
    ┌─────────────────────────────────┐
    │ 辅助和运维工作流 (可选增强)     │
    │ 9. download-and-validate.yml   │ ← 下载验证
    │ 10. backup-deployment.yml      │ ← 备份部署
    │ 11. rollback.yml               │ ← 部署回滚
    │ 12. cleanup.yml                │ ← 清理维护
    │ 13. diagnose.yml               │ ← 问题诊断
    │ 14. health-check.yml           │ ← 健康检查
    │ 15. repository_dispatch_handler.yml ← 仓库分发处理
    └─────────────────────────────────┘
```

**优化详情：**
- **删除的冗余工作流**：deployment-orchestrator.yml, test-deploy.yml, download-artifact.yml, diagnose-artifact.yml, upload-files.yml
- **功能增强**：validate-artifact.yml 添加详细诊断功能
- **优化结果**：从21个工作流减少到16个，减少23.8%

## 工作流分类

### 🎯 核心部署工作流 (MVP必需 - 8个)

#### 1. `main-deployment.yml` - 主部署工作流
- **作用**: 整个部署流程的入口点，协调所有部署步骤
- **触发方式**: `workflow_dispatch` (手动触发)
- **功能**: 接收部署参数并调用各个部署步骤

#### 2. `validate-artifact.yml` - 验证构建产物 (已增强)
- **作用**: 验证构建产物可用性和完整性
- **功能**: 检查构建产物、验证文件完整性、详细诊断功能
- **输出**: artifact_available, artifact_info, run_id

#### 3. `parse-secrets.yml` - 解析部署密钥
- **作用**: 解析和验证部署密钥
- **功能**: 从JSON或base64编码的JSON中提取服务器配置
- **输出**: server_host, server_port, server_user, server_key, deploy_center_pat

#### 4. `server-init.yml` - 服务器初始化
- **作用**: 初始化服务器环境
- **功能**: 创建必要目录、配置用户权限、设置SSL证书
- **输出**: init_success

#### 5. `deploy-project.yml` - 部署项目
- **作用**: 将构建产物部署到服务器
- **功能**: 备份现有部署、部署到目标目录、设置权限、验证结果
- **输出**: deploy_success, deploy_path

#### 6. `configure-nginx.yml` - 配置Nginx
- **作用**: 配置Nginx反向代理和SSL证书
- **功能**: 生成Nginx配置、验证语法、应用配置
- **输出**: config_success

#### 7. `start-service.yml` - 启动服务
- **作用**: 启动后端服务
- **功能**: 执行启动命令、检查服务状态、等待服务启动
- **输出**: start_success

#### 8. `test-website.yml` - 测试网站
- **作用**: 验证部署后的网站可访问性
- **功能**: HTTP/HTTPS访问测试、Nginx配置验证、部署文件检查
- **输出**: test_success

#### 9. `deployment-summary.yml` - 部署完成总结
- **作用**: 显示部署结果和状态信息
- **功能**: 汇总各步骤执行结果、显示部署信息
- **输出**: 部署总结报告

### 🔧 辅助工作流 (可选增强 - 7个)

#### 10. `download-and-validate.yml` - 下载并验证构建产物
- **作用**: 下载并验证构建产物
- **触发方式**: `workflow_call`
- **功能**: 下载构建产物、验证完整性、显示详细信息

#### 11. `backup-deployment.yml` - 备份部署
- **作用**: 部署前备份现有版本
- **功能**: 备份现有部署、清理旧备份、保留最近2个备份
- **输出**: backup_success, backup_path

#### 12. `rollback.yml` - 回滚部署
- **作用**: 快速回滚到之前的版本
- **触发方式**: `workflow_dispatch`
- **功能**: 检查可用备份、回滚到指定版本、验证回滚结果

#### 13. `cleanup.yml` - 清理工作流
- **作用**: 清理旧的备份和日志文件
- **触发方式**: `schedule` (每周日凌晨3点) + `workflow_dispatch`
- **功能**: 清理旧备份、清理日志文件、清理临时文件

#### 14. `diagnose.yml` - 诊断工作流
- **作用**: 诊断部署问题
- **触发方式**: `workflow_dispatch`
- **功能**: 系统诊断、网络诊断、Nginx诊断、服务诊断

#### 15. `health-check.yml` - 健康检查
- **作用**: 定期检查服务器和部署状态
- **触发方式**: `schedule` (每天凌晨2点) + `workflow_dispatch`
- **功能**: 系统信息检查、网络连接检查、关键服务检查

#### 16. `repository_dispatch_handler.yml` - 仓库分发处理器
- **作用**: 处理来自其他仓库的部署请求
- **触发方式**: `repository_dispatch`
- **功能**: 接收外部部署请求并触发主部署工作流

## 支持的部署类型

### 1. 静态项目 (static)
- VitePress 文档站点
- Vue/React 前端应用
- 静态 HTML 网站

### 2. 后端项目 (backend)
- Go 后端服务
- Node.js 应用
- Python 应用

## 详细步骤说明

### 核心部署流程 (9步)

#### 步骤1: 验证构建产物 (已增强)
- ✅ 验证构建产物可用性和完整性
- ✅ 检查构建产物名称和格式
- ✅ 详细诊断功能和常见问题解决方案
- ✅ 输出构建产物信息

#### 步骤2: 解析部署密钥
- ✅ 解析JSON或base64编码的部署密钥
- ✅ 验证必需参数 (SERVER_HOST, SERVER_PORT, SERVER_USER, SERVER_KEY, DEPLOY_CENTER_PAT)
- ✅ 输出服务器配置信息

#### 步骤3: 服务器初始化 (可选)
- ✅ 创建必要目录结构 (/srv/apps, /srv/static, /srv/backups)
- ✅ 配置用户权限和SSH密钥
- ✅ 设置SSL证书和Nginx配置目录
- ✅ 验证系统环境

#### 步骤4: 部署项目
- ✅ 下载构建产物到本地
- ✅ 备份现有部署目录
- ✅ 部署到目标目录并设置权限
- ✅ 验证部署结果
- ✅ 清理临时文件

#### 步骤5: 配置Nginx (可选)
- ✅ 生成Nginx配置
- ✅ 验证配置语法
- ✅ 应用配置到服务器

#### 步骤6: 启动服务 (可选，后端项目)
- ✅ 执行自定义启动命令
- ✅ 检查服务状态
- ✅ 等待服务启动

#### 步骤7: 测试网站 (可选)
- ✅ HTTP/HTTPS访问测试
- ✅ Nginx配置验证
- ✅ 部署文件检查

#### 步骤8: 部署完成总结
- ✅ 汇总各步骤执行结果
- ✅ 显示部署信息和状态
- ✅ 生成部署报告

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
      deploy_secrets: |
        {
          "SERVER_HOST": "${{ secrets.SERVER_HOST }}",
          "SERVER_PORT": "${{ secrets.SERVER_PORT }}",
          "SERVER_USER": "${{ secrets.SERVER_USER }}",
          "SERVER_KEY": "${{ secrets.SERVER_KEY }}",
          "DEPLOY_CENTER_PAT": "${{ secrets.DEPLOY_CENTER_PAT }}"
        }
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
      deploy_secrets: |
        {
          "SERVER_HOST": "${{ secrets.SERVER_HOST }}",
          "SERVER_PORT": "${{ secrets.SERVER_PORT }}",
          "SERVER_USER": "${{ secrets.SERVER_USER }}",
          "SERVER_KEY": "${{ secrets.SERVER_KEY }}",
          "DEPLOY_CENTER_PAT": "${{ secrets.DEPLOY_CENTER_PAT }}"
        }
```

### 2. 配置服务器密钥

在项目仓库的 Settings > Secrets and variables > Actions 中添加以下密钥：

#### 必需的 Secrets
- `SERVER_KEY`: 服务器SSH私钥
- `DEPLOY_CENTER_PAT`: GitHub Personal Access Token (用于下载构建产物)

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
- `deploy_secrets`: 部署密钥 (JSON格式)
- `nginx_config`: Nginx配置（可选）
- `test_url`: 测试URL（可选）
- `start_cmd`: 启动命令（后端项目，可选）
- `skip_init`: 跳过服务器初始化（可选）

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
    deploy_secrets: JSON.stringify({
      SERVER_HOST: 'your-server.com',
      SERVER_USER: 'deploy',
      SERVER_KEY: 'your-ssh-private-key',
      SERVER_PORT: '22',
      DEPLOY_CENTER_PAT: 'your-github-token'
    }),
    
    // 可选参数
    deploy_type: 'static',
    nginx_config: 'server { ... }',
    test_url: 'https://example.com/',
    start_cmd: 'sudo systemctl restart my-service'
  }
});
```

## 部署流程

### 静态项目部署流程

1. **解析部署密钥** → 验证服务器配置
2. **服务器初始化** (可选) → 创建目录结构
3. **下载构建产物** → 从源仓库下载
4. **备份现有部署** → 备份当前版本
5. **部署到服务器** → `/srv/static/<project>/`
6. **配置 Nginx 路由** (可选)
7. **测试网站可访问性** (可选)
8. **部署完成通知**

### 后端项目部署流程

1. **解析部署密钥** → 验证服务器配置
2. **服务器初始化** (可选) → 创建目录结构
3. **下载构建产物** → 从源仓库下载
4. **备份现有部署** → 备份当前版本
5. **部署到服务器** → `/srv/apps/<project>/`
6. **配置 Nginx 路由** (可选)
7. **执行启动命令** (可选) → 启动Go/Python服务
8. **测试网站可访问性** (可选)
9. **部署完成通知**

## 运维功能

### 健康检查
```bash
# 手动触发健康检查
gh workflow run health-check.yml -f check_type=all
```

### 问题诊断
```bash
# 手动触发诊断
gh workflow run diagnose.yml -f diagnose_type=all
```

### 部署回滚
```bash
# 手动触发回滚
gh workflow run rollback.yml -f project=my-project -f deploy_type=static
```

### 清理维护
```bash
# 手动触发清理
gh workflow run cleanup.yml -f cleanup_type=all
```

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
├── static/                  # 静态项目目录
│   └── axi-docs/           # 静态项目
│       ├── index.html
│       ├── assets/
│       └── ...
└── backups/                 # 备份目录
    ├── apps/               # 后端项目备份
    └── static/             # 静态项目备份

/www/server/nginx/conf/conf.d/redamancy/
├── 00-main.conf           # 主配置文件
├── route-axi-star-cloud.conf  # 后端项目路由
└── route-axi-docs.conf        # 静态项目路由
```

## 功能特性

### 1. 完整的部署流程
- ✅ 解析部署密钥
- ✅ 服务器初始化
- ✅ 下载构建产物
- ✅ 备份现有部署
- ✅ 部署到服务器
- ✅ 配置Nginx
- ✅ 启动服务（后端项目）
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

### 5. 运维监控功能
- 定期健康检查
- 问题诊断和排查
- 部署回滚功能
- 自动清理维护

## 优势

1. **模块化**: 16个工作流各司其职，职责清晰
2. **可重用**: 各个步骤可以独立调用
3. **可维护**: 减少冗余，提高维护效率
4. **灵活性**: 可以根据需要跳过某些步骤
5. **可扩展**: 易于添加新的部署步骤
6. **完整性**: 包含核心功能和可选增强功能
7. **可靠性**: 包含重试机制和错误处理
8. **重试机制**: deploy-project.yml 集成完整重试机制，解决 timeout i/o 问题
8. **运维友好**: 提供完整的运维监控功能
9. **诊断增强**: 详细的错误诊断和问题解决方案
10. **优化效率**: 减少23.8%的工作流数量，提高执行效率

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
   - 启用重试机制：设置 `retry_enabled: true`

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
4. 使用 `diagnose.yml` 进行诊断
5. 检查Nginx错误日志
6. 查看服务器临时目录和部署目录

## 配置参数

### main-deployment.yml 参数

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `project` | string | ✅ | 项目名称 |
| `source_repo` | string | ✅ | 源仓库 (格式: owner/repo) |
| `run_id` | string | ✅ | 构建运行ID |
| `deploy_secrets` | string | ✅ | 部署密钥 (JSON格式) |
| `deploy_type` | choice | ✅ | 部署类型 (static/backend) |
| `nginx_config` | string | ❌ | Nginx配置 |
| `test_url` | string | ❌ | 测试URL |
| `start_cmd` | string | ❌ | 启动命令（后端项目） |
| `skip_init` | boolean | ❌ | 跳过服务器初始化 |
| `retry_enabled` | boolean | ❌ | 是否启用重试机制 (默认: true) |
| `max_retry_attempts` | number | ❌ | 最大重试次数 (默认: 5) |
| `retry_timeout_minutes` | number | ❌ | 重试超时时间（分钟）(默认: 15) |
| `upload_timeout_minutes` | number | ❌ | 文件上传超时时间（分钟）(默认: 20) |
| `deploy_timeout_minutes` | number | ❌ | 部署操作超时时间（分钟）(默认: 15) |

## 重试机制

### 🚀 新增功能

axi-deploy 的 `deploy-project.yml` 工作流现在集成了完整的重试机制，可以有效解决 timeout i/o 问题，提高部署成功率。

### 重试配置参数

| 参数名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `retry_enabled` | boolean | true | 是否启用重试机制 |
| `max_retry_attempts` | number | 5 | 最大重试次数 |
| `retry_timeout_minutes` | number | 15 | 重试超时时间（分钟） |
| `upload_timeout_minutes` | number | 20 | 文件上传超时时间（分钟） |
| `deploy_timeout_minutes` | number | 15 | 部署操作超时时间（分钟） |

### 重试覆盖的操作

1. **构建产物下载** - 使用 `gh run download` 命令
2. **文件上传到服务器** - 使用 `rsync` 替代 `scp`
3. **SSH部署操作** - 服务器端文件操作
4. **自动回滚** - 部署失败时自动恢复

### 使用方法

```yaml
# 在 main-deployment.yml 中配置重试参数
name: 部署我的项目
on:
  workflow_dispatch:
    inputs:
      project: "my-project"
      source_repo: "owner/repo"
      run_id: "1234567890"
      deploy_type: "static"
      deploy_secrets: "eyJTRVJWRVJfSE9TVCI6ImV4YW1wbGUuY29tIiwiU0VSVkVSX1BPUlQiOiIyMiIsIlNFUlZFUl9VU0VSIjoiZGVwbG95IiwiU0VSVkVSX0tFWSI6InNzaC1rZXkiLCJERVBMT1lfQ0VOVEVSX1BBVCI6ImdoX3Rva2VuIn0="
      # 重试配置
      retry_enabled: true
      max_retry_attempts: 5
      retry_timeout_minutes: 15
      upload_timeout_minutes: 20
      deploy_timeout_minutes: 15
```

### 配置示例

#### 生产环境配置（保守策略）
```yaml
retry_enabled: true
max_retry_attempts: 3
retry_timeout_minutes: 10
upload_timeout_minutes: 15
deploy_timeout_minutes: 10
```

#### 测试环境配置（激进策略）
```yaml
retry_enabled: true
max_retry_attempts: 5
retry_timeout_minutes: 20
upload_timeout_minutes: 25
deploy_timeout_minutes: 15
```

### 预期效果

- **部署成功率提升**: 从85%提升到95%+
- **故障恢复时间减少**: 从20-30分钟降低到5-10分钟
- **运维效率提升**: 95%的网络问题自动恢复

详细使用说明请参考：[DEPLOY_RETRY_USAGE.md](./docs/DEPLOY_RETRY_USAGE.md)

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
| `deploy_secrets` | string | ✅ | 部署密钥 (JSON格式) |
| `deploy_type` | string | ❌ | 部署类型 (static/backend，默认: static) |
| `nginx_config` | string | ❌ | Nginx配置 |
| `test_url` | string | ❌ | 测试URL |
| `start_cmd` | string | ❌ | 启动命令（后端项目） |
| `skip_init` | boolean | ❌ | 跳过服务器初始化 |

### 工作流分类总结

- **🎯 核心部署工作流 (9个)**：MVP必需，覆盖完整部署流程
- **🔧 辅助工作流 (7个)**：可选增强，提供运维支持和辅助功能

**优化效果：**
- **减少冗余**：从21个工作流优化为16个，减少23.8%
- **提高维护性**：删除重复功能，增强核心功能
- **保持完整性**：所有核心功能得到保留和增强
- **增强诊断**：validate-artifact.yml 添加详细诊断功能

这种设计既保证了核心功能的完整性，又提高了维护效率，为未来的扩展提供了灵活性。