# 部署指南

## 概述

本项目采用单工作流多步骤部署方式，在GitHub Actions视图中显示为多个步骤，确保部署过程的可控性和安全性。

## 🚀 快速开始

### 部署新项目
1. 确保项目已构建并生成了构建产物
2. 进入 `axi-deploy` 仓库 → Actions
3. 选择 "Universal Deploy" 工作流
4. 填写参数：
   - `project`: 项目名称
   - `source_repo`: 源仓库 (如: mlu/axi-star-cloud)
   - `run_id`: 构建运行ID
   - `deploy_type`: static 或 backend
5. 点击 "Run workflow"
6. 系统会自动执行初始化，然后部署项目

### 更新现有项目
1. 直接运行 "Universal Deploy" 工作流
2. 指定新的构建运行ID
3. 系统会自动检查并修复环境，然后部署

## 工作流说明

### 通用部署工作流 (`universal_deploy.yml`)

**用途**: 单工作流多步骤部署，包含服务器初始化和项目部署两个主要步骤。

**触发方式**: 手动触发 (workflow_dispatch)

**工作流步骤**:
1. **服务器初始化步骤** (`server-init` job)
   - 检查并修复服务器环境
   - 验证Nginx配置和证书状态
   - 确保目录结构和权限正确
   - 实现灾后自愈、配置变更管理、健康巡检功能

2. **项目部署步骤** (`deploy` job)
   - 下载构建产物
   - 上传到服务器
   - 根据项目类型执行部署
   - 配置Nginx路由（如果提供）
   - 执行启动命令（后端项目）
   - 测试网站可访问性

**参数说明**:
- `project`: 项目名称 (必需)
- `source_repo`: 源仓库 (格式: owner/repo) (必需)
- `run_id`: 构建运行ID (必需)
- `deploy_type`: 部署类型 (static/backend) (默认: static)
- `nginx_config`: Nginx配置 (可选)
- `test_url`: 测试URL (可选)
- `start_cmd`: 启动命令（后端项目）(可选)
- `skip_init`: 跳过服务器初始化 (默认: false)

## 🔧 服务器管理操作

### 灾后自愈
如果服务器环境出现问题（目录被删、配置丢失等）：
1. 进入 `axi-deploy` 仓库 → Actions
2. 选择 "Universal Deploy" 工作流
3. 点击 "Run workflow"
4. 系统会自动检测并修复缺失的部分

### 配置变更管理
如果需要修改环境常量（如 client_max_body_size）：
1. 进入 `axi-deploy` 仓库 → Actions
2. 选择 "Universal Deploy" 工作流
3. 点击 "Run workflow"
4. 系统会重新生成配置文件

## 自动化部署流程

### 步骤1: 服务器初始化
- 每次部署前自动执行
- 检查并修复服务器环境
- 验证Nginx配置和证书状态
- 确保目录结构和权限正确

### 步骤2: 项目部署
- 下载构建产物
- 上传到服务器
- 根据项目类型执行部署
- 配置Nginx路由（如果提供）
- 执行启动命令（后端项目）
- 测试网站可访问性

## 使用场景

### 1. 首次部署
1. 确保项目已构建并生成了构建产物
2. 进入 `axi-deploy` 仓库
3. 点击 Actions 标签页
4. 选择 "Universal Deploy" 工作流
5. 填写必要参数
6. 点击 "Run workflow" 开始部署
7. 系统会自动执行初始化，然后部署项目

### 2. 更新部署
1. 直接运行 "Universal Deploy" 工作流
2. 指定新的构建运行ID
3. 系统会自动检查并修复环境，然后部署

### 3. 灾后自愈
1. 如果服务器环境出现问题（目录被删、配置丢失等）
2. 直接运行 "Universal Deploy" 工作流
3. 系统会自动检测并修复缺失的部分

### 4. 配置变更管理
1. 修改环境常量（如 client_max_body_size）
2. 运行 "Universal Deploy" 工作流
3. 系统会重新生成配置文件

## 项目类型说明

### 静态项目 (static)
- 部署到 `/srv/static/<project>`
- 适用于 VitePress、Vue、React 等前端项目
- 不需要启动命令

### 后端项目 (backend)
- 部署到 `/srv/apps/<project>`
- 适用于 Go、Node.js 等后端项目
- 可能需要启动命令
- 会自动创建必要的目录结构

## 📋 常用参数

### 部署参数
```yaml
project: "项目名称"
source_repo: "owner/repo"
run_id: "构建运行ID"
deploy_type: "static" | "backend"
nginx_config: "Nginx配置（可选）"
test_url: "测试URL（可选）"
start_cmd: "启动命令（可选）"
skip_init: false  # 跳过初始化（不推荐）
```

## 📁 目录结构

```
/srv/apps/          # 后端项目目录
/srv/static/        # 静态项目目录
/www/server/nginx/conf/conf.d/redamancy/  # Nginx配置目录
/www/server/nginx/ssl/redamancy/          # 证书目录
```

## Nginx配置示例

### 静态项目配置
```nginx
location /docs/ {
    alias /srv/static/axi-docs/;
    try_files $uri $uri/ /docs/index.html;
}
```

### 后端项目配置
```nginx
location /api/ {
    proxy_pass http://127.0.0.1:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## 🔍 故障排查

### 部署失败
1. 检查构建产物是否存在
2. 验证服务器连接是否正常
3. 确认参数是否正确
4. 查看工作流日志获取详细错误信息

### 初始化失败
1. 检查服务器是否安装了Nginx
2. 确认宝塔面板是否已配置SSL证书
3. 验证域名解析是否正确
4. 检查防火墙是否开放了80/443端口

## 常见问题

### Q: 如何获取构建运行ID？
A: 在源项目的 Actions 页面，找到对应的构建工作流，复制运行ID。

### Q: 部署失败怎么办？
A: 检查以下几点:
1. 构建产物是否存在
2. 服务器连接是否正常
3. 参数是否正确
4. 查看工作流日志获取详细错误信息

### Q: 如何跳过初始化步骤？
A: 在部署参数中设置 `skip_init: true`，但建议只在特殊情况下使用。

### Q: 服务器初始化失败怎么办？
A: 检查以下几点:
1. 服务器是否安装了Nginx
2. 宝塔面板是否已配置SSL证书
3. 域名解析是否正确
4. 防火墙是否开放了80/443端口

## 💡 最佳实践

1. **自动化部署**: 每次部署都会自动初始化，无需手动干预
2. **参数管理**: 记录常用的部署参数，避免重复输入
3. **测试验证**: 部署后及时测试网站可访问性
4. **日志监控**: 关注部署日志，及时发现问题
5. **备份策略**: 重要项目部署前建议备份
6. **步骤监控**: 在GitHub Actions视图中监控每个步骤的执行状态

## 安全注意事项

1. 确保服务器密钥安全存储
2. 定期更新SSL证书
3. 监控服务器资源使用情况
4. 及时更新系统和软件包
5. 定期备份重要数据
6. 关注健康巡检结果，及时处理异常 