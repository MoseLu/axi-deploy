# 工作流识别改进

## 问题描述

在 axi-deploy 中央仓库中，所有被触发的工作流都显示为 "deploy"，无法区分是哪个项目的部署。这导致在 GitHub Actions 页面中无法快速识别哪个工作流对应哪个项目。

## 解决方案

### 1. 创建项目专用工作流

为每个项目创建专用的部署工作流，具有明确的项目名称：

- `axi-star-cloud_deploy.yml` - 专门处理 axi-star-cloud 项目
- `axi-docs_deploy.yml` - 专门处理 axi-docs 项目
- `central_external_deploy.yml` - 通用外部部署工作流（重命名为 "Deploy Project (External)"）

### 2. 工作流命名规范

- **项目专用工作流**：`Deploy {项目名}`
  - `Deploy AXI Star Cloud`
  - `Deploy AXI Docs`

- **通用工作流**：`Deploy Project (External)`

### 3. 条件执行

每个项目专用工作流都包含条件判断，确保只处理对应的项目：

```yaml
if: ${{ github.event.client_payload.project == 'axi-star-cloud' }}
```

或

```yaml
if: ${{ github.event.client_payload.project == 'axi-docs' }}
```

## 文件结构

```
axi-deploy/.github/workflows/
├── central_external_deploy.yml      # 通用外部部署工作流
├── axi-star-cloud_deploy.yml        # AXI Star Cloud 专用部署
├── axi-docs_deploy.yml             # AXI Docs 专用部署
└── repository_dispatch_handler.yml  # 事件处理器
```

## 优势

1. **清晰识别**：在 GitHub Actions 页面中可以清楚看到哪个工作流对应哪个项目
2. **独立管理**：每个项目的工作流可以独立配置和维护
3. **条件执行**：避免不必要的工作流执行
4. **向后兼容**：保持现有的触发机制不变

## 使用方式

业务仓库的工作流调用保持不变，中央仓库会根据项目名称自动路由到对应的工作流：

- `axi-star-cloud` 项目 → `axi-star-cloud_deploy.yml`
- `axi-docs` 项目 → `axi-docs_deploy.yml`
- 其他项目 → `central_external_deploy.yml`

## 效果

现在在 GitHub Actions 页面中，您将看到：

- ✅ "Deploy AXI Star Cloud" - 清楚标识为 AXI Star Cloud 项目
- ✅ "Deploy AXI Docs" - 清楚标识为 AXI Docs 项目  
- ✅ "Deploy Project (External)" - 通用外部项目部署

不再有混淆的 "deploy" 工作流名称！ 