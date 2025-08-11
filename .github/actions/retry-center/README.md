# 重试中心 (Retry Center)

统一管理 GitHub Actions 工作流中的重试机制，提供智能重试策略和进度跟踪。

## 特性

- 🎯 **智能重试策略**：支持简单、指数退避、自适应重试
- 📊 **进度跟踪**：实时跟踪执行进度和重试状态
- 🔧 **灵活配置**：根据不同步骤类型自动选择重试策略
- 📈 **详细报告**：生成执行报告和性能指标
- 🔔 **失败通知**：支持多种通知渠道
- 🎨 **可视化准备**：为未来集成到 axi-project-dashboard 做准备

## 快速开始

### 基本用法

```yaml
- name: 使用重试中心执行命令
  uses: ./.github/actions/retry-center
  with:
    step_name: "部署项目"
    command: "echo '部署命令'"
    max_retries: 3
    retry_delay: 5
    timeout_minutes: 10
    strategy: "exponential"
```

### 高级用法

```yaml
- name: 网络操作重试
  uses: ./.github/actions/retry-center
  with:
    step_name: "上传文件"
    command: "scp file.txt user@server:/path/"
    max_retries: 5
    retry_delay: 10
    timeout_minutes: 15
    strategy: "adaptive"
    continue_on_error: false
    notify_on_failure: true
```

## 重试策略

### 1. Simple (简单重试)
- 固定延迟时间
- 适用于临时性错误
- 配置示例：`strategy: "simple"`

### 2. Exponential (指数退避)
- 延迟时间递增 (5s, 10s, 20s...)
- 适用于网络波动
- 配置示例：`strategy: "exponential"`

### 3. Adaptive (自适应重试)
- 根据错误类型调整延迟
- 智能错误处理
- 配置示例：`strategy: "adaptive"`

## 步骤类型配置

### 网络操作 (network)
```yaml
type: "network"
default_retries: 3
default_delay: 5
default_timeout: 10
default_strategy: "exponential"
retryable: true
```

### 文件操作 (file_operation)
```yaml
type: "file_operation"
default_retries: 2
default_delay: 3
default_timeout: 5
default_strategy: "simple"
retryable: true
```

### 验证操作 (validation)
```yaml
type: "validation"
default_retries: 0
default_delay: 0
default_timeout: 2
default_strategy: "simple"
retryable: false
```

### 解析操作 (parsing)
```yaml
type: "parsing"
default_retries: 0
default_delay: 0
default_timeout: 1
default_strategy: "simple"
retryable: false
```

## 错误类型处理

### 可重试错误
- timeout
- connection refused
- network unreachable
- temporary failure
- rate limit
- server error
- gateway timeout
- service unavailable

### 不可重试错误
- permission denied
- file not found
- invalid argument
- syntax error
- authentication failed
- invalid credentials

## 输出参数

```yaml
outputs:
  success: "执行是否成功"
  attempts: "实际重试次数"
  execution_time: "总执行时间（秒）"
  error_message: "错误信息（如果失败）"
```

## 使用示例

### 在 deploy-project.yml 中使用

```yaml
- name: 下载构建产物
  uses: ./.github/actions/retry-center
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
    continue_on_error: false
```

### 在 start-service.yml 中使用

```yaml
- name: 启动服务
  uses: ./.github/actions/retry-center
  with:
    step_name: "启动 PM2 服务"
    command: |
      pm2 start ecosystem.config.js
      pm2 save
    max_retries: 2
    retry_delay: 15
    timeout_minutes: 15
    strategy: "exponential"
    continue_on_error: false
```

## 报告和监控

### 执行报告
重试中心会自动生成 JSON 格式的执行报告：

```json
{
  "step_name": "部署项目",
  "success": true,
  "attempts": 1,
  "execution_time_seconds": 45,
  "timestamp": "2024-01-01T12:00:00Z",
  "error_message": "",
  "workflow_run_id": "123456789",
  "job_name": "deploy"
}
```

### 性能指标
- 执行时间统计
- 重试次数统计
- 成功率统计
- 错误类型分析

## 未来扩展

### 可视化集成
重试中心设计为未来集成到 axi-project-dashboard 做准备：

1. **实时进度显示**：在 dashboard 中显示重试进度
2. **历史记录**：查看历史重试记录和成功率
3. **配置管理**：通过 UI 管理重试策略
4. **告警设置**：配置重试失败通知

### 通知集成
支持多种通知渠道：
- GitHub Actions 内置通知
- Slack 集成
- Email 通知
- 自定义 Webhook

## 最佳实践

1. **合理设置重试次数**：避免无限重试
2. **选择合适的策略**：根据操作类型选择重试策略
3. **设置合理超时**：避免长时间等待
4. **监控重试频率**：及时发现系统问题
5. **记录详细日志**：便于问题排查

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
2. 查看执行报告：检查生成的 JSON 报告
3. 分析错误模式：根据错误类型调整策略
