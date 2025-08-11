# 重试中心部署总结

## 部署概述

重试中心已成功部署到 axi-deploy 项目中，作为一个可复用的 GitHub Actions 工作流，用于统一管理所有工作流中的重试机制。

## 已创建的文件

### 1. 重试中心核心文件
- `.github/actions/retry-center/action.yml` - 重试中心Action配置
- `.github/actions/retry-center/retry-logic.sh` - 重试逻辑脚本
- `.github/actions/retry-center/retry-config.yml` - 重试配置
- `.github/actions/retry-center/README.md` - 重试中心文档

### 2. 重试中心可复用工作流
- `.github/workflows/retry-center.yml` - 重试中心可复用工作流
- `.github/workflows/retry-center-example.yml` - 使用示例工作流

### 3. 部署脚本
- `scripts/apply-retry-center.sh` - 重试中心应用检查脚本
- `scripts/deploy-retry-center.sh` - 重试中心部署脚本
- `scripts/deploy-retry-center-workflow.sh` - 重试中心工作流部署脚本

### 4. 文档
- `RETRY_CENTER_USAGE.md` - 详细使用指南
- `RETRY_CENTER_DEPLOYMENT_SUMMARY.md` - 本部署总结文档

## 已应用重试中心的工作流

### 1. deploy-project.yml
- ✅ 已应用重试中心到"下载构建产物"步骤
- 🔧 配置：3次重试，10秒延迟，指数退避策略
- 📊 类型：网络操作

### 2. start-service.yml
- ✅ 已应用重试中心到"启动服务"步骤
- 🔧 配置：2次重试，15秒延迟，指数退避策略
- 📊 类型：服务启动

### 3. health-check.yml
- ⚠️ 需要手动应用重试中心
- 🔧 建议配置：2次重试，10秒延迟，简单策略
- 📊 类型：健康检查

## 重试中心特性

### 🎯 智能重试策略
- **Simple (简单重试)**：固定延迟时间
- **Exponential (指数退避)**：延迟时间递增
- **Adaptive (自适应重试)**：根据错误类型调整延迟

### 📊 进度跟踪
- 实时跟踪执行进度和重试状态
- 详细的重试日志和错误信息
- 执行时间统计

### 🔧 灵活配置
- 根据不同步骤类型自动选择重试策略
- 支持自定义重试次数、延迟和超时
- 环境变量支持

### 📈 详细报告
- 自动生成JSON格式的执行报告
- 性能指标统计
- 错误类型分析

### 🔔 失败通知
- 支持多种通知渠道
- 可配置的通知条件
- 详细的失败信息

## 使用方式

### 基本用法
```yaml
- name: 使用重试中心执行命令
  uses: ./.github/workflows/retry-center.yml
  with:
    step_name: "步骤名称"
    command: "要执行的命令"
    max_retries: 3
    retry_delay: 5
    timeout_minutes: 10
    strategy: "exponential"
    step_type: "network"
    continue_on_error: false
    notify_on_failure: true
```

### 在deploy-project.yml中的使用
```yaml
- name: 下载构建产物
  uses: ./.github/workflows/retry-center.yml
  with:
    step_name: "下载构建产物"
    command: |
      gh run download ${{ inputs.run_id }} \
        --name "dist-${{ inputs.project }}" \
        --dir . \
        --repo ${{ inputs.source_repo }}
    max_retries: 3
    retry_delay: 10
    timeout_minutes: 15
    strategy: "exponential"
    step_type: "network"
    continue_on_error: false
    notify_on_failure: true
    env_vars: '{"GH_TOKEN": "${{ inputs.deploy_center_pat || github.token }}"}'
```

## 输出参数

重试中心工作流提供以下输出参数：

| 参数 | 描述 |
|------|------|
| success | 执行是否成功 |
| attempts | 实际重试次数 |
| execution_time | 总执行时间（秒） |
| error_message | 错误信息（如果失败） |
| retry_report | 重试报告（JSON格式） |

## 重试报告示例

```json
{
  "step_name": "下载构建产物",
  "workflow_run_id": "123456789",
  "job_name": "retry-execution",
  "timestamp": "2024-01-01T12:00:00Z",
  "success": true,
  "attempts": 1,
  "execution_time_seconds": 45,
  "error_message": "",
  "retry_config": {
    "max_retries": 3,
    "retry_delay": 10,
    "timeout_minutes": 15,
    "strategy": "exponential",
    "step_type": "network"
  },
  "environment": {
    "runner": "ubuntu-latest",
    "workflow": "deploy-project",
    "repository": "owner/repo"
  }
}
```

## 步骤类型配置

| 类型 | 默认重试次数 | 默认延迟 | 默认超时 | 默认策略 | 是否可重试 |
|------|-------------|----------|----------|----------|------------|
| network | 3 | 5s | 10min | exponential | 是 |
| file_operation | 2 | 3s | 5min | simple | 是 |
| validation | 0 | 0s | 2min | simple | 否 |
| parsing | 0 | 0s | 1min | simple | 否 |

## 下一步操作

### 1. 测试重试中心
运行示例工作流测试重试中心功能：
```bash
# 在GitHub Actions中手动触发 retry-center-example.yml
```

### 2. 应用到其他工作流
将重试中心应用到其他需要重试机制的工作流：
- `configure-nginx.yml`
- `download-and-validate.yml`
- `validate-artifact.yml`
- `backup-deployment.yml`
- `rollback.yml`

### 3. 监控和优化
- 监控重试频率和成功率
- 根据实际情况调整重试策略
- 优化超时时间和重试次数

### 4. 集成到Dashboard
为未来集成到 axi-project-dashboard 做准备：
- 实时进度显示
- 历史记录查看
- 配置管理界面
- 告警设置

## 故障排除

### 常见问题

1. **重试次数过多**
   - 检查网络连接
   - 验证服务器状态
   - 调整重试策略

2. **超时错误**
   - 增加超时时间
   - 检查命令复杂度
   - 优化执行逻辑

3. **权限错误**
   - 检查认证信息
   - 验证访问权限
   - 确认密钥有效性

### 调试技巧

1. 启用详细日志：设置 `GITHUB_ACTIONS_STEP_DEBUG=true`
2. 查看重试报告：检查生成的JSON报告
3. 分析错误模式：根据错误类型调整策略

## 总结

重试中心已成功部署并部分应用到关键工作流中。它提供了：

- ✅ 统一的重试机制管理
- ✅ 智能重试策略
- ✅ 详细的执行报告
- ✅ 灵活的配置选项
- ✅ 失败通知功能

建议在测试环境验证重试中心功能后，逐步应用到其他工作流中，以提高整个部署系统的稳定性和可靠性。

---

**部署时间**: $(date)
**部署状态**: ✅ 完成
**下一步**: 测试和优化
