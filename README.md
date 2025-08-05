# Axi Deploy - 统一部署中心

## 概述

Axi Deploy 是一个统一的部署中心，用于管理多个项目的自动化部署。支持静态网站和后端服务的部署，并提供完整的 Nginx 配置管理。

## 最新更新

### 🚀 部署脚本修复 (v2.0)

**解决的问题：**
- ✅ 修复了项目间文件交叉污染问题
- ✅ 为每个项目创建独立的临时目录
- ✅ 添加了部署前和部署后的清理机制
- ✅ 改进了错误处理和日志记录

**主要改进：**
1. **独立临时目录**：每个项目使用 `/tmp/<project>/` 目录
2. **部署前清理**：确保目标目录干净，避免残留文件
3. **部署后清理**：及时清理临时文件
4. **路径一致性**：使用项目名称确保路径正确
5. **类型区分**：明确区分静态项目和后端项目的处理逻辑

## 支持的部署类型

### 1. 静态项目 (static)
- VitePress 文档站点
- Vue/React 前端应用
- 静态 HTML 网站

### 2. 后端项目 (backend)
- Go 后端服务
- Node.js 应用
- Python 应用

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
    uses: MoseLu/axi-deploy/.github/workflows/universal_deploy.yml@master
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
      DEPLOY_CENTER_PAT: ${{ secrets.DEPLOY_CENTER_PAT }}
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
    uses: MoseLu/axi-deploy/.github/workflows/universal_deploy.yml@master
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
    secrets:
      SERVER_HOST: ${{ secrets.SERVER_HOST }}
      SERVER_PORT: ${{ secrets.SERVER_PORT }}
      SERVER_USER: ${{ secrets.SERVER_USER }}
      SERVER_KEY: ${{ secrets.SERVER_KEY }}
      DEPLOY_CENTER_PAT: ${{ secrets.DEPLOY_CENTER_PAT }}
```

### 2. 配置服务器密钥

在项目仓库的 Settings > Secrets and variables > Actions 中添加以下密钥：

- `SERVER_HOST`: 服务器 IP 地址
- `SERVER_PORT`: SSH 端口 (通常是 22)
- `SERVER_USER`: SSH 用户名
- `SERVER_KEY`: SSH 私钥
- `DEPLOY_CENTER_PAT`: GitHub Personal Access Token

### 3. 手动触发部署

在 GitHub Actions 页面手动触发部署工作流，或推送代码到主分支自动触发。

## 部署流程

### 静态项目部署流程

1. **构建产物上传** → `/tmp/<project>/`
2. **清理目标目录** → `/srv/static/<project>/`
3. **复制文件** → 目标目录
4. **清理临时目录** → `/tmp/<project>/`
5. **配置 Nginx 路由**

### 后端项目部署流程

1. **构建产物上传** → `/tmp/<project>/`
2. **清理目标目录** → `/srv/apps/<project>/`
3. **解压 deployment.tar.gz**
4. **设置文件权限**
5. **启动服务**
6. **清理临时目录** → `/tmp/<project>/`
7. **配置 Nginx 路由**

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

## 故障排除

### 常见问题

1. **临时目录不存在**
   - 检查 SCP 上传是否成功
   - 确认项目名称正确

2. **权限问题**
   - 确保 deploy 用户有足够权限
   - 检查文件所有者设置

3. **服务启动失败**
   - 检查二进制文件权限
   - 查看服务日志
   - 确认端口未被占用

4. **Nginx 配置错误**
   - 检查配置文件语法
   - 确认路径正确
   - 查看错误日志

### 调试命令

```bash
# 查看部署日志
sudo journalctl -u star-cloud.service -f

# 检查 Nginx 状态
sudo systemctl status nginx

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# 检查端口占用
sudo netstat -tlnp | grep :8080

# 检查文件权限
ls -la /srv/apps/axi-star-cloud/
ls -la /srv/static/axi-docs/
```

## 配置参数

### universal_deploy.yml 参数

| 参数 | 类型 | 必需 | 描述 |
|------|------|------|------|
| `project` | string | ✅ | 项目名称 |
| `source_repo` | string | ✅ | 源仓库 (格式: owner/repo) |
| `run_id` | string | ✅ | 构建运行ID |
| `deploy_type` | choice | ✅ | 部署类型 (static/backend) |
| `nginx_config` | string | ❌ | Nginx配置 |
| `test_url` | string | ❌ | 测试URL |
| `start_cmd` | string | ❌ | 启动命令（后端项目） |
| `skip_init` | boolean | ❌ | 跳过服务器初始化 |

## 示例项目

### 静态项目
- [axi-docs](https://github.com/MoseLu/axi-docs) - VitePress 文档站点

### 后端项目
- [axi-star-cloud](https://github.com/MoseLu/axi-star-cloud) - Go 后端服务

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个部署中心。

## 许可证

MIT License