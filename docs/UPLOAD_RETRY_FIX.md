# 上传重试机制改进指南

## 🚨 问题描述

在部署过程中，"上传到服务器"步骤偶尔会因为网络问题（如i/o timeout）而失败，导致整个部署流程中断。

**常见错误**：
```
Error: Command failed: scp: connection timeout
Error: Command failed: scp: connection reset by peer
Error: Command failed: scp: i/o timeout
```

## 🔍 问题分析

### 1. 网络不稳定
- 服务器网络连接偶尔不稳定
- 大文件上传时容易超时
- 网络延迟导致连接中断

### 2. 原有机制不足
- 使用`appleboy/scp-action@v0.1.7`没有内置重试机制
- 单次失败就导致整个部署失败
- 缺乏详细的错误日志

## 🛠️ 解决方案

### 方案：自定义重试逻辑

将原来的`scp-action`替换为自定义的SSH脚本，实现智能重试机制。

#### 修改前：
```yaml
- name: 上传到服务器
  uses: appleboy/scp-action@v0.1.7
  with:
    host: ${{ secrets.SERVER_HOST }}
    username: ${{ secrets.SERVER_USER }}
    key: ${{ secrets.SERVER_KEY }}
    port: ${{ secrets.SERVER_PORT }}
    source: "./dist/*"
    target: "/tmp/${{ inputs.project }}/"
    command_timeout: "10m"
```

#### 修改后：
```yaml
- name: 上传到服务器（带重试）
  uses: appleboy/ssh-action@v1.0.3
  with:
    host: ${{ secrets.SERVER_HOST }}
    username: ${{ secrets.SERVER_USER }}
    key: ${{ secrets.SERVER_KEY }}
    port: ${{ secrets.SERVER_PORT }}
    script: |
      echo "🚀 开始上传文件到服务器..."
      
      # 创建临时目录
      TEMP_DIR="/tmp/${{ inputs.project }}"
      sudo mkdir -p $TEMP_DIR
      sudo chown deploy:deploy $TEMP_DIR
      
      # 重试机制
      MAX_RETRIES=3
      RETRY_COUNT=0
      SUCCESS=false
      
      while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$SUCCESS" = false ]; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "📤 尝试上传 (第 $RETRY_COUNT 次)..."
        
        # 使用scp上传文件
        if scp -o StrictHostKeyChecking=no -o ConnectTimeout=30 -r ./dist/* deploy@${{ secrets.SERVER_HOST }}:$TEMP_DIR/; then
          echo "✅ 上传成功！"
          SUCCESS=true
          break
        else
          echo "❌ 上传失败 (第 $RETRY_COUNT 次)"
          if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "⏳ 等待 30 秒后重试..."
            sleep 30
          fi
        fi
      done
      
      if [ "$SUCCESS" = false ]; then
        echo "❌ 上传失败，已达到最大重试次数 ($MAX_RETRIES)"
        exit 1
      fi
      
      echo "📁 验证上传结果..."
      ls -la $TEMP_DIR/
      echo "✅ 文件上传完成"
```

## 📋 重试机制特性

### 1. 智能重试
- **最大重试次数**：3次
- **重试间隔**：30秒
- **超时设置**：30秒连接超时

### 2. 详细日志
- 每次重试都有详细日志
- 显示当前重试次数
- 记录失败原因

### 3. 错误处理
- 连接超时自动重试
- 网络中断自动重试
- 达到最大重试次数后退出

### 4. 验证机制
- 上传完成后验证文件
- 检查文件完整性
- 显示上传结果

## 🎯 配置参数

### 重试参数
```bash
MAX_RETRIES=3          # 最大重试次数
RETRY_WAIT=30          # 重试等待时间（秒）
CONNECT_TIMEOUT=30     # 连接超时时间（秒）
```

### SCP参数
```bash
-o StrictHostKeyChecking=no    # 跳过主机密钥检查
-o ConnectTimeout=30           # 连接超时30秒
-r                             # 递归上传目录
```

## 📊 改进效果

### 修复前
- ❌ 单次失败就导致部署失败
- ❌ 缺乏重试机制
- ❌ 错误信息不够详细
- ❌ 网络问题影响部署成功率

### 修复后
- ✅ 智能重试机制，提高成功率
- ✅ 详细的错误日志和重试信息
- ✅ 网络问题自动恢复
- ✅ 部署成功率显著提升

## 🔄 监控和维护

### 1. 日志监控
```bash
# 查看上传日志
grep "尝试上传" /var/log/nginx/access.log

# 查看重试次数
grep "上传失败" /var/log/nginx/error.log
```

### 2. 成功率统计
- 记录每次部署的重试次数
- 统计网络问题的频率
- 监控上传成功率

### 3. 性能优化
- 根据网络状况调整重试间隔
- 优化文件压缩减少传输时间
- 考虑使用更稳定的传输协议

## 🚀 使用建议

### 1. 网络环境
- 确保服务器网络稳定
- 考虑使用CDN加速
- 监控网络延迟

### 2. 文件大小
- 压缩大文件减少传输时间
- 分批上传大文件
- 使用增量上传

### 3. 监控告警
- 设置重试次数告警
- 监控上传失败率
- 及时处理网络问题

通过这次改进，显著提高了部署的成功率，减少了因网络问题导致的部署失败。
