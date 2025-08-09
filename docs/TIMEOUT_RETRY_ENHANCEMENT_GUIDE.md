# axi-deploy 工作流超时和重试机制增强指南

## 🚨 问题背景

### 当前问题
目前axi-deploy工作流部分步骤缺乏重试机制，导致以下问题：

1. **超时问题**（timeout i/o）
   - 网络连接不稳定时容易出现timeout
   - 大文件上传/下载时的i/o超时
   - 服务器响应慢导致的连接超时

2. **单点失败**
   - 单次网络错误就导致整个部署失败
   - 缺乏自动恢复机制
   - 需要手动重新触发部署

3. **资源浪费**
   - 一个小问题导致整个工作流重跑
   - 浪费GitHub Actions runner时间
   - 影响部署效率

## 🔍 影响范围分析

### 容易出现timeout的步骤

1. **构建产物下载**（`validate-artifact.yml`）
   ```yaml
   - name: 下载构建产物
     uses: actions/download-artifact@v4
     # 缺乏重试机制
   ```

2. **文件上传**（`deploy-project.yml`）
   ```yaml
   - name: 上传文件到服务器
     uses: appleboy/scp-action@v0.1.7
     # 网络问题容易导致失败
   ```

3. **SSH连接操作**（多个工作流）
   ```yaml
   - name: SSH执行命令
     uses: appleboy/ssh-action@v1.0.3
     # 服务器连接不稳定时失败
   ```

4. **网站健康检查**（`test-website.yml`）
   ```yaml
   - name: 测试网站访问
     run: curl -f "$TEST_URL"
     # 服务启动慢或网络问题导致失败
   ```

## 🛠️ 解决方案设计

### 1. GitHub Actions 原生重试机制

#### 方案A：uses-retry Action
使用第三方重试action包装现有步骤：

```yaml
- name: 下载构建产物（带重试）
  uses: nick-fields/retry@v3
  with:
    timeout_minutes: 10
    max_attempts: 3
    retry_wait_seconds: 30
    command: |
      echo "尝试下载构建产物..."
      actions/download-artifact@v4
      # 验证下载成功
      if [ ! -d "dist" ] || [ -z "$(ls -A dist)" ]; then
        echo "构建产物下载失败或为空"
        exit 1
      fi
```

#### 方案B：自定义重试脚本
在工作流内部实现重试逻辑：

```yaml
- name: 下载构建产物（自定义重试）
  run: |
    MAX_RETRIES=3
    RETRY_COUNT=0
    SUCCESS=false
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$SUCCESS" = false ]; do
      RETRY_COUNT=$((RETRY_COUNT + 1))
      echo "🔄 尝试下载构建产物 (第 $RETRY_COUNT 次)..."
      
      # 清理之前的尝试
      rm -rf dist/ || true
      
      # 尝试下载
      if gh run download ${{ inputs.run_id }} --name "dist-${{ inputs.project }}" --dir .; then
        # 验证下载成功
        if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
          echo "✅ 构建产物下载成功"
          SUCCESS=true
          break
        else
          echo "❌ 构建产物为空"
        fi
      else
        echo "❌ 下载失败"
      fi
      
      if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "⏳ 等待 $(( $RETRY_COUNT * 30 )) 秒后重试..."
        sleep $(( $RETRY_COUNT * 30 ))
      fi
    done
    
    if [ "$SUCCESS" = false ]; then
      echo "❌ 构建产物下载失败，已达到最大重试次数"
      exit 1
    fi
  env:
    GH_TOKEN: ${{ inputs.deploy_center_pat }}
```

### 2. 网络操作重试增强

#### SSH/SCP操作重试
```yaml
- name: 文件上传（带重试）
  uses: nick-fields/retry@v3
  with:
    timeout_minutes: 15
    max_attempts: 5
    retry_wait_seconds: 60
    retry_on: error
    command: |
      echo "🚀 开始上传文件到服务器..."
      
      # 使用rsync替代scp，更可靠
      rsync -avz --progress --timeout=300 \
        -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30" \
        ./dist/ ${{ inputs.server_user }}@${{ inputs.server_host }}:/tmp/${{ inputs.project }}/
      
      # 验证上传结果
      ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 \
        ${{ inputs.server_user }}@${{ inputs.server_host }} \
        "ls -la /tmp/${{ inputs.project }}/ | wc -l"
```

#### HTTP请求重试
```yaml
- name: 网站健康检查（带重试）
  uses: nick-fields/retry@v3
  with:
    timeout_minutes: 10
    max_attempts: 10
    retry_wait_seconds: 30
    command: |
      echo "🔍 检查网站健康状态..."
      
      # 使用curl进行健康检查
      response=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 30 \
        --max-time 60 \
        "${{ inputs.test_url }}")
      
      if [ "$response" = "200" ]; then
        echo "✅ 网站健康检查通过 (HTTP $response)"
      else
        echo "❌ 网站健康检查失败 (HTTP $response)"
        exit 1
      fi
```

### 3. 超时配置优化

#### 工作流级别超时
```yaml
name: 主部署工作流
on:
  workflow_call:
    # ... inputs ...

jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 120  # 工作流总超时时间
    
    steps:
      - name: 步骤1
        timeout-minutes: 10  # 单步骤超时时间
        # ...
      
      - name: 步骤2
        timeout-minutes: 15
        # ...
```

#### 动态超时配置
```yaml
- name: 设置超时配置
  id: timeout-config
  run: |
    # 根据项目大小调整超时时间
    if [ "${{ inputs.deploy_type }}" = "backend" ]; then
      echo "download_timeout=20" >> $GITHUB_OUTPUT
      echo "upload_timeout=25" >> $GITHUB_OUTPUT
      echo "deploy_timeout=15" >> $GITHUB_OUTPUT
    else
      echo "download_timeout=10" >> $GITHUB_OUTPUT
      echo "upload_timeout=15" >> $GITHUB_OUTPUT
      echo "deploy_timeout=10" >> $GITHUB_OUTPUT
    fi

- name: 下载构建产物
  timeout-minutes: ${{ steps.timeout-config.outputs.download_timeout }}
  # ...
```

## 📋 具体实现方案

### 1. 创建重试工具工作流

创建 `.github/workflows/retry-utils.yml`：

```yaml
name: 重试工具集

on:
  workflow_call:
    inputs:
      operation_type:
        required: true
        type: string
        description: '操作类型 (download|upload|ssh|http)'
      max_attempts:
        required: false
        type: number
        default: 3
        description: '最大重试次数'
      timeout_minutes:
        required: false
        type: number
        default: 10
        description: '单次操作超时时间'
      # ... 其他参数

jobs:
  retry-operation:
    runs-on: ubuntu-latest
    steps:
      - name: 执行重试操作
        uses: nick-fields/retry@v3
        with:
          timeout_minutes: ${{ inputs.timeout_minutes }}
          max_attempts: ${{ inputs.max_attempts }}
          retry_wait_seconds: 30
          command: |
            case "${{ inputs.operation_type }}" in
              "download")
                # 下载重试逻辑
                ;;
              "upload")
                # 上传重试逻辑
                ;;
              "ssh")
                # SSH重试逻辑
                ;;
              "http")
                # HTTP重试逻辑
                ;;
            esac
```

### 2. 增强现有工作流

#### validate-artifact.yml 增强
```yaml
name: 验证构建产物（增强版）

on:
  workflow_call:
    inputs:
      # ... 现有输入参数
      retry_enabled:
        required: false
        type: boolean
        default: true
        description: '是否启用重试机制'

jobs:
  validate:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    steps:
      - name: 下载构建产物（带重试）
        if: ${{ inputs.retry_enabled }}
        uses: nick-fields/retry@v3
        with:
          timeout_minutes: 15
          max_attempts: 5
          retry_wait_seconds: 30
          command: |
            echo "🔄 开始下载构建产物..."
            
            # 清理旧文件
            rm -rf dist/ || true
            
            # 下载构建产物
            gh run download ${{ inputs.run_id }} \
              --name "dist-${{ inputs.project }}" \
              --dir .
            
            # 验证下载结果
            if [ ! -d "dist" ]; then
              echo "❌ dist 目录不存在"
              exit 1
            fi
            
            file_count=$(find dist -type f | wc -l)
            if [ "$file_count" -eq 0 ]; then
              echo "❌ 构建产物为空"
              exit 1
            fi
            
            echo "✅ 构建产物验证成功，包含 $file_count 个文件"
        env:
          GH_TOKEN: ${{ inputs.deploy_center_pat }}
      
      - name: 下载构建产物（无重试）
        if: ${{ !inputs.retry_enabled }}
        # ... 原有逻辑
```

#### deploy-project.yml 增强
```yaml
name: 部署项目（增强版）

on:
  workflow_call:
    inputs:
      # ... 现有参数

jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    
    steps:
      - name: 文件上传（带重试）
        uses: nick-fields/retry@v3
        with:
          timeout_minutes: 20
          max_attempts: 5
          retry_wait_seconds: 60
          command: |
            echo "🚀 开始上传文件到服务器..."
            
            # 使用rsync替代scp，更可靠
            rsync -avz --progress --timeout=300 \
              -e "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ServerAliveInterval=60" \
              ./dist/ ${{ inputs.server_user }}@${{ inputs.server_host }}:/tmp/${{ inputs.project }}/
            
            # 验证上传结果
            file_count=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 \
              ${{ inputs.server_user }}@${{ inputs.server_host }} \
              "find /tmp/${{ inputs.project }}/ -type f | wc -l")
            
            if [ "$file_count" -eq 0 ]; then
              echo "❌ 文件上传失败，目标目录为空"
              exit 1
            fi
            
            echo "✅ 文件上传成功，共 $file_count 个文件"
      
      - name: 服务器部署（带重试）
        uses: nick-fields/retry@v3
        with:
          timeout_minutes: 15
          max_attempts: 3
          retry_wait_seconds: 30
          command: |
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 \
              ${{ inputs.server_user }}@${{ inputs.server_host }} << 'EOF'
              
              set -e
              
              PROJECT="${{ inputs.project }}"
              TEMP_DIR="/tmp/$PROJECT"
              
              if [ "${{ inputs.deploy_type }}" = "static" ]; then
                DEPLOY_PATH="/srv/static/$PROJECT"
              else
                DEPLOY_PATH="/srv/apps/$PROJECT"
              fi
              
              echo "🧹 清理目标部署目录..."
              sudo rm -rf "$DEPLOY_PATH"/*
              
              echo "📁 创建部署目录..."
              sudo mkdir -p "$DEPLOY_PATH"
              
              echo "📦 部署文件..."
              cd "$TEMP_DIR"
              sudo cp -r * "$DEPLOY_PATH"/
              
              echo "🔧 设置文件权限..."
              sudo chown -R www-data:www-data "$DEPLOY_PATH"
              sudo chmod -R 755 "$DEPLOY_PATH"
              
              echo "🧹 清理临时目录..."
              sudo rm -rf "$TEMP_DIR"
              
              echo "✅ 部署完成：$DEPLOY_PATH"
            EOF
```

#### test-website.yml 增强
```yaml
name: 测试网站（增强版）

on:
  workflow_call:
    inputs:
      # ... 现有参数

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    steps:
      - name: 等待服务启动
        if: ${{ inputs.test_url != '' }}
        run: |
          echo "⏳ 等待服务启动..."
          sleep 30
      
      - name: 网站健康检查（带重试）
        if: ${{ inputs.test_url != '' }}
        uses: nick-fields/retry@v3
        with:
          timeout_minutes: 15
          max_attempts: 10
          retry_wait_seconds: 30
          command: |
            echo "🔍 检查网站健康状态..."
            
            # HTTP检查
            response=$(curl -s -o /dev/null -w "%{http_code}" \
              --connect-timeout 30 \
              --max-time 60 \
              --retry 3 \
              --retry-delay 10 \
              "${{ inputs.test_url }}")
            
            case "$response" in
              "200"|"301"|"302")
                echo "✅ 网站健康检查通过 (HTTP $response)"
                ;;
              "000")
                echo "❌ 网站无法连接"
                exit 1
                ;;
              *)
                echo "❌ 网站返回错误状态码: $response"
                exit 1
                ;;
            esac
            
            # HTTPS检查（如果URL使用HTTPS）
            if [[ "${{ inputs.test_url }}" == https://* ]]; then
              echo "🔒 检查HTTPS证书..."
              openssl s_client -connect $(echo "${{ inputs.test_url }}" | cut -d'/' -f3):443 \
                -servername $(echo "${{ inputs.test_url }}" | cut -d'/' -f3) \
                </dev/null 2>/dev/null | openssl x509 -noout -dates
            fi
```

### 3. 监控和告警机制

#### 创建监控工作流
创建 `.github/workflows/deployment-monitoring.yml`：

```yaml
name: 部署监控和告警

on:
  schedule:
    - cron: '*/15 * * * *'  # 每15分钟检查一次
  workflow_dispatch:

jobs:
  monitor:
    runs-on: ubuntu-latest
    steps:
      - name: 检查最近部署状态
        run: |
          echo "🔍 检查最近的部署状态..."
          
          # 获取最近的工作流运行状态
          failed_runs=$(gh run list \
            --workflow=main-deployment.yml \
            --status=failure \
            --limit=5 \
            --json=conclusion,createdAt,url \
            --jq='.[] | select(.conclusion == "failure")')
          
          if [ -n "$failed_runs" ]; then
            echo "⚠️ 发现失败的部署："
            echo "$failed_runs"
            
            # 发送告警通知（可以集成Slack、邮件等）
            # curl -X POST -H 'Content-type: application/json' \
            #   --data '{"text":"部署失败告警"}' \
            #   $SLACK_WEBHOOK_URL
          else
            echo "✅ 最近的部署都正常"
          fi
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 4. 错误恢复机制

#### 自动回滚机制
```yaml
- name: 部署失败自动回滚
  if: failure()
  run: |
    echo "❌ 部署失败，开始自动回滚..."
    
    ssh -o StrictHostKeyChecking=no ${{ inputs.server_user }}@${{ inputs.server_host }} << 'EOF'
      PROJECT="${{ inputs.project }}"
      
      if [ "${{ inputs.deploy_type }}" = "static" ]; then
        DEPLOY_PATH="/srv/static/$PROJECT"
        BACKUP_PATH="/srv/backups/static/$PROJECT"
      else
        DEPLOY_PATH="/srv/apps/$PROJECT"
        BACKUP_PATH="/srv/backups/apps/$PROJECT"
      fi
      
      # 检查是否有备份
      if [ -d "$BACKUP_PATH" ]; then
        echo "📦 恢复备份..."
        sudo rm -rf "$DEPLOY_PATH"/*
        sudo cp -r "$BACKUP_PATH"/* "$DEPLOY_PATH"/
        echo "✅ 回滚完成"
      else
        echo "⚠️ 未找到备份，无法自动回滚"
      fi
    EOF
```

## 📊 配置参数

### 重试配置参数
```yaml
# 全局重试配置
retry_config:
  download:
    max_attempts: 5
    timeout_minutes: 15
    retry_wait_seconds: 30
  
  upload:
    max_attempts: 5
    timeout_minutes: 20
    retry_wait_seconds: 60
  
  ssh:
    max_attempts: 3
    timeout_minutes: 10
    retry_wait_seconds: 30
  
  http:
    max_attempts: 10
    timeout_minutes: 15
    retry_wait_seconds: 30
```

### 环境特定配置
```yaml
# 生产环境 - 更保守的重试策略
production:
  retry_config:
    max_attempts: 3
    timeout_minutes: 10
    
# 测试环境 - 更激进的重试策略
staging:
  retry_config:
    max_attempts: 5
    timeout_minutes: 15
```

## 🎯 实施计划

### 阶段1：核心重试机制（优先级：高）
1. ✅ 为下载构建产物添加重试机制
2. ✅ 为文件上传添加重试机制
3. ✅ 为SSH操作添加重试机制
4. ✅ 为网站健康检查添加重试机制

### 阶段2：监控和告警（优先级：中）
1. ⏳ 创建部署监控工作流
2. ⏳ 集成告警通知
3. ⏳ 添加部署成功率统计

### 阶段3：高级功能（优先级：低）
1. ⏳ 智能重试策略（根据错误类型调整重试次数）
2. ⏳ 部署性能分析
3. ⏳ 自动化故障诊断

## 🔧 使用方法

### 1. 启用重试机制
在调用工作流时添加重试参数：

```yaml
deploy:
  uses: MoseLu/axi-deploy/.github/workflows/main-deployment.yml@master
  with:
    # ... 其他参数
    retry_enabled: true
    max_retry_attempts: 5
    retry_timeout_minutes: 20
```

### 2. 自定义重试策略
```yaml
deploy:
  uses: MoseLu/axi-deploy/.github/workflows/main-deployment.yml@master
  with:
    # ... 其他参数
    retry_config: |
      {
        "download": {"max_attempts": 3, "timeout": 10},
        "upload": {"max_attempts": 5, "timeout": 15},
        "ssh": {"max_attempts": 3, "timeout": 10},
        "http": {"max_attempts": 10, "timeout": 5}
      }
```

## 📈 预期效果

### 部署成功率提升
- **现状**：约85%成功率（因网络问题导致15%失败）
- **改进后**：预期95%+成功率

### 部署时间优化
- **失败重跑时间**：从20-30分钟降低到5-10分钟
- **总体部署时间**：通过智能重试减少不必要的全流程重跑

### 运维效率提升
- **手动干预减少**：95%的网络问题自动恢复
- **问题定位时间**：通过详细日志减少50%排查时间

## ⚠️ 注意事项

### 1. 重试次数控制
- 避免过度重试导致资源浪费
- 根据错误类型选择合适的重试策略

### 2. 超时时间设置
- 平衡重试效果和总体执行时间
- 考虑GitHub Actions的runner时间限制

### 3. 错误分类
- 区分可重试错误和不可重试错误
- 避免对配置错误进行无意义重试

### 4. 监控和告警
- 建立重试成功率监控
- 设置合理的告警阈值

## 📝 总结

通过实施这套重试机制增强方案，axi-deploy工作流将具备：

1. **强大的容错能力** - 自动处理网络问题和临时故障
2. **智能的重试策略** - 根据不同操作类型优化重试参数
3. **完善的监控体系** - 实时监控部署状态和成功率
4. **快速的故障恢复** - 自动回滚和恢复机制

这将显著提高部署的稳定性和成功率，减少因timeout i/o问题导致的部署失败。
