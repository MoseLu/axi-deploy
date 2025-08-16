# 修复 star-cloud 服务端口配置 (PowerShell 版本)
# 用法: .\fix-star-cloud-service.ps1 <server_host> <server_user> <server_port>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerHost,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerUser,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerPort,
    
    [string]$SshKeyPath = "$env:USERPROFILE\.ssh\id_rsa"
)

# 颜色定义
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

# 日志函数
function Write-Info {
    param([string]$Message)
    Write-Host "$Blue[INFO]$Reset $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "$Green[SUCCESS]$Reset $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "$Yellow[WARNING]$Reset $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "$Red[ERROR]$Reset $Message"
}

Write-Info "开始修复 star-cloud 服务端口配置..."
Write-Info "服务器: $ServerUser@$ServerHost`:$ServerPort"

# 检查SSH密钥是否存在
$SshOpts = ""
if (Test-Path $SshKeyPath) {
    Write-Info "使用SSH密钥: $SshKeyPath"
    $SshOpts = "-i $SshKeyPath"
} else {
    Write-Warning "SSH密钥不存在: $SshKeyPath"
    Write-Info "尝试使用密码认证..."
}

# 构建SSH命令
$SshCmd = "ssh $SshOpts -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p $ServerPort $ServerUser@$ServerHost"

# 修复脚本内容
$FixScript = @"
set -e

PROJECT_DIR='/srv/apps/axi-star-cloud'
SERVICE_FILE="\$PROJECT_DIR/star-cloud.service"

echo '🔧 检查项目目录...'
if [ ! -d "\$PROJECT_DIR" ]; then
    echo '❌ 项目目录不存在: \$PROJECT_DIR'
    exit 1
fi

echo '📁 项目目录: \$PROJECT_DIR'
ls -la "\$PROJECT_DIR/"

echo '🔧 修复 systemd 服务文件...'
if [ -f "\$SERVICE_FILE" ]; then
    echo '📝 备份原服务文件...'
    sudo cp "\$SERVICE_FILE" "\$SERVICE_FILE.backup.\$(date +%Y%m%d_%H%M%S)"
    
    echo '📝 更新服务文件，添加 SERVICE_PORT 环境变量...'
    # 检查是否已有 SERVICE_PORT 环境变量
    if grep -q 'SERVICE_PORT=' "\$SERVICE_FILE"; then
        echo '🔄 更新现有的 SERVICE_PORT 环境变量...'
        sudo sed -i 's/SERVICE_PORT=.*/SERVICE_PORT=8124/' "\$SERVICE_FILE"
    else
        echo '➕ 添加 SERVICE_PORT 环境变量...'
        sudo sed -i '/Environment=GIN_MODE=release/a Environment=SERVICE_PORT=8124' "\$SERVICE_FILE"
    fi
    
    echo '✅ 服务文件已更新'
    echo '📋 更新后的服务文件内容:'
    cat "\$SERVICE_FILE"
else
    echo '❌ 服务文件不存在: \$SERVICE_FILE'
    exit 1
fi

echo '🔧 修复 Go 应用配置文件...'
CONFIG_FILE="\$PROJECT_DIR/backend/config/config-prod.yaml"
if [ -f "\$CONFIG_FILE" ]; then
    echo '📝 备份原配置文件...'
    sudo cp "\$CONFIG_FILE" "\$CONFIG_FILE.backup.\$(date +%Y%m%d_%H%M%S)"
    
    echo '📝 更新端口配置...'
    sudo sed -i "s/port: '8080'/port: '8124'/" "\$CONFIG_FILE"
    
    echo '📝 更新 CORS 配置...'
    if ! grep -q "localhost:8124" "\$CONFIG_FILE"; then
        sudo sed -i "/localhost:8080/a\\    - 'http://localhost:8124'" "\$CONFIG_FILE"
    fi
    
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
"@

# 执行修复脚本
Write-Info "执行修复脚本..."
try {
    $result = Invoke-Expression "$SshCmd `"$FixScript`""
    Write-Host $result
} catch {
    Write-Error "执行失败: $_"
    exit 1
}

Write-Success "star-cloud 服务端口配置修复完成！"
Write-Info "服务现在应该在端口 8124 上运行"
Write-Info "可以使用以下命令检查服务状态："
Write-Host "  ssh $ServerUser@$ServerHost 'sudo systemctl status star-cloud.service'"
Write-Host "  ssh $ServerUser@$ServerHost 'netstat -tlnp | grep 8124'"
Write-Host "  ssh $ServerUser@$ServerHost 'curl http://localhost:8124/health'"
