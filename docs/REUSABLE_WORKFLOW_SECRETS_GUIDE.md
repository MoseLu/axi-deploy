# 可复用工作流 Secrets 限制指南

## 问题描述

### GitHub Actions 安全限制

**⚠️ 重要限制**：可复用工作流（reusable workflows）无法直接访问调用者仓库的 secrets。这是 GitHub Actions 的安全限制，旨在保护敏感信息。

### 影响范围

当业务仓库调用 `axi-deploy` 的可复用工作流时，以下 secrets 无法直接访问：

- `DEPLOY_CENTER_PAT` - GitHub Token
- `SERVER_HOST` - 服务器地址
- `SERVER_USER` - 服务器用户名
- `SERVER_KEY` - 服务器SSH私钥
- `SERVER_PORT` - 服务器SSH端口

## 解决方案

### 1. 通过输入参数传递

所有必需的 secrets 必须通过 `inputs` 参数传递：

```yaml
# 在业务仓库的工作流中
- name: 触发部署
  uses: MoseLu/axi-deploy/.github/workflows/main-deployment.yml@master
  with:
    project: ${{ github.event.repository.name }}
    source_repo: ${{ github.repository }}
    run_id: ${{ github.run_id }}
    deploy_center_pat: ${{ secrets.DEPLOY_CENTER_PAT }}
    server_host: ${{ secrets.SERVER_HOST }}
    server_user: ${{ secrets.SERVER_USER }}
    server_key: ${{ secrets.SERVER_KEY }}
    server_port: ${{ secrets.SERVER_PORT }}
    deploy_type: 'static'
```

### 2. 通过 repository_dispatch 事件传递

从业务仓库发送 `repository_dispatch` 事件时，必须包含所有必需参数：

```javascript
// 在业务仓库的工作流中
await github.rest.repos.createDispatchEvent({
  owner: 'MoseLu',
  repo: 'axi-deploy',
  event_type: 'deploy',
  client_payload: {
    // 必需参数
    project: 'my-project',
    source_repo: 'owner/repo',
    run_id: '1234567890',
    server_host: 'your-server.com',
    server_user: 'deploy',
    server_key: 'your-ssh-private-key',
    server_port: '22',
    deploy_center_pat: 'your-github-token',
    
    // 可选参数
    deploy_type: 'static',
    nginx_config: 'server { ... }',
    test_url: 'https://example.com/',
    start_cmd: 'sudo systemctl restart my-service'
  }
});
```

## 参数说明

### 必需参数

| 参数 | 类型 | 描述 | 示例 |
|------|------|------|------|
| `project` | string | 项目名称 | `my-project` |
| `source_repo` | string | 源仓库 (格式: owner/repo) | `owner/repo` |
| `run_id` | string | 构建运行ID | `1234567890` |
| `server_host` | string | 服务器地址 | `your-server.com` |
| `server_user` | string | 服务器用户名 | `deploy` |
| `server_key` | string | 服务器SSH私钥 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `server_port` | string | 服务器SSH端口 | `22` |
| `deploy_center_pat` | string | GitHub Token (用于下载构建产物) | `ghp_xxxxxxxxxxxxxxxx` |

### 可选参数

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `deploy_type` | string | `static` | 部署类型 (static/backend) |
| `nginx_config` | string | - | Nginx配置 |
| `test_url` | string | - | 测试URL |
| `start_cmd` | string | - | 启动命令（后端项目） |

## 实施步骤

### 1. 业务仓库配置

在业务仓库的 Settings > Secrets and variables > Actions 中配置：

```yaml
# 必需的 Secrets
DEPLOY_CENTER_PAT: your-github-token
SERVER_HOST: your-server.com
SERVER_USER: deploy
SERVER_KEY: your-ssh-private-key
SERVER_PORT: 22
```

### 2. 工作流配置

在业务仓库的工作流中使用：

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: 触发部署
        uses: MoseLu/axi-deploy/.github/workflows/main-deployment.yml@master
        with:
          project: ${{ github.event.repository.name }}
          source_repo: ${{ github.repository }}
          run_id: ${{ github.run_id }}
          deploy_center_pat: ${{ secrets.DEPLOY_CENTER_PAT }}
          server_host: ${{ secrets.SERVER_HOST }}
          server_user: ${{ secrets.SERVER_USER }}
          server_key: ${{ secrets.SERVER_KEY }}
          server_port: ${{ secrets.SERVER_PORT }}
          deploy_type: 'static'
          test_url: 'https://your-domain.com/'
```

### 3. 验证配置

确保所有必需参数都已正确配置：

```bash
# 检查参数是否传递成功
echo "项目: ${{ inputs.project }}"
echo "源仓库: ${{ inputs.source_repo }}"
echo "构建ID: ${{ inputs.run_id }}"
echo "服务器: ${{ inputs.server_host }}:${{ inputs.server_port }}"
echo "用户: ${{ inputs.server_user }}"
```

## 常见问题

### Q1: 为什么需要传递 DEPLOY_CENTER_PAT？

A: 可复用工作流无法访问调用者仓库的 secrets，必须通过输入参数传递 GitHub Token 才能下载构建产物。

### Q2: 如何获取 DEPLOY_CENTER_PAT？

A: 在 GitHub 个人设置中创建 Personal Access Token，或者使用 GitHub App 的 token。

### Q3: 参数传递失败怎么办？

A: 检查参数名称是否正确，确保所有必需参数都已提供，查看工作流日志中的错误信息。

### Q4: 如何保护敏感信息？

A: 使用 GitHub Secrets 存储敏感信息，不要在工作流文件中硬编码。

## 最佳实践

1. **参数验证**：在业务仓库中验证所有必需参数
2. **错误处理**：提供清晰的错误信息和调试数据
3. **安全考虑**：使用最小权限原则配置 GitHub Token
4. **文档维护**：及时更新参数说明和示例
5. **测试验证**：在测试环境中验证配置是否正确

## 总结

通过将 secrets 转换为输入参数，我们解决了可复用工作流的安全限制问题。这种方式虽然需要更多的配置，但提供了更好的安全性和灵活性。

**关键要点**：
- ✅ 所有 secrets 必须通过输入参数传递
- ✅ 业务仓库需要配置相应的 secrets
- ✅ 工作流会验证所有必需参数
- ✅ 提供详细的错误信息和调试数据
