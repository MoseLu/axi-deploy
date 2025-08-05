# 工作流改进总结

## 🎯 改进目标

1. **统一业务代码仓库工作流命名**：使用 `{仓库名}_deploy.yml` 格式
2. **中央仓库工作流标识化**：避免多个工作流无法辨识的问题
3. **解决工作流识别问题**：在 GitHub Actions 页面中清楚区分不同项目的部署

## ✅ 已完成的改进

### 1. 中央部署仓库 (axi-deploy) 工作流重命名

#### 重命名前 → 重命名后
- `deploy.yml` → `central_deploy_handler.yml`
- `external-deploy.yml` → `central_external_deploy.yml`
- `repository-dispatch-handler.yml` → `repository_dispatch_handler.yml`

#### 工作流分类
- **核心部署工作流**：`central_*_deploy.yml`
- **工具类工作流**：`repository_dispatch_handler.yml`

### 2. 业务仓库工作流标准化

#### 已更新的仓库
- `axi-star-cloud`：`deploy.yml` → `axi-star-cloud_deploy.yml`
- `axi-docs`：`axi-docs_deploy.yml`（已符合标准）

#### 命名规范
- 格式：`{仓库名}_deploy.yml`
- 全部小写
- 用下划线连接
- 以 `_deploy.yml` 结尾

### 3. 示例文件重命名

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

## 📋 文件结构对比

### 改进前
```
axi-deploy/.github/workflows/
├── deploy.yml                    # 不明确
├── external-deploy.yml           # 不明确
└── repository-dispatch-handler.yml

axi-star-cloud/.github/workflows/
├── deploy.yml                    # 通用名称

examples/deployments/
├── backend/
│   ├── go-project-deploy.yml     # 不一致
│   └── vue-project-deploy.yml    # 不一致
```

### 改进后
```
axi-deploy/.github/workflows/
├── central_deploy_handler.yml    # 明确标识
├── central_external_deploy.yml   # 明确标识
└── repository_dispatch_handler.yml

axi-star-cloud/.github/workflows/
├── axi-star-cloud_deploy.yml     # 项目特定

examples/deployments/
├── backend/
│   ├── go-project_deploy.yml     # 统一格式
│   └── vue-project_deploy.yml    # 统一格式
```

## 🎉 改进效果

### 1. 清晰识别
- 通过文件名即可知道是哪个项目的部署工作流
- 中央仓库工作流有明确的 `central_` 前缀标识
- 在 GitHub Actions 页面中可以清楚看到哪个工作流对应哪个项目

### 2. 避免冲突
- 不同项目的工作流不会重名
- 中央仓库工作流有明确的分类标识

### 3. 易于维护
- 统一的命名规范便于管理和查找
- 新增项目时遵循统一规范

### 4. 扩展性好
- 支持多项目并行部署
- 每个项目的工作流可以独立配置和维护

## 🔧 工作流识别改进

### 问题描述
在 axi-deploy 中央仓库中，所有被触发的工作流都显示为 "deploy"，无法区分是哪个项目的部署。这导致在 GitHub Actions 页面中无法快速识别哪个工作流对应哪个项目。

### 解决方案

#### 1. 创建项目专用工作流
为每个项目创建专用的部署工作流，具有明确的项目名称：

- `axi-star-cloud_deploy.yml` - 专门处理 axi-star-cloud 项目
- `axi-docs_deploy.yml` - 专门处理 axi-docs 项目
- `central_external_deploy.yml` - 通用外部部署工作流（重命名为 "Deploy Project (External)"）

#### 2. 工作流命名规范
- **项目专用工作流**：`Deploy {项目名}`
  - `Deploy AXI Star Cloud`
  - `Deploy AXI Docs`
- **通用工作流**：`Deploy Project (External)`

#### 3. 条件执行
每个项目专用工作流都包含条件判断，确保只处理对应的项目：

```yaml
if: ${{ github.event.client_payload.project == 'axi-star-cloud' }}
```

或

```yaml
if: ${{ github.event.client_payload.project == 'axi-docs' }}
```

### 使用方式
业务仓库的工作流调用保持不变，中央仓库会根据项目名称自动路由到对应的工作流：

- `axi-star-cloud` 项目 → `axi-star-cloud_deploy.yml`
- `axi-docs` 项目 → `axi-docs_deploy.yml`
- 其他项目 → `central_external_deploy.yml`

### 效果
现在在 GitHub Actions 页面中，您将看到：

- ✅ "Deploy AXI Star Cloud" - 清楚标识为 AXI Star Cloud 项目
- ✅ "Deploy AXI Docs" - 清楚标识为 AXI Docs 项目  
- ✅ "Deploy Project (External)" - 通用外部项目部署

不再有混淆的 "deploy" 工作流名称！ 