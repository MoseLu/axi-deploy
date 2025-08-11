#!/bin/bash

# 重试中心核心逻辑
# 支持多种重试策略和进度跟踪

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --max-retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --retry-delay)
                RETRY_DELAY="$2"
                shift 2
                ;;
            --timeout-minutes)
                TIMEOUT_MINUTES="$2"
                shift 2
                ;;
            --strategy)
                RETRY_STRATEGY="$2"
                shift 2
                ;;
            --step-name)
                STEP_NAME="$2"
                shift 2
                ;;
            --command)
                COMMAND="$2"
                shift 2
                ;;
            --continue-on-error)
                CONTINUE_ON_ERROR="$2"
                shift 2
                ;;
            --notify-on-failure)
                NOTIFY_ON_FAILURE="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
}

# 计算重试延迟
calculate_retry_delay() {
    local attempt=$1
    local base_delay=$2
    local strategy=$3
    
    case $strategy in
        "simple")
            echo $base_delay
            ;;
        "exponential")
            echo $((base_delay * (2 ** (attempt - 1))))
            ;;
        "adaptive")
            # 自适应策略：根据错误类型调整延迟
            local adaptive_delay=$base_delay
            if [ $attempt -gt 2 ]; then
                adaptive_delay=$((base_delay * 2))
            fi
            echo $adaptive_delay
            ;;
        *)
            echo $base_delay
            ;;
    esac
}

# 执行命令并捕获输出
execute_command() {
    local cmd="$1"
    local timeout_minutes="$2"
    local output_file="/tmp/retry_output_$$.log"
    local error_file="/tmp/retry_error_$$.log"
    
    # 使用 timeout 命令限制执行时间
    timeout ${timeout_minutes}m bash -c "$cmd" > "$output_file" 2> "$error_file"
    local exit_code=$?
    
    # 读取输出
    local output=$(cat "$output_file" 2>/dev/null || echo "")
    local error=$(cat "$error_file" 2>/dev/null || echo "")
    
    # 清理临时文件
    rm -f "$output_file" "$error_file"
    
    # 返回结果
    echo "$exit_code|$output|$error"
}

# 检查是否需要重试
should_retry() {
    local exit_code=$1
    local error_output="$2"
    local attempt=$3
    
    # 如果成功，不需要重试
    if [ $exit_code -eq 0 ]; then
        return 1
    fi
    
    # 如果达到最大重试次数，不重试
    if [ $attempt -ge $MAX_RETRIES ]; then
        return 1
    fi
    
    # 检查错误类型，决定是否重试
    local retryable_errors=(
        "timeout"
        "connection refused"
        "network unreachable"
        "temporary failure"
        "rate limit"
        "server error"
        "gateway timeout"
        "service unavailable"
    )
    
    for error_pattern in "${retryable_errors[@]}"; do
        if echo "$error_output" | grep -qi "$error_pattern"; then
            return 0
        fi
    done
    
    # 对于某些特定错误，不重试
    local non_retryable_errors=(
        "permission denied"
        "file not found"
        "invalid argument"
        "syntax error"
    )
    
    for error_pattern in "${non_retryable_errors[@]}"; do
        if echo "$error_output" | grep -qi "$error_pattern"; then
            return 1
        fi
    done
    
    # 默认重试
    return 0
}

# 发送失败通知
send_failure_notification() {
    local step_name="$1"
    local attempts="$2"
    local error_message="$3"
    
    if [ "$NOTIFY_ON_FAILURE" = "true" ]; then
        log_warning "步骤 '$step_name' 在 $attempts 次尝试后失败"
        log_error "错误信息: $error_message"
        
        # 这里可以集成 Slack、Email 等通知服务
        # 例如：curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"步骤 $step_name 失败\"}" $SLACK_WEBHOOK_URL
    fi
}

# 生成执行报告
generate_report() {
    local step_name="$1"
    local success="$2"
    local attempts="$3"
    local execution_time="$4"
    local error_message="$5"
    
    local report_file="/tmp/retry_report_$$.json"
    
    cat > "$report_file" << EOF
{
    "step_name": "$step_name",
    "success": $success,
    "attempts": $attempts,
    "execution_time_seconds": $execution_time,
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "error_message": "$(echo "$error_message" | jq -R -s .)",
    "workflow_run_id": "$GITHUB_RUN_ID",
    "job_name": "$GITHUB_JOB"
}
EOF
    
    echo "$report_file"
}

# 主重试函数
execute_with_retry() {
    # 解析参数
    parse_args "$@"
    
    # 验证必需参数
    if [ -z "$STEP_NAME" ] || [ -z "$COMMAND" ]; then
        log_error "缺少必需参数: step_name 和 command"
        exit 1
    fi
    
    # 设置默认值
    MAX_RETRIES=${MAX_RETRIES:-3}
    RETRY_DELAY=${RETRY_DELAY:-5}
    TIMEOUT_MINUTES=${TIMEOUT_MINUTES:-10}
    RETRY_STRATEGY=${RETRY_STRATEGY:-simple}
    CONTINUE_ON_ERROR=${CONTINUE_ON_ERROR:-false}
    NOTIFY_ON_FAILURE=${NOTIFY_ON_FAILURE:-true}
    
    log_info "开始执行步骤: $STEP_NAME"
    log_debug "配置: 最大重试=$MAX_RETRIES, 延迟=$RETRY_DELAY秒, 超时=$TIMEOUT_MINUTES分钟, 策略=$RETRY_STRATEGY"
    
    local start_time=$(date +%s)
    local attempt=1
    local success=false
    local final_error=""
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log_info "执行尝试 $attempt/$MAX_RETRIES"
        
        # 执行命令
        local result=$(execute_command "$COMMAND" "$TIMEOUT_MINUTES")
        local exit_code=$(echo "$result" | cut -d'|' -f1)
        local output=$(echo "$result" | cut -d'|' -f2)
        local error=$(echo "$result" | cut -d'|' -f3)
        
        # 检查是否成功
        if [ $exit_code -eq 0 ]; then
            log_success "步骤 '$STEP_NAME' 执行成功"
            success=true
            break
        fi
        
        # 检查是否需要重试
        if should_retry "$exit_code" "$error" "$attempt"; then
            log_warning "步骤 '$STEP_NAME' 执行失败，准备重试"
            log_debug "错误信息: $error"
            
            if [ $attempt -lt $MAX_RETRIES ]; then
                local delay=$(calculate_retry_delay $attempt $RETRY_DELAY $RETRY_STRATEGY)
                log_info "等待 $delay 秒后重试..."
                sleep $delay
            fi
        else
            log_error "步骤 '$STEP_NAME' 执行失败，不进行重试"
            log_debug "错误信息: $error"
            break
        fi
        
        attempt=$((attempt + 1))
    done
    
    # 计算执行时间
    local end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    
    # 设置最终错误信息
    if [ "$success" = false ]; then
        final_error="$error"
    fi
    
    # 生成报告
    local report_file=$(generate_report "$STEP_NAME" "$([ "$success" = true ] && echo "true" || echo "false")" "$attempt" "$execution_time" "$final_error")
    
    # 输出结果到 GitHub Actions
    echo "success=$([ "$success" = true ] && echo "true" || echo "false")" >> $GITHUB_OUTPUT
    echo "attempts=$attempt" >> $GITHUB_OUTPUT
    echo "execution_time=$execution_time" >> $GITHUB_OUTPUT
    echo "error_message=$final_error" >> $GITHUB_OUTPUT
    
    # 上传报告
    if [ -f "$report_file" ]; then
        echo "RETRY_REPORT_PATH=$report_file" >> $GITHUB_ENV
        log_info "重试报告已生成: $report_file"
    fi
    
    # 处理最终结果
    if [ "$success" = false ]; then
        send_failure_notification "$STEP_NAME" "$attempt" "$final_error"
        
        if [ "$CONTINUE_ON_ERROR" = "false" ]; then
            log_error "步骤 '$STEP_NAME' 最终失败，退出"
            exit 1
        else
            log_warning "步骤 '$STEP_NAME' 失败，但继续执行"
        fi
    fi
    
    log_info "步骤 '$STEP_NAME' 执行完成，耗时 ${execution_time} 秒"
}
