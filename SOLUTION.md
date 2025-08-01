# 🚀 AXI Deploy 解决方案

## 📋 问题背景

在传统的多项目部署中，每个项目都需要：
- 配置自己的 SSH 密钥和服务器信息
- 维护各自的部署脚本
- 处理不同语言的构建和启动逻辑
- 管理多个仓库的敏感信息

这导致了：
- 🔴 **安全风险** - 敏感信息分散在多个仓库
- 🔴 **维护成本** - 每个项目都要配置部署环境
- 🔴 **不一致性** - 不同项目的部署流程不统一
- 🔴 **扩展困难** - 新增项目需要重复配置

## ✅ 解决方案

### 核心思路

使用 **一个公共仓库 + workflow_dispatch** 把 Go、Node、Python 等不同类型业务库的部署动作全部收拢：

- **公共仓库（axi-deploy）** 里只放一份"通用触发器"
  - 它能拿到自己的 Secrets（SSH key、服务器地址、路径等）
  - 通过 `inputs` 区分项目名、语言、启动方式
- **各业务仓库** 只做构建，然后调用公共仓库的 `workflow_dispatch`，把产物或参数传过去

### 架构设计

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   业务仓库 A     │    │   业务仓库 B     │    │   业务仓库 C     │
│  (Node.js)      │    │  (Go)          │    │  (Python)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ 构建 + 上传产物        │ 构建 + 上传产物        │ 构建 + 上传产物
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │    公共仓库              │
                    │   (axi-deploy)          │
                    │                         │
                    │  🔐 统一管理 Secrets    │
                    │  📦 统一部署逻辑        │
                    │  🌍 支持多语言          │
                    └─────────────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │      服务器             │
                    │  (生产环境)             │
                    └─────────────────────────┘
```

## 🎯 核心优势

### 1. 🔐 集中化安全管理
- **统一密钥管理** - 所有 SSH 配置都在公共仓库
- **权限隔离** - 业务仓库无法访问敏感信息
- **审计便利** - 所有部署操作集中记录

### 2. 🌍 多语言支持
- **Node.js** - React/Vue 前端、Express API
- **Go** - 微服务、CLI 工具
- **Python** - Django/Flask 应用、数据处理
- **Rust** - 高性能服务
- **Java** - 企业应用

### 3. 🔄 标准化流程
- **统一构建** - 每种语言都有标准构建流程
- **统一部署** - 通过 workflow_dispatch 实现标准化
- **统一监控** - 集中化的部署日志和状态

### 4. 📦 极简配置
- **业务仓库** - 只需配置构建和触发
- **公共仓库** - 只需配置一次 SSH 信息
- **新增项目** - 复制模板即可

## 🔧 技术实现

### 1. 公共仓库配置

**GitHub Secrets：**
```bash
SERVER_HOST=192.168.1.100
SERVER_PORT=22
SERVER_USER=root
SERVER_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
```

**通用部署工作流：**
```yaml
# .github/workflows/deploy.yml
name: Deploy Any Project

on:
  workflow_dispatch:
    inputs:
      project: { required: true, type: string }
      lang: { required: true, type: string }
      artifact_id: { required: true, type: string }
      deploy_path: { required: true, type: string }
      start_cmd: { required: true, type: string }
```

### 2. 业务仓库配置

**Node.js 项目示例：**
```yaml
# 构建阶段
- name: 构建项目
  run: npm run build

- name: 上传构建产物
  uses: actions/upload-artifact@v4
  with:
    name: dist-my-node-app
    path: dist/

# 触发部署
- name: 触发部署
  uses: actions/github-script@v7
  with:
    script: |
      await github.rest.actions.createWorkflowDispatch({
        owner: 'your-org',
        repo: 'axi-deploy',
        workflow_id: 'deploy.yml',
        inputs: {
          project: 'my-node-app',
          lang: 'node',
          artifact_id: '${{ needs.build.outputs.artifact-id }}',
          deploy_path: '/www/wwwroot/my-node-app',
          start_cmd: 'cd /www/wwwroot/my-node-app && npm ci --production && pm2 reload app'
        }
      });
```

## 📊 方案对比

| 特性 | 传统方案 | AXI Deploy |
|------|----------|------------|
| 密钥管理 | 分散在各仓库 | 集中管理 |
| 配置复杂度 | 每个项目都要配置 | 一次配置，多处使用 |
| 安全风险 | 高风险 | 低风险 |
| 维护成本 | 高 | 低 |
| 扩展性 | 差 | 优秀 |
| 标准化 | 无 | 统一标准 |

## 🚀 部署流程

### 1. 业务仓库构建
```mermaid
graph LR
    A[代码提交] --> B[触发构建]
    B --> C[安装依赖]
    C --> D[构建项目]
    D --> E[上传产物]
    E --> F[触发部署]
```

### 2. 公共仓库部署
```mermaid
graph LR
    A[接收部署请求] --> B[下载构建产物]
    B --> C[SSH连接服务器]
    C --> D[传输文件]
    D --> E[执行启动命令]
    E --> F[验证部署]
```

## 🛡️ 安全特性

### 1. 权限隔离
- 业务仓库无法访问 SSH 密钥
- 公共仓库无法访问业务代码
- 通过 workflow_dispatch 实现安全调用

### 2. 审计日志
- 所有部署操作都有详细日志
- 可追踪每次部署的来源和结果
- 支持部署历史查询

### 3. 错误处理
- 部署失败时自动回滚
- 详细的错误信息记录
- 支持手动重试机制

## 📈 扩展性

### 1. 新增语言支持
只需在公共仓库添加新的语言处理逻辑，业务仓库无需修改。

### 2. 多环境部署
通过不同的 `inputs` 参数支持开发、测试、生产环境。

### 3. 自定义部署逻辑
通过 `start_cmd` 参数支持任意自定义启动命令。

## 🔍 监控和运维

### 1. 部署状态监控
- 实时查看部署进度
- 部署成功/失败通知
- 自动健康检查

### 2. 日志管理
- 集中化的部署日志
- 结构化日志格式
- 日志轮转和清理

### 3. 故障恢复
- 自动重试机制
- 手动回滚功能
- 紧急修复流程

## 📚 使用指南

### 快速开始
1. 配置公共仓库 Secrets
2. 选择语言模板
3. 修改配置参数
4. 测试部署流程

### 最佳实践
1. 使用语义化版本号
2. 配置环境变量管理
3. 设置监控和告警
4. 定期备份和测试

## 🎉 总结

AXI Deploy 通过集中化的部署管理，解决了多项目部署中的安全、维护、一致性等问题，提供了一个安全、高效、可扩展的部署解决方案。

**核心价值：**
- 🔐 **安全** - 集中化密钥管理
- 🚀 **高效** - 标准化部署流程
- 🌍 **通用** - 支持多种语言
- 📦 **简单** - 极简配置要求
- 🔄 **可靠** - 完善的错误处理

这个解决方案特别适合：
- 拥有多个不同语言项目的团队
- 需要统一部署流程的组织
- 重视安全性的企业环境
- 希望简化运维工作的开发者 