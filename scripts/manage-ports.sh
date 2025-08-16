#!/bin/bash

# 端口管理脚本
# 用于管理服务器上的动态端口分配

set -e

# 配置
PORT_CONFIG_FILE="/srv/port-config.yml"
PORT_RANGE_START=8080
PORT_RANGE_END=10000

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 帮助信息
show_help() {
    echo "端口管理脚本"
    echo ""
    echo "用法: $0 [命令] [参数]"
    echo ""
    echo "命令:"
    echo "  list                    - 列出所有已分配的端口"
    echo "  check <port>            - 检查指定端口是否可用"
    echo "  allocate <project>      - 为项目分配端口"
    echo "  release <project>       - 释放项目端口"
    echo "  find <project>          - 查找项目当前端口"
    echo "  status                  - 显示端口使用状态"
    echo "  cleanup                 - 清理无效的端口分配"
    echo "  help                    - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 list"
    echo "  $0 allocate my-project"
    echo "  $0 check 8080"
    echo "  $0 release my-project"
}

# 检查端口是否可用
check_port_available() {
    local port=$1
    
    # 检查端口是否被监听
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        return 1  # 端口被占用
    fi
    
    # 检查端口是否在防火墙中开放
    if command -v firewall-cmd >/dev/null 2>&1; then
        if ! firewall-cmd --list-ports | grep -q "$port"; then
            echo -e "${YELLOW}⚠️  端口 $port 未在防火墙中开放${NC}"
            return 1
        fi
    fi
    
    return 0  # 端口可用
}

# 查找可用端口
find_available_port() {
    local start_port=$1
    local end_port=$2
    local preferred_port=$3
    
    echo -e "${BLUE}🔍 在端口范围 $start_port-$end_port 中查找可用端口...${NC}"
    
    # 如果指定了首选端口，先检查
    if [ -n "$preferred_port" ] && [ "$preferred_port" -ge "$start_port" ] && [ "$preferred_port" -le "$end_port" ]; then
        echo -e "${BLUE}🎯 检查首选端口: $preferred_port${NC}"
        if check_port_available "$preferred_port"; then
            echo -e "${GREEN}✅ 首选端口 $preferred_port 可用${NC}"
            echo "$preferred_port"
            return 0
        else
            echo -e "${RED}❌ 首选端口 $preferred_port 不可用${NC}"
        fi
    fi
    
    # 从起始端口开始查找
    for port in $(seq "$start_port" "$end_port"); do
        if check_port_available "$port"; then
            echo -e "${GREEN}✅ 找到可用端口: $port${NC}"
            echo "$port"
            return 0
        fi
    done
    
    echo -e "${RED}❌ 在端口范围 $start_port-$end_port 中未找到可用端口${NC}"
    return 1
}

# 更新端口配置文件
update_port_config() {
    local project=$1
    local port=$2
    local action=$3  # "add" 或 "remove"
    
    echo -e "${BLUE}📝 更新端口配置文件: $PORT_CONFIG_FILE${NC}"
    
    # 创建配置目录
    sudo mkdir -p "$(dirname "$PORT_CONFIG_FILE")"
    
    if [ "$action" = "add" ]; then
        # 如果配置文件不存在，创建基础结构
        if [ ! -f "$PORT_CONFIG_FILE" ]; then
            echo "# 动态端口配置" | sudo tee "$PORT_CONFIG_FILE" > /dev/null
            echo "# 自动生成和维护" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
            echo "# 最后更新: $(date)" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
            echo "" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
            echo "projects:" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
        fi
        
        # 检查项目是否已存在
        if grep -q "^  $project:" "$PORT_CONFIG_FILE"; then
            echo -e "${YELLOW}🔄 更新现有项目端口配置${NC}"
            # 更新现有项目的端口
            sudo sed -i "/^  $project:/,/^  [^ ]/ { /^    port:/ s/:.*/: $port/ }" "$PORT_CONFIG_FILE"
        else
            echo -e "${GREEN}➕ 添加新项目端口配置${NC}"
            # 在文件末尾添加新项目
            echo "" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
            echo "  $project:" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
            echo "    port: $port" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
            echo "    description: \"手动分配 - $(date)\"" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
            echo "    allocated_at: \"$(date -Iseconds)\"" | sudo tee -a "$PORT_CONFIG_FILE" > /dev/null
        fi
        
        echo -e "${GREEN}✅ 端口配置文件已更新${NC}"
        
    elif [ "$action" = "remove" ]; then
        if [ -f "$PORT_CONFIG_FILE" ]; then
            # 删除项目配置
            if grep -q "^  $project:" "$PORT_CONFIG_FILE"; then
                echo -e "${YELLOW}🗑️  删除项目端口配置${NC}"
                # 删除项目及其配置
                sudo sed -i "/^  $project:/,/^  [^ ]/d" "$PORT_CONFIG_FILE"
                # 清理多余的空行
                sudo sed -i '/^$/N;/^\n$/D' "$PORT_CONFIG_FILE"
                echo -e "${GREEN}✅ 项目端口配置已删除${NC}"
            else
                echo -e "${YELLOW}⚠️  项目 '$project' 在配置中未找到${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  端口配置文件不存在${NC}"
        fi
    fi
}

# 列出所有已分配的端口
list_ports() {
    echo -e "${BLUE}📋 已分配的端口列表:${NC}"
    echo ""
    
    if [ -f "$PORT_CONFIG_FILE" ]; then
        if grep -q "^  " "$PORT_CONFIG_FILE"; then
            while IFS= read -r line; do
                if [[ $line =~ ^[[:space:]]+([^:]+): ]]; then
                    project="${BASH_REMATCH[1]}"
                    echo -e "${GREEN}📦 $project${NC}"
                elif [[ $line =~ ^[[:space:]]+port:[[:space:]]+([0-9]+) ]]; then
                    port="${BASH_REMATCH[1]}"
                    if check_port_available "$port"; then
                        status="${GREEN}✅ 可用${NC}"
                    else
                        status="${RED}❌ 占用${NC}"
                    fi
                    echo -e "   └─ 端口: $port $status"
                elif [[ $line =~ ^[[:space:]]+description:[[:space:]]+(.+) ]]; then
                    description="${BASH_REMATCH[1]}"
                    echo -e "   └─ 描述: $description"
                elif [[ $line =~ ^[[:space:]]+allocated_at:[[:space:]]+(.+) ]]; then
                    allocated_at="${BASH_REMATCH[1]}"
                    echo -e "   └─ 分配时间: $allocated_at"
                fi
            done < "$PORT_CONFIG_FILE"
        else
            echo -e "${YELLOW}📭 暂无端口分配${NC}"
        fi
    else
        echo -e "${YELLOW}📭 端口配置文件不存在${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📊 当前端口使用情况:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ":(808[0-9]|809[0-9]|81[0-9][0-9]|82[0-9][0-9]|83[0-9][0-9]|84[0-9][0-9]|85[0-9][0-9]|86[0-9][0-9]|87[0-9][0-9]|88[0-9][0-9]|89[0-9][0-9]|9[0-9][0-9][0-9]) " | head -10 || echo "无端口监听"
}

# 检查指定端口
check_port() {
    local port=$1
    
    if [ -z "$port" ]; then
        echo -e "${RED}❌ 请指定要检查的端口${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🔍 检查端口 $port${NC}"
    
    if check_port_available "$port"; then
        echo -e "${GREEN}✅ 端口 $port 可用${NC}"
    else
        echo -e "${RED}❌ 端口 $port 不可用${NC}"
        
        # 显示占用信息
        echo -e "${YELLOW}📊 端口占用信息:${NC}"
        netstat -tlnp 2>/dev/null | grep ":$port " || echo "无详细信息"
    fi
}

# 为项目分配端口
allocate_port() {
    local project=$1
    
    if [ -z "$project" ]; then
        echo -e "${RED}❌ 请指定项目名称${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🎯 为项目 '$project' 分配端口${NC}"
    
    # 检查项目是否已有端口
    if [ -f "$PORT_CONFIG_FILE" ]; then
        existing_port=$(grep -A 1 "^  $project:" "$PORT_CONFIG_FILE" | grep "port:" | awk '{print $2}')
        if [ -n "$existing_port" ]; then
            echo -e "${YELLOW}⚠️  项目 '$project' 已有端口: $existing_port${NC}"
            read -p "是否重新分配? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}取消分配${NC}"
                exit 0
            fi
        fi
    fi
    
    # 查找可用端口
    allocated_port=$(find_available_port "$PORT_RANGE_START" "$PORT_RANGE_END" "")
    
    if [ $? -eq 0 ]; then
        # 更新配置文件
        update_port_config "$project" "$allocated_port" "add"
        
        echo -e "${GREEN}🎉 端口分配成功!${NC}"
        echo -e "项目: $project"
        echo -e "端口: $allocated_port"
        echo -e "配置文件: $PORT_CONFIG_FILE"
    else
        echo -e "${RED}❌ 端口分配失败${NC}"
        exit 1
    fi
}

# 释放项目端口
release_port() {
    local project=$1
    
    if [ -z "$project" ]; then
        echo -e "${RED}❌ 请指定项目名称${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🗑️  释放项目 '$project' 的端口${NC}"
    
    # 查找项目当前端口
    if [ -f "$PORT_CONFIG_FILE" ]; then
        current_port=$(grep -A 1 "^  $project:" "$PORT_CONFIG_FILE" | grep "port:" | awk '{print $2}')
        if [ -n "$current_port" ]; then
            echo -e "${YELLOW}📋 项目 '$project' 当前端口: $current_port${NC}"
            read -p "确认释放此端口? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # 更新配置文件
                update_port_config "$project" "" "remove"
                echo -e "${GREEN}✅ 端口已释放${NC}"
            else
                echo -e "${YELLOW}取消释放${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  项目 '$project' 在配置中未找到${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  端口配置文件不存在${NC}"
    fi
}

# 查找项目端口
find_project_port() {
    local project=$1
    
    if [ -z "$project" ]; then
        echo -e "${RED}❌ 请指定项目名称${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}🔍 查找项目 '$project' 的端口${NC}"
    
    if [ -f "$PORT_CONFIG_FILE" ]; then
        port=$(grep -A 1 "^  $project:" "$PORT_CONFIG_FILE" | grep "port:" | awk '{print $2}')
        if [ -n "$port" ]; then
            echo -e "${GREEN}✅ 找到端口: $port${NC}"
            
            # 检查端口状态
            if check_port_available "$port"; then
                echo -e "${GREEN}   └─ 状态: 可用${NC}"
            else
                echo -e "${RED}   └─ 状态: 占用${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  项目 '$project' 在配置中未找到${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  端口配置文件不存在${NC}"
    fi
}

# 显示端口状态
show_status() {
    echo -e "${BLUE}📊 端口使用状态${NC}"
    echo ""
    
    # 显示端口范围
    echo -e "${BLUE}📋 端口范围: $PORT_RANGE_START-$PORT_RANGE_END${NC}"
    
    # 统计已分配端口
    if [ -f "$PORT_CONFIG_FILE" ]; then
        allocated_count=$(grep -c "^    port:" "$PORT_CONFIG_FILE" || echo "0")
        echo -e "${BLUE}📦 已分配端口数: $allocated_count${NC}"
    else
        echo -e "${YELLOW}📦 已分配端口数: 0 (配置文件不存在)${NC}"
    fi
    
    # 统计正在监听的端口
    listening_count=$(netstat -tlnp 2>/dev/null | grep -E ":(808[0-9]|809[0-9]|81[0-9][0-9]|82[0-9][0-9]|83[0-9][0-9]|84[0-9][0-9]|85[0-9][0-9]|86[0-9][0-9]|87[0-9][0-9]|88[0-9][0-9]|89[0-9][0-9]|9[0-9][0-9][0-9]) " | wc -l)
    echo -e "${BLUE}🔊 正在监听端口数: $listening_count${NC}"
    
    echo ""
    echo -e "${BLUE}🔍 最近10个监听的端口:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ":(808[0-9]|809[0-9]|81[0-9][0-9]|82[0-9][0-9]|83[0-9][0-9]|84[0-9][0-9]|85[0-9][0-9]|86[0-9][0-9]|87[0-9][0-9]|88[0-9][0-9]|89[0-9][0-9]|9[0-9][0-9][0-9]) " | head -10 || echo "无端口监听"
}

# 清理无效的端口分配
cleanup_ports() {
    echo -e "${BLUE}🧹 清理无效的端口分配${NC}"
    
    if [ ! -f "$PORT_CONFIG_FILE" ]; then
        echo -e "${YELLOW}⚠️  端口配置文件不存在${NC}"
        return
    fi
    
    local cleaned=0
    
    # 检查每个已分配的端口
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]+([^:]+): ]]; then
            project="${BASH_REMATCH[1]}"
        elif [[ $line =~ ^[[:space:]]+port:[[:space:]]+([0-9]+) ]]; then
            port="${BASH_REMATCH[1]}"
            
            # 检查端口是否仍然被占用
            if ! netstat -tlnp 2>/dev/null | grep -q ":$port "; then
                echo -e "${YELLOW}🗑️  清理项目 '$project' 的端口 $port (未使用)${NC}"
                update_port_config "$project" "" "remove"
                cleaned=$((cleaned + 1))
            fi
        fi
    done < "$PORT_CONFIG_FILE"
    
    if [ $cleaned -eq 0 ]; then
        echo -e "${GREEN}✅ 无需清理，所有端口分配都有效${NC}"
    else
        echo -e "${GREEN}✅ 清理完成，共清理 $cleaned 个无效分配${NC}"
    fi
}

# 主函数
main() {
    case "$1" in
        "list")
            list_ports
            ;;
        "check")
            check_port "$2"
            ;;
        "allocate")
            allocate_port "$2"
            ;;
        "release")
            release_port "$2"
            ;;
        "find")
            find_project_port "$2"
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup_ports
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
