#!/bin/bash

# 部署验证脚本
# 用于检查部署是否成功并避免文件交叉污染

set -e

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

# 检查目录是否存在且不为空
check_directory() {
    local dir="$1"
    local name="$2"
    
    if [ ! -d "$dir" ]; then
        log_error "$name 目录不存在: $dir"
        return 1
    fi
    
    if [ -z "$(ls -A $dir 2>/dev/null)" ]; then
        log_error "$name 目录为空: $dir"
        return 1
    fi
    
    log_success "$name 目录检查通过: $dir"
    return 0
}

# 检查服务状态
check_service() {
    local service="$1"
    local name="$2"
    
    if systemctl is-active --quiet $service; then
        log_success "$name 服务正在运行: $service"
        return 0
    else
        log_error "$name 服务未运行: $service"
        return 1
    fi
}

# 检查端口是否被占用
check_port() {
    local port="$1"
    local name="$2"
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        log_success "$name 端口 $port 正在监听"
        return 0
    else
        log_error "$name 端口 $port 未监听"
        return 1
    fi
}

# 检查健康检查端点
check_health() {
    local url="$1"
    local name="$2"
    
    if curl -f -s "$url" > /dev/null 2>&1; then
        log_success "$name 健康检查通过: $url"
        return 0
    else
        log_error "$name 健康检查失败: $url"
        return 1
    fi
}

# 检查文件交叉污染
check_cross_contamination() {
    log_info "检查文件交叉污染..."
    
    # 检查后端项目目录是否包含静态项目的文件
    if [ -d "/srv/apps/axi-star-cloud" ]; then
        if [ -d "/srv/apps/axi-star-cloud/docs" ] || [ -d "/srv/apps/axi-star-cloud/dist" ]; then
            log_error "发现文件交叉污染: axi-star-cloud 目录包含 docs 或 dist 文件夹"
            ls -la /srv/apps/axi-star-cloud/ | grep -E "(docs|dist)"
            return 1
        fi
        
        if [ -f "/srv/apps/axi-star-cloud/index.html" ] && [ ! -f "/srv/apps/axi-star-cloud/star-cloud-linux" ]; then
            log_error "发现文件交叉污染: axi-star-cloud 目录包含静态文件但缺少后端二进制文件"
            return 1
        fi
        
        log_success "axi-star-cloud 目录检查通过，无交叉污染"
    fi
    
    # 检查静态项目目录是否包含后端文件
    if [ -d "/srv/static/axi-docs" ]; then
        if [ -f "/srv/static/axi-docs/star-cloud-linux" ] || [ -f "/srv/static/axi-docs/star-cloud.service" ]; then
            log_error "发现文件交叉污染: axi-docs 目录包含后端文件"
            ls -la /srv/static/axi-docs/ | grep -E "(star-cloud|\.service)"
            return 1
        fi
        
        log_success "axi-docs 目录检查通过，无交叉污染"
    fi
    
    return 0
}

# 检查临时目录
check_temp_directories() {
    log_info "检查临时目录..."
    
    # 检查 /tmp 目录中的项目目录
    for project_dir in /tmp/*/; do
        if [ -d "$project_dir" ]; then
            project_name=$(basename "$project_dir")
            log_warning "发现临时目录: $project_dir"
            
            # 检查是否为空
            if [ -z "$(ls -A $project_dir 2>/dev/null)" ]; then
                log_info "临时目录为空，可以清理: $project_dir"
            else
                log_warning "临时目录不为空，建议清理: $project_dir"
                ls -la "$project_dir"
            fi
        fi
    done
}

# 检查 Nginx 配置
check_nginx_config() {
    log_info "检查 Nginx 配置..."
    
    if sudo nginx -t 2>/dev/null; then
        log_success "Nginx 配置语法检查通过"
    else
        log_error "Nginx 配置语法错误"
        sudo nginx -t
        return 1
    fi
    
    if systemctl is-active --quiet nginx; then
        log_success "Nginx 服务正在运行"
    else
        log_error "Nginx 服务未运行"
        return 1
    fi
}

# 检查 SSL 证书
check_ssl_certificates() {
    log_info "检查 SSL 证书..."
    
    local cert_dir="/www/server/nginx/ssl/redamancy"
    
    if [ -f "$cert_dir/fullchain.pem" ] && [ -f "$cert_dir/privkey.pem" ]; then
        log_success "SSL 证书文件存在"
        
        # 检查证书有效期
        local cert_expiry=$(openssl x509 -enddate -noout -in "$cert_dir/fullchain.pem" | cut -d= -f2)
        log_info "证书有效期至: $cert_expiry"
    else
        log_error "SSL 证书文件缺失"
        return 1
    fi
}

# 测试网站访问
test_website_access() {
    log_info "测试网站访问..."
    
    # 测试静态站点
    if curl -f -s -I https://redamancy.com.cn/docs/ > /dev/null 2>&1; then
        log_success "静态站点访问正常: https://redamancy.com.cn/docs/"
    else
        log_warning "静态站点访问失败: https://redamancy.com.cn/docs/"
    fi
    
    # 测试后端 API
    if curl -f -s -I https://redamancy.com.cn/api/health > /dev/null 2>&1; then
        log_success "后端 API 访问正常: https://redamancy.com.cn/api/health"
    else
        log_warning "后端 API 访问失败: https://redamancy.com.cn/api/health"
    fi
    
    # 测试主站点
    if curl -f -s -I https://redamancy.com.cn/ > /dev/null 2>&1; then
        log_success "主站点访问正常: https://redamancy.com.cn/"
    else
        log_warning "主站点访问失败: https://redamancy.com.cn/"
    fi
}

# 生成部署报告
generate_report() {
    local report_file="/tmp/deployment_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "生成部署报告: $report_file"
    
    {
        echo "=== 部署验证报告 ==="
        echo "生成时间: $(date)"
        echo ""
        
        echo "=== 目录结构 ==="
        echo "后端项目目录:"
        ls -la /srv/apps/ 2>/dev/null || echo "目录不存在"
        echo ""
        
        echo "静态项目目录:"
        ls -la /srv/static/ 2>/dev/null || echo "目录不存在"
        echo ""
        
        echo "临时目录:"
        ls -la /tmp/ 2>/dev/null || echo "目录不存在"
        echo ""
        
        echo "=== 服务状态 ==="
        systemctl status star-cloud.service --no-pager -l 2>/dev/null || echo "服务不存在"
        echo ""
        
        echo "=== Nginx 状态 ==="
        systemctl status nginx --no-pager -l 2>/dev/null || echo "Nginx 未运行"
        echo ""
        
        echo "=== 端口占用 ==="
        netstat -tlnp | grep -E ":(80|443|8080)" 2>/dev/null || echo "未找到相关端口"
        echo ""
        
        echo "=== 健康检查 ==="
        curl -f -s http://127.0.0.1:8080/health 2>/dev/null || echo "健康检查失败"
        echo ""
        
    } > "$report_file"
    
    log_success "部署报告已生成: $report_file"
    echo "报告内容:"
    cat "$report_file"
}

# 主函数
main() {
    log_info "开始部署验证..."
    echo ""
    
    local errors=0
    
    # 检查目录结构
    log_info "=== 检查目录结构 ==="
    check_directory "/srv/apps/axi-star-cloud" "后端项目" || ((errors++))
    check_directory "/srv/static/axi-docs" "静态项目" || ((errors++))
    
    echo ""
    
    # 检查文件交叉污染
    log_info "=== 检查文件交叉污染 ==="
    check_cross_contamination || ((errors++))
    
    echo ""
    
    # 检查临时目录
    log_info "=== 检查临时目录 ==="
    check_temp_directories
    
    echo ""
    
    # 检查服务状态
    log_info "=== 检查服务状态 ==="
    check_service "star-cloud.service" "后端服务" || ((errors++))
    check_service "nginx" "Nginx" || ((errors++))
    
    echo ""
    
    # 检查端口
    log_info "=== 检查端口状态 ==="
    check_port "8080" "后端服务" || ((errors++))
    check_port "80" "HTTP" || ((errors++))
    check_port "443" "HTTPS" || ((errors++))
    
    echo ""
    
    # 检查健康检查
    log_info "=== 检查健康检查 ==="
    check_health "http://127.0.0.1:8080/health" "后端服务" || ((errors++))
    
    echo ""
    
    # 检查 Nginx 配置
    log_info "=== 检查 Nginx 配置 ==="
    check_nginx_config || ((errors++))
    
    echo ""
    
    # 检查 SSL 证书
    log_info "=== 检查 SSL 证书 ==="
    check_ssl_certificates || ((errors++))
    
    echo ""
    
    # 测试网站访问
    log_info "=== 测试网站访问 ==="
    test_website_access
    
    echo ""
    
    # 生成报告
    generate_report
    
    echo ""
    
    # 总结
    if [ $errors -eq 0 ]; then
        log_success "部署验证完成，所有检查通过！"
        exit 0
    else
        log_error "部署验证完成，发现 $errors 个问题，请检查上述错误信息。"
        exit 1
    fi
}

# 脚本入口
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "部署验证脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h    显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  - 检查目录结构是否正确"
    echo "  - 检查文件交叉污染"
    echo "  - 检查服务状态"
    echo "  - 检查端口占用"
    echo "  - 检查健康检查"
    echo "  - 检查 Nginx 配置"
    echo "  - 检查 SSL 证书"
    echo "  - 测试网站访问"
    echo "  - 生成部署报告"
    exit 0
fi

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    log_warning "建议以 root 权限运行此脚本以获得完整功能"
fi

# 执行主函数
main "$@" 