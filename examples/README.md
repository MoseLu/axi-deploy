# AXI Deploy 示例文件结构

本目录包含了AXI Deploy的各种示例文件和配置，按类型进行了分类整理。

## 目录结构

### 📁 deployments/ - 部署配置文件
按项目类型分类的GitHub Actions部署配置文件

#### 📁 frontend/ - 前端项目部署
- `vue-project-deploy.yml` - Vue.js项目部署配置
- `react-project-deploy.yml` - React项目部署配置

#### 📁 backend/ - 后端项目部署
- `go-project-deploy.yml` - Go项目基础部署配置
- `go-project-deploy-fixed.yml` - Go项目修复版部署配置
- `node-project-deploy.yml` - Node.js项目部署配置
- `python-project-deploy.yml` - Python项目部署配置
- `axi-star-cloud-deploy.yml` - AXI Star Cloud项目部署配置

#### 📁 docs/ - 文档项目部署
- `vitepress-project-deploy.yml` - VitePress文档项目部署配置
- `axi-docs-deploy-fixed.yml` - AXI Docs修复版部署配置
- `axi-docs-pnpm-deploy.yml` - AXI Docs使用pnpm的部署配置

### 📁 docs/ - 文档说明
- `deployment-types-comparison.md` - 不同部署类型对比说明
- `deployment-verification.md` - 部署验证指南
- `axi-star-cloud-fix-summary.md` - AXI Star Cloud修复总结

### 📁 configs/ - 配置文件
- `axi-docs-nginx-config.md` - AXI Docs的Nginx配置
- `nginx-includes-config.md` - Nginx包含文件配置说明

## 使用说明

1. **选择部署类型**: 根据您的项目类型选择对应的部署配置文件
2. **参考文档**: 查看docs目录中的相关说明文档
3. **配置服务器**: 如需Nginx配置，参考configs目录中的配置文件

## 快速开始

1. 复制对应项目类型的部署配置文件到您的项目根目录
2. 重命名为 `.github/workflows/deploy.yml`
3. 根据您的项目需求修改配置参数
4. 提交并推送到GitHub，触发自动部署 