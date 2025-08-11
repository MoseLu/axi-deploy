# 重试中心使用指南

## 问题解决

之前的错误 `Error: Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/axi-deploy/axi-deploy/.github/actions/retry-center'` 已经解决。

**问题原因：**
- 原工作流试图在 `workflow_call` 类型的工作流中使用本地 action
- GitHub Actions 在运行时可能在不同的上下文中执行，无法找到本地 action 文件

**解决方案：**
- 将重试逻辑直接集成到工作流中，移除对本地 action 的依赖
- 重试中心现在是一个完全自包含的可复用工作流

## 使用方法

### 1. 基本用法

```yaml
jobs:
  my-job:
    uses: ./.github/workflows/retry-center.yml
    with:
      step_name: "部署应用"
      command: "npm run deploy"
      max_retries: 3
      retry_delay: 5
      timeout_minutes: 10
```

### 2. 完整配置示例

```yaml
jobs:
  deploy-with-retry:
    uses: ./.github/workflows/retry-center.yml
    with:
      # 重试配置
      max_retries: 3
      retry_delay: 5
      timeout_minutes: 15
      retry_strategy: "exponential"  # simple/exponential/adaptive
      
      # 执行配置
      step_name: "部署到生产环境"
      command: "docker-compose up -d"
      
      # 错误处理
      continue_on_error: false
      notify_on_failure: true
      
      # 步骤类型
      step_type: "network"  # network/file_operation/validation/parsing
      
      # 环境变量（JSON格式）
      env_vars: '{"NODE_ENV":"production","DEBUG":"false"}'
```

### 3. 获取输出结果

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/retry-center.yml
    with:
      step_name: "部署"
      command: "npm run deploy"
      
  display-results:
    runs-on: ubuntu-latest
    needs: deploy
    steps:
      - name: 显示部署结果
        run: |
          echo "部署成功: ${{ needs.deploy.outputs.success }}"
          echo "重试次数: ${{ needs.deploy.outputs.attempts }}"
          echo "执行时间: ${{ needs.deploy.outputs.execution_time }}秒"
          echo "错误信息: ${{ needs.deploy.outputs.error_message }}"
```

## 重试策略

### 1. Simple（简单重试）
- 固定间隔重试
- 每次重试间隔相同

### 2. Exponential（指数退避）
- 重试间隔逐渐增加
- 公式：`delay * (2 ^ (attempt - 1))`

### 3. Adaptive（自适应）
- 重试间隔线性增加
- 公式：`delay + attempt * 2`

## 输出参数

| 参数 | 描述 | 类型 |
|------|------|------|
| `success` | 执行是否成功 | boolean |
| `attempts` | 实际重试次数 | number |
| `execution_time` | 总执行时间（秒） | number |
| `error_message` | 错误信息（如果失败） | string |
| `retry_report` | 重试报告（JSON格式） | string |

## 错误处理

### 超时处理
- 使用 `timeout` 命令限制单次执行时间
- 超时退出码为 124

### 失败处理
- 根据 `continue_on_error` 参数决定是否继续执行
- 支持失败通知（可集成 Slack、Email 等）

## 报告生成

重试中心会自动生成详细的重试报告，包括：
- 执行统计信息
- 重试配置
- 环境信息
- 时间戳

报告会作为 artifact 上传，保留 30 天。

## 最佳实践

1. **合理设置超时时间**：根据命令的预期执行时间设置
2. **选择合适的重试策略**：
   - 网络操作：使用 exponential 策略
   - 文件操作：使用 simple 策略
   - 复杂验证：使用 adaptive 策略
3. **设置合理的重试次数**：避免无限重试
4. **使用描述性的步骤名称**：便于调试和监控
5. **启用失败通知**：及时发现问题

## 故障排除

### 常见问题

1. **工作流找不到**：确保路径正确 `./.github/workflows/retry-center.yml`
2. **命令执行失败**：检查命令语法和依赖
3. **超时问题**：调整 `timeout_minutes` 参数
4. **重试次数过多**：检查 `max_retries` 设置

### 调试技巧

1. 查看重试报告 artifact
2. 检查工作流日志中的详细输出
3. 使用 `continue_on_error: true` 进行测试
4. 设置较小的重试间隔进行快速测试
