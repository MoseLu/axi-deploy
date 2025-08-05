# 静态项目部署指南

## 概述

本指南介绍如何使用 Axi Deploy 部署静态项目，包括 VitePress 文档站点、Vue/React 前端应用等。

## 部署流程

### 1. 项目配置

在项目根目录创建 `.github/workflows/deploy.yml` 文件：

```yaml
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

### 2. 配置说明

#### 必需参数

- `project`: 项目名称，通常使用 `${{ github.event.repository.name }}`
- `source_repo`: 源仓库，格式为 `owner/repo`
- `run_id`: 构建运行ID，使用 `${{ github.run_id }}`
- `deploy_type`: 部署类型，静态项目使用 `static`

#### 可选参数

- `nginx_config`: Nginx 配置，定义路由规则
- `test_url`: 测试URL，用于验证部署是否成功

### 3. Nginx 配置示例

#### VitePress 文档站点

```nginx
location /docs/ {
    alias /srv/static/${{ github.event.repository.name }}/;
    try_files $uri $uri/ /docs/index.html;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

#### Vue/React 应用

```nginx
location /app/ {
    alias /srv/static/${{ github.event.repository.name }}/;
    try_files $uri $uri/ /app/index.html;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 根路径应用

```nginx
location / {
    root /srv/static/${{ github.event.repository.name }}/;
    try_files $uri $uri/ /index.html;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 部署验证

### 1. 自动验证

部署完成后，系统会自动：
- ✅ 检查文件是否正确上传
- ✅ 验证 Nginx 配置语法
- ✅ 测试网站可访问性
- ✅ 生成部署报告

### 2. 手动验证

```bash
# 检查目录结构
ls -la /srv/static/<project>/

# 检查 Nginx 配置
sudo nginx -t

# 测试网站访问
curl -I https://your-domain.com/your-path/

# 检查文件权限
ls -la /srv/static/<project>/
```

### 3. 常见问题排查

#### 文件未正确部署
```bash
# 检查构建产物
ls -la dist/

# 检查临时目录
ls -la /tmp/<project>/

# 检查目标目录
ls -la /srv/static/<project>/
```

#### Nginx 配置错误
```bash
# 检查配置语法
sudo nginx -t

# 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 重载配置
sudo systemctl reload nginx
```

#### 网站无法访问
```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查端口监听
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# 测试本地访问
curl -I http://localhost/your-path/
```

## 最佳实践

### 1. 构建优化

- 使用生产环境构建
- 启用代码压缩和优化
- 配置适当的缓存策略

### 2. 部署策略

- 使用语义化版本号
- 保留部署历史记录
- 配置自动回滚机制

### 3. 监控和维护

- 定期检查网站性能
- 监控错误日志
- 及时更新依赖包

## 故障排除

### 常见错误

1. **构建失败**
   - 检查 Node.js 版本
   - 验证依赖包安装
   - 查看构建日志

2. **部署失败**
   - 检查服务器连接
   - 验证文件权限
   - 确认目录存在

3. **网站无法访问**
   - 检查 Nginx 配置
   - 验证域名解析
   - 测试网络连接

### 调试命令

```bash
# 查看部署日志
sudo journalctl -u nginx -f

# 检查文件权限
ls -la /srv/static/<project>/

# 测试网络连接
curl -v https://your-domain.com/

# 检查 SSL 证书
openssl s_client -connect your-domain.com:443
```

## 示例项目

### VitePress 文档站点
- 构建命令：`npm run docs:build`
- 构建产物：`docs/.vitepress/dist/`
- 访问路径：`/docs/`

### Vue 应用
- 构建命令：`npm run build`
- 构建产物：`dist/`
- 访问路径：`/app/`

### React 应用
- 构建命令：`npm run build`
- 构建产物：`build/`
- 访问路径：`/app/`

## 总结

通过本指南，您可以成功部署各种类型的静态项目。记住：

1. **正确配置** - 确保所有参数设置正确
2. **测试验证** - 部署后及时验证功能
3. **监控维护** - 定期检查网站状态
4. **备份恢复** - 保留重要配置的备份

如有问题，请参考故障排除部分或联系技术支持。 