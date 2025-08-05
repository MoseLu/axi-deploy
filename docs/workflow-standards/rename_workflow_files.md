# 工作流文件重命名计划

## 需要重命名的文件列表

### 中央部署仓库 (axi-deploy)
- ✅ `deploy.yml` → `central_deploy_handler.yml` (已完成)
- ✅ `external-deploy.yml` → `central_external_deploy.yml` (已完成)
- ✅ `repository-dispatch-handler.yml` → `repository_dispatch_handler.yml` (已完成)

### 业务仓库
- ✅ `axi-star-cloud/.github/workflows/deploy.yml` → `axi-star-cloud_deploy.yml` (已完成)
- ✅ `axi-docs/.github/workflows/axi-docs_deploy.yml` → `axi-docs_deploy.yml` (已符合标准)

### 示例文件重命名

#### Backend 示例
- `go-project-deploy.yml` → `go-project_deploy.yml`
- `go-project-deploy-fixed.yml` → `go-project_deploy-fixed.yml`
- `node-project-deploy.yml` → `node-project_deploy.yml`
- `python-project-deploy.yml` → `python-project_deploy.yml`
- `axi-star-cloud-deploy.yml` → `axi-star-cloud_deploy.yml`

#### Frontend 示例
- `vue-project-deploy.yml` → `vue-project_deploy.yml`
- `react-project-deploy.yml` → `react-project_deploy.yml`

#### Docs 示例
- `vitepress-project-deploy.yml` → `vitepress-project_deploy.yml`
- `axi-docs-pnpm-deploy.yml` → `axi-docs-pnpm_deploy.yml`
- `axi-docs-deploy-fixed.yml` → `axi-docs_deploy-fixed.yml`

## 重命名规则

1. **业务仓库工作流**：`{仓库名}_deploy.yml`
2. **中央仓库工作流**：`central_{功能}_deploy.yml`
3. **示例文件**：`{项目类型}_deploy.yml` 或 `{项目名}_deploy.yml`

## 注意事项

1. 重命名后需要更新所有引用这些文件的地方
2. 确保新的命名规范在所有文档中保持一致
3. 更新 README 和示例文档中的文件引用 