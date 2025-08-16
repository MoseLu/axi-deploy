# 快速修复服务器问题
# 用法: .\quick-fix-server.ps1

param(
    [string]$ServerHost = "47.112.163.152",
    [string]$ServerUser = "deploy",
    [string]$ServerPort = "22"
)

Write-Host "🔧 开始快速修复服务器问题..." -ForegroundColor Blue
Write-Host "服务器: $ServerUser@$ServerHost`:$ServerPort" -ForegroundColor Blue

# 修复脚本内容
$FixScript = @"
set -e

echo '🔧 检查 MySQL 服务状态...'
if ! systemctl is-active --quiet mysql; then
    echo '❌ MySQL 服务未运行，尝试启动...'
    sudo systemctl start mysql
    sleep 5
fi

if systemctl is-active --quiet mysql; then
    echo '✅ MySQL 服务已启动'
else
    echo '❌ MySQL 服务启动失败'
    echo '📋 MySQL 服务状态:'
    sudo systemctl status mysql --no-pager -l
fi

echo '🔧 检查 star-cloud 服务文件...'
PROJECT_DIR='/srv/apps/axi-star-cloud'
SERVICE_FILE="\$PROJECT_DIR/star-cloud.service"

if [ -f "\$SERVICE_FILE" ]; then
    echo '📋 当前服务文件内容:'
    cat "\$SERVICE_FILE"
    
    echo '🔧 修复服务文件...'
    # 备份原文件
    sudo cp "\$SERVICE_FILE" "\$SERVICE_FILE.backup.\$(date +%Y%m%d_%H%M%S)"
    
    # 创建新的服务文件
    sudo tee "\$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=Star Cloud Go Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/srv/apps/axi-star-cloud
ExecStart=/srv/apps/axi-star-cloud/star-cloud-linux
Restart=on-failure
RestartSec=5
User=deploy
Group=deploy
StandardOutput=journal
StandardError=journal
Environment=GIN_MODE=release
Environment=SERVICE_PORT=8124

[Install]
WantedBy=multi-user.target
EOF
    
    echo '✅ 服务文件已更新'
    echo '📋 更新后的服务文件内容:'
    cat "\$SERVICE_FILE"
else
    echo '❌ 服务文件不存在'
fi

echo '🔧 修复配置文件...'
CONFIG_FILE="\$PROJECT_DIR/backend/config/config-prod.yaml"
if [ -f "\$CONFIG_FILE" ]; then
    echo '📝 备份原配置文件...'
    sudo cp "\$CONFIG_FILE" "\$CONFIG_FILE.backup.\$(date +%Y%m%d_%H%M%S)"
    
    echo '📝 更新端口配置...'
    sudo sed -i "s/port: '8080'/port: '8124'/" "\$CONFIG_FILE"
    
    echo '✅ 配置文件已更新'
    echo '📋 更新后的端口配置:'
    grep -A 5 'server:' "\$CONFIG_FILE"
else
    echo '⚠️ 配置文件不存在: \$CONFIG_FILE'
fi

echo '🔧 重新加载 systemd 配置...'
sudo systemctl daemon-reload

echo '🔧 重启 star-cloud 服务...'
sudo systemctl restart star-cloud.service

echo '⏳ 等待服务启动...'
sleep 15

echo '🔍 检查服务状态...'
if sudo systemctl is-active --quiet star-cloud.service; then
    echo '✅ 服务已启动'
else
    echo '❌ 服务启动失败'
    echo '📋 服务状态:'
    sudo systemctl status star-cloud.service --no-pager -l
    echo '📋 服务日志:'
    sudo journalctl -u star-cloud.service --no-pager -n 20
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
    echo '⚠️ 健康检查失败'
    echo '📋 健康检查响应:'
    curl -s http://localhost:8124/health || echo '连接失败'
fi
"@

# 执行修复脚本
Write-Host "执行修复脚本..." -ForegroundColor Blue
try {
    $result = ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p $ServerPort $ServerUser@$ServerHost $FixScript
    Write-Host $result
} catch {
    Write-Host "执行失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 快速修复完成！" -ForegroundColor Green
