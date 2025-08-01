# 📝 变更日志

## [2.0.0] - 2024-01-XX

### 🚀 重大更新 - 多语言部署系统

#### 新增功能

- 🌍 **多语言支持**
  - 支持 Node.js、Go、Python、Rust、Java 等多种语言
  - 每种语言都有专门的构建和部署模板
  - 统一的部署流程，差异化的启动命令

- 🔐 **增强安全性**
  - 集中化的 SSH 密钥管理
  - 业务仓库无需配置敏感信息
  - 完善的权限隔离机制

- 📦 **标准化流程**
  - 统一的构建产物上传机制
  - 标准化的部署触发流程
  - 完善的错误处理和日志记录

#### 核心改进

1. **主部署工作流** (`.github/workflows/deploy.yml`)
   - 支持多语言项目识别
   - 增强的输入参数验证
   - 改进的日志输出格式
   - 更好的错误处理机制

2. **示例模板**
   - `examples/node-project-deploy.yml` - Node.js 项目模板
   - `examples/go-project-deploy.yml` - Go 项目模板
   - `examples/python-project-deploy.yml` - Python 项目模板
   - `examples/rust-project-deploy.yml` - Rust 项目模板

3. **文档更新**
   - `README.md` - 完整的多语言部署指南
   - `QUICKSTART.md` - 快速开始指南
   - `SOLUTION.md` - 解决方案说明
   - `examples/deployment-scenarios.md` - 部署场景指南

#### 技术改进

- **构建产物管理**
  - 使用 `actions/upload-artifact@v4` 上传构建产物
  - 通过 `artifact_id` 参数传递产物标识
  - 支持产物保留期设置

- **部署触发机制**
  - 使用 `actions/github-script@v7` 触发部署
  - 通过 `workflow_dispatch` 实现安全调用
  - 支持完整的部署参数传递

- **服务器配置**
  - 改进的 SSH 连接配置
  - 更好的文件传输机制
  - 增强的启动命令执行

#### 配置要求

**公共仓库 Secrets：**
```bash
SERVER_HOST=192.168.1.100
SERVER_PORT=22
SERVER_USER=root
SERVER_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
```

**业务仓库 Secrets：**
```bash
DEPLOY_CENTER_PAT=your-personal-access-token
```

#### 使用方式

1. **配置公共仓库**
   - 设置 GitHub Secrets
   - 验证 SSH 连接

2. **配置业务仓库**
   - 获取 Personal Access Token
   - 选择语言模板
   - 修改配置参数

3. **触发部署**
   - 推送代码到主分支
   - 查看构建和部署状态
   - 验证部署结果

#### 向后兼容性

- ✅ 保持原有的 SSH 部署功能
- ✅ 支持现有的工作流调用方式
- ✅ 兼容现有的服务器配置

#### 迁移指南

**从旧版本迁移：**

1. 更新公共仓库的部署工作流
2. 在业务仓库中配置 `DEPLOY_CENTER_PAT`
3. 选择对应的语言模板
4. 修改配置参数
5. 测试部署流程

#### 故障排除

- **SSH 连接失败** - 检查 Secrets 配置
- **构建失败** - 检查语言模板配置
- **部署失败** - 检查启动命令和路径权限

#### 未来计划

- [ ] 支持更多语言（Java、PHP、.NET 等）
- [ ] 添加 Docker 部署支持
- [ ] 实现蓝绿部署
- [ ] 添加部署回滚功能
- [ ] 支持多环境部署

---

## [1.0.0] - 2024-01-XX

### 🎉 初始版本

- 基础的 SSH 部署功能
- workflow_dispatch 触发机制
- 简单的文件传输和命令执行
- 基础的错误处理和日志记录 