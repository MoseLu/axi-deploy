# Axi Deploy 文档中心

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

## 核心功能

### 支持的部署类型

#### 1. 静态项目 (static)
- VitePress 文档站点
- Vue/React 前端应用
- 静态 HTML 网站

#### 2. 后端项目 (backend)
- Go 后端服务
- Node.js 应用
- Python 应用

### 部署流程

#### 静态项目部署流程
1. 构建产物上传到 `/tmp/<project>/`
2. 清理目标目录 `/srv/static/<project>/`
3. 复制文件到目标目录
4. 清理临时目录 `/tmp/<project>/`
5. 配置 Nginx 路由

#### 后端项目部署流程
1. 构建产物上传到 `/tmp/<project>/`
2. 清理目标目录 `/srv/apps/<project>/`
3. 解压 deployment.tar.gz
4. 设置文件权限
5. 启动服务
6. 清理临时目录 `/tmp/<project>/`
7. 配置 Nginx 路由

## 配置示例

### 静态项目配置

```yaml
deploy:
  needs: build
  uses: MoseLu/axi-deploy/.github/workflows/universal_deploy.yml@master
  with:
    project: ${{ github.event.repository.name }}
    source_repo: ${{ github.repository }}
    run_id: ${{ github.run_id }}
    deploy_type: static
    nginx_config: |
      location /docs/ {
          alias /srv/static/${{ github.event.repository.name }}/;
          try_files $uri $uri/ /docs/index.html;
          
          # 静态资源缓存
          location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
              expires 1y;
              add_header Cache-Control "public, immutable";
          }
      }
    test_url: https://redamancy.com.cn/docs/
```

### 后端项目配置

```yaml
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
    test_url: https://redamancy.com.cn/
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