# 🚀 部署场景示例

本文档展示了不同项目类型的部署配置示例。

## 1. 前端项目部署

### Vue.js 项目

```yaml
name: Deploy Vue App

on:
  push:
    branches: [ main ]
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
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/www/wwwroot/vue-app',
                commands: |
                  cd /www/wwwroot/vue-app
                  chmod -R 755 .
                  sudo systemctl reload nginx
              }
            });
            console.log('部署已触发:', response);
```

### React 项目

```yaml
name: Deploy React App

on:
  push:
    branches: [ main ]
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
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './build',
                target_path: '/www/wwwroot/react-app'
              }
            });
            console.log('部署已触发:', response);
```

## 2. 后端项目部署

### Node.js API

```yaml
name: Deploy Node.js API

on:
  push:
    branches: [ main ]
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
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/opt/api-server',
                commands: |
                  cd /opt/api-server
                  npm install --production
                  npm run migrate
                  pm2 restart api-server
              }
            });
            console.log('部署已触发:', response);
```

### Python Flask 应用

```yaml
name: Deploy Flask App

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
        
      - name: 设置 Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: 安装依赖
        run: |
          pip install -r requirements.txt
          
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: '.',
                target_path: '/opt/flask-app',
                commands: |
                  cd /opt/flask-app
                  pip install -r requirements.txt
                  sudo systemctl restart flask-app
              }
            });
            console.log('部署已触发:', response);
```

## 3. 静态网站部署

### Hugo 静态网站

```yaml
name: Deploy Hugo Site

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
        with:
          submodules: recursive
          
      - name: 设置 Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true
          
      - name: 构建网站
        run: hugo --minify
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './public',
                target_path: '/www/wwwroot/blog'
              }
            });
            console.log('部署已触发:', response);
```

## 4. 多环境部署

### 开发环境

```yaml
name: Deploy to Development

on:
  push:
    branches: [ develop ]
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
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build:dev
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/www/wwwroot/dev-app',
                commands: |
                  cd /www/wwwroot/dev-app
                  npm install --production
                  pm2 restart dev-app
              }
            });
            console.log('开发环境部署已触发:', response);
```

### 生产环境

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]
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
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build:prod
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/www/wwwroot/prod-app',
                commands: |
                  cd /www/wwwroot/prod-app
                  npm install --production
                  pm2 restart prod-app
                  sudo systemctl reload nginx
              }
            });
            console.log('生产环境部署已触发:', response);
```

## 5. 数据库迁移

```yaml
name: Deploy with Migration

on:
  push:
    branches: [ main ]
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
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build
        
      - name: 触发部署
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/opt/api-server',
                commands: |
                  cd /opt/api-server
                  npm install --production
                  npm run migrate
                  npm run seed
                  pm2 restart api-server
              }
            });
            console.log('部署已触发:', response);
```

## 6. 条件部署

```yaml
name: Conditional Deploy

on:
  push:
    branches: [ main, develop ]
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
          node-version: '18'
          cache: 'npm'
          
      - name: 安装依赖
        run: npm ci
        
      - name: 构建项目
        run: npm run build
        
      - name: 部署到开发环境
        if: github.ref == 'refs/heads/develop'
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/www/wwwroot/dev-app'
              }
            });
            console.log('开发环境部署已触发:', response);
            
      - name: 部署到生产环境
        if: github.ref == 'refs/heads/main'
        uses: actions/github-script@v7
        with:
          script: |
            const { data: response } = await github.rest.actions.createWorkflowDispatch({
              owner: 'MoseLu',
              repo: 'axi-deploy',
              workflow_id: 'deploy-dispatch.yml',
              ref: 'main',
              inputs: {
                caller_repo: '${{ github.repository }}',
                caller_branch: '${{ github.ref_name }}',
                caller_commit: '${{ github.sha }}',
                source_path: './dist',
                target_path: '/www/wwwroot/prod-app',
                commands: |
                  cd /www/wwwroot/prod-app
                  npm install --production
                  pm2 restart prod-app
                  sudo systemctl reload nginx
              }
            });
            console.log('生产环境部署已触发:', response);
```

## 注意事项

1. **环境变量**: 确保在服务器上正确配置了环境变量
2. **权限设置**: 确保部署用户有足够的权限执行所有命令
3. **备份策略**: 建议在部署前自动备份当前版本
4. **回滚机制**: 准备快速回滚到上一个版本的方案
5. **监控告警**: 部署后监控应用状态，设置告警机制 