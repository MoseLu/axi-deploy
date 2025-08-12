# 🔌 WebSocket 部署通知系统指南

## 📋 概述

axi-deploy 现在支持通过 WebSocket 实时通知 axi-project-dashboard 部署过程中的详细信息，包括：

- **步骤级别监控**: 每个部署步骤的开始、进行中、完成、失败状态
- **实时日志流**: 部署过程中的实时日志输出
- **性能指标**: 部署耗时、成功率等指标
- **详细状态**: 具体到哪个 job、哪个 step、用时多少、日志内容

## 🏗️ 系统架构

### 通知流程

```
GitHub Actions 工作流
    ↓
WebSocket 通知工作流 (websocket-notification.yml)
    ↓
axi-project-dashboard API (/project-dashboard/api/webhooks/deployment)
    ↓
WebSocket 服务 (Socket.io)
    ↓
前端实时界面更新
```

### API 路径变更

为了避免与 axi-star-cloud 项目的 API 冲突，axi-project-dashboard 现在使用独立的 API 路径：

- **旧路径**: `https://redamancy.com.cn/api/`
- **新路径**: `https://redamancy.com.cn/project-dashboard/api/`
- **WebSocket**: `https://redamancy.com.cn/project-dashboard/ws/`

## 🔧 配置更改

### 1. Nginx 配置更新

```nginx
# axi-project-dashboard 专用路由
location /project-dashboard {
    alias /srv/apps/axi-project-dashboard/frontend;
    try_files $uri $uri/ /project-dashboard/index.html;
}

# axi-project-dashboard API 路由
location /project-dashboard/api/ {
    rewrite ^/project-dashboard/api/(.*) /api/$1 break;
    proxy_pass http://backend;
    proxy_set_header X-Forwarded-Prefix /project-dashboard;
}

# axi-project-dashboard WebSocket 连接
location /project-dashboard/ws/ {
    rewrite ^/project-dashboard/ws/(.*) /socket.io/$1 break;
    proxy_pass http://websocket;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

### 2. 通知 URL 更新

所有部署通知现在使用新的 API 路径：

```bash
DASHBOARD_URL="https://redamancy.com.cn/project-dashboard/api/webhooks/deployment"
```

## 📡 WebSocket 通知类型

### 1. 步骤通知 (step_started/step_completed)

```json
{
  "type": "step_started",
  "project": "axi-star-cloud",
  "deployment_id": "123456789",
  "step_name": "部署验证",
  "step_status": "started",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "workflow_name": "deploy-project",
  "workflow_id": "987654321",
  "logs": "开始验证部署参数",
  "duration": 0
}
```

### 2. 部署完成通知 (deployment_completed)

```json
{
  "type": "deployment_completed",
  "project": "axi-star-cloud",
  "deployment_id": "123456789",
  "status": "success",
  "duration": 45,
  "timestamp": "2024-01-01T12:01:00.000Z",
  "workflow_name": "deploy-project",
  "workflow_id": "987654321",
  "logs": "部署成功，耗时 45 秒",
  "started_at": "2024-01-01T12:00:15.000Z",
  "completed_at": "2024-01-01T12:01:00.000Z"
}
```

### 3. 日志条目 (log_entry)

```json
{
  "type": "log_entry",
  "project": "axi-star-cloud",
  "deployment_id": "123456789",
  "log_stream_id": "deployment_123456789_1704110400",
  "timestamp": "2024-01-01T12:00:30.000Z",
  "level": "info",
  "message": "正在上传构建产物...",
  "source": "workflow"
}
```

### 4. 指标更新 (metrics_update)

```json
{
  "type": "metrics_update",
  "project": "axi-star-cloud",
  "deployment_id": "123456789",
  "timestamp": "2024-01-01T12:01:00.000Z",
  "metrics": {
    "total_duration": 45,
    "start_time": "2024-01-01T12:00:15.000Z",
    "end_time": "2024-01-01T12:01:00.000Z",
    "status": "success",
    "steps_count": 5,
    "successful_steps": 5,
    "failed_steps": 0
  }
}
```

## 🚀 使用方法

### 1. 自动触发

WebSocket 通知工作流会在以下情况下自动触发：

- 当 `deploy-project` 工作流运行时
- 当 `main-deployment` 工作流运行时
- 工作流状态变化时（开始、进行中、完成）

### 2. 手动触发

可以通过 GitHub Actions 手动触发通知：

```bash
gh workflow run websocket-notification.yml \
  --field project=axi-star-cloud \
  --field deployment_id=123456789 \
  --field step_name="手动步骤" \
  --field step_status=completed \
  --field logs="手动触发的步骤通知" \
  --field duration=30
```

### 3. 在部署工作流中添加通知

在部署工作流的关键步骤中添加通知：

```yaml
- name: 发送步骤通知
  run: |
    NOTIFICATION_DATA=$(cat <<EOF
    {
      "type": "step_started",
      "project": "${{ inputs.project }}",
      "deployment_id": "${{ inputs.run_id }}",
      "step_name": "构建应用",
      "step_status": "started",
      "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
      "workflow_name": "deploy-project",
      "workflow_id": "${{ github.run_id }}",
      "logs": "开始构建应用",
      "duration": 0
    }
    EOF
    )
    
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "User-Agent: axi-deploy-websocket/1.0" \
      -d "$NOTIFICATION_DATA" \
      "https://redamancy.com.cn/project-dashboard/api/webhooks/deployment"
```

## 📊 前端集成

### 1. WebSocket 连接

```javascript
import io from 'socket.io-client';

const socket = io('https://redamancy.com.cn/project-dashboard/ws', {
  transports: ['websocket'],
  path: '/socket.io'
});

// 监听部署事件
socket.on('event', (event) => {
  switch (event.type) {
    case 'step_started':
      console.log('步骤开始:', event.payload);
      break;
    case 'step_completed':
      console.log('步骤完成:', event.payload);
      break;
    case 'deployment_completed':
      console.log('部署完成:', event.payload);
      break;
    case 'log_entry':
      console.log('日志条目:', event.payload);
      break;
  }
});

// 订阅特定项目的部署
socket.emit('subscribe_project', 'axi-star-cloud');

// 订阅特定部署的详细步骤
socket.emit('subscribe_deployment', '123456789');
```

### 2. 实时界面更新

```typescript
interface DeploymentStep {
  stepName: string;
  status: 'started' | 'running' | 'completed' | 'failed' | 'retrying';
  duration: number;
  logs: string;
  timestamp: string;
}

interface DeploymentStatus {
  id: string;
  project: string;
  status: string;
  duration: number;
  steps: DeploymentStep[];
  logs: string[];
}
```

## 🔍 监控和调试

### 1. 检查通知发送

```bash
# 检查 WebSocket 通知工作流状态
gh run list --workflow=websocket-notification.yml

# 查看通知日志
gh run view <run_id> --log
```

### 2. 验证 API 端点

```bash
# 测试通知端点
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"type":"test","project":"test"}' \
  https://redamancy.com.cn/project-dashboard/api/webhooks/deployment
```

### 3. 检查 WebSocket 连接

```bash
# 测试 WebSocket 连接
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: test" \
     https://redamancy.com.cn/project-dashboard/ws/
```

## 🛠️ 故障排查

### 常见问题

1. **通知未收到**
   - 检查 WebSocket 通知工作流是否正常运行
   - 验证 API 端点是否可访问
   - 确认通知数据格式是否正确

2. **API 路径冲突**
   - 确保使用新的 `/project-dashboard/api/` 路径
   - 检查 Nginx 配置是否正确

3. **WebSocket 连接失败**
   - 验证 WebSocket 服务是否运行在端口 8091
   - 检查防火墙设置
   - 确认 Nginx WebSocket 代理配置

### 日志查看

```bash
# 查看 Dashboard 后端日志
ssh deploy@redamancy.com.cn "pm2 logs dashboard-backend --lines 100"

# 查看 Nginx 访问日志
ssh deploy@redamancy.com.cn "tail -f /var/log/nginx/access.log | grep project-dashboard"

# 查看 WebSocket 服务日志
ssh deploy@redamancy.com.cn "pm2 logs dashboard-backend --lines 100 | grep socket"
```

## 📈 性能优化

### 1. 批量通知

对于大量日志条目，考虑批量发送：

```json
{
  "type": "log_batch",
  "project": "axi-star-cloud",
  "deployment_id": "123456789",
  "logs": [
    {"level": "info", "message": "日志1", "timestamp": "..."},
    {"level": "info", "message": "日志2", "timestamp": "..."}
  ]
}
```

### 2. 连接池管理

- 限制最大 WebSocket 连接数
- 实现连接心跳检测
- 自动清理断开的连接

### 3. 消息队列

对于高并发场景，考虑使用 Redis 消息队列：

```typescript
// 使用 Redis 队列处理通知
await redis.lpush('deployment_notifications', JSON.stringify(notification));
```

## 🔄 版本兼容性

### 向后兼容

系统保持对旧通知格式的兼容性：

```json
{
  "project": "axi-star-cloud",
  "status": "success",
  "duration": 45,
  "timestamp": "2024-01-01T12:01:00.000Z"
}
```

### 迁移指南

1. **更新通知 URL**: 使用新的 API 路径
2. **添加通知类型**: 在通知数据中添加 `type` 字段
3. **扩展数据结构**: 添加更多详细信息字段
4. **测试兼容性**: 确保旧格式仍然正常工作

## 📝 更新日志

### v1.0.0 (2024-01-01)
- ✅ 实现 WebSocket 通知系统
- ✅ 添加步骤级别监控
- ✅ 支持实时日志流
- ✅ 实现性能指标收集
- ✅ 更新 API 路径避免冲突
- ✅ 创建专门的 WebSocket 通知工作流
