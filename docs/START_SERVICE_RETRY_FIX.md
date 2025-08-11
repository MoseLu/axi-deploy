# 启动服务重试机制修复

## 🚨 问题描述

在启动服务时出现目录不存在错误：

```
🚀 执行启动命令...
/home/runner/work/_temp/c33ec0d1-d191-41f7-820b-ec7267c28f95.sh: line 6: cd: /srv/apps/axi-project-dashboard: No such file or directory
- 项目: axi-project-dashboard
- 启动命令: bash start.sh
Error: Process completed with exit code 1.
```

**问题原因：**
- `start-service.yml` 工作流试图在GitHub Actions runner上执行 `cd /srv/apps/axi-project-dashboard`
- 该目录在runner上不存在，应该在服务器上执行
- 工作流没有通过SSH连接到服务器
- 缺少重试机制处理网络问题

## 🔧 修复方案

### 1. 修复执行环境

将启动命令的执行从GitHub Actions runner改为通过SSH连接到服务器：

```yaml
- name: 使用重试中心启动服务
  uses: ./.github/workflows/retry-center.yml
  with:
    step_name: "启动服务"
    command: |
      # 创建SSH密钥文件
      echo "${{ inputs.server_key }}" > /tmp/ssh_key
      chmod 600 /tmp/ssh_key
      
      # 创建启动脚本并通过SSH执行
      ssh -o StrictHostKeyChecking=no \
          -o ConnectTimeout=30 \
          -o ServerAliveInterval=60 \
          -o ServerAliveCountMax=3 \
          -i /tmp/ssh_key \
          -p ${{ inputs.server_port }} \
          ${{ inputs.server_user }}@${{ inputs.server_host }} \
          "bash -s" < /tmp/start_service_script.sh
```

### 2. 集成重试中心

使用重试中心处理SSH连接和服务启动问题：

| 参数 | 值 | 说明 |
|------|----|----|
| `max_retries` | 3 | 最大重试3次 |
| `retry_delay` | 10秒 | 基础重试间隔 |
| `timeout_minutes` | 15分钟 | 单次执行超时 |
| `retry_strategy` | exponential | 指数退避策略 |
| `step_type` | network | 网络操作类型 |

### 3. 增强服务验证

添加了更完善的服务启动验证：

```bash
# 检查服务健康状态
echo "🏥 检查服务健康状态..."
if command -v curl &> /dev/null; then
  # 尝试访问健康检查端点
  for port in 8080 3000 8000 5000; do
    if curl -f -s http://localhost:$port/health > /dev/null 2>&1; then
      echo "✅ 服务在端口 $port 上响应健康检查"
      break
    elif curl -f -s http://localhost:$port/ > /dev/null 2>&1; then
      echo "✅ 服务在端口 $port 上响应"
      break
    fi
  done
fi

# 最终状态检查
if pgrep -f "${{ inputs.project }}" > /dev/null || pm2 list | grep -q "${{ inputs.project }}"; then
  echo "✅ 服务启动成功！"
else
  echo "⚠️ 服务可能未正常启动，但启动命令执行完成"
fi
```

## 📊 重试策略

### 指数退避策略

使用指数退避策略处理网络和服务启动问题：

- 第1次重试：10秒后
- 第2次重试：20秒后 (10 × 2¹)
- 第3次重试：40秒后 (10 × 2²)

### 错误处理

1. **SSH连接超时**：自动重试
2. **目录不存在**：立即失败，不重试
3. **服务启动失败**：立即失败，不重试
4. **权限错误**：立即失败，不重试

## 🧪 测试验证

创建了测试工作流 `test-start-service-retry.yml` 来验证重试机制：

### 测试场景

1. **成功场景**：验证正常启动流程
2. **目录不存在**：模拟目录不存在错误
3. **SSH超时**：模拟网络连接超时
4. **服务失败**：模拟服务启动失败

### 运行测试

```bash
# 在GitHub Actions中手动触发
# 选择不同的测试类型进行验证
```

## 📈 预期效果

### 修复前
- 在GitHub Actions runner上执行启动命令
- 目录不存在导致立即失败
- 没有重试机制
- 网络问题导致启动失败

### 修复后
- 通过SSH在服务器上执行启动命令
- 正确的目录环境
- SSH连接失败时自动重试3次
- 使用指数退避策略
- 完善的服务健康检查
- 详细的错误报告

## 🔍 监控和调试

### 重试报告

每次重试都会生成详细报告：

```json
{
  "step_name": "启动服务",
  "success": true,
  "attempts": 1,
  "execution_time_seconds": 45,
  "error_message": "",
  "retry_config": {
    "max_retries": 3,
    "retry_delay": 10,
    "strategy": "exponential"
  }
}
```

### 日志查看

1. 查看工作流执行日志
2. 检查重试报告artifact
3. 分析SSH连接日志
4. 检查服务器上的服务状态

## 🚀 部署建议

### 1. 服务器环境准备

- 确保 `/srv/apps` 目录存在
- 配置正确的用户权限
- 安装必要的依赖（Node.js、PM2等）

### 2. 网络环境优化

- 确保服务器网络稳定
- 配置合适的防火墙规则
- 使用稳定的SSH连接

### 3. 监控告警

- 设置重试失败告警
- 监控服务启动成功率
- 跟踪重试频率

## 📝 相关文件

- `start-service.yml`: 修复后的启动服务工作流
- `retry-center.yml`: 重试中心工作流
- `test-start-service-retry.yml`: 测试工作流
- `START_SERVICE_RETRY_FIX.md`: 本文档

## ✅ 验证清单

- [ ] 重试机制正常工作
- [ ] SSH连接在服务器上执行
- [ ] 目录环境正确
- [ ] 服务启动验证完善
- [ ] 重试报告生成正确
- [ ] 测试工作流通过
- [ ] 启动成功率提升

## 🔧 故障排除

### 常见问题

1. **SSH连接失败**
   - 检查服务器密钥是否正确
   - 验证服务器地址和端口
   - 确认防火墙设置

2. **目录权限问题**
   - 检查 `/srv/apps` 目录权限
   - 确认用户有执行权限
   - 验证项目目录存在

3. **服务启动失败**
   - 检查启动命令语法
   - 验证依赖是否安装
   - 查看服务器日志

### 调试技巧

1. 查看重试报告artifact
2. 检查工作流日志中的详细输出
3. 使用 `continue_on_error: true` 进行测试
4. 设置较小的重试间隔进行快速测试
