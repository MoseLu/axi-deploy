#!/bin/bash

# 同步端口配置文件到服务器
# 用法: ./sync-port-config.sh <server_host> <server_user> <server_port>

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

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根目录
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# 本地端口配置文件
LOCAL_PORT_CONFIG="$PROJECT_ROOT/port-config.yml"

log_info "开始同步端口配置文件..."
log_info "服务器: $SERVER_USER@$SERVER_HOST:$SERVER_PORT"
log_info "本地配置文件: $LOCAL_PORT_CONFIG"

# 检查本地配置文件是否存在
if [ ! -f "$LOCAL_PORT_CONFIG" ]; then
    log_error "本地端口配置文件不存在: $LOCAL_PORT_CONFIG"
    exit 1
fi

# 检查SSH密钥是否存在
if [ ! -f "$SSH_KEY_PATH" ]; then
    log_warning "SSH密钥不存在: $SSH_KEY_PATH"
    log_info "尝试使用密码认证..."
    SSH_OPTS=""
else
    log_info "使用SSH密钥: $SSH_KEY_PATH"
    SSH_OPTS="-i $SSH_KEY_PATH"
fi

# 备份服务器上的现有配置
log_info "备份服务器上的现有配置..."
ssh $SSH_OPTS -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "
    if [ -f '/srv/port-config.yml' ]; then
        sudo cp '/srv/port-config.yml' '/srv/port-config.yml.backup.\$(date +%Y%m%d_%H%M%S)'
        echo '✅ 服务器配置已备份'
    else
        echo '⚠️ 服务器上不存在端口配置文件'
    fi
"

# 上传新的配置文件
log_info "上传新的端口配置文件..."
scp $SSH_OPTS -o StrictHostKeyChecking=no -o ConnectTimeout=10 -P "$SERVER_PORT" "$LOCAL_PORT_CONFIG" "$SERVER_USER@$SERVER_HOST:/tmp/port-config.yml"

# 移动到正确位置并设置权限
log_info "设置配置文件权限..."
ssh $SSH_OPTS -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "
    sudo mkdir -p /srv
    sudo mv /tmp/port-config.yml /srv/port-config.yml
    sudo chown root:root /srv/port-config.yml
    sudo chmod 644 /srv/port-config.yml
    echo '✅ 配置文件已移动到正确位置'
"

# 验证配置文件
log_info "验证配置文件..."
ssh $SSH_OPTS -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "
    if [ -f '/srv/port-config.yml' ]; then
        echo '📋 服务器端口配置:'
        cat /srv/port-config.yml
        echo ''
        echo '✅ 配置文件验证成功'
    else
        echo '❌ 配置文件验证失败'
        exit 1
    fi
"

log_success "端口配置文件同步完成！"
log_info "服务器上的配置文件: /srv/port-config.yml"
