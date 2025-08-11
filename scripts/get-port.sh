#!/bin/bash

# 获取项目端口的脚本
# 用法: ./get-port.sh <project_name>
# 返回: 端口号

set -e

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根目录
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# 端口配置文件
PORT_CONFIG="$PROJECT_ROOT/port-config.yml"

# 检查参数
if [ $# -eq 0 ]; then
    echo "❌ 错误: 请提供项目名称"
    echo "用法: $0 <project_name>"
    echo "示例: $0 axi-project-dashboard"
    exit 1
fi

PROJECT_NAME="$1"

# 检查配置文件是否存在
if [ ! -f "$PORT_CONFIG" ]; then
    echo "❌ 错误: 端口配置文件不存在: $PORT_CONFIG"
    exit 1
fi

# 使用grep和awk解析YAML文件获取端口
PORT=$(grep -A 1 "^  $PROJECT_NAME:" "$PORT_CONFIG" | grep "port:" | awk '{print $2}')

if [ -z "$PORT" ]; then
    echo "❌ 错误: 项目 '$PROJECT_NAME' 在端口配置中未找到"
    echo "📋 可用的项目:"
    grep "^  [a-zA-Z]" "$PORT_CONFIG" | sed 's/^  //' | sed 's/:$//'
    exit 1
fi

echo "$PORT"
