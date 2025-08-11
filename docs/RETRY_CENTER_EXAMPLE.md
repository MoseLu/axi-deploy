# 重试中心集成示例

## 在现有工作流中使用重试中心

### 示例1：部署步骤重试

```yaml
name: 部署应用

on:
  push:
    branches: [ main ]

jobs:
  # 使用重试中心进行部署
  deploy:
    uses: ./.github/workflows/retry-center.yml
    with:
      step_name: "部署应用到服务器"
      command: |
        echo "开始部署..."
        docker-compose down
        docker-compose up -d
        echo "部署完成"
      max_retries: 3
      retry_delay: 10
      timeout_minutes: 20
      retry_strategy: "exponential"
      continue_on_error: false
      notify_on_failure: true
      step_type: "network"
      
  # 部署后的健康检查
  health-check:
    runs-on: ubuntu-latest
    needs: deploy
    if: needs.deploy.outputs.success == 'true'
    steps:
      - name: 健康检查
        run: |
          echo "部署成功，进行健康检查..."
          curl -f http://localhost:3000/health || exit 1
```

### 示例2：文件操作重试

```yaml
name: 文件同步

on:
  workflow_dispatch:

jobs:
  sync-files:
    uses: ./.github/workflows/retry-center.yml
    with:
      step_name: "同步配置文件"
      command: |
        echo "同步配置文件..."
        rsync -av --delete config/ /remote/config/
        echo "同步完成"
      max_retries: 2
      retry_delay: 5
      timeout_minutes: 15
      retry_strategy: "simple"
      continue_on_error: true
      notify_on_failure: false
      step_type: "file_operation"
```

### 示例3：API调用重试

```yaml
name: API测试

on:
  schedule:
    - cron: '0 */6 * * *'  # 每6小时执行

jobs:
  test-api:
    uses: ./.github/workflows/retry-center.yml
    with:
      step_name: "测试API端点"
      command: |
        echo "测试API端点..."
        curl -f -X POST \
          -H "Content-Type: application/json" \
          -d '{"test": "data"}' \
          https://api.example.com/test
        echo "API测试完成"
      max_retries: 5
      retry_delay: 30
      timeout_minutes: 10
      retry_strategy: "adaptive"
      continue_on_error: false
      notify_on_failure: true
      step_type: "network"
      env_vars: '{"API_KEY":"${{ secrets.API_KEY }}"}'
```

### 示例4：复杂命令重试

```yaml
name: 数据库迁移

on:
  push:
    branches: [ develop ]

jobs:
  migrate-database:
    uses: ./.github/workflows/retry-center.yml
    with:
      step_name: "执行数据库迁移"
      command: |
        echo "开始数据库迁移..."
        
        # 备份当前数据库
        pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
        
        # 执行迁移
        npm run migrate
        
        # 验证迁移结果
        npm run validate-migration
        
        echo "数据库迁移完成"
      max_retries: 2
      retry_delay: 60
      timeout_minutes: 30
      retry_strategy: "exponential"
      continue_on_error: false
      notify_on_failure: true
      step_type: "validation"
      env_vars: '{"DATABASE_URL":"${{ secrets.DATABASE_URL }}","NODE_ENV":"production"}'
```

## 获取重试结果

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/retry-center.yml
    with:
      step_name: "部署"
      command: "npm run deploy"
      
  post-deploy:
    runs-on: ubuntu-latest
    needs: deploy
    steps:
      - name: 显示部署结果
        run: |
          echo "=== 部署结果 ==="
          echo "成功: ${{ needs.deploy.outputs.success }}"
          echo "重试次数: ${{ needs.deploy.outputs.attempts }}"
          echo "执行时间: ${{ needs.deploy.outputs.execution_time }}秒"
          
          if [ "${{ needs.deploy.outputs.success }}" = "false" ]; then
            echo "错误信息: ${{ needs.deploy.outputs.error_message }}"
            echo "重试报告: ${{ needs.deploy.outputs.retry_report }}"
          fi
          
      - name: 条件执行
        if: needs.deploy.outputs.success == 'true'
        run: |
          echo "部署成功，执行后续步骤..."
          
      - name: 失败处理
        if: needs.deploy.outputs.success == 'false'
        run: |
          echo "部署失败，执行回滚..."
```

## 最佳实践

1. **合理设置重试参数**：
   - 网络操作：`max_retries: 3-5`, `retry_delay: 10-30`
   - 文件操作：`max_retries: 2-3`, `retry_delay: 5-10`
   - 数据库操作：`max_retries: 1-2`, `retry_delay: 60+`

2. **使用适当的重试策略**：
   - 网络问题：`exponential`
   - 文件系统：`simple`
   - 复杂操作：`adaptive`

3. **设置合理的超时时间**：
   - 根据命令的预期执行时间设置
   - 考虑网络延迟和系统负载

4. **错误处理**：
   - 关键步骤：`continue_on_error: false`
   - 非关键步骤：`continue_on_error: true`

5. **监控和通知**：
   - 生产环境：`notify_on_failure: true`
   - 开发环境：`notify_on_failure: false`
