#!/bin/bash

# 动态端口分配器
# 用于检测端口占用并自动分配可用端口

set -e

# 配置
PORT_CONFIG_FILE="/srv/port-config.yml"
PORT_RANGE_START=8080
PORT_RANGE_END=10000
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查端口是否被占用
check_port_usage() {
    local port=$1
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        return 0  # 端口被占用
    else
        return 1  # 端口可用
    fi
}

# 获取端口占用信息
get_port_usage_info() {
    local port=$1
    local usage_info=$(netstat -tlnp 2>/dev/null | grep ":$port " | head -1)
    if [ -n "$usage_info" ]; then
        echo "$usage_info"
    else
        echo ""
    fi
}

# 查找可用端口
find_available_port() {
    local start_port=${1:-$PORT_RANGE_START}
    local end_port=${2:-$PORT_RANGE_END}
    
    log_info "🔍 在端口范围 $start_port-$end_port 中查找可用端口..."
    
    for port in $(seq $start_port $end_port); do
        if ! check_port_usage $port; then
            log_success "找到可用端口: $port"
            echo $port
            return 0
        fi
    done
    
    log_error "在端口范围 $start_port-$end_port 中未找到可用端口"
    return 1
}

# 检查项目端口配置
check_project_port() {
    local project_name=$1
    
    if [ ! -f "$PORT_CONFIG_FILE" ]; then
        log_warning "端口配置文件不存在: $PORT_CONFIG_FILE"
        return 1
    fi
    
    local current_port=$(grep -A 1 "^  $project_name:" "$PORT_CONFIG_FILE" | grep "port:" | awk '{print $2}' 2>/dev/null)
    
    if [ -n "$current_port" ]; then
        echo "$current_port"
        return 0
    else
        log_warning "项目 '$project_name' 在端口配置中未找到"
        return 1
    fi
}

# 更新项目端口配置
update_project_port() {
    local project_name=$1
    local new_port=$2
    
    if [ ! -f "$PORT_CONFIG_FILE" ]; then
        log_error "端口配置文件不存在: $PORT_CONFIG_FILE"
        return 1
    fi
    
    # 备份原文件
    cp "$PORT_CONFIG_FILE" "$PORT_CONFIG_FILE$BACKUP_SUFFIX"
    log_info "已备份端口配置文件: $PORT_CONFIG_FILE$BACKUP_SUFFIX"
    
    # 更新端口配置
    if grep -q "^  $project_name:" "$PORT_CONFIG_FILE"; then
        # 项目已存在，更新端口
        sed -i "/^  $project_name:/,/^  [^ ]/ s/port: [0-9]*/port: $new_port/" "$PORT_CONFIG_FILE"
        log_success "已更新项目 '$project_name' 的端口为: $new_port"
    else
        # 项目不存在，添加新配置
        echo "  $project_name:" >> "$PORT_CONFIG_FILE"
        echo "    port: $new_port" >> "$PORT_CONFIG_FILE"
        echo "    description: \"$project_name 服务\"" >> "$PORT_CONFIG_FILE"
        log_success "已添加项目 '$project_name' 的端口配置: $new_port"
    fi
}

# 分配端口给项目
allocate_port_for_project() {
    local project_name=$1
    local preferred_port=$2
    
    log_info "🔧 为项目 '$project_name' 分配端口..."
    
    # 检查是否有首选端口
    if [ -n "$preferred_port" ]; then
        log_info "检查首选端口: $preferred_port"
        if ! check_port_usage $preferred_port; then
            log_success "首选端口 $preferred_port 可用"
            update_project_port "$project_name" "$preferred_port"
            echo "$preferred_port"
            return 0
        else
            local usage_info=$(get_port_usage_info $preferred_port)
            log_warning "首选端口 $preferred_port 被占用: $usage_info"
        fi
    fi
    
    # 查找可用端口
    local available_port=$(find_available_port)
    if [ -n "$available_port" ]; then
        update_project_port "$project_name" "$available_port"
        echo "$available_port"
        return 0
    else
        log_error "无法为项目 '$project_name' 分配端口"
        return 1
    fi
}

# 显示端口使用情况
show_port_usage() {
    log_info "📊 当前端口使用情况:"
    echo "端口范围: $PORT_RANGE_START-$PORT_RANGE_END"
    echo ""
    
    # 显示已占用的端口
    local used_ports=$(netstat -tlnp 2>/dev/null | grep -E ":(808[0-9]|809[0-9]|81[0-9][0-9]|82[0-9][0-9]|83[0-9][0-9]|84[0-9][0-9]|85[0-9][0-9]|86[0-9][0-9]|87[0-9][0-9]|88[0-9][0-9]|89[0-9][0-9]|9[0-9][0-9][0-9]) " | sort -k4 -n)
    
    if [ -n "$used_ports" ]; then
        echo "已占用的端口:"
        echo "$used_ports" | while read line; do
            echo "  $line"
        done
    else
        echo "  (无占用端口)"
    fi
    
    echo ""
    
    # 显示配置文件中的端口分配
    if [ -f "$PORT_CONFIG_FILE" ]; then
        echo "配置文件中的端口分配:"
        grep -A 2 "^  " "$PORT_CONFIG_FILE" | while read line; do
            if [[ $line =~ ^[[:space:]]+[^[:space:]]+: ]]; then
                echo "  $line"
            elif [[ $line =~ port: ]]; then
                echo "    $line"
            fi
        done
    else
        echo "端口配置文件不存在: $PORT_CONFIG_FILE"
    fi
}

# 主函数
main() {
    local action=$1
    local project_name=$2
    local port=$3
    
    case "$action" in
        "check")
            if [ -z "$project_name" ]; then
                log_error "请指定项目名称"
                exit 1
            fi
            current_port=$(check_project_port "$project_name")
            if [ -n "$current_port" ]; then
                if check_port_usage $current_port; then
                    usage_info=$(get_port_usage_info $current_port)
                    log_warning "项目 '$project_name' 的端口 $current_port 被占用: $usage_info"
                    exit 1
                else
                    log_success "项目 '$project_name' 的端口 $current_port 可用"
                    exit 0
                fi
            else
                log_error "项目 '$project_name' 未配置端口"
                exit 1
            fi
            ;;
        "allocate")
            if [ -z "$project_name" ]; then
                log_error "请指定项目名称"
                exit 1
            fi
            allocated_port=$(allocate_port_for_project "$project_name" "$port")
            if [ -n "$allocated_port" ]; then
                log_success "已为项目 '$project_name' 分配端口: $allocated_port"
                echo "$allocated_port"
                exit 0
            else
                log_error "端口分配失败"
                exit 1
            fi
            ;;
        "show")
            show_port_usage
            ;;
        "find")
            available_port=$(find_available_port)
            if [ -n "$available_port" ]; then
                log_success "找到可用端口: $available_port"
                echo "$available_port"
                exit 0
            else
                log_error "未找到可用端口"
                exit 1
            fi
            ;;
        *)
            echo "用法: $0 {check|allocate|show|find} [项目名称] [端口]"
            echo ""
            echo "命令:"
            echo "  check <项目名称>    检查项目端口是否可用"
            echo "  allocate <项目名称> [端口]  为项目分配端口"
            echo "  show               显示端口使用情况"
            echo "  find               查找可用端口"
            echo ""
            echo "示例:"
            echo "  $0 check axi-star-cloud"
            echo "  $0 allocate axi-star-cloud 8124"
            echo "  $0 show"
            echo "  $0 find"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
