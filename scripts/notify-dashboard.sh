#!/bin/bash

# 部署通知脚本
# 用于在 axi-deploy 部署完成后通知 axi-project-dashboard

set -e

# 配置
DASHBOARD_URL="https://redamancy.com.cn/project-dashboard/api/webhooks/deployment"
PROJECT_NAME="$1"
DEPLOY_STATUS="$2"
DEPLOY_DURATION="$3"
SOURCE_REPO="$4"
RUN_ID="$5"
DEPLOY_TYPE="$6"
SERVER_HOST="$7"
LOGS="$8"
ERROR_MESSAGE="$9"

# 验证必需参数
if [ -z "$PROJECT_NAME" ] || [ -z "$DEPLOY_STATUS" ]; then
    echo "❌ 错误: 缺少必需参数"
    echo "用法: $0 <项目名称> <部署状态> [部署耗时] [源仓库] [运行ID] [部署类型] [服务器地址] [日志] [错误信息]"
    echo "示例: $0 axi-star-cloud success 45 MoseLu/axi-star-cloud 123456789 backend redamancy.com.cn"
    exit 1
fi

# 设置默认值
DEPLOY_DURATION=${DEPLOY_DURATION:-0}
SOURCE_REPO=${SOURCE_REPO:-""}
RUN_ID=${RUN_ID:-""}
DEPLOY_TYPE=${DEPLOY_TYPE:-"static"}
SERVER_HOST=${SERVER_HOST:-"redamancy.com.cn"}
LOGS=${LOGS:-""}
ERROR_MESSAGE=${ERROR_MESSAGE:-""}

# 构建通知数据
NOTIFICATION_DATA=$(cat <<EOF
{
  "project": "$PROJECT_NAME",
  "status": "$DEPLOY_STATUS",
  "duration": $DEPLOY_DURATION,
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "sourceRepo": "$SOURCE_REPO",
  "runId": "$RUN_ID",
  "deployType": "$DEPLOY_TYPE",
  "serverHost": "$SERVER_HOST",
  "logs": "$LOGS",
  "errorMessage": "$ERROR_MESSAGE"
}
EOF
)

echo "📤 发送部署通知到 axi-project-dashboard..."
echo "项目: $PROJECT_NAME"
echo "状态: $DEPLOY_STATUS"
echo "耗时: ${DEPLOY_DURATION}秒"
echo "目标: $DASHBOARD_URL"

# 发送通知
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "User-Agent: axi-deploy/1.0" \
  -d "$NOTIFICATION_DATA" \
  "$DASHBOARD_URL" \
  2>/dev/null)

# 解析响应
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 部署通知发送成功"
    echo "响应: $RESPONSE_BODY"
else
    echo "❌ 部署通知发送失败 (HTTP $HTTP_CODE)"
    echo "响应: $RESPONSE_BODY"
    # 不退出，因为这只是通知，不应该影响部署流程
fi

echo "🎉 部署通知完成"
