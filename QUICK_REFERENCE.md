# 快速参考

## 🚀 日常部署操作

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
6. 系统会自动初始化服务器，然后部署项目

### 更新现有项目
1. 直接运行 "Universal Deploy" 工作流
2. 指定新的构建运行ID
3. 系统会自动检查并修复环境，然后部署

## 🔧 服务器管理操作

### 灾后自愈
如果服务器环境出现问题（目录被删、配置丢失等）：
1. 进入 `axi-deploy` 仓库 → Actions
2. 选择 "Server Initialization" 工作流
3. 点击 "Run workflow"
4. 系统会自动检测并修复缺失的部分

### 配置变更管理
如果需要修改环境常量（如 client_max_body_size）：
1. 进入 `axi-deploy` 仓库 → Actions
2. 选择 "Server Initialization" 工作流
3. 设置 `force_rebuild: true`
4. 点击 "Run workflow"
5. 系统会重新生成配置文件

### 健康巡检
- 每周一凌晨2点自动执行
- 检查证书软链、Nginx配置、防火墙状态
- 如果发现问题，CI会标红提醒

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

### 初始化参数
```yaml
domain: "redamancy.com.cn"
run_user: "deploy"
apps_root: "/srv/apps"
static_root: "/srv/static"
nginx_conf_dir: "/www/server/nginx/conf/conf.d/redamancy"
cert_src: "/www/server/panel/vhost/cert/redamancy.com.cn"
cert_dst: "/www/server/nginx/ssl/redamancy"
force_rebuild: false  # 强制重建配置
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

### 健康巡检失败
1. 检查证书软链是否正常
2. 验证Nginx配置语法
3. 确认防火墙规则
4. 查看巡检日志获取详细信息

## 📁 目录结构

```
/srv/apps/          # 后端项目目录
/srv/static/        # 静态项目目录
/www/server/nginx/conf/conf.d/redamancy/  # Nginx配置目录
/www/server/nginx/ssl/redamancy/          # 证书目录
```

## 🔗 相关文档

- [部署指南](DEPLOYMENT_GUIDE.md) - 详细的使用说明
- [工作流重组总结](WORKFLOW_REORGANIZATION_SUMMARY.md) - 变更记录和设计思路

## 💡 最佳实践

1. **自动化部署**: 每次部署都会自动初始化，无需手动干预
2. **参数管理**: 记录常用的部署参数，避免重复输入
3. **测试验证**: 部署后及时测试网站可访问性
4. **日志监控**: 关注部署日志，及时发现问题
5. **备份策略**: 重要项目部署前建议备份
6. **定期巡检**: 利用自动健康巡检功能，及时发现问题 