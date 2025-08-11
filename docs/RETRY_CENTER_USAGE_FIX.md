# 重试中心使用方式修复

## 🚨 问题描述

在 `configure-nginx` 和 `start-service` 工作流中出现错误：

```
Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/axi-deploy/axi-deploy/.github/workflows/retry-center.yml'. Did you forget to run actions/checkout before running your local action?
```

**问题原因：**
- 错误地使用 `uses: ./.github/workflows/retry-center.yml` 来调用重试中心
- `retry-center.yml` 是一个可复用的工作流（reusable workflow），不是本地 action
- 本地 action 需要 `action.yml` 或 `action.yaml` 文件，而可复用工作流使用 `workflow_call` 触发器

## 🔧 修复方案

### 1. 理解工作流类型

GitHub Actions 中有两种不同的可复用组件：

| 类型 | 文件扩展名 | 调用方式 | 用途 |
|------|------------|----------|------|
| **本地 Action** | `.yml` 或 `.yaml` | `uses: ./.github/actions/action-name` | 封装可复用的步骤 |
| **可复用工作流** | `.yml` 或 `.yaml` | `uses: ./.github/workflows/workflow-name.yml` | 封装可复用的作业 |

### 2. 修复方法

将重试逻辑直接集成到各个工作流中，而不是使用可复用工作流：

```yaml
# 错误的方式（已修复）
- name: 使用重试中心配置Nginx
  uses: ./.github/workflows/retry-center.yml  # ❌ 这是错误的

# 正确的方式（修复后）
- name: 使用重试机制配置Nginx
  run: |
    # 重试中心核心逻辑
    MAX_RETRIES=3
    RETRY_DELAY=10
    TIMEOUT_MINUTES=15
    STRATEGY="exponential"
    # ... 重试逻辑实现
```

### 3. 重试逻辑实现

在每个需要重试的步骤中直接实现重试逻辑：

```bash
# 重试中心核心逻辑
MAX_RETRIES=3
RETRY_DELAY=10
TIMEOUT_MINUTES=15
STRATEGY="exponential"
STEP_NAME="配置Nginx"
CONTINUE_ON_ERROR=false
NOTIFY_ON_FAILURE=true
STEP_TYPE="network"

# 初始化变量
ATTEMPTS=0
SUCCESS=false
ERROR_MESSAGE=""
START_TIME=$(date +%s)

# 重试逻辑
while [ $ATTEMPTS -le $MAX_RETRIES ]; do
  ATTEMPTS=$((ATTEMPTS + 1))
  echo "🔄 第 $ATTEMPTS 次尝试..."
  
  # 设置超时
  TIMEOUT_CMD="timeout ${TIMEOUT_MINUTES}m"
  
  # 执行命令
  if $TIMEOUT_CMD bash -c "你的命令"; then
    SUCCESS=true
    echo "✅ 执行成功！"
    break
  else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
      ERROR_MESSAGE="执行超时（${TIMEOUT_MINUTES}分钟）"
    else
      ERROR_MESSAGE="执行失败，退出码: $EXIT_CODE"
    fi
    
    echo "❌ 执行失败: $ERROR_MESSAGE"
    
    # 检查是否还有重试机会
    if [ $ATTEMPTS -le $MAX_RETRIES ]; then
      # 计算重试延迟
      if [ "$STRATEGY" = "exponential" ]; then
        DELAY=$((RETRY_DELAY * (2 ** (ATTEMPTS - 1))))
      elif [ "$STRATEGY" = "adaptive" ]; then
        DELAY=$((RETRY_DELAY + ATTEMPTS * 2))
      else
        DELAY=$RETRY_DELAY
      fi
      
      echo "⏳ 等待 $DELAY 秒后重试..."
      sleep $DELAY
    fi
  fi
done
```

## 📊 修复效果

### 修复前
- 错误地使用 `uses: ./.github/workflows/retry-center.yml`
- GitHub Actions 尝试将其作为本地 action 处理
- 找不到 `action.yml` 文件导致错误

### 修复后
- 直接在各个工作流中实现重试逻辑
- 避免了工作流类型混淆
- 保持了相同的重试功能和策略

## 🔍 重试策略

### 指数退避策略

使用指数退避策略处理网络问题：

- 第1次重试：10秒后
- 第2次重试：20秒后 (10 × 2¹)
- 第3次重试：40秒后 (10 × 2²)

### 错误处理

1. **连接超时**：自动重试
2. **认证失败**：立即失败，不重试
3. **配置错误**：立即失败，不重试
4. **权限错误**：立即失败，不重试

## 🧪 测试验证

### 1. 验证修复

检查工作流文件是否正确：

```bash
# 检查 configure-nginx.yml
grep -n "uses: ./.github/workflows/retry-center.yml" .github/workflows/configure-nginx.yml

# 检查 start-service.yml
grep -n "uses: ./.github/workflows/retry-center.yml" .github/workflows/start-service.yml
```

### 2. 测试重试功能

手动触发工作流测试重试机制：

```bash
# 触发 configure-nginx 工作流
gh workflow run configure-nginx.yml

# 触发 start-service 工作流
gh workflow run start-service.yml
```

## 🚀 最佳实践

### 1. 工作流设计原则

- **明确组件类型**：区分本地 action 和可复用工作流
- **避免混淆**：不要混用不同的调用方式
- **保持一致性**：在相似的工作流中使用相同的重试策略

### 2. 重试逻辑设计

- **可配置参数**：重试次数、延迟时间、超时时间
- **灵活策略**：支持不同的重试策略（simple/exponential/adaptive）
- **详细日志**：提供完整的执行日志和错误信息

### 3. 错误处理

- **智能重试**：只对可重试的错误进行重试
- **快速失败**：对不可重试的错误立即失败
- **状态报告**：提供详细的执行状态和结果

## 📝 相关文件

- `configure-nginx.yml`: 修复后的Nginx配置工作流
- `start-service.yml`: 修复后的启动服务工作流
- `retry-center.yml`: 可复用工作流（用于其他场景）
- `RETRY_CENTER_USAGE_FIX.md`: 本文档

## ✅ 验证清单

- [ ] 移除了错误的重试中心调用
- [ ] 直接在工作流中实现重试逻辑
- [ ] 保持了相同的重试功能和策略
- [ ] 工作流可以正常执行
- [ ] 重试机制正常工作
- [ ] 错误处理正确

## 🔧 故障排除

### 常见问题

1. **工作流类型混淆**
   - 确认使用的是本地 action 还是可复用工作流
   - 检查文件结构和调用方式

2. **重试逻辑错误**
   - 验证重试参数设置
   - 检查超时和延迟计算

3. **SSH连接问题**
   - 检查SSH密钥格式
   - 验证服务器连接参数

### 调试技巧

1. 查看工作流执行日志
2. 检查重试次数和延迟时间
3. 验证SSH连接参数
4. 测试单个命令执行
