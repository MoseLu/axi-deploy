#!/bin/bash

# AXI Deploy - 通用部署脚本
# 用于在服务器上执行部署操作

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 显示部署信息
show_deploy_info() {
    log_info "开始部署..."
    log_info "部署时间: $(date)"
    log_info "当前用户: $(whoami)"
    log_info "当前目录: $(pwd)"
    log_info "目标路径: $TARGET_PATH"
}

# 检查目录权限
check_permissions() {
    log_info "检查目录权限..."
    
    if [ ! -d "$TARGET_PATH" ]; then
        log_warning "目标目录不存在，创建目录: $TARGET_PATH"
        mkdir -p "$TARGET_PATH"
    fi
    
    if [ ! -w "$TARGET_PATH" ]; then
        log_error "没有写入权限: $TARGET_PATH"
        exit 1
    fi
    
    log_success "目录权限检查通过"
}

# 备份当前版本
backup_current() {
    if [ -d "$TARGET_PATH" ] && [ "$(ls -A $TARGET_PATH)" ]; then
        log_info "备份当前版本..."
        BACKUP_DIR="$TARGET_PATH.backup.$(date +%Y%m%d_%H%M%S)"
        cp -r "$TARGET_PATH" "$BACKUP_DIR"
        log_success "备份完成: $BACKUP_DIR"
    fi
}

# 安装依赖
install_dependencies() {
    if [ -f "$TARGET_PATH/package.json" ]; then
        log_info "安装 Node.js 依赖..."
        cd "$TARGET_PATH"
        npm install --production
        log_success "依赖安装完成"
    fi
}

# 重启应用
restart_application() {
    log_info "重启应用..."
    
    # 检查是否有 PM2 进程
    if command -v pm2 &> /dev/null; then
        if pm2 list | grep -q "my-app"; then
            log_info "重启 PM2 应用: my-app"
            pm2 restart my-app
        else
            log_info "启动 PM2 应用: my-app"
            pm2 start npm --name "my-app" -- start
        fi
    fi
    
    # 重启 Nginx
    if command -v nginx &> /dev/null; then
        log_info "重启 Nginx..."
        sudo systemctl reload nginx
    fi
    
    log_success "应用重启完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    if [ -d "$TARGET_PATH" ]; then
        log_info "目标目录内容:"
        ls -la "$TARGET_PATH"
        
        if [ -f "$TARGET_PATH/package.json" ]; then
            log_info "Node.js 项目信息:"
            cd "$TARGET_PATH"
            npm list --depth=0
        fi
    fi
    
    log_success "部署验证完成"
}

# 清理备份
cleanup_backups() {
    log_info "清理旧备份..."
    
    # 保留最近5个备份
    BACKUP_COUNT=$(find "$TARGET_PATH.backup."* -maxdepth 0 -type d 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 5 ]; then
        find "$TARGET_PATH.backup."* -maxdepth 0 -type d -printf '%T@ %p\n' | sort -n | head -n $((BACKUP_COUNT - 5)) | cut -d' ' -f2- | xargs rm -rf
        log_success "清理完成，保留最近5个备份"
    fi
}

# 主函数
main() {
    # 设置目标路径（可通过环境变量覆盖）
    TARGET_PATH="${TARGET_PATH:-/www/wwwroot/my-app}"
    
    show_deploy_info
    check_permissions
    backup_current
    install_dependencies
    restart_application
    verify_deployment
    cleanup_backups
    
    log_success "部署完成!"
}

# 执行主函数
main "$@" 