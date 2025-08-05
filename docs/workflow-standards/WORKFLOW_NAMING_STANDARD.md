# 工作流命名标准

## 1. 业务代码仓库工作流命名规范

### 统一格式：`{仓库名}_deploy.yml`

**示例：**
- `axi-star-cloud` → `axi-star-cloud_deploy.yml`
- `axi-docs` → `axi-docs_deploy.yml`
- `my-vue-app` → `my-vue-app_deploy.yml`

### 命名规则：
1. 使用仓库的完整名称
2. 全部小写
3. 用下划线连接
4. 以 `_deploy.yml` 结尾

## 2. 中央部署仓库工作流命名规范

### 工作流分类：

#### 2.1 核心部署工作流
- `central_deploy_handler.yml` - 中央部署处理器（原 deploy.yml）
- `central_external_deploy.yml` - 外部项目部署工作流（原 external-deploy.yml）

#### 2.2 项目特定部署工作流
- `{项目名}_deploy.yml` - 特定项目的部署工作流

**示例：**
- `axi-star-cloud_deploy.yml` - axi-star-cloud 项目专用部署
- `axi-docs_deploy.yml` - axi-docs 项目专用部署

#### 2.3 工具类工作流
- `repository_dispatch_handler.yml` - 仓库调度处理器
- `health_check.yml` - 健康检查工作流
- `nginx_init.yml` - Nginx 初始化工作流

## 3. 迁移计划

### 第一阶段：重命名现有工作流
1. `deploy.yml` → `central_deploy_handler.yml`
2. `external-deploy.yml` → `central_external_deploy.yml`
3. `repository-dispatch-handler.yml` → `repository_dispatch_handler.yml`

### 第二阶段：更新业务仓库工作流
1. `axi-star-cloud/.github/workflows/deploy.yml` → `axi-star-cloud_deploy.yml`
2. `axi-docs/.github/workflows/axi-docs_deploy.yml` → `axi-docs_deploy.yml`（已符合标准）

### 第三阶段：更新示例文件
1. 更新 `examples/deployments/` 下的所有示例文件
2. 统一使用 `{项目名}_deploy.yml` 格式

## 4. 优势

1. **清晰识别**：通过文件名即可知道是哪个项目的部署工作流
2. **避免冲突**：不同项目的工作流不会重名
3. **易于维护**：统一的命名规范便于管理和查找
4. **扩展性好**：新增项目时遵循统一规范

## 5. 实施步骤

1. 创建新的工作流文件
2. 更新所有引用
3. 删除旧的工作流文件
4. 更新文档和示例 