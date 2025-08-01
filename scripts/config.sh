#!/bin/bash

# 动态配置脚本
# 从环境变量或GitHub Secrets中读取配置

# 服务器配置 - 从环境变量读取
SERVER_PUBLIC_IP="${SERVER_HOST:-47.112.163.152}"
SERVER_PRIVATE_IP="${SERVER_PRIVATE_IP:-}"
SSH_PORT="${SERVER_PORT:-22}"
DEPLOY_USER="${SERVER_USER:-root}"

# 部署路径配置
DEFAULT_TARGET_PATH="${TARGET_PATH:-/www/wwwroot}"

# 日志配置
LOG_FILE="${LOG_FILE:-/var/log/axi-deploy.log}"

# 导出变量供其他脚本使用
export SERVER_PUBLIC_IP
export SERVER_PRIVATE_IP
export SSH_PORT
export DEPLOY_USER
export DEFAULT_TARGET_PATH
export LOG_FILE

# 显示当前配置（调试用）
if [ "${DEBUG:-false}" = "true" ]; then
    echo "🔧 当前配置:"
    echo "- 服务器IP: $SERVER_PUBLIC_IP"
    echo "- SSH端口: $SSH_PORT"
    echo "- 部署用户: $DEPLOY_USER"
    echo "- 目标路径: $DEFAULT_TARGET_PATH"
fi 