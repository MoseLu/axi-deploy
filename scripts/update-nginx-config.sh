#!/bin/bash

# Nginx配置更新脚本
# 用于动态更新Nginx配置中的端口

set -e

# 配置
NGINX_CONF_DIR="/www/server/nginx/conf/conf.d/redamancy"
NGINX_MAIN_CONF="/www/server/nginx/conf/nginx.conf"
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

# 备份Nginx配置
backup_nginx_config() {
    local config_file=$1
    
    if [ -f "$config_file" ]; then
        cp "$config_file" "$config_file$BACKUP_SUFFIX"
        log_info "已备份配置文件: $config_file$BACKUP_SUFFIX"
    fi
}

# 更新项目特定的Nginx配置
update_project_nginx_config() {
    local project_name=$1
    local new_port=$2
    local config_file="$NGINX_CONF_DIR/${project_name}.conf"
    
    log_info "🔧 更新项目 '$project_name' 的Nginx配置..."
    log_info "- 配置文件: $config_file"
    log_info "- 新端口: $new_port"
    
    # 检查配置文件是否存在
    if [ ! -f "$config_file" ]; then
        log_warning "项目配置文件不存在: $config_file"
        return 1
    fi
    
    # 备份配置文件
    backup_nginx_config "$config_file"
    
    # 更新端口配置
    # 查找并替换所有proxy_pass中的端口
    local old_port_pattern="proxy_pass http://127.0.0.1:[0-9]+"
    local new_port_pattern="proxy_pass http://127.0.0.1:$new_port"
    
    if grep -q "$old_port_pattern" "$config_file"; then
        sed -i "s/$old_port_pattern/$new_port_pattern/g" "$config_file"
        log_success "已更新Nginx配置中的端口为: $new_port"
    else
        log_warning "未找到需要更新的端口配置"
    fi
    
    # 检查配置语法
    if nginx -t -c "$NGINX_MAIN_CONF" >/dev/null 2>&1; then
        log_success "Nginx配置语法检查通过"
        return 0
    else
        log_error "Nginx配置语法检查失败"
        # 恢复备份
        if [ -f "$config_file$BACKUP_SUFFIX" ]; then
            cp "$config_file$BACKUP_SUFFIX" "$config_file"
            log_info "已恢复配置文件备份"
        fi
        return 1
    fi
}

# 更新通用Nginx配置（如axi-star-cloud.conf）
update_generic_nginx_config() {
    local project_name=$1
    local new_port=$2
    
    log_info "🔧 更新通用Nginx配置..."
    
    # 查找项目相关的配置文件
    local config_files=()
    
    # 常见的配置文件模式
    local patterns=(
        "$NGINX_CONF_DIR/${project_name}.conf"
        "$NGINX_CONF_DIR/${project_name}-*.conf"
        "$NGINX_CONF_DIR/*${project_name}*.conf"
        "$NGINX_CONF_DIR/route-${project_name}.conf"
        "$NGINX_CONF_DIR/nginx-${project_name}.conf"
    )
    
    for pattern in "${patterns[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                config_files+=("$file")
            fi
        done
    done
    
    if [ ${#config_files[@]} -eq 0 ]; then
        log_warning "未找到项目 '$project_name' 的Nginx配置文件"
        return 1
    fi
    
    # 更新所有找到的配置文件
    local success_count=0
    for config_file in "${config_files[@]}"; do
        log_info "更新配置文件: $config_file"
        if update_project_nginx_config "$project_name" "$new_port" "$config_file"; then
            ((success_count++))
        fi
    done
    
    if [ $success_count -gt 0 ]; then
        log_success "成功更新 $success_count 个配置文件"
        return 0
    else
        log_error "所有配置文件更新失败"
        return 1
    fi
}

# 重新加载Nginx配置
reload_nginx() {
    log_info "🔄 重新加载Nginx配置..."
    
    if systemctl is-active --quiet nginx; then
        if nginx -s reload; then
            log_success "Nginx配置重新加载成功"
            return 0
        else
            log_error "Nginx配置重新加载失败"
            return 1
        fi
    else
        log_warning "Nginx服务未运行，尝试启动..."
        if systemctl start nginx; then
            log_success "Nginx服务启动成功"
            return 0
        else
            log_error "Nginx服务启动失败"
            return 1
        fi
    fi
}

# 显示Nginx配置信息
show_nginx_config() {
    local project_name=$1
    
    log_info "📊 Nginx配置信息:"
    echo "配置目录: $NGINX_CONF_DIR"
    echo ""
    
    # 显示项目相关的配置文件
    if [ -n "$project_name" ]; then
        echo "项目 '$project_name' 的配置文件:"
        local found=false
        
        for file in "$NGINX_CONF_DIR"/*; do
            if [ -f "$file" ] && [[ "$file" == *"$project_name"* ]]; then
                echo "  $file"
                found=true
                
                # 显示端口配置
                local ports=$(grep -o "proxy_pass http://127.0.0.1:[0-9]*" "$file" | grep -o "[0-9]*" | sort -u)
                if [ -n "$ports" ]; then
                    echo "    端口: $ports"
                fi
            fi
        done
        
        if [ "$found" = false ]; then
            echo "  (未找到相关配置文件)"
        fi
    else
        echo "所有配置文件:"
        for file in "$NGINX_CONF_DIR"/*.conf; do
            if [ -f "$file" ]; then
                echo "  $file"
            fi
        done
    fi
    
    echo ""
    echo "Nginx服务状态:"
    if systemctl is-active --quiet nginx; then
        echo "  ✅ 运行中"
    else
        echo "  ❌ 未运行"
    fi
}

# 主函数
main() {
    local action=$1
    local project_name=$2
    local port=$3
    
    case "$action" in
        "update")
            if [ -z "$project_name" ] || [ -z "$port" ]; then
                log_error "请指定项目名称和端口"
                exit 1
            fi
            if update_generic_nginx_config "$project_name" "$port"; then
                if reload_nginx; then
                    log_success "Nginx配置更新完成"
                    exit 0
                else
                    log_error "Nginx重新加载失败"
                    exit 1
                fi
            else
                log_error "Nginx配置更新失败"
                exit 1
            fi
            ;;
        "show")
            show_nginx_config "$project_name"
            ;;
        "reload")
            if reload_nginx; then
                log_success "Nginx重新加载成功"
                exit 0
            else
                log_error "Nginx重新加载失败"
                exit 1
            fi
            ;;
        *)
            echo "用法: $0 {update|show|reload} [项目名称] [端口]"
            echo ""
            echo "命令:"
            echo "  update <项目名称> <端口>  更新项目的Nginx配置"
            echo "  show [项目名称]           显示Nginx配置信息"
            echo "  reload                   重新加载Nginx配置"
            echo ""
            echo "示例:"
            echo "  $0 update axi-star-cloud 8124"
            echo "  $0 show axi-star-cloud"
            echo "  $0 reload"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
