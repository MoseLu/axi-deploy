#!/bin/bash

# 修复 star-cloud 服务端口配置
# 用法: ./fix-star-cloud-service.sh <server_host> <server_user> <server_port>

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

# 检查参数
if [ $# -lt 3 ]; then
    log_error "参数不足"
    echo "用法: $0 <server_host> <server_user> <server_port> [ssh_key_path]"
    echo "示例: $0 47.112.163.152 deploy 22"
    exit 1
fi

SERVER_HOST="$1"
SERVER_USER="$2"
SERVER_PORT="$3"
SSH_KEY_PATH="${4:-~/.ssh/id_rsa}"

log_info "开始修复 star-cloud 服务端口配置..."
log_info "服务器: $SERVER_USER@$SERVER_HOST:$SERVER_PORT"

# 检查SSH密钥是否存在
if [ ! -f "$SSH_KEY_PATH" ]; then
    log_warning "SSH密钥不存在: $SSH_KEY_PATH"
    log_info "尝试使用密码认证..."
    SSH_OPTS=""
else
    log_info "使用SSH密钥: $SSH_KEY_PATH"
    SSH_OPTS="-i $SSH_KEY_PATH"
fi

# 修复服务配置
log_info "修复 star-cloud 服务配置..."
ssh $SSH_OPTS -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "
    set -e
    
    PROJECT_DIR='/srv/apps/axi-star-cloud'
    SERVICE_FILE='\$PROJECT_DIR/star-cloud.service'
    
    echo '🔧 检查项目目录...'
    if [ ! -d '\$PROJECT_DIR' ]; then
        echo '❌ 项目目录不存在: \$PROJECT_DIR'
        exit 1
    fi
    
    echo '📁 项目目录: \$PROJECT_DIR'
    ls -la '\$PROJECT_DIR/'
    
    echo '🔧 修复 systemd 服务文件...'
    if [ -f '\$SERVICE_FILE' ]; then
        echo '📝 备份原服务文件...'
        sudo cp '\$SERVICE_FILE' '\$SERVICE_FILE.backup.\$(date +%Y%m%d_%H%M%S)'
        
        echo '📝 更新服务文件，添加 SERVICE_PORT 环境变量...'
        # 检查是否已有 SERVICE_PORT 环境变量
        if grep -q 'SERVICE_PORT=' '\$SERVICE_FILE'; then
            echo '🔄 更新现有的 SERVICE_PORT 环境变量...'
            sudo sed -i 's/SERVICE_PORT=.*/SERVICE_PORT=8124/' '\$SERVICE_FILE'
        else
            echo '➕ 添加 SERVICE_PORT 环境变量...'
            sudo sed -i '/Environment=GIN_MODE=release/a Environment=SERVICE_PORT=8124' '\$SERVICE_FILE'
        fi
        
        echo '✅ 服务文件已更新'
        echo '📋 更新后的服务文件内容:'
        cat '\$SERVICE_FILE'
    else
        echo '❌ 服务文件不存在: \$SERVICE_FILE'
        exit 1
    fi
    
    echo '🔧 修复 Go 应用配置文件...'
    CONFIG_FILE='\$PROJECT_DIR/backend/config/config-prod.yaml'
    if [ -f '\$CONFIG_FILE' ]; then
        echo '📝 备份原配置文件...'
        sudo cp '\$CONFIG_FILE' '\$CONFIG_FILE.backup.\$(date +%Y%m%d_%H%M%S)'
        
        echo '📝 更新端口配置...'
        sudo sed -i \"s/port: '8080'/port: '8124'/\" '\$CONFIG_FILE'
        
        echo '📝 更新 CORS 配置...'
        if ! grep -q \"localhost:8124\" '\$CONFIG_FILE'; then
            sudo sed -i \"/localhost:8080/a\\    - 'http://localhost:8124'\" '\$CONFIG_FILE'
        fi
        
        echo '✅ 配置文件已更新'
        echo '📋 更新后的端口配置:'
        grep -A 5 'server:' '\$CONFIG_FILE'
    else
        echo '⚠️ 配置文件不存在: \$CONFIG_FILE'
    fi
    
    echo '🔧 重新加载 systemd 配置...'
    sudo systemctl daemon-reload
    
    echo '🔧 重启 star-cloud 服务...'
    sudo systemctl restart star-cloud.service
    
    echo '⏳ 等待服务启动...'
    sleep 10
    
    echo '🔍 检查服务状态...'
    if sudo systemctl is-active --quiet star-cloud.service; then
        echo '✅ 服务已启动'
    else
        echo '❌ 服务启动失败'
        echo '📋 服务状态:'
        sudo systemctl status star-cloud.service --no-pager -l
        exit 1
    fi
    
    echo '🔍 检查端口监听...'
    if netstat -tlnp 2>/dev/null | grep -q ':8124 '; then
        echo '✅ 端口 8124 正在监听'
        netstat -tlnp 2>/dev/null | grep ':8124 '
    else
        echo '❌ 端口 8124 未监听'
        echo '📋 当前端口监听情况:'
        netstat -tlnp 2>/dev/null | grep -E ':(808[0-9]|809[0-9]|81[0-9][0-9]) '
    fi
    
    echo '🔍 测试健康检查...'
    if curl -s -o /dev/null -w '%{http_code}' http://localhost:8124/health | grep -q '200'; then
        echo '✅ 健康检查通过'
    else
        echo '⚠️ 健康检查失败，但服务可能仍在启动中'
        echo '📋 健康检查响应:'
        curl -s http://localhost:8124/health || echo '连接失败'
    fi
"

log_success "star-cloud 服务端口配置修复完成！"
log_info "服务现在应该在端口 8124 上运行"
log_info "可以使用以下命令检查服务状态："
echo "  ssh $SERVER_USER@$SERVER_HOST 'sudo systemctl status star-cloud.service'"
echo "  ssh $SERVER_USER@$SERVER_HOST 'netstat -tlnp | grep 8124'"
echo "  ssh $SERVER_USER@$SERVER_HOST 'curl http://localhost:8124/health'"
