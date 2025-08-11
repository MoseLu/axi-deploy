#!/bin/bash

# 应用重试中心到工作流文件
# 这个脚本将重试中心应用到关键的工作流步骤中

set -e

echo "🚀 开始应用重试中心到工作流文件..."

# 检查重试中心是否存在
if [ ! -f ".github/actions/retry-center/action.yml" ]; then
    echo "❌ 重试中心不存在，请先创建重试中心"
    exit 1
fi

echo "✅ 重试中心配置存在"

# 备份原始文件
BACKUP_DIR=".github/workflows/backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp .github/workflows/*.yml "$BACKUP_DIR/"
echo "✅ 已备份原始文件到: $BACKUP_DIR"

# 统计应用重试中心的位置
RETRY_COUNT=0

# 检查deploy-project.yml是否已经应用了重试中心
if grep -q "uses: ./.github/actions/retry-center" .github/workflows/deploy-project.yml; then
    echo "✅ deploy-project.yml 已经应用了重试中心"
    RETRY_COUNT=$((RETRY_COUNT + 1))
else
    echo "⚠️ deploy-project.yml 需要手动应用重试中心"
fi

# 检查start-service.yml是否已经应用了重试中心
if grep -q "uses: ./.github/actions/retry-center" .github/workflows/start-service.yml; then
    echo "✅ start-service.yml 已经应用了重试中心"
    RETRY_COUNT=$((RETRY_COUNT + 1))
else
    echo "⚠️ start-service.yml 需要手动应用重试中心"
fi

# 检查health-check.yml是否已经应用了重试中心
if grep -q "uses: ./.github/actions/retry-center" .github/workflows/health-check.yml; then
    echo "✅ health-check.yml 已经应用了重试中心"
    RETRY_COUNT=$((RETRY_COUNT + 1))
else
    echo "⚠️ health-check.yml 需要手动应用重试中心"
fi

echo ""
echo "📊 重试中心应用统计:"
echo "- 已应用: $RETRY_COUNT 个文件"
echo "- 总工作流文件: $(ls .github/workflows/*.yml | wc -l) 个"

echo ""
echo "🔧 建议手动应用重试中心到以下步骤:"
echo "1. deploy-project.yml - 下载构建产物步骤"
echo "2. start-service.yml - 启动服务步骤"
echo "3. health-check.yml - 健康检查步骤"
echo "4. configure-nginx.yml - nginx配置步骤"
echo "5. download-and-validate.yml - 下载验证步骤"

echo ""
echo "📝 重试中心使用示例:"
echo "```yaml"
echo "- name: 使用重试中心执行命令"
echo "  uses: ./.github/actions/retry-center"
echo "  with:"
echo "    step_name: \"步骤名称\""
echo "    command: \"要执行的命令\""
echo "    max_retries: 3"
echo "    retry_delay: 5"
echo "    timeout_minutes: 10"
echo "    strategy: \"exponential\""
echo "    continue_on_error: false"
echo "```"

echo ""
echo "✅ 重试中心应用检查完成！"
