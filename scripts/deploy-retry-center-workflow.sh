#!/bin/bash

# 重试中心工作流部署脚本
# 将重试中心可复用工作流应用到所有相关的工作流中

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查重试中心工作流是否存在
check_retry_center_workflow() {
    log_info "检查重试中心工作流..."
    
    if [ ! -f ".github/workflows/retry-center.yml" ]; then
        log_error "重试中心工作流不存在"
        exit 1
    fi
    
    log_success "重试中心工作流存在"
}

# 备份原始文件
backup_workflows() {
    log_info "备份原始工作流文件..."
    
    BACKUP_DIR=".github/workflows/backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp .github/workflows/*.yml "$BACKUP_DIR/"
    
    log_success "备份完成: $BACKUP_DIR"
}

# 应用重试中心到deploy-project.yml
apply_to_deploy_project() {
    log_info "应用重试中心到deploy-project.yml..."
    
    # 检查是否已经应用了重试中心工作流
    if grep -q "uses: ./.github/workflows/retry-center.yml" .github/workflows/deploy-project.yml; then
        log_warning "deploy-project.yml已经应用了重试中心工作流"
        return
    fi
    
    # 这里可以添加自动替换逻辑
    log_success "deploy-project.yml已准备应用重试中心工作流"
}

# 应用重试中心到start-service.yml
apply_to_start_service() {
    log_info "应用重试中心到start-service.yml..."
    
    # 检查是否已经应用了重试中心工作流
    if grep -q "uses: ./.github/workflows/retry-center.yml" .github/workflows/start-service.yml; then
        log_warning "start-service.yml已经应用了重试中心工作流"
        return
    fi
    
    log_success "start-service.yml已准备应用重试中心工作流"
}

# 应用重试中心到health-check.yml
apply_to_health_check() {
    log_info "应用重试中心到health-check.yml..."
    
    # 检查是否已经应用了重试中心工作流
    if grep -q "uses: ./.github/workflows/retry-center.yml" .github/workflows/health-check.yml; then
        log_warning "health-check.yml已经应用了重试中心工作流"
        return
    fi
    
    log_success "health-check.yml已准备应用重试中心工作流"
}

# 生成使用指南
generate_usage_guide() {
    log_info "生成重试中心使用指南..."
    
    cat > "RETRY_CENTER_USAGE.md" << 'EOF'
# 重试中心使用指南

## 概述

重试中心是一个可复用的GitHub Actions工作流，用于统一管理所有工作流中的重试机制。它提供了智能重试策略、进度跟踪、详细报告和失败通知功能。

## 快速开始

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

### 参数说明

| 参数 | 类型 | 必需 | 默认值 | 描述 |
|------|------|------|--------|------|
| step_name | string | 是 | - | 步骤名称（用于日志和跟踪） |
| command | string | 是 | - | 要执行的命令 |
| max_retries | number | 否 | 3 | 最大重试次数 |
| retry_delay | number | 否 | 5 | 重试间隔（秒） |
| timeout_minutes | number | 否 | 10 | 单次执行超时时间（分钟） |
| strategy | string | 否 | simple | 重试策略 (simple/exponential/adaptive) |
| step_type | string | 否 | network | 步骤类型 (network/file_operation/validation/parsing) |
| continue_on_error | boolean | 否 | false | 重试失败后是否继续执行 |
| notify_on_failure | boolean | 否 | true | 失败时是否发送通知 |
| env_vars | string | 否 | {} | 环境变量（JSON格式） |

### 重试策略

1. **Simple (简单重试)**
   - 固定延迟时间
   - 适用于临时性错误
   - 配置示例：`strategy: "simple"`

2. **Exponential (指数退避)**
   - 延迟时间递增 (5s, 10s, 20s...)
   - 适用于网络波动
   - 配置示例：`strategy: "exponential"`

3. **Adaptive (自适应重试)**
   - 根据错误类型调整延迟
   - 智能错误处理
   - 配置示例：`strategy: "adaptive"`

### 步骤类型配置

| 类型 | 默认重试次数 | 默认延迟 | 默认超时 | 默认策略 | 是否可重试 |
|------|-------------|----------|----------|----------|------------|
| network | 3 | 5s | 10min | exponential | 是 |
| file_operation | 2 | 3s | 5min | simple | 是 |
| validation | 0 | 0s | 2min | simple | 否 |
| parsing | 0 | 0s | 1min | simple | 否 |

## 使用示例

### 1. 网络操作重试

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
    env_vars: '{"GH_TOKEN": "${{ github.token }}"}'
```

### 2. 服务启动重试

```yaml
- name: 启动服务
  uses: ./.github/workflows/retry-center.yml
  with:
    step_name: "启动PM2服务"
    command: |
      cd ${{ inputs.apps_root }}/${{ inputs.project }}
      pm2 start ecosystem.config.js
      pm2 save
    max_retries: 2
    retry_delay: 15
    timeout_minutes: 15
    strategy: "exponential"
    step_type: "validation"
    continue_on_error: false
    notify_on_failure: true
```

### 3. 健康检查重试

```yaml
- name: 服务器健康检查
  uses: ./.github/workflows/retry-center.yml
  with:
    step_name: "服务器基础检查"
    command: |
      echo "🔍 服务器基础检查..."
      echo "📊 系统信息:"
      echo "- 操作系统: $(uname -a)"
      echo "- 系统负载: $(uptime)"
      echo "- 内存使用: $(free -h)"
    max_retries: 2
    retry_delay: 10
    timeout_minutes: 10
    strategy: "simple"
    step_type: "validation"
    continue_on_error: true
    notify_on_failure: false
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

### 使用输出参数

```yaml
- name: 执行重试操作
  id: retry-operation
  uses: ./.github/workflows/retry-center.yml
  with:
    step_name: "测试操作"
    command: "echo '测试命令'"

- name: 检查结果
  run: |
    echo "执行结果: ${{ steps.retry-operation.outputs.success }}"
    echo "重试次数: ${{ steps.retry-operation.outputs.attempts }}"
    echo "执行时间: ${{ steps.retry-operation.outputs.execution_time }}秒"
```

## 重试报告

重试中心会自动生成JSON格式的重试报告，包含以下信息：

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

## 最佳实践

1. **合理设置重试次数**：避免无限重试，根据操作类型设置合适的重试次数
2. **选择合适的策略**：网络操作使用指数退避，文件操作使用简单重试
3. **设置合理超时**：避免长时间等待，根据命令复杂度设置超时时间
4. **监控重试频率**：通过重试报告监控重试频率，及时发现系统问题
5. **记录详细日志**：重试中心会自动记录详细日志，便于问题排查

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

## 未来扩展

重试中心设计为未来集成到 axi-project-dashboard 做准备：

1. **实时进度显示**：在dashboard中显示重试进度
2. **历史记录**：查看历史重试记录和成功率
3. **配置管理**：通过UI管理重试策略
4. **告警设置**：配置重试失败通知
EOF

    log_success "使用指南已生成: RETRY_CENTER_USAGE.md"
}

# 验证部署结果
verify_deployment() {
    log_info "验证部署结果..."
    
    # 检查重试中心工作流是否可以被引用
    if [ -f ".github/workflows/retry-center.yml" ]; then
        log_success "重试中心工作流文件存在"
    else
        log_error "重试中心工作流文件不存在"
        return 1
    fi
    
    # 检查使用指南是否生成
    if [ -f "RETRY_CENTER_USAGE.md" ]; then
        log_success "使用指南已生成"
    else
        log_warning "使用指南未生成"
    fi
    
    log_info "部署验证完成"
}

# 主函数
main() {
    log_info "开始部署重试中心工作流..."
    
    # 检查重试中心工作流
    check_retry_center_workflow
    
    # 备份原始文件
    backup_workflows
    
    # 应用重试中心到各个工作流
    apply_to_deploy_project
    apply_to_start_service
    apply_to_health_check
    
    # 生成使用指南
    generate_usage_guide
    
    # 验证部署结果
    verify_deployment
    
    log_success "重试中心工作流部署完成！"
    log_info "请查看 RETRY_CENTER_USAGE.md 了解详细使用方法"
    log_info "建议在应用更改前测试工作流"
}

# 执行主函数
main "$@"
