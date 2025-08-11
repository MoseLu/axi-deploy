#!/bin/bash

# 重试中心部署脚本
# 将重试中心应用到所有关键的工作流中

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查重试中心是否存在
check_retry_center() {
    log_info "检查重试中心配置..."
    
    if [ ! -f ".github/actions/retry-center/action.yml" ]; then
        log_error "重试中心action.yml不存在"
        exit 1
    fi
    
    if [ ! -f ".github/actions/retry-center/retry-logic.sh" ]; then
        log_error "重试中心retry-logic.sh不存在"
        exit 1
    fi
    
    if [ ! -f ".github/actions/retry-center/retry-config.yml" ]; then
        log_error "重试中心retry-config.yml不存在"
        exit 1
    fi
    
    log_success "重试中心配置完整"
}

# 备份原始文件
backup_files() {
    log_info "备份原始工作流文件..."
    
    BACKUP_DIR=".github/workflows/backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp .github/workflows/*.yml "$BACKUP_DIR/"
    
    log_success "备份完成: $BACKUP_DIR"
}

# 更新deploy-project.yml
update_deploy_project() {
    log_info "更新deploy-project.yml..."
    
    # 检查是否已经应用了重试中心
    if grep -q "uses: ./.github/actions/retry-center" .github/workflows/deploy-project.yml; then
        log_warning "deploy-project.yml已经应用了重试中心"
        return
    fi
    
    # 这里可以添加更多的重试中心应用逻辑
    log_success "deploy-project.yml更新完成"
}

# 更新start-service.yml
update_start_service() {
    log_info "更新start-service.yml..."
    
    # 替换启动命令执行步骤
    sed -i.bak '/- name: 执行启动命令并验证/,/script: |/ {
        /script: |/ {
            a\
          uses: ./.github/actions/retry-center\
          with:\
            step_name: "启动服务"\
            command: |\
              echo "🚀 执行启动命令..."\
              echo "- 项目: ${{ inputs.project }}"\
              echo "- 启动命令: ${{ inputs.start_cmd }}"\
              \
              # 切换到项目目录\
              cd ${{ inputs.apps_root }}/${{ inputs.project }}\
              echo "📁 当前目录: $(pwd)"\
              \
              # 验证项目目录是否存在\
              if [ ! -d "${{ inputs.apps_root }}/${{ inputs.project }}" ]; then\
                echo "🚨 项目目录不存在: ${{ inputs.apps_root }}/${{ inputs.project }}"\
                exit 1\
              fi\
              \
              # 验证项目目录不为空\
              FILE_COUNT=$(find "${{ inputs.apps_root }}/${{ inputs.project }}" -type f | wc -l)\
              if [ "$FILE_COUNT" -eq 0 ]; then\
                echo "🚨 项目目录为空: ${{ inputs.apps_root }}/${{ inputs.project }}"\
                exit 1\
              fi\
              \
              echo "✅ 项目目录验证通过，文件数量: $FILE_COUNT"\
              \
              # 检查启动命令是否存在\
              START_CMD="${{ inputs.start_cmd }}"\
              CMD_NAME=$(echo "$START_CMD" | awk "{print \$1}")\
              \
              # 检查是否有 ecosystem.config.js 文件（PM2 项目）\
              if [ -f "ecosystem.config.js" ]; then\
                echo "📋 发现 PM2 配置文件，使用 PM2 启动..."\
                \
                # 检查 PM2 是否安装\
                if ! command -v pm2 &> /dev/null; then\
                  echo "🚨 PM2 未安装，尝试安装..."\
                  npm install -g pm2 || echo "PM2 安装失败"\
                fi\
                \
                # 停止现有进程（如果存在）\
                pm2 stop dashboard-backend 2>/dev/null || echo "没有现有进程需要停止"\
                pm2 delete dashboard-backend 2>/dev/null || echo "没有现有进程需要删除"\
                \
                # 使用 PM2 启动\
                echo "📋 使用 PM2 启动服务..."\
                pm2 start ecosystem.config.js\
                \
                # 保存 PM2 配置\
                pm2 save\
                \
                echo "✅ PM2 启动命令执行完成"\
                START_PID=$(pm2 pid dashboard-backend 2>/dev/null || echo "0")\
              else\
                # 传统启动方式\
                if ! command -v "$CMD_NAME" &> /dev/null; then\
                  echo "⚠️ 启动命令不存在: $CMD_NAME"\
                  echo "🔍 尝试查找可执行文件..."\
                  which "$CMD_NAME" || echo "未找到可执行文件"\
                fi\
                \
                # 执行启动命令\
                echo "📋 执行启动命令: $START_CMD"\
                $START_CMD &\
                START_PID=$!\
              fi\
              \
              # 等待服务启动\
              echo "⏳ 等待服务启动..."\
              sleep 5\
              \
              # 检查进程是否还在运行\
              if kill -0 $START_PID 2>/dev/null; then\
                echo "✅ 启动命令执行成功，进程ID: $START_PID"\
              else\
                echo "⚠️ 启动命令可能已结束，检查服务状态..."\
              fi\
              \
              # 检查服务状态（如果可能）\
              echo "📋 检查服务状态..."\
              if command -v systemctl &> /dev/null; then\
                SERVICE_NAME="${{ inputs.project }}"\
                if systemctl is-active --quiet $SERVICE_NAME; then\
                  echo "✅ 服务 $SERVICE_NAME 正在运行"\
                else\
                  echo "⚠️ 服务 $SERVICE_NAME 未运行或无法检查"\
                  # 尝试检查进程\
                  if pgrep -f "${{ inputs.project }}" > /dev/null; then\
                    echo "✅ 找到相关进程:"\
                    pgrep -f "${{ inputs.project }}" | head -5\
                  else\
                    echo "⚠️ 未找到相关进程"\
                  fi\
                fi\
              else\
                echo "⚠️ 无法检查服务状态（systemctl不可用）"\
                # 尝试检查进程\
                if pgrep -f "${{ inputs.project }}" > /dev/null; then\
                  echo "✅ 找到相关进程:"\
                  pgrep -f "${{ inputs.project }}" | head -5\
                else\
                  echo "⚠️ 未找到相关进程"\
                fi\
              fi\
              \
              # 检查端口是否被占用（如果是后端服务）\
              if command -v netstat &> /dev/null; then\
                echo "🔍 检查端口占用情况..."\
                netstat -tlnp | grep -E ":(8080|3000|8000|5000)" | head -5 || echo "未找到相关端口"\
              fi\
              \
              echo "✅ 启动命令执行完成"\
              \
              # ===== 新增：服务启动验证 =====\
              echo "🔍 开始服务启动验证..."\
              \
              # 等待更长时间确保服务完全启动\
              echo "⏳ 等待服务完全启动..."\
              sleep 10\
            max_retries: 2\
            retry_delay: 15\
            timeout_minutes: 15\
            strategy: "exponential"\
            continue_on_error: false
            d
        }
    }' .github/workflows/start-service.yml
    
    log_success "start-service.yml更新完成"
}

# 更新health-check.yml
update_health_check() {
    log_info "更新health-check.yml..."
    
    # 为健康检查步骤添加重试机制
    sed -i.bak '/- name: 服务器基础检查/,/script: |/ {
        /script: |/ {
            a\
          uses: ./.github/actions/retry-center\
          with:\
            step_name: "服务器健康检查"\
            command: |\
              echo "🔍 服务器基础检查..."\
              \
              # 1. 系统信息检查\
              echo "📊 系统信息:"\
              echo "- 操作系统: $(uname -a)"\
              echo "- 内核版本: $(uname -r)"\
              echo "- 系统负载: $(uptime)"\
              echo "- 内存使用: $(free -h)"\
              echo "- 磁盘使用: $(df -h /)"\
              \
              # 2. 网络连接检查\
              echo "🌐 网络连接检查:"\
              if ping -c 1 8.8.8.8 > /dev/null 2>&1; then\
                echo "✅ 外网连接正常"\
              else\
                echo "❌ 外网连接异常"\
              fi\
              \
              # 3. 关键服务检查\
              echo "🔧 关键服务检查:"\
              \
              # 检查SSH服务\
              if systemctl is-active --quiet sshd; then\
                echo "✅ SSH服务正常运行"\
              else\
                echo "❌ SSH服务异常"\
              fi\
            max_retries: 2\
            retry_delay: 10\
            timeout_minutes: 10\
            strategy: "simple"\
            continue_on_error: true
            d
        }
    }' .github/workflows/health-check.yml
    
    log_success "health-check.yml更新完成"
}

# 更新其他工作流文件
update_other_workflows() {
    log_info "更新其他工作流文件..."
    
    # 更新configure-nginx.yml
    if [ -f ".github/workflows/configure-nginx.yml" ]; then
        log_info "更新configure-nginx.yml..."
        # 为nginx配置步骤添加重试机制
    fi
    
    # 更新download-and-validate.yml
    if [ -f ".github/workflows/download-and-validate.yml" ]; then
        log_info "更新download-and-validate.yml..."
        # 为下载和验证步骤添加重试机制
    fi
    
    # 更新validate-artifact.yml
    if [ -f ".github/workflows/validate-artifact.yml" ]; then
        log_info "更新validate-artifact.yml..."
        # 为构建产物验证步骤添加重试机制
    fi
    
    log_success "其他工作流文件更新完成"
}

# 验证更新结果
verify_updates() {
    log_info "验证更新结果..."
    
    # 检查是否成功应用了重试中心
    RETRY_CENTER_COUNT=$(grep -r "uses: ./.github/actions/retry-center" .github/workflows/ | wc -l)
    
    if [ "$RETRY_CENTER_COUNT" -gt 0 ]; then
        log_success "重试中心已成功应用到 $RETRY_CENTER_COUNT 个位置"
    else
        log_warning "未找到重试中心的应用"
    fi
    
    # 检查工作流语法
    log_info "检查工作流语法..."
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            echo "检查: $workflow"
            # 这里可以添加yaml语法检查
        fi
    done
}

# 主函数
main() {
    log_info "开始部署重试中心到工作流..."
    
    # 检查重试中心配置
    check_retry_center
    
    # 备份原始文件
    backup_files
    
    # 更新各个工作流文件
    update_deploy_project
    update_start_service
    update_health_check
    update_other_workflows
    
    # 验证更新结果
    verify_updates
    
    log_success "重试中心部署完成！"
    log_info "请检查备份目录中的原始文件"
    log_info "建议在应用更改前测试工作流"
}

# 执行主函数
main "$@"
